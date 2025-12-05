module JSTK2 (
    input wire clk,          // 系統時鐘，建議 50~100MHz
    input wire rst,

    // SPI 物理腳位
    output wire jstk_ss_n,
    output wire jstk_mosi,
    input  wire jstk_miso,
    output wire jstk_sclk,

    // 搖桿與按鍵資料（每次更新完會給新值）
    output reg [9:0] jstk_x,     // 0~1023，512 為中間
    output reg [9:0] jstk_y,     // 0~1023，512 為中間
    output reg       btn_jstk,   // 搖桿按鈕
    output reg       btn_trigger,// 板子上 Trigger 按鈕
    output reg       data_valid  // 資料更新完成脈衝
);

    // SPI 傳送命令：讀全部資料 (0xFF 0xFF)
    wire [15:0] tx_data = 16'hFFFF;
    wire       [7:0] rx_data;
    wire        spi_done;

    spi_mode0_master spi_inst (
        .clk(clk),
        .rst(rst),
        .ss_n(jstk_ss_n),
        .sclk(jstk_sclk),
        .mosi(jstk_mosi),
        .miso(jstk_miso),
        .start(1'b1),           // 持續發送
        .data_in(tx_data),
        .data_out({8'd0, rx_data}),
        .done(spi_done)
    );

    // JSTK2 回傳格式：連續 5 bytes
    // Byte0: X low
    // Byte1: X high
    // Byte2: Y low
    // Byte3: Y high
    // Byte4: buttons (bit0=trigger, bit1=jstk)
    reg [2:0] byte_cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            byte_cnt <= 0;
            jstk_x <= 10'd512;
            jstk_y <= 10'd512;
            btn_jstk <= 0;
            btn_trigger <= 0;
            data_valid <= 0;
        end else if (spi_done) begin
            data_valid <= (byte_cnt == 3'd4);
            case (byte_cnt)
                0: jstk_x[7:0]  <= rx_data;
                1: jstk_x[9:8]  <= rx_data[1:0];
                2: jstk_y[7:0]  <= rx_data;
                3: jstk_y[9:8]  <= rx_data[1:0];
                4: {btn_jstk, btn_trigger} <= rx_data[1:0];
            endcase
            byte_cnt <= byte_cnt + 1;
        end
    end
endmodule

module spi_mode0_master (
    input clk, rst,
    output reg ss_n,
    output reg sclk,
    output reg mosi,
    input  miso,
    input  start,
    input  [15:0] data_in,
    output reg [15:0] data_out,
    output reg done
);
    reg [4:0] cnt;
    reg [15:0] shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            ss_n <= 1;
            sclk <= 0;
            done <= 0;
        end else if (start && cnt==0) begin
            shift_reg <= data_in;
            ss_n <= 0;
            cnt <= 1;
        end else if (cnt != 0) begin
            if (cnt[0]) sclk <= 1;
            else begin
                sclk <= 0;
                if (cnt != 16) begin
                    mosi <= shift_reg[15];
                    shift_reg <= {shift_reg[14:0], miso};
                end
                cnt <= cnt + 1;
                if (cnt == 31) begin
                    done <= 1;
                    ss_n <= 1;
                    data_out <= {shift_reg[14:0], miso};
                    cnt <= 0;
                end else done <= 0;
            end
        end
    end
endmodule