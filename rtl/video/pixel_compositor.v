// Aloysius owns the single final RGB selector. This is diagnostic art,
// not the promised final sprites, text screens or procedural wood.
module pixel_compositor #(
    parameter N = 8
) (
    input         [     9:0] x,
    input         [     9:0] y,
    input                    video_on,
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

    integer i;
    reg signed [15:0] qx, qy;
    reg signed [12:0] cx, cy, dx, dy;
    reg [12:0] abs_x, abs_y;
    reg signed [16:0] effect_dx, effect_dy;
    reg [16:0] effect_abs_x, effect_abs_y;
    always @(*) begin
        rgb   = y[5] ? 12'h642 : 12'h753;
        qx    = 0;
        qy    = 0;
        cx    = 0;
        cy    = 0;
        dx    = 0;
        dy    = 0;
        abs_x = 0;
        abs_y = 0;
        for (i = 0; i < N; i = i + 1) begin
            qx    = positions_x[i*16+:16];
            qy    = positions_y[i*16+:16];
            cx    = qx >>> 4;
            cy    = qy >>> 4;
            dx    = $signed({1'b0, x}) - cx;
            dy    = $signed({1'b0, y}) - cy;
            abs_x = dx < 0 ? -dx : dx;
            abs_y = dy < 0 ? -dy : dy;
            if (active[i] && abs_y <= 18 && abs_x <= extent18(abs_y[4:0]))
                rgb = bomb[i] ? 12'h111 : 12'hF40;
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
        if (y < 12)
            case (state)
                0: rgb = 12'h00F;
                1: rgb = 12'h0F0;
                2: rgb = 12'hFF0;
                3: rgb = 12'hF00;
            endcase
        if (!video_on) rgb = 0;
    end
endmodule
