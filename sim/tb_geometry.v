`timescale 1ns / 1ps
module tb_geometry;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset = 1, event_valid = 0, slash = 1, playing = 1;
    reg [9:0] x0 = 0, y0 = 0, x1 = 0, y1 = 0;
    reg [1:0] active = 3;
    reg [31:0] px = 0, py = 0;
    wire [1:0] hits;
    wire busy;
    slice_detector #(
        .N(2)
    ) dut (
        .clk         (clk),
        .reset       (reset),
        .playing     (playing),
        .blade_event (event_valid),
        .slash_active(slash),
        .x0          (x0),
        .y0          (y0),
        .x1          (x1),
        .y1          (y1),
        .active      (active),
        .positions_x (px),
        .positions_y (py),
        .hit_mask    (hits),
        .busy        (busy)
    );

    wire [7:0] hits8;
    wire busy8;
    slice_detector #(
        .N(8)
    ) full_size (
        .clk         (clk),
        .reset       (reset),
        .playing     (playing),
        .blade_event (event_valid),
        .slash_active(slash),
        .x0          (x0),
        .y0          (y0),
        .x1          (x1),
        .y1          (y1),
        .active      ({4{active}}),
        .positions_x ({4{px}}),
        .positions_y ({4{py}}),
        .hit_mask    (hits8),
        .busy        (busy8)
    );

    function reference_hit;
        input integer cx, cy;
        reg signed [63:0] u, v, w, z, dot, len2, cross_value, distance;
        begin
            u           = $signed({1'b0, x1}) - $signed({1'b0, x0});
            v           = $signed({1'b0, y1}) - $signed({1'b0, y0});
            w           = cx - $signed({1'b0, x0});
            z           = cy - $signed({1'b0, y0});
            dot         = w * u + z * v;
            len2        = u * u + v * v;
            cross_value = w * v - z * u;
            if (len2 == 0 || dot <= 0) reference_hit = w * w + z * z <= 324;
            else if (dot >= len2) begin
                w             = cx - $signed({1'b0, x1});
                z             = cy - $signed({1'b0, y1});
                reference_hit = w * w + z * z <= 324;
            end else reference_hit = cross_value * cross_value <= 324 * len2;
        end
    endfunction

    reg [1:0] expected;
    integer t, cx0, cy0, cx1, cy1, cycles;
    task transact;
        begin
            expected[0] = active[0] && slash && reference_hit(cx0, cy0);
            expected[1] = active[1] && slash && reference_hit(cx1, cy1);
            @(negedge clk);
            event_valid = 1;
            @(negedge clk);
            event_valid = 0;
            cycles      = 0;
            while (busy && cycles < 20) begin
                @(negedge clk);
                cycles = cycles + 1;
            end
            if (cycles >= 20 || hits !== expected)
                $fatal(1, "Geometry mismatch trial %0d expected %b got %b", t, expected, hits);
            @(negedge clk);
            if (hits !== 0) $fatal(1, "Repeated hit pulse");
            while (busy8 && cycles < 40) begin
                @(negedge clk);
                cycles = cycles + 1;
            end
            if (cycles >= 40 || hits8 !== {4{expected}}) $fatal(1, "Eight-slot hit mask mismatch");
            @(negedge clk);
            if (hits8 !== 0) $fatal(1, "Repeated eight-slot hit pulse");
        end
    endtask
    task pack_positions;
        begin
            px[15:0]  = cx0 * 16;
            py[15:0]  = cy0 * 16;
            px[31:16] = cx1 * 16;
            py[31:16] = cy1 * 16;
        end
    endtask

    // Render verification: exact original integer circle and flash masks.
    reg [9:0] rx = 0, ry = 0;
    reg [15:0] rpx = 16'd1600, rpy = 16'd1600;
    reg  [ 5:0] ttl = 0;
    wire [11:0] rgb;
    pixel_compositor #(
        .N(1)
    ) renderer (
        .x           (rx),
        .y           (ry),
        .video_on    (1'b1),
        .state       (2'd1),
        .cursor_x    (10'd1000),
        .cursor_y    (10'd1000),
        .slash_active(1'b0),
        .active      (1'b1),
        .bomb        (1'b0),
        .positions_x (rpx),
        .positions_y (rpy),
        .effect_x    (16'sd300),
        .effect_y    (16'sd200),
        .ttl         (ttl),
        .rgb         (rgb)
    );
    integer dx, dy;
    initial begin
        repeat (2) @(negedge clk);
        reset = 0;
        // Exact tangent, near miss, zero length and long diagonal.
        x0    = 0;
        y0    = 100;
        x1    = 1023;
        y1    = 100;
        cx0   = 500;
        cy0   = 118;
        cx1   = 500;
        cy1   = 119;
        pack_positions;
        transact;
        x0  = 100;
        y0  = 100;
        x1  = 100;
        y1  = 100;
        cx0 = 100;
        cy0 = 100;
        cx1 = 119;
        cy1 = 100;
        pack_positions;
        transact;
        x0  = 1023;
        y0  = 1023;
        x1  = 0;
        y1  = 0;
        cx0 = 500;
        cy0 = 500;
        cx1 = -2048;
        cy1 = 2047;
        pack_positions;
        transact;
        for (t = 0; t < 200; t = t + 1) begin
            x0     = $urandom_range(0, 1023);
            y0     = $urandom_range(0, 1023);
            x1     = $urandom_range(0, 1023);
            y1     = $urandom_range(0, 1023);
            cx0    = $urandom_range(0, 4095) - 2048;
            cy0    = $urandom_range(0, 4095) - 2048;
            cx1    = $urandom_range(0, 4095) - 2048;
            cy1    = $urandom_range(0, 4095) - 2048;
            active = $urandom_range(0, 3);
            slash  = $urandom_range(0, 1);
            pack_positions;
            transact;
        end
        // Reset aborts an in-flight transaction.
        @(negedge clk);
        slash       = 1;
        event_valid = 1;
        @(negedge clk);
        event_valid = 0;
        reset       = 1;
        @(negedge clk);
        if (busy || hits != 0) $fatal(1, "Reset did not abort scan");
        reset = 0;
        for (dx = -20; dx <= 20; dx = dx + 1)
        for (dy = -20; dy <= 20; dy = dy + 1) begin
            rx = 100 + dx;
            ry = 100 + dy;
            #1;
            if ((rgb == 12'hF40) !== (dx * dx + dy * dy <= 324))
                $fatal(1, "Fruit circle mismatch dx=%0d dy=%0d", dx, dy);
        end
        ttl = 12;
        for (dx = -31; dx <= 31; dx = dx + 1)
        for (dy = -31; dy <= 31; dy = dy + 1) begin
            rx = 300 + dx;
            ry = 200 + dy;
            #1;
            if ((rgb == 12'hFF0) !== (dx * dx + dy * dy < 900)) $fatal(1, "Flash mask mismatch");
        end
        $display("PASS: geometry regression, reset abort, exact circle masks");
        $finish;
    end
    initial begin
        #1000000;
        $fatal(1, "Timeout");
    end
endmodule
