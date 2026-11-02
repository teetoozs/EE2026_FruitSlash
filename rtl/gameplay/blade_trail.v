// Sherwin: dojo-style blade trail. Samples the cursor every TICK clocks while the slash
// is held; the last 16 samples are drawn as a thick streak that tapers to a point
// (hot gold tip, orange body, deep-red ember tail). When the slash is released the
// trail drains away over 16 ticks (about 0.16 s).
// Top layer: when on is high, show rgb instead of whatever is underneath.
module blade_trail #(
    parameter TICK = 1000000, // 100 MHz / 1000000 = 100 samples per second (16 samples = 160 ms)
    parameter MID = 0         // 1 = also draw midpoints (smoother, about twice the logic)
) (
    input             clk,
    input      [ 9:0] x,
    input      [ 9:0] y,
    input      [ 9:0] cursor_x,
    input      [ 9:0] cursor_y,
    input             slash_active,
    output reg        on  = 0,
    output reg [11:0] rgb = 0
);
    reg [19:0] cnt = 0;
    reg [15:0] valid = 0;
    reg [9:0] hx[0:15];
    reg [9:0] hy[0:15];
    integer i;
    initial for (i = 0; i < 16; i = i + 1) begin hx[i] = 0; hy[i] = 0; end
    always @(posedge clk) begin
        if (cnt >= TICK - 1) begin
            cnt <= 0;
            for (i = 15; i > 0; i = i - 1) begin
                hx[i] <= hx[i-1];
                hy[i] <= hy[i-1];
            end
            hx[0] <= cursor_x;
            hy[0] <= cursor_y;
            valid <= {valid[14:0], slash_active};
        end else cnt <= cnt + 1'b1;
    end
    // Per pixel: a diamond around each sample AND around the midpoint of each pair of
    // neighbouring samples when MID=1 (so very fast swipes stay continuous). Radius 10 (newest) tapering to 4.
    reg        hit;
    reg [11:0] col;
    reg [ 9:0] dx, dy, mx, my;
    reg [ 3:0] rad;
    always @(*) begin
        hit = 1'b0;
        col = 12'h000;
        for (i = 15; i >= 0; i = i - 1) begin
            rad = 4'd10 - ((i * 6) / 15);
            // sample i
            dx = (x > hx[i]) ? x - hx[i] : hx[i] - x;
            dy = (y > hy[i]) ? y - hy[i] : hy[i] - y;
            if (valid[i] && (dx + dy <= rad)) begin
                hit = 1'b1;
                col = (i < 2) ? 12'hFFE : (i < 5) ? 12'hFD4 : (i < 8) ? 12'hFA0 : (i < 11) ? 12'hF60 : (i < 14) ? 12'hD30 : 12'h912;
            end
            // midpoint between sample i and i+1 (older neighbour)
            if (MID && i < 15) begin
                mx = (hx[i] + hx[i+1]) >> 1;
                my = (hy[i] + hy[i+1]) >> 1;
                dx = (x > mx) ? x - mx : mx - x;
                dy = (y > my) ? y - my : my - y;
                if (valid[i] && valid[i+1] && (dx + dy <= rad)) begin
                    hit = 1'b1;
                    col = (i < 2) ? 12'hFFE : (i < 5) ? 12'hFD4 : (i < 8) ? 12'hFA0 : (i < 11) ? 12'hF60 : (i < 14) ? 12'hD30 : 12'h912;
                end
            end
        end
    end
    always @(posedge clk) begin
        on  <= hit && (x < 640) && (y < 480);  // keep blanking black
        rgb <= col;
    end
endmodule
 