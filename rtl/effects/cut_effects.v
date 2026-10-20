// Shen: first-hit flash only; replace with independent halves/particles.
module cut_effects #(
    parameter N = 8
) (
    input                        clk,
    input                        reset,
    input                        game_tick,
    input                        playing,
    input             [   N-1:0] hit_mask,
    input             [N*16-1:0] positions_x,
    input             [N*16-1:0] positions_y,
    output reg signed [    15:0] effect_x = 0,
    output reg signed [    15:0] effect_y = 0,
    output reg        [     5:0] ttl = 0
);
    integer i;
    reg found;
    always @(posedge clk) begin
        if (reset) ttl <= 0;
        else if (playing) begin
            if (game_tick && ttl != 0) ttl <= ttl - 1'b1;
            found = 0;
            for (i = 0; i < N; i = i + 1)
            if (hit_mask[i] && !found) begin
                effect_x <= $signed(positions_x[i*16+:16]) >>> 4;
                effect_y <= $signed(positions_y[i*16+:16]) >>> 4;
                ttl      <= 12;
                found = 1;
            end
        end
    end
endmodule
