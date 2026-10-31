// Single RGB selector: original procedural arcade art and life HUD.
// DETAILED_ART=0 retains flat diagnostic masks for geometry regression.
module pixel_compositor #(
    parameter N = 8,
    parameter VARIABLE_RADIUS = 0,
    parameter DETAILED_ART = 0
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
    input  signed [    15:0] effect_x,
    input  signed [    15:0] effect_y,
    input         [     5:0] ttl,
    output reg    [    11:0] rgb
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

    // Original flash used dx^2 + dy^2 < 900 (strict comparison).
    function [4:0] extent30;
        input [4:0] row;
        begin
            case (row)
                5'd0: extent30 = 5'd29;
                5'd1: extent30 = 5'd29;
                5'd2: extent30 = 5'd29;
                5'd3: extent30 = 5'd29;
                5'd4: extent30 = 5'd29;
                5'd5: extent30 = 5'd29;
                5'd6: extent30 = 5'd29;
                5'd7: extent30 = 5'd29;
                5'd8: extent30 = 5'd28;
                5'd9: extent30 = 5'd28;
                5'd10: extent30 = 5'd28;
                5'd11: extent30 = 5'd27;
                5'd12: extent30 = 5'd27;
                5'd13: extent30 = 5'd27;
                5'd14: extent30 = 5'd26;
                5'd15: extent30 = 5'd25;
                5'd16: extent30 = 5'd25;
                5'd17: extent30 = 5'd24;
                5'd18: extent30 = 5'd23;
                5'd19: extent30 = 5'd23;
                5'd20: extent30 = 5'd22;
                5'd21: extent30 = 5'd21;
                5'd22: extent30 = 5'd20;
                5'd23: extent30 = 5'd19;
                5'd24: extent30 = 5'd17;
                5'd25: extent30 = 5'd16;
                5'd26: extent30 = 5'd14;
                5'd27: extent30 = 5'd13;
                5'd28: extent30 = 5'd10;
                5'd29: extent30 = 5'd7;
                default: extent30 = 0;
            endcase
        end
    endfunction

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
    reg signed [16:0] effect_dx, effect_dy;
    reg [16:0] effect_abs_x, effect_abs_y;
    always @(*) begin
        rgb = y[5] ? 12'h642 : 12'h753;
        if (DETAILED_ART) begin
            rgb = y[6] ? 12'h532 : 12'h643;
            if (((x[6:0] + {3'b0, y[5:2]}) & 7'd31) == 0) rgb = 12'h432;
            if (y[5:0] < 2) rgb = 12'h321;
        end
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
            dx     = $signed({1'b0, x}) - cx;
            dy     = $signed({1'b0, y}) - cy;
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
                        if (dx >= -8 && dx <= -4 && dy >= -9 && dy <= -5) rgb = 12'hFDB;
                    end
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
        effect_dx    = $signed({1'b0, x}) - effect_x;
        effect_dy    = $signed({1'b0, y}) - effect_y;
        effect_abs_x = effect_dx < 0 ? -effect_dx : effect_dx;
        effect_abs_y = effect_dy < 0 ? -effect_dy : effect_dy;
        if (ttl != 0 && effect_abs_y < 30 && effect_abs_x <= extent30(effect_abs_y[4:0]))
            rgb = 12'hFF0;
        dx = $signed({1'b0, x}) - $signed({1'b0, cursor_x});
        dy = $signed({1'b0, y}) - $signed({1'b0, cursor_y});
        if ((dx >= -6 && dx <= 6 && dy == 0) || (dy >= -6 && dy <= 6 && dx == 0))
            rgb = slash_active ? 12'hF00 : 12'hFFF;
        for (i = 0; i < 3; i = i + 1)
        if (heart[i] && heart_levels[i*4+:4] != 0) rgb = {heart_levels[i*4+:4], 8'h22};
        if (!video_on) rgb = 0;
    end
endmodule
