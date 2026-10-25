`timescale 1ns / 1ps
module tb_effects;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset = 1, playing = 1, tick = 0;
    reg [7:0] hit = 0, bomb = 0;
    reg [127:0] px = 0, py = 0;
    wire [15:0] active;
    wire [255:0] hx, hy;
    wire signed [15:0] fx, fy;
    wire [5:0] ttl;
    wire [7:0] splash_active;
    wire [127:0] splash_x, splash_y;
    wire [39:0] splash_age;
    reg [9:0] x = 0, y = 0;
    reg video_on = 1;
    wire [11:0] rgb;
    cut_effects dut (
        .clk(clk), .reset(reset), .game_tick(tick), .playing(playing),
        .hit_mask(hit), .bomb(bomb), .positions_x(px), .positions_y(py),
        .effect_x(fx), .effect_y(fy), .ttl(ttl),
        .splash_active(splash_active), .splash_x(splash_x),
        .splash_y(splash_y), .splash_age(splash_age),
        .halves_active(active), .halves_x(hx), .halves_y(hy)
    );
    pixel_compositor renderer (
        .x(x), .y(y), .video_on(video_on), .state(2'd1),
        .cursor_x(10'd1000), .cursor_y(10'd1000), .slash_active(1'b0),
        .active(8'd0), .bomb(8'd0), .positions_x(128'd0), .positions_y(128'd0),
        .effect_x(fx), .effect_y(fy), .ttl(ttl),
        .splash_active(splash_active), .splash_x(splash_x),
        .splash_y(splash_y), .splash_age(splash_age),
        .halves_active(active), .halves_x(hx), .halves_y(hy), .rgb(rgb)
    );
    task step;
        begin @(posedge clk); #1; @(negedge clk); end
    endtask
    task frame;
        begin tick = 1; step; tick = 0; end
    endtask
    integer i, dx, dy, left_x, right_x, left_y, right_y;
    reg expected;
    reg [255:0] saved_x, saved_y;
    initial begin
        step; reset = 0;
        // All eight simultaneous fruits, including a tick on the capture cycle.
        for (i = 0; i < 8; i = i + 1) begin
            px[i*16+:16] = (100 + i*60)*16;
            py[i*16+:16] = 200*16;
        end
        hit = 255; tick = 1; step; hit = 0; tick = 0;
        if (splash_active !== 255 || splash_age !== 0 || splash_x !== px || splash_y !== py)
            $fatal(1, "All cuts must capture splash state");
        if (active !== 16'hffff || ttl !== 0) $fatal(1, "All fruit cuts must create halves, not flashes");
        if (hx[15:0] !== 16'd1600 || hy[15:0] !== 16'd3200)
            $fatal(1, "Capture lost to simultaneous tick");
        repeat (4) frame;
        if ($signed(hx[15:0]) >= 1600 || $signed(hx[31:16]) <= 1600 ||
            $signed(hy[15:0]) <= 3200 || $signed(hy[31:16]) <= 3200)
            $fatal(1, "Pieces must separate and fall");
        // Compare visible pixels against two mathematical semicircles.
        left_x = $signed(hx[15:0]) >>> 4;
        right_x = $signed(hx[31:16]) >>> 4;
        left_y = $signed(hy[15:0]) >>> 4;
        right_y = $signed(hy[31:16]) >>> 4;
        for (dy = 175; dy <= 230; dy = dy + 1)
            for (dx = 65; dx <= 132; dx = dx + 1) begin
                x = dx; y = dy; #1;
                expected = (dx < left_x && (dx-left_x)*(dx-left_x)+(dy-left_y)*(dy-left_y)<=324) ||
                           (dx >= right_x && (dx-right_x)*(dx-right_x)+(dy-right_y)*(dy-right_y)<=324);
                if ((rgb == 12'hF40) !== expected) $fatal(1, "Half pixel mismatch at %0d,%0d", dx, dy);
            end
        @(negedge clk);
        if (splash_age[4:0] !== 4) $fatal(1, "Splash age must follow game ticks");
        saved_x = hx; saved_y = hy; playing = 0;
        repeat (5) frame;
        if (hx !== saved_x || hy !== saved_y) $fatal(1, "Pause must freeze halves");
        if (splash_age[4:0] !== 4) $fatal(1, "Pause must freeze splash");
        reset = 1; step; reset = 0; playing = 1;
        if (splash_active !== 0 || active !== 0 || ttl !== 0) $fatal(1, "Restart must clear effects");
        // Mixed fruit/bomb hit: bomb retains flash, never produces fruit pieces.
        hit = 3; bomb = 2; step; hit = 0;
        if (splash_active !== 1) $fatal(1, "Bomb must not create juice");
        if (active !== 16'h0003 || ttl !== 12) $fatal(1, "Bomb filtering failed");
        // Reuse a slot: replace old pair at the new position.
        px[15:0] = 16'd4800; hit = 1; step; hit = 0;
        if (hx[15:0] !== 16'd4800 || hx[31:16] !== 16'd4800)
            $fatal(1, "Slot reuse failed");
        if (splash_x[15:0] !== 4800 || splash_age[4:0] !== 0)
            $fatal(1, "Slot reuse must restart splash at new cut position");
        repeat (23) frame;
        if (splash_active !== 1 || splash_age[4:0] !== 23)
            $fatal(1, "Splash must last 24 ticks");
        frame;
        if (splash_active !== 0) $fatal(1, "Splash must expire after 24 ticks");
        repeat (76) frame;
        if (splash_active !== 0 || active !== 0 || ttl !== 0) $fatal(1, "Effects must expire");
        // Negative x stays signed; visible right semicircle is clipped at screen edge.
        px[15:0] = -16'sd64; py[15:0] = 16'd1600;
        hit = 1; step; hit = 0;
        x = 0; y = 100; #1;
        if (rgb !== 12'hF40) $fatal(1, "Signed edge rendering failed");
        video_on = 0; #1;
        if (rgb !== 0) $fatal(1, "Blanking failed");
        $display("PASS: fruit halves, simultaneous hits, motion, pixels, pause, restart, bombs, reuse, expiry");
        $finish;
    end
    initial begin #1000000; $fatal(1, "Timeout"); end
endmodule

