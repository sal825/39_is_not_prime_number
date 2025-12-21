module mem_addr_gen(
    input clk,              // 25MHz VGA 像素時鐘
    input rst,              // 非同步重置訊號
    input [9:0] h_cnt,      // VGA 當前掃描的水平像素座標 (0-639)
    input [9:0] v_cnt,      // VGA 當前掃描的垂直像素座標 (0-479)
    input vsync,            // 垂直同步訊號，用來在每幀畫面的開頭同步數據
    input [9:0] img_x,      // 來自控制邏輯的角色 X 座標
    input [9:0] img_x_1,
    input [9:0] img_y,      // 來自控制邏輯的角色 Y 座標
    input [9:0] img_y_1,
    input [2:0] frame_idx,  // 當前動畫播放到第幾幀 (例如 0~3 或 0~5)
    input [2:0] frame_idx_1,
    input is_moving,        // 角色是否正在移動 (決定播放哪組動畫)
    input is_moving_1,
    input face_left,        // 角色是否面向左邊 (決定是否鏡像翻轉)
    input face_left_1,
    input [4:0] gate_open,      // 新增：門是否開啟 (來自 Top)
    output reg [16:0] pixel_addr,     // 輸出給 BRAM 的讀取地址 (1D)
    output wire out_show_pixel,        // 輸出給 Top 的顯示開關 (經過延遲同步)
    output reg [3:0] out_tile_id, // 新增：同步後的 Tile ID 輸出
    output reg out_is_char_sync, // 新增：同步後的「正在畫角色」訊號
    output reg out_is_char_sync_1
    );

    // 角色圖塊的大小固定為 32x32 像素
    localparam IMG_W = 32;
    localparam IMG_H = 32;
    
    // --- 1. 座標同步暫存器 (Shadow Registers) ---
    // 目的：為了解決搖桿不同步產生的雜訊線。
    // 在每幀畫面的 vsync 期間才鎖定一次 img_x/y，確保在繪製同一幀畫面時，角色的座標是固定的。
    reg [9:0] x_s, y_s;
    reg [9:0] x_s_1, y_s_1;
    always @(posedge vsync or posedge rst) begin
        if (rst) begin 
            {x_s, y_s} <= {10'd32, 10'd320}; 
            {x_s_1, y_s_1} <= {10'd32, 10'd416}; 
        end
        else begin
            {x_s, y_s} <= {img_x, img_y};
            {x_s_1, y_s_1} <= {img_x_1, img_y_1};
        end
    end

    // --- 2. 區域判斷 (Combinational Logic - T0 階段) ---
    // 判斷當前 VGA 掃描點 (h_cnt, v_cnt) 是否落在角色區域內
    wire is_char = (h_cnt >= x_s + 3 && h_cnt < x_s + IMG_W - 3) && (v_cnt >= y_s + 5 && v_cnt < y_s + IMG_H);
    wire is_char_1 = (h_cnt >= x_s_1 + 3 && h_cnt < x_s_1 + IMG_W - 3) && (v_cnt >= y_s_1 + 5 && v_cnt < y_s_1 + IMG_H);
    
    // 將螢幕座標轉為網格座標 (>> 5 等於除以 32)，用來查找 20x15 的地圖陣列
    wire [4:0] gx = h_cnt >> 5; 
    wire [3:0] gy = v_cnt >> 5;
    
    // --- 3. 地圖定義 (Map Array) ---
    // 每個 bit 代表一個 32x32 的區塊。1: 障礙物/地板, 0: 空地
    wire [79:0] map [0:14];

    
    localparam T_EMPTY = 4'h0;
    localparam T_SPIKE = 4'h1;
    localparam T_GATE_1  = 4'h2;
    localparam T_GATE_2  = 4'h3;
    localparam T_GATE_3  = 4'h4;
    localparam T_PLATE_1 = 4'h5;
    localparam T_PLATE_2 = 4'h6;
    localparam T_PLATE_3 = 4'h7;
    localparam T_EXIT  = 4'h8;
    localparam T_WALL  = 4'h9;
    assign map[0]  = {{19{T_EMPTY}}, {T_EMPTY}};
    assign map[1]  = {{10{T_EMPTY}}, {10{T_WALL}}}; 
    assign map[2]  = {20{T_EMPTY}};
    assign map[3]  = {{10{T_WALL}}, {10{T_EMPTY}}};
    assign map[4]  = {20{T_EMPTY}};
    assign map[5]  = {{10{T_WALL}}, {10{T_EMPTY}}};
    assign map[6]  = {20{T_EMPTY}};
    assign map[7]  = {{10{T_WALL}}, {10{T_EMPTY}}};
    assign map[8]  = {20{T_EMPTY}};
    assign map[9]  = {{7{T_EMPTY}}, T_GATE_1, {4{T_EMPTY}}, T_GATE_2, {4{T_EMPTY}}, T_GATE_3, T_EMPTY, T_EXIT};
    assign map[10] = {{5{T_EMPTY}}, T_SPIKE, T_EMPTY, T_GATE_1, {4{T_EMPTY}}, T_GATE_2, {4{T_EMPTY}}, T_GATE_3, T_EMPTY, T_EXIT};
    assign map[11] = {{2{T_WALL}}, {3{T_PLATE_1}}, {15{T_WALL}}};
    assign map[12] = {20{T_EMPTY}};
    assign map[13] = {{2{T_EMPTY}}, T_SPIKE, T_EMPTY, T_GATE_1, {10{T_EMPTY}}, {5{T_PLATE_3}}};
    assign map[14] = {{5{T_WALL}}, {5{T_PLATE_1}}, {5{T_PLATE_2}}, {5{T_WALL}}};


    wire [3:0] current_tile_id = (h_cnt < 640 && v_cnt < 480) ? map[gy][(19-gx)*4 +: 4] : T_EMPTY;//往上取4個bit
    // 判斷當前掃描點是否落在地圖中的「1」區域
    wire is_tile = (current_tile_id == T_WALL) || 
                   (current_tile_id == T_SPIKE) || 
                   (current_tile_id == T_EXIT) || 
                   (current_tile_id == T_PLATE_1) ||
                   (current_tile_id == T_PLATE_2) ||
                   (current_tile_id == T_PLATE_3) ||
                   (current_tile_id == T_GATE_1 && !gate_open[4]) ||
                   (current_tile_id == T_GATE_2 && !gate_open[3]) ||
                   (current_tile_id == T_GATE_3 && !gate_open[2]);
    
    // 最終顯示開關：只要是角色或是地圖塊就要亮起顏色
    //wire comb_show = is_char || is_char_1 || is_tile;

    // --- 4. 地址計算 (組合邏輯) ---
    reg [7:0] coeff;     // 當前讀取圖片的總寬度 (換行計算用)
    reg [9:0] lx, ly;    // 在單一圖塊內的局部 X, Y 座標
    reg [16:0] b_off;    // 在 COE 檔案中的起始偏移地址
    wire [4:0] rel_x = h_cnt - x_s; // 掃描點相對於角色左上角的 X 距離 (0-31)
    wire [4:0] rel_x_1 = h_cnt - x_s_1;

    always @(*) begin
        // 預設初始化，防止產生 Latch
        lx = 0; ly = 0; b_off = 0; coeff = 1;
        
        if (is_tile) begin
            // 地板/牆壁模式
            lx = h_cnt[4:0];    // 等同於 h_cnt % 32
            ly = v_cnt[4:0];    // 等同於 v_cnt % 32
            b_off = 0;          // 地板圖磚在 COE 最前面 (0)
            coeff = 32;         // 地板圖檔原始寬度是 32
            case (current_tile_id)
                T_WALL:  b_off = 0;
                T_EXIT:  b_off = 11264;
                T_PLATE_1: b_off = 0;
                T_GATE_1:  b_off = 12288;
                T_PLATE_2: b_off = 0;
                T_GATE_2:  b_off = 12288;
                T_PLATE_3: b_off = 0;
                T_GATE_3:  b_off = 12288;
                T_SPIKE: b_off = 23552;
                default: b_off = 0;
            endcase
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
        end else if (is_char_1) begin 
            // 角色模式
            ly = (v_cnt - y_s_1); // 垂直相對座標
            
            // 處理鏡像與動畫位址
            if (is_moving_1) begin
                // 走路動畫 (Walk): 寬度 192, 位於位址 8192
                // (face_left ? (31 - rel_x) : rel_x) 實現硬體鏡像翻轉
                lx = (face_left_1 ? (5'd31 - rel_x_1) : rel_x_1) + (frame_idx_1 * 32);
                b_off = 17408;
                coeff = 192;
            end else begin
                // 待機動畫 (Idle): 寬度 128, 位於位址 4096
                lx = (face_left_1 ? (5'd31 - rel_x_1) : rel_x_1) + (frame_idx_1 * 32);
                b_off = 13312;
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
    reg [3:0] id_pipe_1, id_pipe_2, id_pipe_3; // ID 的延遲鏈
    reg [1:0] char_p;
    reg [1:0] char_p_1;
    reg [3:0] delay_pipe; 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pixel_addr <= 0;
            delay_pipe <= 4'b0000;
            {id_pipe_1, id_pipe_2, id_pipe_3, out_tile_id} <= 0;
            {char_p, char_p_1, out_is_char_sync, out_is_char_sync_1} <= 0;
        end else begin
            // 計算 1D 地址公式：起始位址 + (列偏移 * 圖片寬) + 行偏移
            pixel_addr <= b_off + (ly * coeff) + lx;
            
            // 將顯示開關推入移位暫存器
            //delay_pipe <= {delay_pipe[2:0], comb_show};
            delay_pipe <= {delay_pipe[2:0], (is_char || is_char_1 || (current_tile_id != 4'h0))};
            // Tile ID 也要同步延遲 3 拍 (對齊 delay_pipe[2])
            id_pipe_1 <= current_tile_id;
            id_pipe_2 <= id_pipe_1;
            out_tile_id <= id_pipe_2; // 此輸出會與 BRAM 的 pixel 同時抵達

            // 同步「是否正在畫角色」訊號
            char_p <= {char_p[0], is_char};
            char_p_1 <= {char_p_1[0], is_char_1};
            out_is_char_sync <= char_p[1];
            out_is_char_sync_1 <= char_p_1[1];
        end
    end

    // 延遲 3 個時脈週期後的訊號，此時 BRAM 剛好吐出對應位址的顏色
    assign out_show_pixel = delay_pipe[2]; 

endmodule