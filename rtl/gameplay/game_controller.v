// Sherwin: score/lives events are hit masks, so simultaneous cuts survive.
module game_controller #(
    parameter N = 8
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
    output reg [  7:0] combo = 0
);
    // 0 title, 1 playing, 2 paused, 3 game over.
    integer i, fruits, bombs, next_score;
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
        // Base 10 points/fruit; release awards 5 per extra fruit in a stroke.
        next_score = score + fruits * 10;
        if (!slash_active && combo > 1) next_score = next_score + (combo - 1) * 5;
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
