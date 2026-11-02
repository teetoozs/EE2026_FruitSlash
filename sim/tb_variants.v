`timescale 1ns / 1ps
module tb_variants;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset = 1, event_valid = 0;
    reg [4:0] radius = 12;
    reg [9:0] x = 100, y = 100;
    wire hit, busy;
    slice_detector #(
        .N(1),
        .VARIABLE_RADIUS(1)
    ) detector (
        .clk         (clk),
        .reset       (reset),
        .playing     (1'b1),
        .blade_event (event_valid),
        .slash_active(1'b1),
        .x0          (x),
        .y0          (y),
        .x1          (x),
        .y1          (y),
        .active      (1'b1),
        .positions_x (16'd1600),
        .positions_y (16'd1600),
        .radii       (radius),
        .hit_mask    (hit),
        .busy        (busy)
    );
    wire [11:0] rgb;
    pixel_compositor #(
        .N(1),
        .VARIABLE_RADIUS(1)
    ) renderer (
        .x           (x),
        .y           (y),
        .wall_on(1'b0), .wall_rgb(12'b0),
        .video_on    (1'b1),
        .heart_levels(12'hFFF),
        .radii       (radius),
        .state       (2'd1),
        .cursor_x    (10'd1000),
        .cursor_y    (10'd1000),
        .slash_active(1'b0),
        .active      (1'b1),
        .bomb        (1'b0),
        .positions_x (16'd1600),
        .positions_y (16'd1600),
        .explosion_active(1'b0),
        .explosion_x(16'd0),
        .explosion_y(16'd0),
        .explosion_age(6'd0),
        .halves_active(2'd0),
        .halves_x(32'd0),
        .halves_y(32'd0),
        .effect_radii(5'd18),
        .splash_active(1'b0),
        .splash_x(16'd0),
        .splash_y(16'd0),
        .splash_age(5'd0),
        .rgb         (rgb)
    );
    integer rad, dx, dy;
    task check_hit;
        input expected;
        begin
            @(negedge clk);
            event_valid = 1;
            @(negedge clk);
            event_valid = 0;
            while (busy) @(negedge clk);
            if (hit !== expected) $fatal(1, "Radius hit mismatch r=%0d x=%0d", radius, x);
            @(negedge clk);
        end
    endtask
    initial begin
        repeat (2) @(negedge clk);
        reset = 0;
        for (rad = 12; rad <= 24; rad = rad + 6) begin
            radius = rad;
            for (dx = -25; dx <= 25; dx = dx + 1)
            for (dy = -25; dy <= 25; dy = dy + 1) begin
                x = 100 + dx;
                y = 100 + dy;
                #1;
                if ((rgb == 12'hF40) !== (dx * dx + dy * dy <= rad * rad))
                    $fatal(1, "Variable circle geometry");
            end
            x = 100 + rad;
            y = 100;
            check_hit(1);
            x = 101 + rad;
            check_hit(0);
        end
        x = 100;
        y = 0;
        #1;
        if (rgb == 12'h0F0) $fatal(1, "Debug stripe remains");
        x = 522;
        y = 20;
        #1;
        if (rgb != 12'hF22) $fatal(1, "VGA heart missing");
        $display("PASS: variable fruit sizes and HUD");
        $finish;
    end
    initial begin
        #1000000;
        $fatal(1, "Timeout");
    end
endmodule
