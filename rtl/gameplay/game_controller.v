// Sherwin: score/lives events are hit masks, so simultaneous cuts survive.
module game_controller #(
    parameter N = 8,
    parameter MAX_MULT = 5
) (
    input              clk,
    input              reset,
    input              start_pressed,
    input tri0 [2:0] starting_lives,
    input              pause,
    input              effects_busy,
    input              slash_active,
    input      [N-1:0] hit_mask,
    input      [N-1:0] bomb,
    input [N-1:0] missed,
    input bonus_hit,
    output reg [  1:0] state = 0,
    output             playing,
    output             new_round,
    output reg [ 15:0] score = 0,
    output reg [ 15:0] best_score = 0,
    output reg [  2:0] lives = 3,
    output reg [  7:0] combo = 0,
    output     [  2:0] multiplier
);
    wire [2:0] initial_lives=(starting_lives>=1 && starting_lives<=5) ? starting_lives:3'd3;
    // 0 title, 1 playing, 2 paused, 3 game over.
    integer i,j;
    reg [3:0] fruits,losses;
    reg bombs;
    reg [8:0] fruit_points;
    reg [9:0] pending_points=0;
    wire [16:0] score_sum={1'b0,score}+pending_points;
    wire [15:0] next_score=score_sum[16] ? 16'hffff:score_sum[15:0];
    wire [2:0] capped_combo=combo>=MAX_MULT ? MAX_MULT:combo[2:0];
    assign multiplier = 3'd1;
    assign playing   = (state == 1) && !pause;
    assign new_round = start_pressed && !effects_busy && (state == 0 || state == 3);
    always @(*) begin
        fruits = 0;
        bombs  = 0;
        losses = 0;
        for (j=0; j<N; j=j+1) losses = losses + missed[j];
        for (i = 0; i < N; i = i + 1)
        if (hit_mask[i]) begin
            if (bomb[i]) bombs = 1;
            else fruits = fruits + 1;
        end
        fruit_points=fruits; // One point per fruit, independent of combo.
        losses = losses + bombs;
    end
    always @(posedge clk) begin
        // Compare the registered score, off the score-adder critical path.
        if(score>best_score) best_score<=score;
        if(reset || new_round) pending_points<=0;
        else if(playing && !effects_busy) pending_points<=fruit_points+(bonus_hit ? 10'd1:10'd0);
        else pending_points<=0;
        if(!reset && !new_round) score<=next_score;
        if (reset) begin
            state <= 0;
            score <= 0;
            lives <= initial_lives;
            combo <= 0;
        end else if (new_round) begin
            state <= 1;
            score <= 0;
            lives <= initial_lives;
            combo <= 0;
        end else
            case (state)
                1:
                if (pause) state <= 2;
                else if (!effects_busy) begin

                    if (!slash_active || losses != 0) combo <= 0;
                    else if (combo + fruits > 255) combo <= 255;
                    else combo <= combo + fruits;
                    if (bombs != 0 || (losses >= lives && losses != 0)) begin
                        lives <= 0;
                        state <= 3;
                    end else lives <= lives - losses;
                end
                2: if (!pause) state <= 1;
                default: begin
                    if(state==0) lives<=initial_lives;
                end
            endcase
    end
    // TODO: title/menu UI data, richer combo policy, multiplier, session stats.
endmodule
