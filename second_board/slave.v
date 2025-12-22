module lab6_practice_slave (
    input wire clk,
    input wire rst,
    input wire [3:0] data_in,
    output reg [15:0] led
);

    reg [3:0] data_sync1, data_sync2, data_reg;

    // 兩段同步器 (處理跨板時脈非同步問題)
    always @(posedge clk) begin
        data_sync1 <= data_in;
        data_sync2 <= data_sync1;
        data_reg   <= data_sync2;
    end

    // 解碼邏輯
    always @(posedge clk) begin
        if (rst) begin
            led <= 16'h0000; 
        end else begin
            // 預設狀態
            led <= 16'h0000; 
            
            case (data_reg)
                4'd14: begin
                    // 當 Master 處於 BOSS_SCENE 時
                    led <= 16'hFFFF; // 全部亮起 (假設 0 為亮)
                end
                4'd15: begin
                    led <= 16'h0000; // 閒置狀態，全滅
                end
                default: begin
                    // 如果是其他代碼 (0-13)，只亮對應的那顆燈
                    led[data_reg] <= 1'b0; 
                end
            endcase
        end
    end
endmodule