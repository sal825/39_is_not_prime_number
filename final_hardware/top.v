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
    output  vsync
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

    mem_addr_gen mem_addr_gen_inst( //可以放state
      .clk(clk),
      .rst(rst),
      .h_cnt(h_cnt),
      .v_cnt(v_cnt),
      .pixel_addr(pixel_addr),
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

    always @(*) begin
        if (valid) begin 
            if (h_cnt < 320 && v_cnt < 240) {vgaRed, vgaGreen, vgaBlue} = pixel;
            else {vgaRed, vgaGreen, vgaBlue} = ~pixel;
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

    SevenSegment seg(
        .display(DISPLAY),
        .digit(DIGIT),
        .nums(nums),
        .rst(rst),
        .clk(clk)
    );

    // Pmod JA (JSTK2)
    wire JA1; // ss_n
    wire JA2; // mosi
    wire JA3; // miso
    wire JA4; // sclk

    wire [9:0] jstk_x, jstk_y;
    wire btn_jstk, btn_trigger, jstk_valid;

    JSTK2 jstk_inst (
        .clk(clk),
        .rst(rst),
        .jstk_ss_n(JA1),
        .jstk_mosi(JA2),
        .jstk_miso(JA3),
        .jstk_sclk(JA4),
        .jstk_x(jstk_x),
        .jstk_y(jstk_y),
        .btn_jstk(btn_jstk),
        .btn_trigger(btn_trigger),
        .data_valid(jstk_valid)
    );

    // 搖桿方向判斷（死區設 200，避免漂移）
    wire move_up    = jstk_valid && (jstk_y > 512 + 200);
    wire move_down  = jstk_valid && (jstk_y < 512 - 200);
    wire move_left  = jstk_valid && (jstk_x < 512 - 200);
    wire move_right = jstk_valid && (jstk_x > 512 + 200);

    assign nums = {jstk_x/1000, jstk_x/100, jstk_x/10, jstk_x%10};

    always @(*) begin
        //nums = {4'd0, 4'd4, 4'd2, 4'd8}; 
        LED = 0;
        LED[3] = move_up;
        LED[2] = move_down;
        LED[1] = move_left;
        LED[0] = move_right;
        
        state = 0;
    end
    

endmodule