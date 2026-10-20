// Shen: division-free swept segment vs radius-18 circular hitbox.
// 64-bit intermediates avoid overflow in cross^2 comparisons.
module slice_detector #(
    parameter N = 8
) (
    input                 playing,
    input                 blade_event,
    input                 slash_active,
    input      [     9:0] x0,
    input      [     9:0] y0,
    input      [     9:0] x1,
    input      [     9:0] y1,
    input      [   N-1:0] active,
    input      [N*16-1:0] positions_x,
    input      [N*16-1:0] positions_y,
    output reg [   N-1:0] hit_mask
);
    integer i;
    reg signed [15:0] qx, qy;
    reg signed [63:0] ax, ay, bx, by, cx, cy, ux, uy, wx, wy;
    reg signed [63:0] dot, len2, cross_value, dist2;
    always @(*) begin
        hit_mask    = 0;
        ax          = x0;
        ay          = y0;
        bx          = x1;
        by          = y1;
        ux          = bx - ax;
        uy          = by - ay;
        len2        = ux * ux + uy * uy;
        qx          = 0;
        qy          = 0;
        cx          = 0;
        cy          = 0;
        wx          = 0;
        wy          = 0;
        dot         = 0;
        cross_value = 0;
        dist2       = 0;
        for (i = 0; i < N; i = i + 1) begin
            qx          = positions_x[i*16+:16];
            qy          = positions_y[i*16+:16];
            cx          = qx >>> 4;
            cy          = qy >>> 4;
            wx          = cx - ax;
            wy          = cy - ay;
            dot         = wx * ux + wy * uy;
            cross_value = wx * uy - wy * ux;
            if (len2 == 0 || dot <= 0) dist2 = wx * wx + wy * wy;
            else if (dot >= len2) dist2 = (cx - bx) * (cx - bx) + (cy - by) * (cy - by);
            else dist2 = 0;
            if (playing && blade_event && slash_active && active[i]) begin
                if (len2 == 0 || dot <= 0 || dot >= len2) hit_mask[i] = dist2 <= 324;
                else hit_mask[i] = (cross_value * cross_value <= 324 * len2);
            end
        end
    end
    // TODO: fruit-specific hitboxes; validate resource use before enlarging N.
endmodule
