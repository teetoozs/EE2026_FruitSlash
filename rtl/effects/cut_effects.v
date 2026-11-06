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
    input tri0 [N*4-1:0] fruit_types,
    input tri0 [N*2-1:0] spins,
    output reg [N*4-1:0] effect_types=0,
    output reg [N*2-1:0] effect_spins=0,
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
    reg signed [9:0] vy [0:2*N-1];
    reg signed [8:0] vx [0:2*N-1];
    wire signed [10:0] swipe_dx=$signed({1'b0,blade_x1})-$signed({1'b0,blade_x0});
    wire signed [10:0] swipe_dy=$signed({1'b0,blade_y1})-$signed({1'b0,blade_y0});
    wire [10:0] abs_dx=swipe_dx<0 ? -swipe_dx:swipe_dx;
    wire [10:0] abs_dy=swipe_dy<0 ? -swipe_dy:swipe_dy;
    // 0 vertical, 1 horizontal, 2 falling diagonal, 3 rising diagonal.
    wire [1:0] direction=abs_dx>({1'b0,abs_dy}<<1) ? 1:
        abs_dy>({1'b0,abs_dx}<<1) ? 0:(swipe_dx[10]^swipe_dy[10]) ? 3:2;
    // Bounded impulse from swipe displacement; big halves receive half impulse.
    wire [11:0] swipe_length={1'b0,abs_dx}+{1'b0,abs_dy};
    wire signed [15:0] impulse=swipe_length>64 ? 16'sd96:16'sd32+$signed({4'b0,swipe_length});
    wire signed [15:0] drag_x=swipe_dx>48 ? 16'sd48:swipe_dx< -48 ? -16'sd48:swipe_dx;
    wire signed [15:0] drag_y=swipe_dy>48 ? 16'sd48:swipe_dy< -48 ? -16'sd48:swipe_dy;
    reg signed [8:0] init_vx0,init_vx1,init_vy0,init_vy1;
    always @(*) begin
        init_vx0=drag_x;init_vx1=drag_x;init_vy0=drag_y;init_vy1=drag_y;
        case(direction)
         0:begin init_vx0=drag_x-impulse;init_vx1=drag_x+impulse;end
         1:begin init_vy0=drag_y-impulse;init_vy1=drag_y+impulse;end
         2:begin init_vx0=drag_x+(impulse>>>1);init_vx1=drag_x-(impulse>>>1);init_vy0=drag_y-(impulse>>>1);init_vy1=drag_y+(impulse>>>1);end
         3:begin init_vx0=drag_x-(impulse>>>1);init_vx1=drag_x+(impulse>>>1);init_vy0=drag_y-(impulse>>>1);init_vy1=drag_y+(impulse>>>1);end
        endcase
    end
    reg [2*N-1:0] move_pending=0;
    reg [$clog2(2*N+1)-1:0] move_index=0;
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
            splash_active <= 0;move_pending<=0;move_index<=0;
            effect_radii <= 0;cut_direction<=0;effect_types<=0;effect_spins<=0;
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
                move_pending<=halves_active;move_index<=0;
            end else if(move_index<2*N) begin
                move_index<=move_index+1'b1;
                move_pending[move_index]<=0;
                if(move_pending[move_index] && halves_active[move_index]) begin
                    px[move_index]<=px[move_index]+$signed(vx[move_index]);
                    py[move_index]<=py[move_index]+$signed(vy[move_index]);
                    vy[move_index]<=vy[move_index]+10'sd4;
                    life[move_index]<=life[move_index]-1'b1;
                    if(life[move_index]<=1 || py[move_index]>16'sd8000 ||
                       px[move_index]<-16'sd512 || px[move_index]>16'sd10752)
                       halves_active[move_index]<=0;
                end
            end
            for (i = 0; i < N; i = i + 1) begin
                if (hit_mask[i]) begin
                    if (!bomb[i]) begin
                        effect_types[i*4+:4]<=fruit_types[i*4+:4];effect_spins[i*2+:2]<=spins[i*2+:2];
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
                        // The same impulse circuit feeds every hit, including simultaneous cuts.
                        vx[2*i]<=(VARIABLE_RADIUS && radii[i*5+:5]>15) ? init_vx0>>>1:init_vx0;
                        vx[2*i+1]<=(VARIABLE_RADIUS && radii[i*5+:5]>15) ? init_vx1>>>1:init_vx1;
                        vy[2*i]<=(VARIABLE_RADIUS && radii[i*5+:5]>15) ? init_vy0>>>1:init_vy0;
                        vy[2*i+1]<=(VARIABLE_RADIUS && radii[i*5+:5]>15) ? init_vy1>>>1:init_vy1;
                        move_pending[2*i]<=0;move_pending[2*i+1]<=0;
                        life[2*i] <= 90;
                        life[2*i+1] <= 90;
                    end
                end
            end
        end
    end
endmodule
