module lab6_practice_slave (
    input wire clk,
    input wire rst,
    input wire [3:0] data_in,
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
endmodule