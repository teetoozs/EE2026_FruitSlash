// Titus: eight slots; signed 16-bit Q12.4 centres/velocities.
// One owner writes slots; remove_mask overrides movement and slot reuse.
module object_physics #(
    parameter N = 8, parameter WAVE_SIZE = 3
) (
    input                 clk,
    input                 reset,
    input                 game_tick,
    input                 playing,
    input      [     1:0] difficulty,
    input      [   N-1:0] remove_mask,
    output reg [   N-1:0] active = 0,
    output reg [   N-1:0] bomb = 0,
    output reg [N-1:0] missed = 0,
    output     [N*16-1:0] positions_x,
    output     [N*16-1:0] positions_y
);
    reg signed [15:0] px[0:N-1], py[0:N-1], vx[0:N-1], vy[0:N-1];
    reg [15:0] random_state = 16'hACE1;
    reg [ 7:0] spawn_count = 0;
    integer i, slot, wave, target_count;
    reg [15:0] fruit_random;
    reg [2:0] motion_phase = 0;
    // Four motion updates per five game ticks: exactly 20% slower on average.
    function [15:0] advance_random;
        input [15:0] value;
        reg [15:0] v;
        integer j;
        begin
            v=value;
            for(j=0;j<8;j=j+1)
                v={v[14:0],v[15]^v[13]^v[12]^v[10]};
            advance_random=v;
        end
    endfunction
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
        missed <= 0;
        if (reset) begin
            active       <= 0;
            bomb         <= 0;
            spawn_count  <= 0;
            motion_phase <= 0;
            random_state <= 16'hACE1;
        end else if (playing) begin
            active <= active & ~remove_mask;
            if (game_tick) begin
                motion_phase <= motion_phase == 4 ? 0 : motion_phase + 1'b1;
                random_state <= {
                    random_state[14:0],
                    random_state[15] ^ random_state[13] ^ random_state[12] ^ random_state[10]
                };
                for (i = 0; i < N; i = i + 1)
                if (active[i] && !remove_mask[i] && motion_phase != 4) begin
                    px[i] <= px[i] + vx[i];
                    py[i] <= py[i] + vy[i];
                    vy[i] <= vy[i] + 16'sd3;
                    if (py[i] > 16'sd8704 || px[i] < -16'sd1024 || px[i] > 16'sd11264) begin
                        active[i] <= 0;
                        missed[i] <= !bomb[i];
                    end
                end
                if (spawn_count >= (8'd65 - {6'd0, difficulty} * 8'd10)) begin
                    spawn_count <= 0;
                    // LFSR thresholds approximate 70/20/10 over many waves.
                    target_count = random_state <= 16'd45875 ? 1 :
                                   random_state <= 16'd58982 ? 2 : 3;
                    if(target_count > WAVE_SIZE) target_count=WAVE_SIZE;
                    wave = 0;
                    fruit_random = random_state;
                    for (slot = 0; slot < N; slot = slot + 1) begin
                        if (!active[slot] && !remove_mask[slot] && wave < target_count) begin
                            active[slot] <= 1;
                            // At most one bomb per wave; other slots are fruit.
                            bomb[slot] <= (wave == target_count-1 && random_state[3:0] == 0);
                            case (fruit_random[11:10])
                                0: begin
                                    px[slot] <= (16'd120 + {8'd0,fruit_random[7:0]}) << 4;
                                    py[slot] <= 16'sd8000;
                                    vx[slot] <= fruit_random[9] ? (16'sd12 + $signed({12'd0,fruit_random[3:0]})) : -(16'sd12 + $signed({12'd0,fruit_random[3:0]}));
                                    vy[slot] <= -16'sd152 - $signed({12'd0,fruit_random[7:4]}) - $signed({12'd0,difficulty,2'b00});
                                end
                                1: begin
                                    px[slot] <= (16'd120 + {8'd0,fruit_random[7:0]}) << 4;
                                    py[slot] <= -16'sd768;
                                    vx[slot] <= 0;
                                    vy[slot] <= 16'sd16 + $signed({12'd0,fruit_random[7:4]});
                                end
                                2: begin
                                    px[slot] <= -16'sd768;
                                    py[slot] <= (16'd150 + {10'd0,fruit_random[5:0]}) << 4;
                                    vx[slot] <= 16'sd80 + $signed({11'd0,fruit_random[4:0]});
                                    vy[slot] <= -16'sd48 - $signed({11'd0,fruit_random[8:4]});
                                end
                                3: begin
                                    px[slot] <= 16'sd11008;
                                    py[slot] <= (16'd150 + {10'd0,fruit_random[5:0]}) << 4;
                                    vx[slot] <= -16'sd80 - $signed({11'd0,fruit_random[4:0]});
                                    vy[slot] <= -16'sd48 - $signed({11'd0,fruit_random[8:4]});
                                end
                            endcase
                            wave = wave + 1;
                            fruit_random = advance_random(fruit_random);
                        end
                    end
                end else spawn_count <= spawn_count + 1'b1;
            end
        end
    end
    // Spawn counts include a possible bomb; insufficient free slots cap the wave.
endmodule
