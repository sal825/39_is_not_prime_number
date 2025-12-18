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
    output wire SCLK
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


    wire [16:0] move_pixel_addr;
    // mem_addr_gen mem_addr_gen_inst( //可以放state
    //   .clk(clk),
    //   .rst(rst),
    //   .h_cnt(h_cnt),
    //   .v_cnt(v_cnt),
    //   .pixel_addr(pixel_addr),
    //   .state(state)
    // );

    blk_mem_gen_0 blk_mem_gen_0_inst(
      .clka(clk_25MHz),
      .wea(0),
      .addra(move_pixel_addr),
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

    // always @(*) begin
    //     if (valid) begin 
    //         if (h_cnt < 320 && v_cnt < 240) {vgaRed, vgaGreen, vgaBlue} = pixel;
    //         else {vgaRed, vgaGreen, vgaBlue} = ~pixel;
    //     end
    // end

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

    // Pmod JA (JSTK2)
    // wire SS; // ss_n
    // wire MOSI; // mosi
    // wire MISO; // miso
    // wire SCLK; // sclk

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
    
    //wire rst_n = ~rst;

    // PmodJSTK u_jstk (
    //     .CLK(clk),
    //     .RST(rst),
    //     .SS(SS),
    //     .MOSI(MOSI),
    //     .MISO(MISO),
    //     .SCLK(SCLK),
    //     .sndRec(sndRec),
    //     .DIN(40'h0000000000),
    //     .DOUT(jstk_data)
    // );
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
    reg [9:0] img_x, img_y;
    localparam IMG_W = 160; // 圖片寬度
    localparam IMG_H = 120; // 圖片高度
    // ===== 搖桿方向判斷（死區）=====
    wire joy_left  = (jstk_X < 10'd400);
    wire joy_right = (jstk_X > 10'd600);
    wire joy_down  = (jstk_Y < 10'd400);
    wire joy_up    = (jstk_Y > 10'd600);

    always @(posedge sndRec or posedge rst) begin
        if (rst) begin
            img_x <= 10'd0;//初始位置
            img_y <= 10'd360; 
        end else begin
            if (joy_left  && img_x > 0)
                img_x <= img_x - 3;
            else if (joy_right && img_x < 640 - IMG_W)
                img_x <= img_x + 3;

            if (joy_up    && img_y < 480 - IMG_H)
                img_y <= img_y + 3;
            else if (joy_down && img_y >=3)
                img_y <= img_y - 3;
        end
    end


    // 3. VGA 位址計算
    // 判斷當前像素是否在圖片移動區域內
    wire is_img_area =
    (h_cnt >= img_x && h_cnt < img_x + IMG_W) &&
    (v_cnt >= img_y && v_cnt < img_y + IMG_H);

    // ROM 取圖座標（不加 offset）
    wire [9:0] tex_x = h_cnt - img_x;
    wire [9:0] tex_y = v_cnt - img_y;

    // pixel address
    assign move_pixel_addr = is_img_area
        ? (tex_y * IMG_W + tex_x)
        : 17'd0;


    // 4. VGA 輸出邏輯
    always @(*) begin
        if (!valid) begin
            {vgaRed, vgaGreen, vgaBlue} = 12'h000;
        end else if (is_img_area) begin
            {vgaRed, vgaGreen, vgaBlue} = pixel; // 顯示圖片
        end else begin
            {vgaRed, vgaGreen, vgaBlue} = 12'h222; // 預設背景顏色 (深灰)
        end
    end

    // Data to be sent to PmodJSTK, lower two bits will turn on leds on PmodJSTK
    assign sndData = {8'b100000, {sw[6], sw[7]}};

    always @(sndRec or rst or jstkData) begin
            if(rst == 1'b1) begin
                    LED <= 3'b000;
            end
            else begin
                   LED <= {13'b0, jstkData[2], jstkData[1], jstkData[0]};

            end
    end
    

endmodule