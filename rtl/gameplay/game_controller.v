// Sherwin: score/lives events are hit masks, so simultaneous cuts survive.
module game_controller #(
    parameter N = 8,
    parameter MAX_MULT = 5
) (
    input              clk,
    input              reset,
    input              start_pressed,
    input              pause,
    input              slash_active,
    input      [N-1:0] hit_mask,
    input      [N-1:0] bomb,
    output reg [  1:0] state = 0,
    output             playing,
    output             new_round,
    output reg [ 15:0] score = 0,
    output reg [ 15:0] best_score = 0,
    output reg [  1:0] lives = 3,
    output reg [  7:0] combo = 0,
    output     [  2:0] multiplier
);
    // 0 title, 1 playing, 2 paused, 3 game over.
    integer i, j;
    integer fruits = 0, bombs = 0, fruit_points = 0, next_score = 0;
    assign multiplier = (combo + 1 > MAX_MULT) ? MAX_MULT : combo + 1;
    assign playing   = (state == 1) && !pause;
    assign new_round = start_pressed && (state == 0 || state == 3);
    always @(*) begin
        fruits = 0;
        bombs  = 0;
        for (i = 0; i < N; i = i + 1)
        if (hit_mask[i]) begin
            if (bomb[i]) bombs = bombs + 1;
            else fruits = fruits + 1;
        end
        // Live multiplier: the k-th fruit of a swipe scores 10*k, capped at MAX_MULT.
        fruit_points = 0;
        for (j = 1; j <= fruits; j = j + 1)
            fruit_points = fruit_points + 10 * (((combo + j) > MAX_MULT) ? MAX_MULT : (combo + j));
        next_score = score + fruit_points;
        
        if (next_score > 65535) next_score = 65535;
    end
    always @(posedge clk) begin
        if (reset) begin
            state <= 0;
            score <= 0;
            lives <= 3;
            combo <= 0;
        end else if (new_round) begin
            state <= 1;
            score <= 0;
            lives <= 3;
            combo <= 0;
        end else
            case (state)
                1:
                if (pause) state <= 2;
                else begin
                    score <= next_score;
                    if (next_score > best_score) best_score <= next_score;
                    if (!slash_active) combo <= 0;
                    else if (combo + fruits > 255) combo <= 255;
                    else combo <= combo + fruits;
                    if (bombs >= lives && bombs != 0) begin
                        lives <= 0;
                        state <= 3;
                    end else lives <= lives - bombs;
                end
                2: if (!pause) state <= 1;
                default: begin
                end
            endcase
    end
    // TODO: title/menu UI data, richer combo policy, multiplier, session stats.
endmodule
