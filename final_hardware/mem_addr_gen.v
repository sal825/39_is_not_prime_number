module mem_addr_gen(
    input clk,            // 25MHz
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
    output wire out_show_pixel
    );

    localparam IMG_W = 32;
    localparam IMG_H = 32;
    
    // --- 地圖定義 (20x15 網格) ---
    // 0: 空地, 1: 障礙物/地板
    // 這裡示範建立一個簡單的地圖
    wire [19:0] map [0:14];
    assign map[0]  = 20'b00000000000000000000;
    assign map[1]  = 20'b00000000000000000000;
    assign map[11] = 20'b00000000001110000000; // 在中間放三個障礙物
    assign map[12] = 20'b00000000000000000000;
    assign map[13] = 20'b00000000000000011000; // 右下角放兩個
    assign map[14] = 20'b11111111111111111111; // 最底下一整排是地板

    // 同步座標
    reg [9:0] x_s, y_s;
    always @(posedge vsync or posedge rst) begin
        if (rst) {x_s, y_s} <= {10'd0, 10'd416};
        else {x_s, y_s} <= {img_x, img_y};
    end

    // 取得當前掃描點所在的網格座標 (h_cnt/32, v_cnt/32)
    wire [4:0] grid_x = h_cnt >> 5; 
    wire [3:0] grid_y = v_cnt >> 5;
    wire is_map_block = (h_cnt < 640 && v_cnt < 480) ? map[grid_y][19-grid_x] : 0;

    // 角色區域判斷
    wire is_char = (h_cnt >= x_s && h_cnt < x_s + IMG_W) && (v_cnt >= y_s && v_cnt < y_s + IMG_H);
    // 地板/障礙物判斷：只要地圖上該點是 1 就是 Tile
    wire is_tile = is_map_block;
    
    // 繪製優先權：角色在障礙物後面
    wire comb_show = is_char || is_tile;

    reg [7:0] coeff;
    reg [9:0] lx, ly;
    reg [16:0] b_off;
    wire [4:0] rel_x = h_cnt - x_s;

    always @(*) begin
        lx = 0; ly = 0; b_off = 0; coeff = 1;
        if (is_tile) begin
            // 障礙物使用地板的 64x64 切片，這裡為了對齊 32x32，取其一半
            lx = h_cnt[4:0]; // 32x32 循環
            ly = v_cnt[4:0];
            b_off = 0;
            coeff = 64;
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
        // end else if (is_tile) begin
        //     // 障礙物使用地板的 64x64 切片，這裡為了對齊 32x32，取其一半
        //     lx = h_cnt[4:0]; // 32x32 循環
        //     ly = v_cnt[4:0];
        //     b_off = 0;
        //     coeff = 64;
        // end
    end

    // 管線延遲 (Pipeline) 對齊 BRAM
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