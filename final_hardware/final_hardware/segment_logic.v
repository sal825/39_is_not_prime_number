module segment_logic(
    input rst, 
    input clk, 
    input [3:0] state,
    output reg [15:0] nums
    );
    
    reg [31:0] cnt;
    reg [9:0] sec;

    always @(posedge clk, posedge rst) begin
        if (rst) begin 
            cnt <= 0;
            sec <= 0;
            min <= 0;
        end else begin 
            if (cnt != 100000000) cnt <= cnt + 1;
            else begin 
                cnt <= 0;
                sec <= sec + 1;
            end
        end
    end

    always @(*) begin
        nums[15:12] <= min/10;
        nums[11:8] <= min % 10;
        nums[7:4] <= sec / 10;
        nums[3:0] <= sec % 10; 
    end
    
endmodule