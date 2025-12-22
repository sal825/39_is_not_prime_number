module top(
    input wire clk,
    input wire rst,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    input wire btnR,
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
    localparam BOSS_SCENE = 4'h4;
    wire clk_25MHz;
    always @(posedge clk_25MHz, posedge rst) begin
        if (rst) begin 
            state <= START_SCENE;
        end else begin 
            state <= next_state;
        end
    end

    wire btnR_db, btnR_op;
    debounce db1(.pb(btnR), .pb_debounced(btnR_db), .clk(clk_25MHz));
    onepulse op1(.signal(btnR_db), .clk(clk_25MHz), .op(btnR_op));

    reg [31:0] cnt_boss;
    reg [9:0] boss_sec;
    always @(posedge clk_25MHz, posedge rst) begin
        if (rst) begin 
            cnt_boss <= 0;
            boss_sec <= 0;
        end else begin 
            if (state != BOSS_SCENE) begin 
                cnt_boss <= 0;
                boss_sec <= 0;
            end else begin
                if (cnt_boss < 25000000) cnt_boss <= cnt_boss + 1;
                else begin 
                    cnt_boss <= 0;
                    boss_sec <= boss_sec + 1;
                end
            end
        end
    end

    
    //MUSIC==========================================================================================
    // Internal Signal
    wire clk22;
    clock_divider #(.n(22)) clock_22(.clk(clk), .clk_div(clk22));    // for display

    // --- 音樂相關訊號修正 ---
    wire [15:0] audio_in_left, audio_in_right;
    reg [11:0] ibeatNum;
    reg en_reg;               // 同步後的開關
    wire [31:0] toneL, toneR;
    
    // 關鍵修正 1：將頻率輸出改為暫存器 (Pipelining)
    reg [21:0] freq_outL_reg, freq_outR_reg;
    
    // 關鍵修正 2：音量與開關同步鎖存
    reg [1:0] volume_reg;
    always @(posedge clk) begin
        if (rst) begin
            volume_reg <= 2'b00;
            en_reg <= 0;
            freq_outL_reg <= 0;
            freq_outR_reg <= 0;
        end else begin
            // 鎖存開關與音量，對齊 100MHz
            en_reg <= (sw[0] || sw[1]);
            volume_reg <= sw[1:0];
            
            // 鎖存除法結果，過濾組合邏輯雜訊
            // 增加保護判斷：若 tone 為 0 則輸出 0 (靜音)
            freq_outL_reg <= (toneL == 0) ? 22'd0 : (50000000 / toneL);
            freq_outR_reg <= (toneR == 0) ? 22'd0 : (50000000 / toneR);
        end
    end

    // ibeatNum 維持在 clk22，但它是給 music ROM 用的，沒問題
    always @(posedge clk22 or posedge rst) begin
        if (rst) ibeatNum <= 0;
        else begin
            if (en_reg == 0 || ibeatNum == 12'd1200) ibeatNum <= 12'd0;
            else ibeatNum <= ibeatNum + 1;
        end
    end

    music_wii music(
        .ibeatNum(ibeatNum),
        .en(en_reg),
        .toneL(toneL),
        .toneR(toneR)
    );

    note_gen noteGen_00(
        .clk(clk), 
        .rst(rst), 
        .volume(volume_reg),       // 使用同步後的音量
        .note_div_left(freq_outL_reg), // 使用管線化後的頻率
        .note_div_right(freq_outR_reg),
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

    reg [2:0] spike_sec;
    reg [31:0] cnt_spike;
    wire spike_on = (spike_sec > 3'b110);
    
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
        .state(state),
        .spike_on(spike_on),
        .next_state(next_state),
        .boss_sec(boss_sec)
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
    localparam KEY_CODES_W = 9'h1D;
    localparam KEY_CODES_A = 9'h1C;
    localparam KEY_CODES_S = 9'h1B;
    localparam KEY_CODES_D = 9'h23;
    localparam KEY_CODES_SPACE = 9'h29;
    localparam KEY_CODES_ENTER = 9'h5A;
    localparam KEY_CODES_Q= 9'h15;
    localparam KEY_CODE_MINUS = 9'h7B;

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
        .clk(clk_25MHz)//不確定
    );

    wire key_down_op;
    reg key_is_down;
    always @(*) begin
        key_is_down = |key_down;
    end
    onepulse op2(.signal(key_is_down), .clk(clk_25MHz), .op(key_down_op));

    //7-segment===============================================================================================================
    wire [15:0] nums;
    segment_logic seg_lg(
        .nums(nums),
        .clk(clk),
        .rst(rst),
        .state(state)
    );
    wire [9:0] posData;

    SevenSegment seg(
        .display(DISPLAY),
        .digit(DIGIT),
        .nums(nums),//只是測試用
        .rst(rst),
        .clk(clk)
    );

    //joy stick=============================================================================================================

    // Signal to send/receive data to/from PMOD peripherals
    wire sndRec;

    // Data read from PmodJSTK
    wire [39:0] jstkData;
    
    // Holds data to be sent to PmodJSTK
    //wire [9:0] sndData;//本來放Din
    
    // --- 第一顆搖桿控制 (JA1) ---
    PmodJSTK P1_Controller (
        .CLK(clk), 
        .RST(rst), 
        .sndRec(sndRec), 
        .DIN(8'h80),
        .MISO(MISO),     // 硬體引腳：JA1 Pin 3
        .SS(SS),         // 硬體引腳：JA1 Pin 1
        .SCLK(SCLK),     // 硬體引腳：JA1 Pin 4
        .MOSI(MOSI),     // 硬體引腳：JA1 Pin 2
        .DOUT(jstkData)
    );

    wire [39:0] jstkData_1;
    // --- 第二顆搖桿控制 (JA3) ---
    PmodJSTK P2_Controller (
        .CLK(clk), 
        .RST(rst), 
        .sndRec(sndRec), 
        .DIN(8'h80),
        .MISO(MISO_1),   // 硬體引腳：JA3 Pin 3 (需在 XDC 定義)
        .SS(SS_1),       // 硬體引腳：JA3 Pin 1 (需在 XDC 定義)
        .SCLK(SCLK_1),   // 硬體引腳：JA3 Pin 4 (需在 XDC 定義)
        .MOSI(MOSI_1),   // 硬體引腳：JA3 Pin 2 (需在 XDC 定義)
        .DOUT(jstkData_1)
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
    wire [9:0] jstk_X_1 = {jstkData_1[9:8], jstkData_1[23:16]};
    wire [9:0] jstk_Y_1 = {jstkData_1[25:24], jstkData_1[39:32]};
    
   

    localparam IMG_W = 32; // 圖片寬度
    localparam IMG_H = 32; // 圖片高度
    
    wire joy_left   = (jstk_X < 10'd400);
    wire joy_right  = (jstk_X > 10'd600);
    wire joy_up     = (jstk_Y < 10'd400);
    wire joy_down   = (jstk_Y > 10'd600);

    wire joy_left_1   = (jstk_X_1 > 10'd600);
    wire joy_right_1  = (jstk_X_1 < 10'd450);
    wire joy_up_1     = (jstk_Y_1 < 10'd400);
    wire joy_down_1   = (jstk_Y_1 > 10'd600);



    assign is_moving = joy_left || joy_right;
    assign is_moving_1 = joy_left_1 || joy_right_1;
    
    reg jumping;
    reg on_ground;
    reg jumping_1;
    reg on_ground_1;        

    // --- 地圖數據 (20x15) ---
    reg [79:0] map [0:14];

    localparam T_EMPTY = 4'h0; //不能改empty的數字!!
    localparam T_SPIKE = 4'h1;
    localparam T_SPIKE_L = 4'h2;
    localparam T_GATE_1  = 4'h3;
    localparam T_GATE_2  = 4'h4;
    localparam T_GATE_3  = 4'h5;
    localparam T_PLATE_1 = 4'h6;
    localparam T_PLATE_2 = 4'h7;
    localparam T_PLATE_3 = 4'h8;
    localparam T_EXIT  = 4'h9;
    localparam T_WALL  = 4'hA;
    localparam T_GOLD = 4'hB;
    // --- 1. 產生位移脈衝 (例如每 0.2 秒移動一格) ---
    reg [31:0] shift_tick;
    wire shift_en = (shift_tick == 32'd100_000_000); // 25MHz 下，5,000,000 拍 = 0.2秒
    reg [3:0] shift_tick_cnt;

    always @(posedge clk_25MHz or posedge rst) begin
        if (rst) shift_tick <= 0;
        else if (state == BOSS_SCENE) begin
            if (shift_tick >= 32'd100_000_000) shift_tick <= 0;
            else shift_tick <= shift_tick + 1;
        end else shift_tick <= 0;
    end

    wire [3:0] grid_top, grid_top_1;
    reg [5:0] gold_number;

    // --- 2. 地圖主邏輯 ---
    always @(posedge clk_25MHz or posedge rst) begin
        if (rst) begin 
            map[0]  <= {{19{T_EMPTY}}, {T_EMPTY}};
            map[1]  <= {{10{T_EMPTY}}, {10{T_WALL}}}; 
            map[2]  <= {20{T_EMPTY}};
            map[3]  <= {{10{T_WALL}}, {10{T_EMPTY}}};
            map[4]  <= {20{T_EMPTY}};
            map[5]  <= {{10{T_WALL}}, {10{T_EMPTY}}};
            map[6]  <= {20{T_EMPTY}};
            map[7]  <= {{8{T_GOLD}}, {8{T_WALL}}, {10{T_EMPTY}}};
            map[8]  <= {20{T_EMPTY}};
            map[9]  <= {{7{T_EMPTY}}, T_GATE_1, {4{T_EMPTY}}, T_GATE_2, {4{T_EMPTY}}, T_GATE_3, T_EMPTY, T_EXIT};
            map[10] <= {{4{T_EMPTY}}, T_EXIT, T_SPIKE, T_EMPTY, T_GATE_1, {4{T_EMPTY}}, T_GATE_2, {4{T_EMPTY}}, T_GATE_3, T_EMPTY, T_EXIT};
            map[11] <= {T_WALL, T_GOLD, {3{T_PLATE_1}}, {15{T_WALL}}};
            map[12] <= {{15{T_EMPTY}}, T_EXIT};
            map[13] <= {{2{T_EMPTY}}, T_EXIT, T_SPIKE, T_EMPTY, T_GATE_1, {9{T_EMPTY}}, {5{T_PLATE_3}}};
            map[14] <= {{5{T_WALL}}, {5{T_PLATE_1}}, {5{T_PLATE_2}}, {5{T_WALL}}};
        end else begin
            if (state == START_SCENE) begin
                map[0]  <= {{19{T_EMPTY}}, {T_EMPTY}};
                map[1]  <= {{10{T_EMPTY}}, {10{T_WALL}}}; 
                map[2]  <= {20{T_EMPTY}};
                map[3]  <= {{10{T_WALL}}, {10{T_EMPTY}}};
                map[4]  <= {20{T_EMPTY}};
                map[5]  <= {{10{T_WALL}}, {10{T_EMPTY}}};
                map[6]  <= {20{T_EMPTY}};
                map[7]  <= {{8{T_GOLD}}, {8{T_WALL}}, {10{T_EMPTY}}};
                map[8]  <= {20{T_EMPTY}};
                map[9]  <= {{7{T_EMPTY}}, T_GATE_1, {4{T_EMPTY}}, T_GATE_2, {4{T_EMPTY}}, T_GATE_3, T_EMPTY, T_EXIT};
                map[10] <= {{4{T_EMPTY}}, T_EXIT, T_SPIKE, T_EMPTY, T_GATE_1, {4{T_EMPTY}}, T_GATE_2, {4{T_EMPTY}}, T_GATE_3, T_EMPTY, T_EXIT};
                map[11] <= {T_WALL, T_GOLD, {3{T_PLATE_1}}, {15{T_WALL}}};
                map[12] <= {{15{T_EMPTY}}, T_EXIT};
                map[13] <= {{2{T_EMPTY}}, T_EXIT, T_SPIKE, T_EMPTY, T_GATE_1, {9{T_EMPTY}}, {5{T_PLATE_3}}};
                map[14] <= {{5{T_WALL}}, {5{T_PLATE_1}}, {5{T_PLATE_2}}, {5{T_WALL}}};
            end else if (state == PLAY_SCENE) begin 
                if (map[grid_top][(19-grid_mid_x)*4 +: 4] == T_GOLD) begin 
                    map[grid_top][(19-grid_mid_x)*4 +: 4] <= T_WALL;
                end
                if (map[grid_top_1][(19-grid_mid_x_1)*4 +: 4] == T_GOLD) begin 
                    map[grid_top_1][(19-grid_mid_x_1)*4 +: 4] <= T_WALL;
                end
            end
            else if (state == BOSS_SCENE) begin
                if (boss_sec <= 1) begin
                    // 初始化 BOSS 房間
                    map[0] <= {20{T_WALL}}; map[1] <= {20{T_WALL}}; map[2] <= {20{T_WALL}};
                    map[3] <= {20{T_WALL}}; map[4] <= {20{T_WALL}}; map[5] <= {20{T_WALL}};
                    map[6] <= {20{T_WALL}}; map[7] <= {20{T_WALL}}; map[8] <= {20{T_WALL}};
                    map[9] <= {T_WALL, {18{T_EMPTY}}, T_WALL};
                    map[10] <= {T_WALL, {18{T_EMPTY}}, T_WALL};
                    map[11] <= {20{T_WALL}};
                    map[12] <= {T_WALL, {18{T_EMPTY}}, T_WALL};
                    map[13] <= {T_WALL, {18{T_EMPTY}}, T_WALL};
                    map[14] <= {20{T_WALL}};
                end 
                else if (shift_en) begin
                    // 向上排位移
                    map[10][39:4] <= map[10][35:0];
                    map[10][75:40] <= map[10][79:44];

                    map[10][3:0] <= T_WALL;
                    map[10][79:76] <= T_WALL;

                    map[9][39:4] <= map[9][35:0];
                    map[9][75:40] <= map[9][79:44];

                    map[9][3:0] <= T_WALL;
                    map[9][79:76] <= T_WALL;

                    map[12][39:4] <= map[12][35:0];
                    map[12][75:40] <= map[12][79:44];

                    map[12][3:0] <= T_WALL;
                    map[12][79:76] <= T_WALL;

                    // 向下排位移
                    map[13][39:4] <= map[13][35:0];
                    map[13][75:40] <= map[13][79:44];

                    map[13][3:0] <= T_WALL;
                    map[13][79:76] <= T_WALL;
                end
            end
        end
    end

    // --- 1. 修正 boss_kill 定義 ---
    reg [4:0] boss_kill; // 改為 5-bit，才能存 0~16
    always @(posedge clk_25MHz or posedge rst) begin 
        if (rst) begin
            boss_kill <= 0;
        end else begin
            if (state != BOSS_SCENE) boss_kill <= 0;
            else begin 
                // 增加一個上限 16，防止加過頭
                if (key_down_op && (last_change == 9'h4E || last_change == 9'h16) && boss_kill < 16) 
                    boss_kill <= boss_kill + 1;
            end
        end
    end

    // --- 2. 座標同步延遲 (對齊 BRAM 的 3 拍延遲) ---
    reg [9:0] h_pipe [0:2], v_pipe [0:2];
    always @(posedge clk_25MHz) begin
        h_pipe[0] <= h_cnt; h_pipe[1] <= h_pipe[0]; h_pipe[2] <= h_pipe[1];
        v_pipe[0] <= v_cnt; v_pipe[1] <= v_pipe[0]; v_pipe[2] <= v_pipe[1];
    end
    wire [9:0] h_sync = h_pipe[2];
    wire [9:0] v_sync = v_pipe[2];


    // --- 多點碰撞偵測點 ---
    wire [9:0] char_L = img_x;
    wire [9:0] char_R = img_x + 31;
    wire [9:0] char_T = img_y;
    wire [9:0] char_B = img_y + 31;

    wire [9:0] char_L_1 = img_x_1;
    wire [9:0] char_R_1 = img_x_1 + 31;
    wire [9:0] char_T_1 = img_y_1;
    wire [9:0] char_B_1 = img_y_1 + 31;

    wire [4:0] grid_mid_x  = (char_L + 16) >> 5;
    wire [4:0] grid_mid_x_1  = (char_L_1 + 16) >> 5;

    assign grid_top = char_T >> 5;
    assign grid_top_1 = char_T_1 >> 5;

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

    wire win_now = (tile_id_R_mid == T_EXIT && tile_id_R_mid_1 == T_EXIT);


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

    //為了用不同的clock所以做enable
    // 建議修改 ClkDiv 的邏輯，使其產生一個 "tick" (脈衝) 而非 50% 佔空比的時脈
    reg [22:0] tick_cnt;
    wire move_en; // 這是我們邏輯的觸發開關

    always @(posedge clk_25MHz or posedge rst) begin
        if (rst) begin
            tick_cnt <= 0;
        end else begin
            if (tick_cnt >= 5000000) // 25MHz / 5Hz = 5,000,000
                tick_cnt <= 0;
            else
                tick_cnt <= tick_cnt + 1;
        end
    end
    assign move_en = (tick_cnt == 5000000); // 每 0.2 秒產生一個週期寬度的 1



    reg [9:0] jump_start_y;
    reg [9:0] jump_start_y_1;
    // --- 瞬移技能邏輯 ---
    localparam TELEPORT_DIST = 10'd64;
    localparam TELEPORT_CD   = 11'd1800;    // 約 3 秒 (5Hz 時脈下)

    reg space_prev;
    reg [23:0] teleport_cd;

    reg skill_mode;
    reg [4:0] cursor_x; // 0-19 格
    reg [3:0] cursor_y; // 0-14 格
    reg q_prev, enter_prev;

    wire [9:0] abs_target_x = cursor_x << 5;
    wire [9:0] abs_target_y = cursor_y << 5;
    // 地圖碰撞檢查
    assign target_tile_id = map[cursor_y][ cursor_x*4 +: 4];
    reg teleporting;
    // --- 跳躍與移動邏輯 (保持不變) ---
    // 請確保在 top 模組中有定義 move_en
    // 例如產生 20Hz: 
    // reg [22:0] move_cnt; wire move_en = (move_cnt == 1250000);
    // always @(posedge clk_25MHz) move_cnt <= (move_en)? 0 : move_cnt + 1;
    reg [9:0] fail_x, fail_y; // 記錄失敗位置的像素座標
    reg [4:0] fail_flash_cnt;
    always @(posedge clk_25MHz or posedge rst) begin
        if (rst) begin
            img_x <= 10'd32;      img_y <= 10'd320;
            img_x_1 <= 10'd32;    img_y_1 <= 10'd416;
            jumping <= 0;         jumping_1 <= 0;
            on_ground <= 1;       on_ground_1 <= 1;
            face_left <= 0;       face_left_1 <= 0;
            space_prev <= 1'b0;   teleport_cd <= 24'd0;
            skill_mode <= 0;      teleporting <= 1'b0;
            cursor_x <= 0;        cursor_y <= 0;
            q_prev <= 1'b0;       enter_prev <= 1'b0;
        end else begin
            // --- 立即判斷狀態切換 (START/BOSS Reset) ---
            if (state == START_SCENE || (state == BOSS_SCENE && boss_sec <= 1)) begin 
                img_x <= 10'd32;      img_y <= 10'd320;
                img_x_1 <= 10'd32;    img_y_1 <= 10'd416;
                jumping <= 0;         jumping_1 <= 0;
                on_ground <= 1;       on_ground_1 <= 1;
                face_left <= 0;       face_left_1 <= 0;
                teleport_cd <= 24'd0; skill_mode <= 0;
                teleporting <= 1'b0;
            end 
            else if (state == PLAY_SCENE || state == BOSS_SCENE) begin

                // ============================================================
                // [A] 鍵盤即時偵測區 (不在 move_en 內，反應速度 25MHz)
                // ============================================================
                
                // 1. Q 鍵進入/退出技能模式
                if (key_down[KEY_CODES_Q] && !q_prev) begin
                    skill_mode <= ~skill_mode;
                    cursor_x <= img_x >> 5; // 進入時游標跟隨角色
                    cursor_y <= img_y >> 5;
                end
                q_prev <= key_down[KEY_CODES_Q];

                // 2. Enter 確定瞬移 (角色 0)
                if (skill_mode && key_down[KEY_CODES_ENTER] && !enter_prev) begin
                    if (target_tile_id ==T_EMPTY && on_ground) begin
                        img_x <= cursor_x << 5;
                        img_y <= cursor_y << 5;
                        jumping <= 0;
                        on_ground <= 1;
                        teleporting <= 1'b1;
                        skill_mode <= 0;
                    end else begin
                        fail_x <= cursor_x << 5;
                        fail_y <= cursor_y << 5;
                        fail_flash_cnt <= 5'd30; // 亮紅色的時間 (30幀約0.5秒)
                        skill_mode <= 0;
                    end
                end
                enter_prev <= key_down[KEY_CODES_ENTER];

                // 3. Space 瞬移 (角色 1)
                if (key_down[KEY_CODES_SPACE] && !space_prev && teleport_cd == 0) begin
                    teleport_cd <= TELEPORT_CD;
                    if (joy_left_1 || face_left_1) begin
                        if (img_x_1 >= TELEPORT_DIST && !wall_L_1)
                            img_x_1 <= img_x_1 - TELEPORT_DIST;
                    end else begin
                        if (img_x_1 + TELEPORT_DIST <= 640 - 32 && !wall_R_1)
                            img_x_1 <= img_x_1 + TELEPORT_DIST;
                    end
                end
                space_prev <= key_down[KEY_CODES_SPACE];

                // ============================================================
                // [B] 定速移動邏輯區 (在 move_en 內，控制遊戲節奏)
                // ============================================================
                if (move_en) begin
                    
                    // --- 游標移動 (放在這裡防止 WASD 跑太快) ---
                    if (skill_mode) begin
                        if (key_down[KEY_CODES_A] && cursor_x > 0)  cursor_x <= cursor_x - 1;
                        if (key_down[KEY_CODES_D] && cursor_x < 19) cursor_x <= cursor_x + 1;
                        if (key_down[KEY_CODES_W] && cursor_y > (img_y >> 5))  cursor_y <= cursor_y - 1;
                        if (key_down[KEY_CODES_S] && cursor_y < (img_y >> 5)+3) cursor_y <= cursor_y + 1;
                    end

                    // --- 角色 0 走路與重力 ---
                    if (!skill_mode && !teleporting) begin
                        // 左右移動 (搖桿)
                        if (joy_left && img_x >= 5 && !wall_L) begin
                            img_x <= img_x - 5; face_left <= 1;
                        end else if (joy_right && img_x < (640 - 37) && !wall_R) begin
                            img_x <= img_x + 5; face_left <= 0;
                        end

                        // 跳躍/掉落
                        if (jumping) begin
                            if (hitting_ceiling || img_y <= jump_start_y - 64 || img_y <= 10)
                                jumping <= 0;
                            else
                                img_y <= img_y - 5;
                        end else begin
                            if (tile_below || img_y >= 416) begin
                                on_ground <= 1;
                                img_y <= (img_y >= 416) ? 416 : (grid_below << 5) - 32;
                            end else begin
                                on_ground <= 0;
                                img_y <= img_y + 5;
                            end
                        end
                    end

                    // --- 角色 1 走路與重力 ---
                    if (joy_left_1 && img_x_1 >= 5 && !wall_L_1) begin 
                        img_x_1 <= img_x_1 - 5; face_left_1 <= 1;
                    end else if (joy_right_1 && img_x_1 < (640 - 37) && !wall_R_1) begin 
                        img_x_1 <= img_x_1 + 5; face_left_1 <= 0;
                    end

                    if (jumping_1) begin
                        if (hitting_ceiling_1 || img_y_1 <= jump_start_y_1 - 64 || img_y_1 <= 10)
                            jumping_1 <= 0;
                        else
                            img_y_1 <= img_y_1 - 5;
                    end else begin
                        if (tile_below_1 || img_y_1 >= 416) begin
                            on_ground_1 <= 1;
                            img_y_1 <= (img_y_1 >= 416) ? 416 : (grid_below_1 << 5) - 32;
                        end else begin
                            on_ground_1 <= 0;
                            img_y_1 <= img_y_1 + 5;
                        end
                    end

                    // 冷卻時間倒數
                    if (teleport_cd > 0) teleport_cd <= teleport_cd - 1;
                end

                // --- 跳躍觸發 (不受 move_en 限制以確保靈敏，或放進 move_en 皆可) ---
                if (jstkData[1] && on_ground && !jumping) begin
                    jumping <= 1;
                    on_ground <= 0;
                    jump_start_y <= img_y;
                end
                if (jstkData_1[1] && on_ground_1 && !jumping_1) begin 
                    jumping_1 <= 1;
                    on_ground_1 <= 0;
                    jump_start_y_1 <= img_y_1;
                end

                // 重置傳送狀態標籤
                if (teleporting) teleporting <= 1'b0;

            end // end of PLAY/BOSS SCENE
        end
    end

    wire lose_to_boss = (map[grid_mid_y][(19 - grid_mid_x)*4 +: 4] == T_WALL || map[grid_mid_y_1][(19 - grid_mid_x_1)*4 +: 4] == T_WALL);

    // Data to be sent to PmodJSTK, lower two bits will turn on leds on PmodJSTK
    //assign sndData = {8'b100000, {sw[6], sw[7]}};

    always @(sndRec or rst or jstkData) begin
            if(rst == 1'b1) begin
                LED <= 3'b000;
            end
            else begin
                LED <= {10'b0, jstkData_1[2:0],jstkData[2:0]};//0是按搖桿，1是搖桿底下那顆按鈕
            end
    end

    

    always @(posedge clk_25MHz, posedge rst) begin
        if (rst) begin
            spike_sec <= 0;
            cnt_spike <= 0;
        end else begin
            cnt_spike <= cnt_spike + 1;
            if (cnt_spike >= 25000000) begin
                cnt_spike <= 0;
                spike_sec <= spike_sec + 1;
            end
        end
    end

    //瞬移錯誤的紅色提示
    reg [4:0] current_tile_idx;
    always @(posedge clk_25MHz or posedge rst) begin
        if (rst) fail_flash_cnt <= 0;
        else if (fail_flash_cnt > 0) fail_flash_cnt <= fail_flash_cnt - 1;
    end


    always @(*) begin
        if (!valid_sync) begin
            {vgaRed, vgaGreen, vgaBlue} = 12'h000;
        end
        else if (fail_flash_cnt > 0 && 
                ((h_cnt - 2) >= fail_x) && ((h_cnt - 2) < (fail_x + 32)) &&
                (v_cnt >= fail_y) && (v_cnt < (fail_y + 32))) 
        begin
            {vgaRed, vgaGreen, vgaBlue} = 12'hF00; // 純紅色
        end
        else if (skill_mode && 
                ((h_cnt - 2) >= abs_target_x) && ((h_cnt - 2) < (abs_target_x + 32)) &&
                (v_cnt >= abs_target_y) && (v_cnt < (abs_target_y + 32))) 
        begin
            {vgaRed, vgaGreen, vgaBlue} = 12'hFFF; // 純白色
        end
        else if (state == PLAY_SCENE) begin
            
            if (show_pixel_sync) begin
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
        end else if (state == BOSS_SCENE) begin 
            if (show_pixel_sync) begin
                // A. 先讀取底層顏色 (Boss 的照片)
                {vgaRed, vgaGreen, vgaBlue} = pixel;

                // B. 計算當前座標屬於第幾隻 Boss (假設一排 8 隻，共兩排)
                // 第一排: y < 128, 每格寬 80 (80*8=640)
                // 第二排: 128 <= y < 256
                if (v_sync < 256) begin
                    // 計算當前像素屬於 0~15 哪一個索引
                    // 使用 wire 輔助計算較清晰
                    //reg [4:0] current_tile_idx;
                    current_tile_idx = (h_sync / 80) + (v_sync >= 128 ? 8 : 0);

                    // 如果這隻已經被殺掉 (index < boss_kill)，蓋上紅色
                    if (current_tile_idx < boss_kill) begin
                        vgaRed = 4'hF; 
                        // 如果想保留 Boss 輪廓但變紅，可以只改 R，或是讓 G, B 變暗
                        // vgaGreen = vgaGreen >> 2; 
                        // vgaBlue = vgaBlue >> 2;
                    end
                end
            end else begin
                {vgaRed, vgaGreen, vgaBlue} = 12'h000;
            end
        end else begin 
            {vgaRed, vgaGreen, vgaBlue} = pixel;
        end
    end

    reg step_on_spike;
    always @(posedge clk_25MHz, posedge rst) begin
        if (rst) step_on_spike <= 0;
        else begin
            if (state == PLAY_SCENE) begin
                step_on_spike <= spike_on && (map[char_B >> 5][(19 - ((char_L + 5) >> 5))*4 +: 4] == T_SPIKE || map[char_B >> 5][(19 - ((char_R - 5) >> 5))*4 +: 4] == T_SPIKE ||
                        map[char_B_1 >> 5][(19 - ((char_L_1 + 5) >> 5))*4 +: 4] == T_SPIKE || map[char_B_1 >> 5][(19 - ((char_R_1 - 5) >> 5))*4 +: 4] == T_SPIKE);
            end else begin 
                step_on_spike <= 0;
            end           
        end
    end
        
    
    always @(*) begin
        next_state = state; 
        if (state == START_SCENE) begin 
            if (btnR_op) next_state = PLAY_SCENE;
        end else if (state == PLAY_SCENE) begin
            if (step_on_spike) next_state = LOSE_SCENE;
            if (win_now) next_state = BOSS_SCENE;
        end else if (state == LOSE_SCENE) begin
            if (btnR_op) next_state = START_SCENE;
        end else if (state == WIN_SCENE) begin 
            if (btnR_op) next_state = START_SCENE;
        end else if (state == BOSS_SCENE) begin 
            if (boss_kill == 16) next_state = WIN_SCENE;
            if (lose_to_boss) next_state = LOSE_SCENE;
        end
    end

    always @(posedge clk_25MHz or posedge rst) begin
        if (rst) begin
            data_out <= 4'd15; // 預設 15，Slave 就不會滅掉任何燈
        end else begin
            if (state == BOSS_SCENE) begin
                data_out <= 4'd14; // 發送代碼 14 給 Slave
            end else if (state == PLAY_SCENE) begin
                data_out <= 4'd1;  // 舉例：一般遊戲中發送 1
            end else begin
                data_out <= 4'd15; // 其他狀態不動作
            end
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
//48578 lose 80*60 (43776-48575)
//53378 win 80*60 (48576-53375)
//63618 boss 80*128 (53376-63615)
//64642 spike_left 32*32 (63616-64639)
//65666 gold 32*32 (64640-65663)
//角色32*32