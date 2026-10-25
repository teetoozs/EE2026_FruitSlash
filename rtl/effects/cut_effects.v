// Yuncong: one pair per object slot; a new cut in a reused slot replaces its old pair.
// Positions/velocities use signed Q12.4, like object_physics.
module cut_effects #(parameter N = 8) (
    input clk,
    input reset,
    input game_tick,
    input playing,
    input [N-1:0] hit_mask,
    input [N-1:0] bomb,
    input [N*16-1:0] positions_x,
    input [N*16-1:0] positions_y,
    output reg signed [15:0] effect_x = 0,
    output reg signed [15:0] effect_y = 0,
    output reg [5:0] ttl = 0,
    output reg [2*N-1:0] halves_active = 0,
    output [2*N*16-1:0] halves_x,
    output [2*N*16-1:0] halves_y,
    output reg [N-1:0] splash_active = 0,
    output reg [N*16-1:0] splash_x = 0,
    output reg [N*16-1:0] splash_y = 0,
    output [N*5-1:0] splash_age
);
    reg signed [15:0] px [0:2*N-1];
    reg signed [15:0] py [0:2*N-1];
    reg signed [15:0] vy [0:2*N-1];
    reg [6:0] life [0:2*N-1];
    reg [4:0] age [0:N-1];
    integer i;
    reg found;
    genvar k;
    generate
        for (k = 0; k < 2*N; k = k + 1) begin : pack
            assign halves_x[k*16+:16] = px[k];
            assign halves_y[k*16+:16] = py[k];
        end
        for (k = 0; k < N; k = k + 1) begin : pack_splash
            assign splash_age[k*5+:5] = age[k];
        end
    endgenerate
    always @(posedge clk) begin
        if (reset) begin
            ttl <= 0;
            splash_active <= 0;
            splash_x <= 0;
            splash_y <= 0;
            for (i = 0; i < N; i = i + 1) age[i] <= 0;
            halves_active <= 0;
            effect_x <= 0;
            effect_y <= 0;
            for (i = 0; i < 2*N; i = i + 1) begin
                px[i] <= 0;
                py[i] <= 0;
                vy[i] <= 0;
                life[i] <= 0;
            end
        end else if (playing) begin
            if (game_tick) begin
                for (i = 0; i < N; i = i + 1) begin
                    if (splash_active[i]) begin
                        if (age[i] == 23) splash_active[i] <= 0;
                        else age[i] <= age[i] + 1'b1;
                    end
                end
                if (ttl != 0) ttl <= ttl - 1'b1;
                for (i = 0; i < 2*N; i = i + 1) begin
                    if (halves_active[i]) begin
                        // Even pieces are left semicircles, odd pieces right semicircles.
                        px[i] <= px[i] + ((i % 2 == 0) ? -16'sd32 : 16'sd32);
                        py[i] <= py[i] + vy[i];
                        vy[i] <= vy[i] + 16'sd4;
                        life[i] <= life[i] - 1'b1;
                        if (life[i] <= 1 || py[i] > 16'sd8000 ||
                            px[i] < -16'sd512 || px[i] > 16'sd10752)
                            halves_active[i] <= 0;
                    end
                end
            end
            found = 0;
            for (i = 0; i < N; i = i + 1) begin
                if (hit_mask[i]) begin
                    if (!bomb[i]) begin
                        splash_active[i] <= 1;
                        splash_x[i*16+:16] <= positions_x[i*16+:16];
                        splash_y[i*16+:16] <= positions_y[i*16+:16];
                        age[i] <= 0;
                        // Capture before physics removes the original. New hits win over ticks.
                        halves_active[2*i] <= 1;
                        halves_active[2*i+1] <= 1;
                        px[2*i] <= positions_x[i*16+:16];
                        px[2*i+1] <= positions_x[i*16+:16];
                        py[2*i] <= positions_y[i*16+:16];
                        py[2*i+1] <= positions_y[i*16+:16];
                        vy[2*i] <= 16'sd16;
                        vy[2*i+1] <= 16'sd24;
                        life[2*i] <= 90;
                        life[2*i+1] <= 90;
                    end else if (!found) begin
                        effect_x <= $signed(positions_x[i*16+:16]) >>> 4;
                        effect_y <= $signed(positions_y[i*16+:16]) >>> 4;
                        ttl <= 12;
                        found = 1;
                    end
                end
            end
        end
    end
endmodule
