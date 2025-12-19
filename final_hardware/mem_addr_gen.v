module mem_addr_gen(
    input clk,              // 25MHz VGA 像素時鐘
    input rst,              // 非同步重置訊號
    input [9:0] h_cnt,      // VGA 當前掃描的水平像素座標 (0-639)
    input [9:0] v_cnt,      // VGA 當前掃描的垂直像素座標 (0-479)
    input vsync,            // 垂直同步訊號，用來在每幀畫面的開頭同步數據
    input [9:0] img_x,      // 來自控制邏輯的角色 X 座標
    input [9:0] img_y,      // 來自控制邏輯的角色 Y 座標
    input [2:0] frame_idx,  // 當前動畫播放到第幾幀 (例如 0~3 或 0~5)
    input is_moving,        // 角色是否正在移動 (決定播放哪組動畫)
    input face_left,        // 角色是否面向左邊 (決定是否鏡像翻轉)
    output reg [16:0] pixel_addr,     // 輸出給 BRAM 的讀取地址 (1D)
    output wire out_show_pixel        // 輸出給 Top 的顯示開關 (經過延遲同步)
    );

    // 角色圖塊的大小固定為 32x32 像素
    localparam IMG_W = 32;
    localparam IMG_H = 32;
    
    // --- 1. 座標同步暫存器 (Shadow Registers) ---
    // 目的：為了解決搖桿不同步產生的雜訊線。
    // 在每幀畫面的 vsync 期間才鎖定一次 img_x/y，確保在繪製同一幀畫面時，角色的座標是固定的。
    reg [9:0] x_s, y_s;
    always @(posedge vsync or posedge rst) begin
        if (rst) {x_s, y_s} <= {10'd0, 10'd416};
        else {x_s, y_s} <= {img_x, img_y};
    end

    // --- 2. 區域判斷 (Combinational Logic - T0 階段) ---
    // 判斷當前 VGA 掃描點 (h_cnt, v_cnt) 是否落在角色區域內
    wire is_char = (h_cnt >= x_s && h_cnt < x_s + IMG_W) && (v_cnt >= y_s && v_cnt < y_s + IMG_H);
    
    // 將螢幕座標轉為網格座標 (>> 5 等於除以 32)，用來查找 20x15 的地圖陣列
    wire [4:0] gx = h_cnt >> 5; 
    wire [3:0] gy = v_cnt >> 5;
    
    // --- 3. 地圖定義 (Map Array) ---
    // 每個 bit 代表一個 32x32 的區塊。1: 障礙物/地板, 0: 空地
    wire [19:0] map [0:14];
    assign map[0]  = 20'b11111111111111111111; // 頂部牆壁
    assign map[1]  = 20'b10000000000000000001; 
    assign map[2]  = 20'b10000000000000001111; // 平台
    assign map[3]  = 20'b10110000000001000001;
    assign map[4]  = 20'b10000110000000000001;
    assign map[5]  = 20'b10000000111111100001;
    assign map[6]  = 20'b10000000000000000001;
    assign map[7]  = 20'b10000000000000011111;
    assign map[8]  = 20'b11110000110011100001;
    assign map[9]  = 20'b10000000000000000001;
    assign map[10] = 20'b10000011000000000001;
    assign map[11] = 20'b11111111111111000001;
    assign map[12] = 20'b10000000000000000001;
    assign map[13] = 20'b10000000000000011111;
    assign map[14] = 20'b11111111111111111111; // 地板

    // 判斷當前掃描點是否落在地圖中的「1」區域
    wire is_tile = (h_cnt < 640 && v_cnt < 480) ? map[gy][19-gx] : 0;
    
    // 最終顯示開關：只要是角色或是地圖塊就要亮起顏色
    wire comb_show = is_char || is_tile;

    // --- 4. 地址計算 (組合邏輯) ---
    reg [7:0] coeff;     // 當前讀取圖片的總寬度 (換行計算用)
    reg [9:0] lx, ly;    // 在單一圖塊內的局部 X, Y 座標
    reg [16:0] b_off;    // 在 COE 檔案中的起始偏移地址
    wire [4:0] rel_x = h_cnt - x_s; // 掃描點相對於角色左上角的 X 距離 (0-31)

    always @(*) begin
        // 預設初始化，防止產生 Latch
        lx = 0; ly = 0; b_off = 0; coeff = 1;
        
        if (is_tile) begin
            // 地板/牆壁模式
            lx = h_cnt[4:0];    // 等同於 h_cnt % 32
            ly = v_cnt[4:0];    // 等同於 v_cnt % 32
            b_off = 0;          // 地板圖磚在 COE 最前面 (0)
            coeff = 32;         // 地板圖檔原始寬度是 32
        end 
        else if (is_char) begin 
            // 角色模式
            ly = (v_cnt - y_s); // 垂直相對座標
            
            // 處理鏡像與動畫位址
            if (is_moving) begin
                // 走路動畫 (Walk): 寬度 192, 位於位址 8192
                // (face_left ? (31 - rel_x) : rel_x) 實現硬體鏡像翻轉
                lx = (face_left ? (5'd31 - rel_x) : rel_x) + (frame_idx * 32);
                b_off = 5120;
                coeff = 192;
            end else begin
                // 待機動畫 (Idle): 寬度 128, 位於位址 4096
                lx = (face_left ? (5'd31 - rel_x) : rel_x) + (frame_idx * 32);
                b_off = 1024;
                coeff = 128;
            end
        end 
    end

    // --- 5. 管線化與同步 (Pipeline - T1~T2 階段) ---
    // 核心原理：
    // T0: 算出地址計算所需零件。
    // T1: pixel_addr 存入暫存器輸出給 BRAM。
    // T2: BRAM 內部處理。
    // T3: BRAM 噴出數據。
    // 因此控制訊號 `out_show_pixel` 必須延遲對應的拍數才能跟顏色對齊。
    reg [3:0] delay_pipe; 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pixel_addr <= 0;
            delay_pipe <= 4'b0000;
        end else begin
            // 計算 1D 地址公式：起始位址 + (列偏移 * 圖片寬) + 行偏移
            pixel_addr <= b_off + (ly * coeff) + lx;
            
            // 將顯示開關推入移位暫存器
            delay_pipe <= {delay_pipe[2:0], comb_show};
        end
    end

    // 延遲 3 個時脈週期後的訊號，此時 BRAM 剛好吐出對應位址的顏色
    assign out_show_pixel = delay_pipe[2]; 

endmodule