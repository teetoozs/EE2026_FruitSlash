// Capture every bomb in a hit mask, then run a shared freeze/blast timeline.
// This timeline is independent of playing so a fatal hit can finish its animation.
module bomb_effects #(parameter N = 8) (
    input clk,
    input reset,
    input game_tick,
    input paused,
    input [N-1:0] hit_mask,
    input [N-1:0] bomb,
    input [N*16-1:0] positions_x,
    input [N*16-1:0] positions_y,
    output busy,
    output reg [N-1:0] active = 0,
    output reg [N*16-1:0] origins_x = 0,
    output reg [N*16-1:0] origins_y = 0,
    output reg [5:0] age = 0
);
    assign busy = |active;
    always @(posedge clk) begin
        if (reset) begin
            active <= 0;
            origins_x <= 0;
            origins_y <= 0;
            age <= 0;
        end else if (!paused) begin
            if (!busy && |(hit_mask & bomb)) begin
                active <= hit_mask & bomb;
                origins_x <= positions_x;
                origins_y <= positions_y;
                age <= 0;
            end else if (busy && game_tick) begin
                if (age == 47) begin
                    active <= 0;
                    age <= 0;
                end else age <= age + 1'b1;
            end
        end
    end
endmodule
