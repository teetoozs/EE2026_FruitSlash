// Titus: eight slots; signed 16-bit Q12.4 centres/velocities.
// One owner writes slots; remove_mask overrides movement and slot reuse.
module object_physics #(
    parameter N = 8
) (
    input                 clk,
    input                 reset,
    input                 game_tick,
    input                 playing,
    input      [     1:0] difficulty,
    input      [   N-1:0] remove_mask,
    output reg [   N-1:0] active = 0,
    output reg [   N-1:0] bomb = 0,
    output     [N*16-1:0] positions_x,
    output     [N*16-1:0] positions_y
);
    reg signed [15:0] px[0:N-1], py[0:N-1], vx[0:N-1], vy[0:N-1];
    reg [15:0] random_state = 16'hACE1;
    reg [ 7:0] spawn_count = 0;
    integer i, slot;
    initial
        for (i = 0; i < N; i = i + 1) begin
            px[i] = 0;
            py[i] = 0;
            vx[i] = 0;
            vy[i] = 0;
        end
    genvar k;
    generate
        for (k = 0; k < N; k = k + 1) begin : pack
            assign positions_x[k*16+:16] = px[k];
            assign positions_y[k*16+:16] = py[k];
        end
    endgenerate
    always @(posedge clk) begin
        if (reset) begin
            active       <= 0;
            bomb         <= 0;
            spawn_count  <= 0;
            random_state <= 16'hACE1;
        end else if (playing) begin
            active <= active & ~remove_mask;
            if (game_tick) begin
                random_state <= {
                    random_state[14:0],
                    random_state[15] ^ random_state[13] ^ random_state[12] ^ random_state[10]
                };
                for (i = 0; i < N; i = i + 1)
                if (active[i] && !remove_mask[i]) begin
                    px[i] <= px[i] + vx[i];
                    py[i] <= py[i] + vy[i];
                    vy[i] <= vy[i] + 16'sd3;
                    if (py[i] > 16'sd8320 || px[i] < -16'sd512 || px[i] > 16'sd10752)
                        active[i] <= 0;
                end
                if (spawn_count >= (8'd65 - {6'd0, difficulty} * 8'd10)) begin
                    spawn_count <= 0;
                    slot = -1;
                    for (i = 0; i < N; i = i + 1)
                    if (!active[i] && !remove_mask[i] && slot == -1) slot = i;
                    if (slot != -1) begin
                        active[slot] <= 1;
                        bomb[slot]   <= random_state[3:0] == 0;
                        px[slot]     <= (16'd100 + {7'd0, random_state[8:0]}) << 4;
                        py[slot]     <= 16'sd8000;
                        vx[slot]     <= random_state[9] ? 16'sd20 : -16'sd20;
                        vy[slot]     <= -16'sd168 - $signed({12'd0, difficulty, 2'b00});
                    end
                end else spawn_count <= spawn_count + 1'b1;
            end
        end
    end
    // TODO: fruit types/colours, difficulty tuning, launch waves and misses.
endmodule
