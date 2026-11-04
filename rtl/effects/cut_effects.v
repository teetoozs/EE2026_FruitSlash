// Yuncong: one pair per object slot; a new cut in a reused slot replaces its old pair.
// Positions/velocities use signed Q12.4, like object_physics.
module cut_effects #(parameter N = 8, parameter VARIABLE_RADIUS = 0) (
    input clk,
    input [9:0] blade_x0,blade_y0,blade_x1,blade_y1,
    input reset,
    input game_tick,
    input playing,
    input [N-1:0] hit_mask,
    input [N-1:0] bomb,
    input [N*5-1:0] radii,
    output reg [N*5-1:0] effect_radii = 0,
    output reg [N*2-1:0] cut_direction=0,
    input [N*16-1:0] positions_x,
    input [N*16-1:0] positions_y,
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
    reg signed [15:0] vx [0:2*N-1];
    wire signed [10:0] swipe_dx=$signed({1'b0,blade_x1})-$signed({1'b0,blade_x0});
    wire signed [10:0] swipe_dy=$signed({1'b0,blade_y1})-$signed({1'b0,blade_y0});
    wire [10:0] abs_dx=swipe_dx<0 ? -swipe_dx:swipe_dx;
    wire [10:0] abs_dy=swipe_dy<0 ? -swipe_dy:swipe_dy;
    // 0 vertical, 1 horizontal, 2 falling diagonal, 3 rising diagonal.
    wire [1:0] direction=abs_dx>({1'b0,abs_dy}<<1) ? 1:
        abs_dy>({1'b0,abs_dx}<<1) ? 0:(swipe_dx[10]^swipe_dy[10]) ? 3:2;
    reg [6:0] life [0:2*N-1];
    reg [4:0] age [0:N-1];
    integer i;
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
            splash_active <= 0;
            effect_radii <= 0;cut_direction<=0;
            splash_x <= 0;
            splash_y <= 0;
            for (i = 0; i < N; i = i + 1) age[i] <= 0;
            halves_active <= 0;
            for (i = 0; i < 2*N; i = i + 1) begin
                px[i] <= 0;
                py[i] <= 0;
                vy[i] <= 0;vx[i]<=0;
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
                for (i = 0; i < 2*N; i = i + 1) begin
                    if (halves_active[i]) begin
                        // Even pieces are left semicircles, odd pieces right semicircles.
                        px[i] <= px[i] + vx[i];
                        py[i] <= py[i] + vy[i];
                        vy[i] <= vy[i] + 16'sd4;
                        life[i] <= life[i] - 1'b1;
                        if (life[i] <= 1 || py[i] > 16'sd8000 ||
                            px[i] < -16'sd512 || px[i] > 16'sd10752)
                            halves_active[i] <= 0;
                    end
                end
            end
            for (i = 0; i < N; i = i + 1) begin
                if (hit_mask[i]) begin
                    if (!bomb[i]) begin
                        effect_radii[i*5+:5] <= VARIABLE_RADIUS ? radii[i*5+:5] : 5'd18;
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
                        cut_direction[i*2+:2]<=direction;
                        case(direction)
                          0:begin vx[2*i]<=-32;vx[2*i+1]<=32;vy[2*i]<=16;vy[2*i+1]<=16;end
                          1:begin vx[2*i]<=0;vx[2*i+1]<=0;vy[2*i]<=-32;vy[2*i+1]<=32;end
                          2:begin vx[2*i]<=24;vx[2*i+1]<=-24;vy[2*i]<=-24;vy[2*i+1]<=24;end
                          3:begin vx[2*i]<=-24;vx[2*i+1]<=24;vy[2*i]<=-24;vy[2*i+1]<=24;end
                        endcase
                        life[2*i] <= 90;
                        life[2*i+1] <= 90;
                    end
                end
            end
        end
    end
endmodule
