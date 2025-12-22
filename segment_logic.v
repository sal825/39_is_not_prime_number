module segment_logic(
    input rst, 
    input clk, 
    input [3:0] state,
    output reg [15:0] nums
    );
    
    reg [31:0] cnt;
    reg [9:0] sec;
    
    // always @(posedge clk, posedge rst) begin
    //     if (rst) begin 
    //         cnt <= 0;
    //         sec <= 0;
            
    //     end else begin 
    //         if (cnt != 100000000) cnt <= cnt + 1;
    //         else begin 
    //             cnt <= 0;
    //             sec <= sec + 1;
    //         end
    //     end
    // end
    reg [9:0] best_sec;       // 新增：儲存最短秒數

    // 時間計數邏輯
    always @(posedge clk or posedge rst) begin
        if (rst) begin 
            cnt <= 0;
            sec <= 0;
            best_sec <= 10'd000; // 初始設為最大值
        end else begin 
            if (state == 4'd1 || state == 4'd4) begin // PLAY_SCENE 或 BOSS_SCENE 才計時
                if (cnt != 100000000) cnt <= cnt + 1;
                else begin 
                    cnt <= 0;
                    sec <= sec + 1;
                end
            end else if (state == 4'd0) begin // 回到 START_SCENE 重置當前時間
                sec <= 0;
                cnt <= 0;
            end
            
            // 更新最佳時間邏輯：進入 WIN_SCENE 時比較
            if (state == 4'd3) begin // WIN_SCENE
                if (sec < best_sec || best_sec == 10'd000) begin
                    best_sec <= sec;
                end
            end
        end
    end
    always @(*) begin
        nums[15:12] <= best_sec / 1000;
        nums[11:8] <= best_sec / 100;
        nums[7:4] <= best_sec / 10;
        nums[3:0] <= best_sec % 10; 
    end
    
endmodule