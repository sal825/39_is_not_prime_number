// 這個模組處理 BRAM 延遲後的數據，進行去背判斷，並輸出最終的 VGA 顏色。

module pixel_mux(
    input clk,
    input rst,
    
    // 從 mem_addr_gen 來的時序控制訊號 (已延遲一拍)
    input is_char_pixel_d,
    
    // 從 BRAM 讀取到的顏色 (12-bit RGB: 4-bit R, 4-bit G, 4-bit B)
    input [11:0] read_data,   
    
    // VGA 最終輸出顏色 (12-bit)
    output reg [11:0] vga_color_out
);
    
    // 定義透明色 (亮洋紅色 FF00FF)
    // 由於您的顏色是 12-bit (R4G4B4)，FF00FF 轉換後為 12'hF0F
    // R: FF -> F, G: 00 -> 0, B: FF -> F
    localparam [11:0] CHROMA_KEY_COLOR = 12'hF0F; 
    
    // 內部背景顏色延遲暫存器 (用於補償角色透明時所需的背景顏色)
    reg [11:0] last_bg_color;
    
    // 時序邏輯：儲存前一拍的背景顏色
    always @(posedge clk) begin
        if (rst) begin
            last_bg_color <= 12'h000;
        end else if (is_char_pixel_d == 0) begin
            // 只有當前一週期讀取的是背景地址 (is_char_pixel_d=0) 時，
            // 才將 BRAM 輸出 (read_data) 視為背景顏色並儲存。
            last_bg_color <= read_data;
        end
    end
    
    // 組合邏輯：顏色多工器
    always @(*) begin
        if (is_char_pixel_d) begin 
            // 情況 1：前一拍讀取的是角色顏色 (read_data = Char_Color)
            if (read_data == CHROMA_KEY_COLOR) begin
                // 角色是透明色，使用前一拍儲存的背景顏色
                vga_color_out = last_bg_color; 
            end else begin
                // 角色不透明，顯示角色顏色
                vga_color_out = read_data;
            end
        end else begin
            // 情況 2：前一拍讀取的是背景顏色 (read_data = Background_Color)
            // 直接輸出背景顏色
            vga_color_out = read_data;
        end
    end

endmodule