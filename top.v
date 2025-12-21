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

    reg [3:0] state, next_state;

    localparam START_SCENE = 4'h0;
    localparam PLAY_SCENE = 4'h1;
    localparam LOSE_SCENE = 4'h2;
    localparam WIN_SCENE = 4'h3;

    always @(posedge clk, posedge rst) begin
        if (rst) begin 
            state <= START_SCENE;
        end else begin 
            state <= next_state;
        end
    end

    
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
    reg [9:0] img_x, img_y, img_x_1, img_y_1;
    reg [2:0] frame_idx = 0; reg [2:0] frame_idx_1 = 0;
    reg [31:0] cnt, cnt_1;
    // --- 角色移動狀態判斷 ---
    wire is_moving, is_moving_1;
    reg prev_moving, prev_moving_1; // 用於偵測狀態切換
    reg face_left, face_left_1; 

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

    always @(posedge clk_25MHz or posedge rst) begin
        if (rst) begin
            cnt_1 <= 0;
            frame_idx_1 <= 0;
            prev_moving_1 <= 0;
        end else begin 
            // 如果狀態從移動變靜止（或反之），立刻重置幀索引，避免索引超出邊界
            if (is_moving_1 != prev_moving_1) begin
                frame_idx_1 <= 0;
                cnt_1 <= 0;
                prev_moving_1 <= is_moving_1;
            end else begin
                cnt_1 <= cnt_1 + 1;
                // 調整動畫播放速度 (25MHz 下，4,000,000 約 0.16秒一幀)
                if (cnt_1 >= 4000000) begin 
                    cnt_1 <= 0;
                    if (is_moving_1) begin
                        // 走路動畫 6 格 (0-5)
                        if (frame_idx_1 >= 5) frame_idx_1 <= 0;
                        else frame_idx_1 <= frame_idx_1 + 1;
                    end else begin
                        // 待機動畫 4 格 (0-3)
                        if (frame_idx_1 >= 3) frame_idx_1 <= 0;
                        else frame_idx_1 <= frame_idx_1 + 1;
                    end
                end
            end
        end
    end

    wire show_pixel_sync;
    wire [3:0] current_id_sync;
    wire [4:0] gate_open;
    wire is_char_sync, is_char_sync_1;
    
    // --- 實例化地址生成器 (記得接上 is_moving) ---
    mem_addr_gen mem_addr_gen_inst(
        .clk(clk_25MHz),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .vsync(vsync),
        .img_x(img_x),
        .img_x_1(img_x_1),
        .img_y(img_y),
        .img_y_1(img_y_1),
        .frame_idx(frame_idx),
        .frame_idx_1(frame_idx_1),
        .is_moving(is_moving),      // 傳入移動狀態
        .is_moving_1(is_moving_1),
        .pixel_addr(pixel_addr),
        .out_show_pixel(show_pixel_sync),
        .face_left(face_left),
        .face_left_1(face_left_1),
        .out_tile_id(current_id_sync),
        .gate_open(gate_open),
        .out_is_char_sync(is_char_sync),
        .out_is_char_sync_1(is_char_sync_1),
        .state(state)
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

    
    

    //keyboard===============================================================================================================
    localparam KEY_CODES_1 = 9'b0_0001_0110;
    localparam KEY_CODES_2 = 9'b0_0001_1110;
    localparam KEY_CODES_3 = 9'b0_0010_0110;
    localparam KEY_CODES_4 = 9'b0_0010_0101;
    localparam KEY_CODES_5 = 9'b0_0010_1110;
    localparam KEY_CODES_6 = 9'b0_0011_0110;
    localparam KEY_CODES_7 = 9'b0_0011_1101;
    localparam KEY_CODES_8 = 9'b0_0011_1110;
    localparam KEY_CODES_A = 9'h1C;
    localparam KEY_CODES_D = 9'h23;
    localparam KEY_CODES_SPACE = 9'h29;

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
    
    localparam IMG_W = 32; // 圖片寬度
    localparam IMG_H = 32; // 圖片高度
    
    wire joy_left   = (jstk_X < 10'd400);
    wire joy_right  = (jstk_X > 10'd600);
    wire joy_up     = (jstk_Y < 10'd400);
    wire joy_down   = (jstk_Y > 10'd600);

    assign is_moving = joy_left || joy_right;
    assign is_moving_1 = (key_down && (last_change == KEY_CODES_A || last_change == KEY_CODES_D));
    
    reg jumping;
    reg on_ground;
    reg jumping_1;
    reg on_ground_1;        

    // --- 地圖數據 (20x15) ---
    wire [79:0] map [0:14];

    localparam T_EMPTY = 4'h0; //不能改這個數字!!
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

    // --- 多點碰撞偵測點 ---
    wire [9:0] char_L = img_x;
    wire [9:0] char_R = img_x + 31;
    wire [9:0] char_T = img_y;
    wire [9:0] char_B = img_y + 31;


    wire [9:0] char_L_1 = img_x_1;
    wire [9:0] char_R_1 = img_x_1 + 31;
    wire [9:0] char_T_1 = img_y_1;
    wire [9:0] char_B_1 = img_y_1 + 31;

    // 1. 垂直偵測：左腳(L+4)與右腳(R-4)
    wire [4:0] grid_L_foot = (char_L + 4) >> 5;
    wire [4:0] grid_R_foot = (char_R - 4) >> 5;
    wire [3:0] grid_below  = (char_B + 1) >> 5; 

    wire [4:0] grid_L_foot_1 = (char_L_1 + 4) >> 5;
    wire [4:0] grid_R_foot_1 = (char_R_1 - 4) >> 5;
    wire [3:0] grid_below_1  = (char_B_1 + 1) >> 5; 
    
    // 取得腳下兩點的 Tile ID
    wire [3:0] tile_id_below_L = (grid_below < 15) ? map[grid_below][(19 - grid_L_foot)*4 +: 4] : T_WALL;
    wire [3:0] tile_id_below_R = (grid_below < 15) ? map[grid_below][(19 - grid_R_foot)*4 +: 4] : T_WALL;

    wire [3:0] tile_id_below_L_1 = (grid_below_1 < 15) ? map[grid_below_1][(19 - grid_L_foot_1)*4 +: 4] : T_WALL;
    wire [3:0] tile_id_below_R_1 = (grid_below_1 < 15) ? map[grid_below_1][(19 - grid_R_foot_1)*4 +: 4] : T_WALL;
    // 只要不是 EMPTY 就視為地板
    wire tile_below = (tile_id_below_L >= T_PLATE_1) || (tile_id_below_R >= T_PLATE_1)
                     || (tile_id_below_L == T_GATE_1 && !gate_open[4]) || (tile_id_below_R == T_GATE_3 && !gate_open[4])
                     || (tile_id_below_L == T_GATE_2 && !gate_open[3]) || (tile_id_below_R == T_GATE_2 && !gate_open[3])
                     || (tile_id_below_L == T_GATE_3 && !gate_open[2]) || (tile_id_below_R == T_GATE_1 && !gate_open[2]);
    wire tile_below_1 = (tile_id_below_L_1 >= T_PLATE_1) || (tile_id_below_R_1 >= T_PLATE_1)
                     || (tile_id_below_L_1 == T_GATE_1 && !gate_open[4]) || (tile_id_below_R_1 == T_GATE_3 && !gate_open[4])
                     || (tile_id_below_L_1 == T_GATE_2 && !gate_open[3]) || (tile_id_below_R_1 == T_GATE_2 && !gate_open[3])
                     || (tile_id_below_L_1 == T_GATE_3 && !gate_open[2]) || (tile_id_below_R_1 == T_GATE_1 && !gate_open[2]);

    assign gate_open = {(tile_id_below_L == T_PLATE_1 || tile_id_below_L_1 == T_PLATE_1), (tile_id_below_L == T_PLATE_2 || tile_id_below_L_1 == T_PLATE_2), (tile_id_below_L == T_PLATE_3 || tile_id_below_L_1 == T_PLATE_3), 2'b0};

    // 2. 水平偵測
    wire [4:0] grid_next_R = (char_R + 5) >> 5;
    wire [4:0] grid_next_L = (char_L >= 5) ? (char_L - 5) >> 5 : 0;
    wire [3:0] grid_mid_y  = (char_T + 16) >> 5;
    wire [3:0] grid_top_y  = (char_T + 4) >> 5;

    wire [4:0] grid_next_R_1 = (char_R_1 + 5) >> 5;
    wire [4:0] grid_next_L_1 = (char_L_1 >= 5) ? (char_L_1 - 5) >> 5 : 0;
    wire [3:0] grid_mid_y_1  = (char_T_1 + 16) >> 5;
    wire [3:0] grid_top_y_1  = (char_T_1 + 4) >> 5;
    
    // 右側偵測
    wire [3:0] tile_id_R_mid = (grid_next_R < 20) ? map[grid_mid_y][(19 - grid_next_R)*4 +: 4] : T_EMPTY;
    wire [3:0] tile_id_R_top = (grid_next_R < 20) ? map[grid_top_y][(19 - grid_next_R)*4 +: 4] : T_EMPTY;
    wire wall_R = (tile_id_R_mid >= T_PLATE_1) || (tile_id_R_top >= T_PLATE_1)
                || (tile_id_R_mid == T_GATE_1 && !gate_open[4]) || (tile_id_R_top == T_GATE_1 && !gate_open[4])
                || (tile_id_R_mid == T_GATE_2 && !gate_open[3]) || (tile_id_R_top == T_GATE_2 && !gate_open[3])
                || (tile_id_R_mid == T_GATE_3 && !gate_open[2]) || (tile_id_R_top == T_GATE_3 && !gate_open[2]);

    wire [3:0] tile_id_R_mid_1 = (grid_next_R_1 < 20) ? map[grid_mid_y_1][(19 - grid_next_R_1)*4 +: 4] : T_EMPTY;//不會有門
    wire [3:0] tile_id_R_top_1 = (grid_next_R_1 < 20) ? map[grid_top_y_1][(19 - grid_next_R_1)*4 +: 4] : T_EMPTY;
    wire wall_R_1 = (tile_id_R_mid_1 >= T_PLATE_1) || (tile_id_R_top_1 >= T_PLATE_1)
                || (tile_id_R_mid_1 == T_GATE_1 && !gate_open[4]) || (tile_id_R_top_1 == T_GATE_1 && !gate_open[4])
                || (tile_id_R_mid_1 == T_GATE_2 && !gate_open[3]) || (tile_id_R_top_1 == T_GATE_2 && !gate_open[3])
                || (tile_id_R_mid_1 == T_GATE_3 && !gate_open[2]) || (tile_id_R_top_1 == T_GATE_3 && !gate_open[2]);


    // 左側偵測
    wire [3:0] tile_id_L_mid = (char_L >= 5) ? map[grid_mid_y][(19 - grid_next_L)*4 +: 4] : T_WALL;
    wire [3:0] tile_id_L_top = (char_L >= 5) ? map[grid_top_y][(19 - grid_next_L)*4 +: 4] : T_WALL;
    wire wall_L = (tile_id_L_mid >= T_PLATE_1) || (tile_id_L_top >= T_PLATE_1)
                || (tile_id_L_mid == T_GATE_1 && !gate_open[4]) || (tile_id_L_top == T_GATE_1 && !gate_open[4])
                || (tile_id_L_mid == T_GATE_2 && !gate_open[3]) || (tile_id_L_top == T_GATE_2 && !gate_open[3])
                || (tile_id_L_mid == T_GATE_3 && !gate_open[2]) || (tile_id_L_top == T_GATE_3 && !gate_open[2]);

    wire [3:0] tile_id_L_mid_1 = (char_L_1 >= 5) ? map[grid_mid_y_1][(19 - grid_next_L_1)*4 +: 4] : T_WALL;
    wire [3:0] tile_id_L_top_1 = (char_L_1 >= 5) ? map[grid_top_y_1][(19 - grid_next_L_1)*4 +: 4] : T_WALL;
    wire wall_L_1 = (tile_id_L_mid_1 >= T_PLATE_1) || (tile_id_L_top_1 >= T_PLATE_1)
                || (tile_id_L_mid_1 == T_GATE_1 && !gate_open[4]) || (tile_id_L_top_1 == T_GATE_1 && !gate_open[4])
                || (tile_id_L_mid_1 == T_GATE_2 && !gate_open[3]) || (tile_id_L_top_1 == T_GATE_2 && !gate_open[3])
                || (tile_id_L_mid_1 == T_GATE_3 && !gate_open[2]) || (tile_id_L_top_1 == T_GATE_3 && !gate_open[2]);

    // 3. 頭頂偵測
    wire [3:0] grid_above = (char_T > 0) ? (char_T - 1) >> 5 : 0;
    wire [3:0] tile_id_above_L = (char_T > 0) ? map[grid_above][(19 - grid_L_foot)*4 +: 4] : T_EMPTY;
    wire [3:0] tile_id_above_R = (char_T > 0) ? map[grid_above][(19 - grid_R_foot)*4 +: 4] : T_EMPTY;
    wire hitting_ceiling = (tile_id_above_L >= T_PLATE_1) || (tile_id_above_R >= T_PLATE_1)
                || (tile_id_above_L == T_GATE_1 && !gate_open[4]) || (tile_id_above_R == T_GATE_1 && !gate_open[4])
                || (tile_id_above_L == T_GATE_2 && !gate_open[3]) || (tile_id_above_R == T_GATE_2 && !gate_open[3])
                || (tile_id_above_L == T_GATE_3 && !gate_open[2]) || (tile_id_above_R == T_GATE_3 && !gate_open[2]);

    wire [3:0] grid_above_1 = (char_T_1 > 0) ? (char_T_1 - 1) >> 5 : 0;
    wire [3:0] tile_id_above_L_1 = (char_T_1 > 0) ? map[grid_above_1][(19 - grid_L_foot_1)*4 +: 4] : T_EMPTY;
    wire [3:0] tile_id_above_R_1 = (char_T_1 > 0) ? map[grid_above_1][(19 - grid_R_foot_1)*4 +: 4] : T_EMPTY;
    wire hitting_ceiling_1 = (tile_id_above_L_1 >= T_PLATE_1) || (tile_id_above_R_1 >= T_PLATE_1)
                || (tile_id_above_L_1 == T_GATE_1 && !gate_open[4]) || (tile_id_above_R_1 == T_GATE_1 && !gate_open[4])
                || (tile_id_above_L_1 == T_GATE_2 && !gate_open[3]) || (tile_id_above_R_1 == T_GATE_2 && !gate_open[3])
                || (tile_id_above_L_1 == T_GATE_3 && !gate_open[2]) || (tile_id_above_R_1 == T_GATE_3 && !gate_open[2]);

    reg [9:0] jump_start_y;
    reg [9:0] jump_start_y_1;
    // --- 跳躍與移動邏輯 (保持不變) ---
    always @(posedge sndRec or posedge rst) begin
        if (rst) begin
            img_x <= 10'd32;
            img_y <= 10'd320;
            img_x_1 <= 10'd32;
            img_y_1 <= 10'd416;
            jumping <= 0;
            jumping_1 <= 0;
            on_ground <= 1;
            on_ground_1 <= 1;
            face_left <= 0;
            face_left_1 <= 0;
        end else begin
            if (joy_left && img_x >= 5 && !wall_L) begin
                img_x <= img_x - 5; face_left <= 1;
            end else if (joy_right && img_x < (640 - 32 - 5) && !wall_R) begin
                img_x <= img_x + 5; face_left <= 0;
            end

            if (key_down && last_change == KEY_CODES_A && !wall_L_1) begin 
                img_x_1 <= img_x_1 - 5; face_left_1 <= 1;
            end else if (key_down && last_change == KEY_CODES_D && !wall_R_1) begin 
                img_x_1 <= img_x_1 + 5; face_left_1 <= 0;
            end

            if (jumping) begin
                if (hitting_ceiling || img_y <= jump_start_y - 64 || img_y <= 10) begin
                    jumping <= 0;
                end else begin
                    img_y <= img_y - 5;
                end
            end 
            else begin
                if (tile_below || img_y >= 416) begin
                    on_ground <= 1;
                    if (img_y >= 416) img_y <= 416;
                    else img_y <= (grid_below << 5) - 32;
                end else begin
                    on_ground <= 0;
                    img_y <= img_y + 5;
                end
            end

            if (jumping_1) begin
                if (hitting_ceiling_1 || img_y_1 <= jump_start_y_1 - 64 || img_y_1 <= 10) begin
                    jumping_1 <= 0;
                end else begin
                    img_y_1 <= img_y_1 - 5;
                end
            end 
            else begin
                if (tile_below_1 || img_y_1 >= 416) begin
                    on_ground_1 <= 1;
                    if (img_y_1 >= 416) img_y_1 <= 416;
                    else img_y_1 <= (grid_below_1 << 5) - 32;
                end else begin
                    on_ground_1 <= 0;
                    img_y_1 <= img_y_1 + 5;
                end
            end

            if (jstkData[1] && on_ground && !jumping) begin
                jumping <= 1;
                on_ground <= 0;
                jump_start_y <= img_y;
            end

            if (key_down && last_change == KEY_CODES_SPACE && on_ground_1 && !jumping_1) begin 
                jumping_1 <= 1;
                on_ground_1 <= 0;
                jump_start_y_1 <= img_y_1;
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

    reg [3:0] spike_sec;
    reg [31:0] cnt_spike;
    wire spike_on = (spike_sec > 3'b100);

    always @(posedge clk, posedge rst) begin
        if (rst) begin 
            spike_sec <= 0;
            cnt_spike <= 0;
        end else begin 
            cnt_spike <= cnt_spike + 1;
            if (cnt_spike >= 100000000) begin
                cnt_spike <= 0;
                spike_sec <= spike_sec + 1;
            end
        end
    end

    // 3. 顯示邏輯
    always @(*) begin
        if (!valid_sync) begin
            {vgaRed, vgaGreen, vgaBlue} = 12'h000;
        end else if (show_pixel_sync) begin
            {vgaRed, vgaGreen, vgaBlue} = pixel;
            if (!is_char_sync && !is_char_sync_1) begin
                if (current_id_sync == T_PLATE_1 || current_id_sync == T_GATE_1) begin //這個也要延遲三拍
                    if (current_id_sync == T_GATE_1 && gate_open[4]) {vgaRed, vgaGreen, vgaBlue} = 12'h000;
                    else vgaRed = 4'hF;
                end else if (current_id_sync == T_PLATE_2 || current_id_sync == T_GATE_2) begin 
                    if (current_id_sync == T_GATE_2 && gate_open[3]) {vgaRed, vgaGreen, vgaBlue} = 12'h000;
                    else vgaGreen = 4'hF;
                end else if (current_id_sync == T_PLATE_3 || current_id_sync == T_GATE_3) begin 
                    if (current_id_sync == T_GATE_3 && gate_open[2]) {vgaRed, vgaGreen, vgaBlue} = 12'h000;
                    else vgaBlue = 4'hF;
                end else if (current_id_sync == T_SPIKE) begin
                    if (spike_on) {vgaRed, vgaGreen, vgaBlue} = pixel;
                    else {vgaRed, vgaGreen, vgaBlue} = 12'h000;
                end
            end
            
            
            
        end else begin
            {vgaRed, vgaGreen, vgaBlue} = 12'h000;
        end
    end

    wire step_on_spike = spike_on && (map[char_B >> 5][(19 - (char_L >> 5))*4 +: 4] == T_SPIKE || map[char_B >> 5][(19 - (char_R >> 5))*4 +: 4] == T_SPIKE ||
                         map[char_B_1 >> 5][(19 - (char_L_1 >> 5))*4 +: 4] == T_SPIKE || map[char_B_1 >> 5][(19 - (char_R_1 >> 5))*4 +: 4] == T_SPIKE);
    
    reg [2:0] lose_sec;
    reg [31:0] cnt_lose;
    always @(posedge clk, posedge rst) begin
        if (rst) begin 
            lose_sec <= 0;
            cnt_lose <= 0;
        end else begin 
            if (state == LOSE_SCENE) begin 
                cnt_lose <= cnt_lose + 1;
                if (cnt_lose >= 10000000000) begin 
                    cnt_lose <= 0;
                    lose_sec <= lose_sec + 1;
                end
            end else begin 
                lose_sec <= 0;
                cnt_lose <= 0;
            end
        end
    end
    
    always @(*) begin
        next_state = state; 
        if (state == START_SCENE) begin 
            if (key_down && last_change == KEY_CODES_1) next_state = PLAY_SCENE;
        end else if (state == PLAY_SCENE) begin 
            if (step_on_spike) next_state = LOSE_SCENE;
        end else if (state == LOSE_SCENE) begin 
            if (lose_sec >= 5) next_state = START_SCENE;
        end
    end

endmodule

//1026 tile 32*32 (0-1023)
//5122 idle 128*32 4張(1024-5119)
//11266 walk 192*32 6張(5120-11263)
//12290 exit 32*32 (11264-12287)
//13314 jail 32*32 (12288-13311)
//17410 第二隻idle 128*32 (13312-17407)
//23554 第二隻walk 192*32 (17408-23551)
//24578 spike 32*32 (23552-24575)
//43778 start 160*120 (24576-43775)
//角色32*32