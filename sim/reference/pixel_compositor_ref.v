// Single RGB selector: original procedural arcade art and life HUD.
// DETAILED_ART=0 retains flat diagnostic masks for geometry regression.
module pixel_compositor_ref #(
    parameter N = 8,
    parameter VARIABLE_RADIUS = 0,
    parameter DETAILED_ART = 0,
    parameter SIZE_SHIFT = 0
) (
    input clk,reset,
    input [9:0] raster_y,
    input         [     9:0] x,
    input         [     9:0] y,
    input                    video_on,
    input         [    11:0] heart_levels,
    input         [ N*5-1:0] radii,
    input         [ N*2-1:0] health,
    input         [     1:0] state,
    input         [     9:0] cursor_x,
    input         [     9:0] cursor_y,
    input                    slash_active,
    input         [   N-1:0] active,
    input         [   N-1:0] bomb,
    input         [N*16-1:0] positions_x,
    input         [N*16-1:0] positions_y,
    input [N-1:0] explosion_active,
    input [N*16-1:0] explosion_x,
    input [N*16-1:0] explosion_y,
    input [8:0] explosion_age,
    input         [N*5-1:0] effect_radii,
    input tri0 [N*2-1:0] cut_direction,
    input tri0 [N*4-1:0] fruit_types,effect_types,
    input tri0 [N*2-1:0] spins,effect_spins,
    input         [2*N-1:0] halves_active,
    input         [2*N*16-1:0] halves_x,
    input         [2*N*16-1:0] halves_y,
    input         [N-1:0] splash_active,
    input         [N*16-1:0] splash_x,
    input         [N*16-1:0] splash_y,
    input         [N*5-1:0] splash_age,
    input wall_on, input [11:0] wall_rgb,
    output reg    [    11:0] rgb
);

    wire splash_pixel;
    wire [11:0] splash_rgb;
    (* keep_hierarchy = "yes" *) splash_renderer #(.N(N), .FRUIT_PALETTE(DETAILED_ART)) juice (
        .x(x),
        .y(y),
        .active(splash_active),
        .positions_x(splash_x),
        .positions_y(splash_y),
        .ages(splash_age),
        .radii(effect_radii),
        .pixel_on(splash_pixel),
        .rgb(splash_rgb)
    );

    // Exact integer circle row widths: no per-fruit pixel multipliers.
    function [4:0] extent18;
        input [4:0] row;
        begin
            case (row)
                5'd0: extent18 = 5'd18;
                5'd1: extent18 = 5'd17;
                5'd2: extent18 = 5'd17;
                5'd3: extent18 = 5'd17;
                5'd4: extent18 = 5'd17;
                5'd5: extent18 = 5'd17;
                5'd6: extent18 = 5'd16;
                5'd7: extent18 = 5'd16;
                5'd8: extent18 = 5'd16;
                5'd9: extent18 = 5'd15;
                5'd10: extent18 = 5'd14;
                5'd11: extent18 = 5'd14;
                5'd12: extent18 = 5'd13;
                5'd13: extent18 = 5'd12;
                5'd14: extent18 = 5'd11;
                5'd15: extent18 = 5'd9;
                5'd16: extent18 = 5'd8;
                5'd17: extent18 = 5'd5;
                5'd18: extent18 = 5'd0;
                default: extent18 = 0;
            endcase
        end
    endfunction

    wire explosion_pixel;
    wire [11:0] explosion_rgb;
    bomb_renderer #(.N(N)) blast (
        .x(x),
        .y(y),
        .active(explosion_active),
        .origins_x(explosion_x),
        .origins_y(explosion_y),
        .age(explosion_age),
        .pixel_on(explosion_pixel),
        .rgb(explosion_rgb)
    );

    function [4:0] extent12;
        input [4:0] row;
        begin
            case (row)
                0: extent12 = 12;
                1: extent12 = 11;
                2: extent12 = 11;
                3: extent12 = 11;
                4: extent12 = 11;
                5: extent12 = 10;
                6: extent12 = 10;
                7: extent12 = 9;
                8: extent12 = 8;
                9: extent12 = 7;
                10: extent12 = 6;
                11: extent12 = 4;
                12: extent12 = 0;
                default: extent12 = 0;
            endcase
        end
    endfunction
    function [4:0] extent24;
        input [4:0] row;
        begin
            case (row)
                0: extent24 = 24;
                1: extent24 = 23;
                2: extent24 = 23;
                3: extent24 = 23;
                4: extent24 = 23;
                5: extent24 = 23;
                6: extent24 = 23;
                7: extent24 = 22;
                8: extent24 = 22;
                9: extent24 = 22;
                10: extent24 = 21;
                11: extent24 = 21;
                12: extent24 = 20;
                13: extent24 = 20;
                14: extent24 = 19;
                15: extent24 = 18;
                16: extent24 = 17;
                17: extent24 = 16;
                18: extent24 = 15;
                19: extent24 = 14;
                20: extent24 = 13;
                21: extent24 = 11;
                22: extent24 = 9;
                23: extent24 = 6;
                24: extent24 = 0;
                default: extent24 = 0;
            endcase
        end
    endfunction
    wire [2:0] heart;
    genvar h;
    generate
        for (h = 0; h < 3; h = h + 1) begin : hud
            heart_pixel #(
                .SCALE(1)
            ) shape (
                .x       (x),
                .y       (y),
                .left    (10'd514 + h * 10'd40),
                .top     (10'd16),
                .pixel_on(heart[h])
            );
        end
    endgenerate
    integer i;
    reg [4:0] radius,extent;
    reg signed [15:0] qx,qy;
    reg signed [12:0] dx,dy,tx,ty;
    reg [12:0] ax,ay,inner_y;
    reg [4:0] inner_extent;
    reg signed [13:0] side;
    reg [3:0] kind;
    reg [1:0] spin;
    reg mask,picked,picked_bomb,picked_cut,picked_stem;
    reg signed [12:0] art_dx,art_dy;
    reg [5:0] art_radius;
    reg [3:0] art_kind;
    reg [11:0] background;
    wire [11:0] surface_rgb;
    fruit_surface surface(.dx(art_dx),.dy(art_dy),.radius(art_radius),
        .kind(art_kind),.bomb(picked_bomb),.cut_edge(picked_cut),.rgb(surface_rgb));
    wire [5:0] wood_u=x[5:0];
    wire [6:0] wood_v=y[6:0]+(x[6] ? 7'd64:7'd0);
    wire [5:0] grain_phase=wood_u+{3'b0,y[6:4]}+(y[7] ? 6'd3:6'd0);
    wire grain=grain_phase[3:0]==0 || (grain_phase[4:0]==7 && y[3]);
    wire nail=(wood_u==6 || wood_u==57) && (wood_v==6 || wood_v==119);
    // Select one visible surface, then shade it once (not once per object).
    always @(*) begin
        background=y[5] ? 12'h642:12'h753;
        if(DETAILED_ART) begin
            background=x[6] ? 12'h964:12'hA75;
            if(grain) background=x[6] ? 12'h853:12'h964;
            if(wood_u<2 || wood_v<2) background=12'h532;
            else if(wood_u==2 || wood_v==2) background=12'hC97;
            if(nail) background=12'h555;
        end
        if(wall_on) background=wall_rgb;
        if(splash_pixel) background=splash_rgb;
        picked=0;picked_bomb=0;picked_cut=0;picked_stem=0;
        art_dx=0;art_dy=0;art_radius=18;art_kind=0;
        qx=0;qy=0;dx=0;dy=0;tx=0;ty=0;ax=0;ay=0;radius=18;extent=0;
        side=0;kind=0;spin=0;mask=0;inner_y=0;inner_extent=0;
        for(i=0;i<N;i=i+1) begin
            qx=positions_x[i*16+:16];qy=positions_y[i*16+:16];
            dx=($signed({1'b0,x})-(qx>>>4))>>>SIZE_SHIFT;
            dy=($signed({1'b0,y})-(qy>>>4))>>>SIZE_SHIFT;
            kind=fruit_types[i*4+:4];spin=spins[i*2+:2];tx=dx;ty=dy;
            if(DETAILED_ART && kind==4 && !bomb[i]) case(spin)
                1:begin dx=ty;dy=-tx;end
                2:begin dx=-tx;dy=-ty;end
                3:begin dx=-ty;dy=tx;end
            endcase
            ax=dx<0 ? -dx:dx;ay=dy<0 ? -dy:dy;
            radius=VARIABLE_RADIUS ? radii[i*5+:5]:18;
            case(radius)
                12:extent=extent12(ay[4:0]);24:extent=extent24(ay[4:0]);default:extent=extent18(ay[4:0]);
            endcase
            mask=ay<=radius && ax<=extent;
            if(DETAILED_ART && !bomb[i]) begin
                if(kind==4) begin
                    inner_y=(dy+$signed({1'b0,radius}>>2))<0 ? -(dy+$signed({1'b0,radius}>>2)):(dy+$signed({1'b0,radius}>>2));
                    inner_extent=radius==12 ? extent12(inner_y[4:0]):extent18(inner_y[4:0]);
                    mask=mask && !(inner_y<radius && inner_extent>4 && ax+4<inner_extent);
                end
                if(kind==6 && dy<0) mask=mask && $signed({1'b0,ax})<=$signed({1'b0,radius})+(dy>>>1);
            end
            if(active[i] && mask) begin
                picked=1;picked_bomb=bomb[i];picked_cut=0;picked_stem=0;
                art_dx=dx;art_dy=dy;art_radius={1'b0,radius};art_kind=kind;
            end
            if(DETAILED_ART && active[i] && dy<-$signed({1'b0,radius}) &&
              dy>=-$signed({1'b0,radius})-5 && ax<=(kind==7 && !bomb[i] ? 6:1)) begin
                picked=1;picked_bomb=bomb[i];picked_stem=1;picked_cut=0;
                art_kind=kind;
            end
        end
        for(i=0;i<2*N;i=i+1) begin
            qx=halves_x[i*16+:16];qy=halves_y[i*16+:16];
            dx=($signed({1'b0,x})-(qx>>>4))>>>SIZE_SHIFT;
            dy=($signed({1'b0,y})-(qy>>>4))>>>SIZE_SHIFT;
            case(cut_direction[(i/2)*2+:2])
                1:side=dy;2:side=$signed({dy[12],dy})-$signed({dx[12],dx});
                3:side=$signed({dy[12],dy})+$signed({dx[12],dx});default:side=dx;
            endcase
            kind=effect_types[(i/2)*4+:4];spin=effect_spins[(i/2)*2+:2];tx=dx;ty=dy;
            if(DETAILED_ART && kind==4) case(spin)
                1:begin dx=ty;dy=-tx;end
                2:begin dx=-tx;dy=-ty;end
                3:begin dx=-ty;dy=tx;end
            endcase
            ax=dx<0 ? -dx:dx;ay=dy<0 ? -dy:dy;
            radius=VARIABLE_RADIUS ? effect_radii[(i/2)*5+:5]:18;
            case(radius)
                12:extent=extent12(ay[4:0]);24:extent=extent24(ay[4:0]);default:extent=extent18(ay[4:0]);
            endcase
            mask=ay<=radius && ax<=extent;
            if(DETAILED_ART) begin
                if(kind==4) begin
                    inner_y=(dy+$signed({1'b0,radius}>>2))<0 ? -(dy+$signed({1'b0,radius}>>2)):(dy+$signed({1'b0,radius}>>2));
                    inner_extent=radius==12 ? extent12(inner_y[4:0]):extent18(inner_y[4:0]);
                    mask=mask && !(inner_y<radius && inner_extent>4 && ax+4<inner_extent);
                end
                if(kind==6 && dy<0) mask=mask && $signed({1'b0,ax})<=$signed({1'b0,radius})+(dy>>>1);
            end
            if(halves_active[i] && mask && ((i%2==0 && side<0)||(i%2==1 && side>=0))) begin
                picked=1;picked_bomb=0;picked_stem=0;picked_cut=side>=-1 && side<=1;
                art_dx=dx;art_dy=dy;art_radius={1'b0,radius};art_kind=kind;
            end
        end
    end
    always @(*) begin
        rgb=background;
        if(picked) rgb=DETAILED_ART ? (picked_stem ? (picked_bomb ? 12'hFF8:12'h5B3):surface_rgb):picked_bomb ? 12'h111:12'hF40;
        if(explosion_pixel) rgb=explosion_rgb;
        if(heart[0] && heart_levels[3:0]!=0) rgb={heart_levels[3:0],8'h22};
        if(heart[1] && heart_levels[7:4]!=0) rgb={heart_levels[7:4],8'h22};
        if(heart[2] && heart_levels[11:8]!=0) rgb={heart_levels[11:8],8'h22};
        if(!video_on) rgb=0;
    end
endmodule

