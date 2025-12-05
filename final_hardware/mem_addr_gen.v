module mem_addr_gen(
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input [4:0] state,
    output reg [16:0] pixel_addr
    );

    localparam WIDTH = 160;
    localparam HEIGHT = 120;

    reg [7:0] local_x;  // 0-159
    reg [6:0] local_y;  // 0-119 local是在小圖片的位置座標
    reg [16:0] base_row_offset;
    reg [16:0] base_col_offset;

    //概念 用cnt計算在小圖片的位置 用pic_id計算在大圖片的位置(也可以當作改變原點) 兩個合起來

    always @(*) begin
        
        if (h_cnt < 640 && v_cnt < 480) begin
            local_x = h_cnt >> 2;
            local_y = v_cnt >> 2;
            base_col_offset = 0;
            base_row_offset = 0;            
        end 
        else begin
            //可視區外
            local_x = 0;
            local_y = 0;
            base_col_offset = 0;
            base_row_offset = 0;
        end
    end

    always @(posedge clk, posedge rst) begin
        if (rst) pixel_addr <= 0;
        else pixel_addr <= base_row_offset + (local_y * WIDTH) + base_col_offset + local_x;
    end

    
endmodule
