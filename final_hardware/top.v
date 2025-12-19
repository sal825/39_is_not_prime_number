module top(
    input wire clk,
    input wire rst,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    input wire [15:0] sw,//[0]是音樂開關
    output reg [15:0] LED,
    output wire audio_mclk, // master clock
    output wire audio_lrck, // left-right clock
    output wire audio_sck,  // serial clock
    output wire audio_sdin, // serial audio data input
    output wire [6:0] DISPLAY,
    output wire [3:0] DIGIT,
    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue,
    output  hsync,
    output  vsync,
    input wire MISO,
    output wire SS,
    output wire MOSI,
    output wire SCLK,
    input wire MISO_1,
    output wire SS_1,
    output wire MOSI_1,
    output wire SCLK_1,
    output reg [3:0] data_out
    );

    reg [3:0] state;
    
    //MUSIC==========================================================================================
    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;
    reg [11:0] ibeatNum;    // 目前第幾拍 (0~4095)
    reg en;                 // 音樂開關
    wire [31:0] toneL, toneR;
    wire [21:0] freq_outL = 50000000 / toneL;
    wire [21:0] freq_outR = 50000000 / toneR;
    wire clk22;
    clock_divider #(.n(22)) clock_22(.clk(clk), .clk_div(clk22));    // for display

    always @(posedge clk22 or posedge rst) begin
        if (rst)
            ibeatNum <= 0;
        else begin
            if (en == 0 || ibeatNum == 12'd1200) ibeatNum <= 12'd0;          // 播完一輪後重頭開始
            else ibeatNum <= ibeatNum + 1;
        end
    end

    reg [1:0] volume;
    always @(posedge clk, posedge rst) begin//later 改
        if (rst) begin
            en <= 0;    // 按 reset 就開始播音樂
            volume <= 2'b00;
        end else begin
            if (sw[0] || sw[1]) begin 
                en <= 1;
                volume <= sw[1:0];
            end
            else en <= 0;
        end
    end

    music_wii music(
        .ibeatNum(ibeatNum),
        .en(en),
        .toneL(toneL),
        .toneR(toneR)
    );

    note_gen noteGen_00(
        .clk(clk), 
        .rst(rst), 
        .volume(volume),
        .note_div_left(freq_outL),
        .note_div_right(freq_outR),
        .audio_left(audio_in_left),
        .audio_right(audio_in_right)
    );

    speaker_control sc(
        .clk(clk), 
        .rst(rst), 
        .audio_in_left(audio_in_left),
        .audio_in_right(audio_in_right),
        .audio_mclk(audio_mclk),
        .audio_lrck(audio_lrck),
        .audio_sck(audio_sck),
        .audio_sdin(audio_sdin)
    );

    //VGA==========================================================================================================

    wire [11:0] data;
    wire clk_25MHz;
    clock_divider #(.n(2)) clock_25MHZ(.clk(clk), .clk_div(clk_25MHz));
    wire [16:0] pixel_addr;
    wire [11:0] pixel;
    wire valid;
    wire [9:0] h_cnt; //0-799（每掃一行就從 0 數到 799）0~639 是可視區
    wire [9:0] v_cnt;  //0-524（每掃完一行，v_cnt +1）0~479
    reg [9:0] img_x, img_y;
    reg [2:0] frame_idx = 0;
    reg [31:0] cnt;
    // --- 角色移動狀態判斷 ---
    wire is_moving;
    reg prev_moving; // 用於偵測狀態切換
    reg face_left; 

    // --- 動畫幀計數邏輯 ---
    always @(posedge clk_25MHz or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            frame_idx <= 0;
            prev_moving <= 0;
        end else begin 
            // 如果狀態從移動變靜止（或反之），立刻重置幀索引，避免索引超出邊界
            if (is_moving != prev_moving) begin
                frame_idx <= 0;
                cnt <= 0;
                prev_moving <= is_moving;
            end else begin
                cnt <= cnt + 1;
                // 調整動畫播放速度 (25MHz 下，4,000,000 約 0.16秒一幀)
                if (cnt >= 4000000) begin 
                    cnt <= 0;
                    if (is_moving) begin
                        // 走路動畫 6 格 (0-5)
                        if (frame_idx >= 5) frame_idx <= 0;
                        else frame_idx <= frame_idx + 1;
                    end else begin
                        // 待機動畫 4 格 (0-3)
                        if (frame_idx >= 3) frame_idx <= 0;
                        else frame_idx <= frame_idx + 1;
                    end
                end
            end
        end
    end

    wire show_pixel_sync;
    
    // --- 實例化地址生成器 (記得接上 is_moving) ---
    mem_addr_gen mem_addr_gen_inst(
        .clk(clk_25MHz),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .vsync(vsync),
        .img_x(img_x),
        .img_y(img_y),
        .frame_idx(frame_idx),
        .is_moving(is_moving),      // 傳入移動狀態
        .pixel_addr(pixel_addr),
        .out_show_pixel(show_pixel_sync),
        .face_left(face_left)
    );

    blk_mem_gen_0 blk_mem_gen_0_inst(
      .clka(clk_25MHz),
      .wea(0),
      .addra(pixel_addr),
      .dina(data[11:0]),
      .douta(pixel)
    ); 

    vga_controller   vga_inst(
      .pclk(clk_25MHz),
      .reset(rst),
      .hsync(hsync),
      .vsync(vsync),
      .valid(valid),
      .h_cnt(h_cnt),
      .v_cnt(v_cnt)
    );

    // 2. valid 也需要同步延遲 (對齊 show_pixel_sync)
    reg [3:0] valid_pipe;
    always @(posedge clk_25MHz) begin
        valid_pipe <= {valid_pipe[2:0], valid};
    end
    wire valid_sync = valid_pipe[2]; // 這裡的 index 要跟 mem_addr_gen 裡面的一樣

    // 3. 顯示邏輯
    always @(*) begin
        if (!valid_sync) begin
            {vgaRed, vgaGreen, vgaBlue} = 12'h000;
        end else if (show_pixel_sync) begin
            {vgaRed, vgaGreen, vgaBlue} = pixel; 
        end else begin
            {vgaRed, vgaGreen, vgaBlue} = 12'h000; 
        end
    end
    

    //keyboard===============================================================================================================
    localparam KEY_CODES_1 = 9'b0_0001_0110;
    localparam KEY_CODES_2 = 9'b0_0001_1110;
    localparam KEY_CODES_3 = 9'b0_0010_0110;
    localparam KEY_CODES_4 = 9'b0_0010_0101;
    localparam KEY_CODES_5 = 9'b0_0010_1110;
    localparam KEY_CODES_6 = 9'b0_0011_0110;
    localparam KEY_CODES_7 = 9'b0_0011_1101;
    localparam KEY_CODES_8 = 9'b0_0011_1110;

    wire [511:0] key_down;
    wire [8:0] last_change;
    wire key_valid;
    KeyboardDecoder key_de (
        .key_down(key_down), //每個鍵的狀態 1代表按下
        .last_change(last_change), //最後變化的鍵的9-bit code
        .key_valid(key_valid), //有鍵狀態變化時為1
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );

    //7-segment===============================================================================================================
    wire [15:0] nums;
    // segment_logic seg_lg(
    //     .nums(nums),
    //     .clk(clk),
    //     .rst(rst),
    //     .state(state)
    // );
    wire [9:0] posData;

    SevenSegment seg(
        .display(DISPLAY),
        .digit(DIGIT),
        .nums(posData),//只是測試用
        .rst(rst),
        .clk(clk)
    );

    //joy stick=============================================================================================================

    // Signal to send/receive data to/from PMOD peripherals
    wire sndRec;

    // Data read from PmodJSTK
    wire [39:0] jstkData;
    // Signal carrying joystick X data
    wire [9:0] XposData;
    // Signal carrying joystick Y data
    wire [9:0] YposData;
    // Holds data to be sent to PmodJSTK
    wire [9:0] sndData;
    
    PmodJSTK PmodJSTK_Int(
        .CLK(clk),
        .RST(rst),
        .sndRec(sndRec),
        .DIN(sndData),
        .MISO(MISO),
        .SS(SS),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .DOUT(jstkData)
    );

    
    ClkDiv_5Hz genSndRec(
            .CLK(clk),
            .RST(rst),
            .CLKOUT(sndRec)
    );

    // // Collect joystick state for position state
    // assign YposData = {jstkData[25:24], jstkData[39:32]};
    // assign XposData = {jstkData[9:8], jstkData[23:16]};

    // Use state of switch 0 to select output of X position or Y position data to SSD
    //我先隨便找三個switch，{jstkData[9:8], jstkData[23:16]}控制x， {jstkData[25:24], jstkData[39:32]}控制Y
    wire [9:0] jstk_X = {jstkData[9:8], jstkData[23:16]};
    wire [9:0] jstk_Y = {jstkData[25:24], jstkData[39:32]};
    
    localparam IMG_W = 32;//160; // 圖片寬度
    localparam IMG_H = 32;//120; // 圖片高度
    
    wire joy_left   = (jstk_X < 10'd400);
    wire joy_right  = (jstk_X > 10'd600);
    wire joy_up     = (jstk_Y < 10'd400);
    wire joy_down   = (jstk_Y > 10'd600);

    assign is_moving = joy_left || joy_right;
    
    reg jumping;
    reg on_ground;              
    parameter GROUND_Y = 416;  


    // --- 地圖數據 (20x15) ---
    wire [19:0] map [0:14];
    assign map[0]  = 20'b11111111111111111111;
    assign map[1]  = 20'b10000000000000000001;
    assign map[2]  = 20'b10000000000000001111;
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
    assign map[14] = 20'b11111111111111111111;
    // 其他填充 0... (請自行補齊 assign map[0...10, 12] = 0)

    // --- 多點碰撞偵測點 ---
    // 角色邊界
    wire [9:0] char_L = img_x;
    wire [9:0] char_R = img_x + 31;
    wire [9:0] char_T = img_y;
    wire [9:0] char_B = img_y + 31;

    // 1. 垂直偵測：左腳(L+4)與右腳(R-4)，只要有一隻腳踩到東西就不掉下去
    wire [4:0] grid_L_foot = (char_L + 4) >> 5;
    wire [4:0] grid_R_foot = (char_R - 4) >> 5;
    wire [3:0] grid_below  = (char_B + 1) >> 5; // 檢查腳下 1 像素
    
    wire tile_below = (grid_below < 15) ? (map[grid_below][19 - grid_L_foot] || map[grid_below][19 - grid_R_foot]) : 1;

    // 2. 水平偵測：同時檢查腰部與頭部高度，防止半個身子陷進牆壁
    wire [4:0] grid_next_R = (char_R + 5) >> 5;
    wire [4:0] grid_next_L = (char_L >= 5) ? (char_L - 5) >> 5 : 0;
    wire [3:0] grid_mid_y  = (char_T + 16) >> 5;
    wire [3:0] grid_top_y  = (char_T + 4) >> 5;
    
    wire wall_R = (grid_next_R < 20) ? (map[grid_mid_y][19 - grid_next_R] || map[grid_top_y][19 - grid_next_R]) : 0;
    wire wall_L = (char_L >= 5) ? (map[grid_mid_y][19 - grid_next_L] || map[grid_top_y][19 - grid_next_L]) : 1;

    // 3. 頭頂偵測
    wire [3:0] grid_above = (char_T > 0) ? (char_T - 1) >> 5 : 0;
    wire hitting_ceiling = (char_T > 0) ? (map[grid_above][19 - grid_L_foot] || map[grid_above][19 - grid_R_foot]) : 0;

    reg [9:0] jump_start_y;

    always @(posedge sndRec or posedge rst) begin
        if (rst) begin
            img_x <= 10'd32; img_y <= 10'd416;
            jumping <= 0; on_ground <= 1; face_left <= 0;
        end else begin
            // --- 左右移動 (包含牆壁偵測) ---
            if (joy_left && img_x >= 5 && !wall_L) begin
                img_x <= img_x - 5; face_left <= 1;
            end else if (joy_right && img_x < (640 - 32 - 5) && !wall_R) begin
                img_x <= img_x + 5; face_left <= 0;
            end

            // --- 垂直邏輯 ---
            if (jumping) begin
                if (hitting_ceiling || img_y <= jump_start_y - 64 || img_y <= 10) begin
                    jumping <= 0; // 撞頭或達高度，開始下落
                end else begin
                    img_y <= img_y - 5;
                end
            end 
            else begin
                // 下落或站在地面
                if (tile_below || img_y >= 416) begin
                    on_ground <= 1;
                    // --- 關鍵校準：吸附到地板表面 ---
                    if (img_y >= 416) img_y <= 416;
                    else img_y <= (grid_below << 5) - 32;
                end else begin
                    on_ground <= 0;
                    img_y <= img_y + 5;
                end
            end

            // 跳躍觸發
            if (jstkData[1] && on_ground && !jumping) begin
                jumping <= 1; on_ground <= 0; jump_start_y <= img_y;
            end
        end
    end

    // Data to be sent to PmodJSTK, lower two bits will turn on leds on PmodJSTK
    assign sndData = {8'b100000, {sw[6], sw[7]}};

    always @(sndRec or rst or jstkData) begin
            if(rst == 1'b1) begin
                    LED <= 3'b000;
            end
            else begin
                   LED <= {13'b0, jstkData[2], jstkData[1], jstkData[0]};//0是按搖桿，1是搖桿底下那顆按鈕

            end
    end
    

endmodule

//4098 tile 64*64 (0-4095)
//8194 idle 128*32 4張(4096-8191)
//14338 walk 192*32 6張(8192-14335)
//22530 jump 256*32 8張(14336-22527)
//角色32*32