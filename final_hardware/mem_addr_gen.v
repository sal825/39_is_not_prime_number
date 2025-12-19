module mem_addr_gen(
    input clk,
    input rst,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input vsync,
    input [9:0] img_x,
    input [9:0] img_y,
    input [2:0] frame_idx,
    input is_moving,
    input face_left,
    output reg [16:0] pixel_addr,
    output wire out_show_pixel // 同步後的顯示訊號
    );

    localparam IMG_W = 32;
    localparam IMG_H = 32;
    
    // 座標同步暫存器
    reg [9:0] x_s, y_s;
    always @(posedge vsync or posedge rst) begin
        if (rst) {x_s, y_s} <= {10'd0, 10'd416};
        else {x_s, y_s} <= {img_x, img_y};
    end

    // 區域判斷 (T0)
    wire is_char = (h_cnt >= x_s && h_cnt < x_s + IMG_W) && (v_cnt >= y_s && v_cnt < y_s + IMG_H);
    wire [4:0] gx = h_cnt >> 5; 
    wire [3:0] gy = v_cnt >> 5;
    
    // 地圖定義 (20x15) - 需與 top.v 一致
    wire [19:0] map [0:14];
    assign map[0]  = 20'b11111111111111111111;
    assign map[1]  = 20'b10000000000000000001;
    assign map[2]  = 20'b10000000000000001111;
    assign map[3]  = 20'b10110000000001000001;
    assign map[4]  = 20'b10000110000000000001;
    assign map[5]  = 20'b10000000111111100001;
    assign map[6]  = 20'b10000000000000000001;
    assign map[7]  = 20'b10000000000000011111;
    assign map[8]  = 20'b11110000110011100001;
    assign map[9]  = 20'b10000000000000000001;
    assign map[10] = 20'b10000011000000000001;
    assign map[11] = 20'b11111111111111000001;
    assign map[12] = 20'b10000000000000000001;
    assign map[13] = 20'b10000000000000011111;
    assign map[14] = 20'b11111111111111111111;
    // genvar i;
    // generate
    //     for (i=0; i<11; i=i+1) assign map[i] = 20'h0;
    //     assign map[12] = 20'h0;
    // endgenerate

    wire is_tile = (h_cnt < 640 && v_cnt < 480) ? map[gy][19-gx] : 0;
    wire comb_show = is_char || is_tile;

    // 地址計算 (T0)
    reg [7:0] coeff; reg [9:0] lx, ly; reg [16:0] b_off;
    wire [4:0] rel_x = h_cnt - x_s;

    always @(*) begin
        lx = 0; ly = 0; b_off = 0; coeff = 1;
        if (is_tile) begin
            lx = h_cnt[4:0]; ly = v_cnt[4:0];
            b_off = 0; coeff = 64;
        end else if (is_char) begin 
            ly = (v_cnt - y_s);
            if (is_moving) begin
                lx = (face_left ? (5'd31 - rel_x) : rel_x) + (frame_idx * 32); 
                b_off = 8192; coeff = 192;
            end else begin
                lx = (face_left ? (5'd31 - rel_x) : rel_x) + (frame_idx * 32);
                b_off = 4096; coeff = 128;
            end
        end 
        // else if (is_tile) begin
        //     lx = h_cnt[4:0]; ly = v_cnt[4:0];
        //     b_off = 0; coeff = 64;
        // end
    end

    // 管線延遲 (Pipeline) 對齊 BRAM 延遲
    reg [3:0] delay_pipe; 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pixel_addr <= 0;
            delay_pipe <= 4'b0000;
        end else begin
            pixel_addr <= b_off + (ly * coeff) + lx;
            delay_pipe <= {delay_pipe[2:0], comb_show};
        end
    end

    assign out_show_pixel = delay_pipe[2]; 

endmodule