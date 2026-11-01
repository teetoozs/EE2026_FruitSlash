`timescale 1ns / 1ps
module tb_splash;
    reg [9:0] x = 0, y = 0;
    reg enabled = 1;
    reg [15:0] px = 16'd1600, py = 16'd1600;
    reg [4:0] age = 0;
    wire visible;
    wire [11:0] colour;
    splash_renderer #(.N(1)) dut (
        .x(x), .y(y), .active(enabled), .positions_x(px), .positions_y(py),
        .ages(age), .pixel_on(visible), .rgb(colour)
    );
    function integer absolute;
        input integer v;
        begin absolute = v < 0 ? -v : v; end
    endfunction
    integer a, ix, iy, dx, dy, spread, radius, core, p, ox, oy;
    integer vx [0:7];
    integer vy [0:7];
    reg expected;
    reg [11:0] expected_colour;
    initial begin
        vx[0]=1; vy[0]=0; vx[1]=-1; vy[1]=0;
        vx[2]=0; vy[2]=1; vx[3]=0; vy[3]=-1;
        vx[4]=1; vy[4]=1; vx[5]=-1; vy[5]=1;
        vx[6]=1; vy[6]=-1; vx[7]=-1; vy[7]=-1;
        // Reference explicitly places eight separate droplets at each animation age.
        for (a = 0; a <= 24; a = a + 1) begin
            age = a;
            spread = 5 + a;
            radius = a < 8 ? 3 : (a < 16 ? 2 : 1);
            core = a < 8 ? 10 : (a < 16 ? 7 : 4);
            expected_colour = a < 8 ? 12'hF90 : (a < 16 ? 12'hD60 : 12'hA40);
            for (iy = 65; iy <= 140; iy = iy + 1)
                for (ix = 65; ix <= 135; ix = ix + 1) begin
                    x = ix; y = iy;
                    dx = ix - 100; dy = iy - 100 - a/4;
                    expected = absolute(dx) + absolute(dy) <= core;
                    for (p = 0; p < 8; p = p + 1) begin
                        ox = vx[p]*spread; oy = vy[p]*spread;
                        if (absolute(dx-ox) + absolute(dy-oy) <= radius) expected = 1;
                    end
                    expected = expected && a < 24 && (a < 16 || (ix%2 == iy%2));
                    #1;
                    if (visible !== expected) $fatal(1, "Splash pixel mismatch age=%0d x=%0d y=%0d", a, ix, iy);
                    if (visible && colour !== expected_colour) $fatal(1, "Splash fade colour mismatch");
                end
        end
        age = 0; enabled = 0; x = 100; y = 100; #1;
        if (visible !== 0) $fatal(1, "Inactive splash visible");
        enabled = 1; px = -16'sd64; x = 0; #1;
        if (visible !== 1) $fatal(1, "Signed origin must clip at left edge");
        $display("PASS: splash animation pixels, fade, expiry, signed coordinates");
        $finish;
    end
endmodule
