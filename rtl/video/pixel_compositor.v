// Single RGB selector: original procedural arcade art and life HUD.
// DETAILED_ART=0 retains flat diagnostic masks for geometry regression.
module pixel_compositor #(
    parameter N = 8,
    parameter VARIABLE_RADIUS = 0,
    parameter DETAILED_ART = 0,
    parameter SIZE_SHIFT = 0
) (
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
    reg [4:0] radius, extent;
    reg [11:0] fruit_colour;
    reg signed [15:0] qx, qy;
    reg signed [12:0] cx, cy, dx, dy;
    reg [12:0] abs_x, abs_y;
    reg signed [13:0] cut_side;
    // Vertical timber planks: seams, staggered end joints, grain and nail heads.
    wire [5:0] wood_u=x[5:0];
    wire [6:0] wood_v=y[6:0]+(x[6] ? 7'd64:7'd0);
    wire [5:0] grain_phase=wood_u+{3'b0,y[6:4]}+(y[7] ? 6'd3:6'd0);
    wire wood_grain=(grain_phase[3:0]==0)||(grain_phase[4:0]==7 && y[3]);
    wire nail=(wood_u==6 || wood_u==57) && (wood_v==6 || wood_v==119);
    always @(*) begin
        rgb = y[5] ? 12'h642 : 12'h753;
        if (DETAILED_ART) begin
            rgb=x[6] ? 12'h743:12'h853;
            if(wood_grain) rgb=x[6] ? 12'h632:12'h742;
            if(wood_u<2 || wood_v<2) rgb=12'h210;
            else if(wood_u==2 || wood_v==2) rgb=12'hA75;
            if(nail) rgb=12'h221;
            // Darken the outside of the arena to frame the action.
            if(x<32 || x>=608 || y<16 || y>=464)
                rgb={1'b0,rgb[11:9],1'b0,rgb[7:5],1'b0,rgb[3:1]};
        end
        if (wall_on) rgb = wall_rgb;
        if (splash_pixel) rgb = splash_rgb;
        cut_side=0;
        qx           = 0;
        qy           = 0;
        cx           = 0;
        cy           = 0;
        dx           = 0;
        dy           = 0;
        abs_x        = 0;
        abs_y        = 0;
        radius       = 18;
        extent       = 0;
        fruit_colour = 12'hF40;
        for (i = 0; i < N; i = i + 1) begin
            qx     = positions_x[i*16+:16];
            qy     = positions_y[i*16+:16];
            cx     = qx >>> 4;
            cy     = qy >>> 4;
            dx     = ($signed({1'b0, x}) - cx) >>> SIZE_SHIFT;
            dy     = ($signed({1'b0, y}) - cy) >>> SIZE_SHIFT;
            abs_x  = dx < 0 ? -dx : dx;
            abs_y  = dy < 0 ? -dy : dy;
            radius = VARIABLE_RADIUS ? radii[i*5+:5] : 5'd18;
            case (radius)
                12: extent = extent12(abs_y[4:0]);
                24: extent = extent24(abs_y[4:0]);
                default: extent = extent18(abs_y[4:0]);
            endcase
            case (i % 4)
                0: fruit_colour = 12'hF40;
                1: fruit_colour = 12'hE23;
                2: fruit_colour = 12'h5D3;
                3: fruit_colour = 12'hB4E;
            endcase
            if (active[i] && abs_y <= radius && abs_x <= extent) begin
                rgb = bomb[i] ? 12'h111 : fruit_colour;
                if (DETAILED_ART) begin
                    // Outlined, shaded original arcade fruit graphics.
                    if (bomb[i]) begin
                        rgb = 12'h222;
                        if (dx < -3 && dy < -3) rgb = 12'h555;
                    end else begin
                        if (radius == 24) begin  // Watermelon with dark rind stripes.
                            rgb = dx[3] ? 12'h294 : 12'h5B3;
                            if (health[i*2+:2] < 3 && abs_x < 2) rgb = 12'hF76;
                            if (health[i*2+:2] < 2 && abs_y < 2) rgb = 12'hF76;
                        end else if (dy > 4)
                            rgb = {
                                1'b0,
                                fruit_colour[11:9],
                                1'b0,
                                fruit_colour[7:5],
                                1'b0,
                                fruit_colour[3:1]
                            };
                        // Rounded highlight, plus peel speckles; no extra multipliers.
                        if(i%4==0 && dx[2:0]==2 && dy[2:0]==3) rgb=12'hD60;
                        if(i%4==1 && dx[2:0]==3 && dy[2:0]==2) rgb=12'hFC7;
                        if(dx>=-9 && dx<=-3 && dy>=-10 && dy<=-4 &&
                           (dx+dy>=-17) && (dx+dy<=-9)) rgb=12'hFDB;
                    end
                    // Faceted spherical lighting: dark rim and lower-right hemisphere.
                    if ((dx+dy)>$signed({1'b0,radius})/2 || abs_x+2>=extent)
                        rgb={1'b0,rgb[11:9],1'b0,rgb[7:5],1'b0,rgb[3:1]};
                    if (abs_x == extent || abs_y == radius) rgb = 12'h321;
                end
            end
            if (DETAILED_ART && active[i]) begin
                // Leaf/stem or a lit bomb fuse above the circular body.
                if (dx >= -1 && dx <= 1 && dy >= -$signed(
                        {1'b0, radius}
                    ) - 5 && dy < -$signed(
                        {1'b0, radius}
                    ))
                    rgb = bomb[i] ? 12'hFA2 : 12'h653;
                if (!bomb[i] && dx >= 2 && dx <= 7 && dy >= -$signed(
                        {1'b0, radius}
                    ) - 4 && dy <= -$signed(
                        {1'b0, radius}
                    ))
                    rgb = 12'h5B3;
                // Three visible durability pips above the large fruit.
                if (!bomb[i] && radius == 24 && dy >= -33 && dy <= -30) begin
                    if (dx >= -10 && dx <= -6) rgb = health[i*2+:2] >= 1 ? 12'hFE8 : 12'h432;
                    if (dx >= -2 && dx <= 2) rgb = health[i*2+:2] >= 2 ? 12'hFE8 : 12'h432;
                    if (dx >= 6 && dx <= 10) rgb = health[i*2+:2] >= 3 ? 12'hFE8 : 12'h432;
                end
            end
        end
        // Two complementary semicircles per fruit, drawn above intact objects.
        for (i = 0; i < 2*N; i = i + 1) begin
            qx = halves_x[i*16+:16];
            qy = halves_y[i*16+:16];
            cx = qx >>> 4;
            cy = qy >>> 4;
            dx = ($signed({1'b0, x}) - cx) >>> SIZE_SHIFT;
            dy = ($signed({1'b0, y}) - cy) >>> SIZE_SHIFT;
            abs_x = dx < 0 ? -dx : dx;
            abs_y = dy < 0 ? -dy : dy;
            radius = VARIABLE_RADIUS ? effect_radii[(i/2)*5+:5] : 5'd18;
            case (radius)
                12: extent = extent12(abs_y[4:0]);
                24: extent = extent24(abs_y[4:0]);
                default: extent = extent18(abs_y[4:0]);
            endcase
            case ((i/2) % 4)
                0: fruit_colour = 12'hF40;
                1: fruit_colour = 12'hE23;
                2: fruit_colour = 12'h5D3;
                3: fruit_colour = 12'hB4E;
            endcase
            case(cut_direction[(i/2)*2+:2])
              1:cut_side=dy;
              2:cut_side=$signed({dy[12],dy})-$signed({dx[12],dx});
              3:cut_side=$signed({dy[12],dy})+$signed({dx[12],dx});
              default:cut_side=dx;
            endcase
            if (halves_active[i] && abs_y <= radius && abs_x <= extent &&
                ((i % 2 == 0 && cut_side < 0) || (i % 2 == 1 && cut_side >= 0))) begin
                rgb = DETAILED_ART ? fruit_colour : 12'hF40;
                if (DETAILED_ART) begin
                    if (radius == 24) rgb = dx[3] ? 12'h294 : 12'h5B3;
                    else if (dy > 4)
                        rgb = {1'b0, fruit_colour[11:9], 1'b0, fruit_colour[7:5],
                               1'b0, fruit_colour[3:1]};
                    // Rounded highlight, plus peel speckles; no extra multipliers.
                        if(i%4==0 && dx[2:0]==2 && dy[2:0]==3) rgb=12'hD60;
                        if(i%4==1 && dx[2:0]==3 && dy[2:0]==2) rgb=12'hFC7;
                        if(dx>=-9 && dx<=-3 && dy>=-10 && dy<=-4 &&
                           (dx+dy>=-17) && (dx+dy<=-9)) rgb=12'hFDB;
                    // Faceted spherical lighting: dark rim and lower-right hemisphere.
                    if ((dx+dy)>$signed({1'b0,radius})/2 || abs_x+2>=extent)
                        rgb={1'b0,rgb[11:9],1'b0,rgb[7:5],1'b0,rgb[3:1]};
                    if (abs_x == extent || abs_y == radius) rgb = 12'h321;
                    // Exposed cut edge: red flesh for watermelon, pale flesh otherwise.
                    if (cut_side >= -1 && cut_side <= 1) rgb = radius == 24 ? 12'hF76 : 12'hFDB;
                end
            end
        end
        if (|explosion_active)
            rgb = {1'b0, rgb[11:9], 1'b0, rgb[7:5], 1'b0, rgb[3:1]};
        if (explosion_pixel) rgb = explosion_rgb;
        dx = $signed({1'b0, x}) - $signed({1'b0, cursor_x});
        dy = $signed({1'b0, y}) - $signed({1'b0, cursor_y});
        // Cursor is composited above menus by cursor_settings.
        for (i = 0; i < 3; i = i + 1)
        if (heart[i] && heart_levels[i*4+:4] != 0) rgb = {heart_levels[i*4+:4], 8'h22};
        if (!video_on) rgb = 0;
    end
endmodule
