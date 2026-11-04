// Sherwin: score/lives events are hit masks, so simultaneous cuts survive.
module game_controller #(
    parameter N = 8,
    parameter MAX_MULT = 5
) (
    input              clk,
    input              reset,
    input              start_pressed,
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
    output reg [  1:0] lives = 3,
    output reg [  7:0] combo = 0,
    output     [  2:0] multiplier
);
    // 0 title, 1 playing, 2 paused, 3 game over.
    integer i,j;
    reg [3:0] fruits,losses;
    reg bombs;
    reg [8:0] fruit_points;
    reg [9:0] pending_points=0;
    wire [16:0] score_sum={1'b0,score}+pending_points;
    wire [15:0] next_score=score_sum[16] ? 16'hffff:score_sum[15:0];
    wire [2:0] capped_combo=combo>=MAX_MULT ? MAX_MULT:combo[2:0];
    assign multiplier = (combo + 1 > MAX_MULT) ? MAX_MULT : combo + 1;
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
        // Compact truth table replaces a serial chain of adders.
        fruit_points=0;
        case({capped_combo,fruits})
            7'd0: fruit_points=9'd0;
            7'd1: fruit_points=9'd10;
            7'd2: fruit_points=9'd30;
            7'd3: fruit_points=9'd60;
            7'd4: fruit_points=9'd100;
            7'd5: fruit_points=9'd150;
            7'd6: fruit_points=9'd200;
            7'd7: fruit_points=9'd250;
            7'd8: fruit_points=9'd300;
            7'd16: fruit_points=9'd0;
            7'd17: fruit_points=9'd20;
            7'd18: fruit_points=9'd50;
            7'd19: fruit_points=9'd90;
            7'd20: fruit_points=9'd140;
            7'd21: fruit_points=9'd190;
            7'd22: fruit_points=9'd240;
            7'd23: fruit_points=9'd290;
            7'd24: fruit_points=9'd340;
            7'd32: fruit_points=9'd0;
            7'd33: fruit_points=9'd30;
            7'd34: fruit_points=9'd70;
            7'd35: fruit_points=9'd120;
            7'd36: fruit_points=9'd170;
            7'd37: fruit_points=9'd220;
            7'd38: fruit_points=9'd270;
            7'd39: fruit_points=9'd320;
            7'd40: fruit_points=9'd370;
            7'd48: fruit_points=9'd0;
            7'd49: fruit_points=9'd40;
            7'd50: fruit_points=9'd90;
            7'd51: fruit_points=9'd140;
            7'd52: fruit_points=9'd190;
            7'd53: fruit_points=9'd240;
            7'd54: fruit_points=9'd290;
            7'd55: fruit_points=9'd340;
            7'd56: fruit_points=9'd390;
            7'd64: fruit_points=9'd0;
            7'd65: fruit_points=9'd50;
            7'd66: fruit_points=9'd100;
            7'd67: fruit_points=9'd150;
            7'd68: fruit_points=9'd200;
            7'd69: fruit_points=9'd250;
            7'd70: fruit_points=9'd300;
            7'd71: fruit_points=9'd350;
            7'd72: fruit_points=9'd400;
            7'd80: fruit_points=9'd0;
            7'd81: fruit_points=9'd50;
            7'd82: fruit_points=9'd100;
            7'd83: fruit_points=9'd150;
            7'd84: fruit_points=9'd200;
            7'd85: fruit_points=9'd250;
            7'd86: fruit_points=9'd300;
            7'd87: fruit_points=9'd350;
            7'd88: fruit_points=9'd400;
            default:fruit_points=0;
        endcase
        losses = losses + bombs;
    end
    always @(posedge clk) begin
        // Compare the registered score, off the score-adder critical path.
        if(score>best_score) best_score<=score;
        if(reset || new_round) pending_points<=0;
        else if(playing && !effects_busy) pending_points<=fruit_points+(bonus_hit ? 10'd25:10'd0);
        else pending_points<=0;
        if(!reset && !new_round) score<=next_score;
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
                end
            endcase
    end
    // TODO: title/menu UI data, richer combo policy, multiplier, session stats.
endmodule
