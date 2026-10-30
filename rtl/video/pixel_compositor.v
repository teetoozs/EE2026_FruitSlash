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
    input [N-1:0] explosion_active,
    input [N*16-1:0] explosion_x,
    input [N*16-1:0] explosion_y,
    input [5:0] explosion_age,
    input         [2*N-1:0] halves_active,
    input         [2*N*16-1:0] halves_x,
    input         [2*N*16-1:0] halves_y,
    input         [N-1:0] splash_active,
    input         [N*16-1:0] splash_x,
    input         [N*16-1:0] splash_y,
    input         [N*5-1:0] splash_age,
    output reg    [    11:0] rgb
);

    wire splash_pixel;
    wire [11:0] splash_rgb;
    splash_renderer #(.N(N)) juice (
        .x(x),
        .y(y),
        .active(splash_active),
        .positions_x(splash_x),
        .positions_y(splash_y),
        .ages(splash_age),
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

    integer i;
    reg signed [15:0] qx, qy;
    reg signed [12:0] cx, cy, dx, dy;
    reg [12:0] abs_x, abs_y;
    always @(*) begin
        rgb   = y[5] ? 12'h642 : 12'h753;
        if (splash_pixel) rgb = splash_rgb;
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
        // Two complementary semicircles per fruit, drawn above intact objects.
        for (i = 0; i < 2*N; i = i + 1) begin
            qx = halves_x[i*16+:16];
            qy = halves_y[i*16+:16];
            cx = qx >>> 4;
            cy = qy >>> 4;
            dx = $signed({1'b0, x}) - cx;
            dy = $signed({1'b0, y}) - cy;
            abs_x = dx < 0 ? -dx : dx;
            abs_y = dy < 0 ? -dy : dy;
            if (halves_active[i] && abs_y <= 18 && abs_x <= extent18(abs_y[4:0]) &&
                ((i % 2 == 0 && dx < 0) || (i % 2 == 1 && dx >= 0)))
                rgb = 12'hF40;
        end
        if (|explosion_active)
            rgb = {1'b0, rgb[11:9], 1'b0, rgb[7:5], 1'b0, rgb[3:1]};
        if (explosion_pixel) rgb = explosion_rgb;
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
