module lab6_practice_slave (
    input wire clk,
    input wire rst,
    input wire [3:0] data_in,
    input wire [15:0] sw,
    output wire audio_mclk,
    output wire audio_lrck,
    output wire audio_sck,
    output wire audio_sdin,
    output wire [6:0] DISPLAY,
    output wire [3:0] DIGIT,
    output reg [15:0] led
);
    reg state;
    localparam IDLE = 0;
    localparam PLAY = 1;

    reg [15:0] nums;
    SevenSegment seg(
        .display(DISPLAY),
        .digit(DIGIT),
        .nums(nums),
        .rst(rst),
        .clk(clk)
    );

    reg [31:0] cnt_play;
    reg [9:0] sec_play;
    always @(posedge clk, posedge rst) begin
        if (rst) begin 
            cnt_play <= 0;
            sec_play <= 0;
        end else begin 
            if (state == PLAY) begin
                if (cnt_play < 100000000) cnt_play <= cnt_play + 1;
                else begin 
                    cnt_play <= 0;
                    sec_play <= sec_play + 1;
                end
            end else begin 
                cnt_play <= 0;
                sec_play <= 0;
            end
        end
    end

    

    always @(*) begin
        if (state == PLAY) begin
            nums[15:12] = sec_play / 1000;
            nums[11:8] = (sec_play / 100) % 10;
            nums[7:4] = (sec_play / 10) % 10;
            nums[3:0] = sec_play % 10;
        end else nums = 16'hFFFF;
    end


    reg [3:0] data_sync1, data_sync2, data_reg;

    // 兩段同步器 (處理跨板時脈非同步問題)
    always @(posedge clk) begin
        data_sync1 <= data_in;
        data_sync2 <= data_sync1;
        data_reg   <= data_sync2;
    end

    // 解碼邏輯
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin

            if (data_reg[3] == 1) state <= PLAY;
            else state <= IDLE;

        end
    end

    always @(posedge clk, posedge rst) begin
        if (rst) led <= 0;
        else begin 
            if (state == IDLE) led <= 0;
            else begin 
                case (data_reg[2:0]) 
                    3'd0: led = 16'b0000_0000_0000_0000;
                    3'd1: led = 16'b1000_0000_0000_0000;
                    3'd2: led = 16'b1100_0000_0000_0000;
                    3'd3: led = 16'b1110_0000_0000_0000;
                    3'd4: led = 16'b1111_0000_0000_0000;
                    3'd5: led = 16'b1111_1000_0000_0000;
                    3'd6: led = 16'b1111_1100_0000_0000;
                    3'd7: led = 16'b1111_1110_0000_0000;
                endcase
            end
        end
    end

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
    
    reg [31:0] toneL_stable, toneR_stable;

    always @(posedge clk) begin
        if (rst) begin
            toneL_stable <= 0;
            toneR_stable <= 0;
            freq_outL_reg <= 0;
            freq_outR_reg <= 0;
            en_reg <= 0;
            volume_reg <= 2'b00;
        end else begin
            // 第一層：先穩定 tone
            toneL_stable <= toneL;
            toneR_stable <= toneR;
            en_reg <= (sw[0] || sw[1]);
            volume_reg <= sw[1:0];
            // 第二層：計算頻率。確保除數不為 0
            if (toneL_stable == 0) freq_outL_reg <= 0;
            else freq_outL_reg <= (50000000 / toneL_stable);
            
            if (toneR_stable == 0) freq_outR_reg <= 0;
            else freq_outR_reg <= (50000000 / toneR_stable);
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
endmodule