`timescale 1ns / 1ps
module tb_effect_variants;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset = 1, slash = 1;
    reg [2:0] active = 7, contact = 0;
    reg [14:0] radii = {5'd24,5'd18,5'd12};
    wire [2:0] destroyed;
    wire [5:0] health;
    wire [5:0] halves_active;
    wire [95:0] hx, hy;
    wire [14:0] captured_radii;
    reg [9:0] x = 0, y = 0;
    wire [11:0] flat_rgb, art_rgb;
    fruit_damage #(.N(3)) damage (
        .clk(clk), .reset(reset), .playing(1'b1), .slash_active(slash),
        .active(active), .bomb(3'd0), .contact(contact), .radii(radii),
        .destroyed(destroyed), .health(health)
    );
    cut_effects #(.N(3), .VARIABLE_RADIUS(1)) effects (
        .clk(clk), .reset(reset), .game_tick(1'b0), .playing(1'b1),
        .hit_mask(destroyed), .bomb(3'd0), .radii(radii),
        .positions_x({16'd4800,16'd3200,16'd1600}),
        .positions_y({3{16'd3200}}),
        .halves_active(halves_active), .halves_x(hx), .halves_y(hy),
        .effect_radii(captured_radii)
    );
    genvar mode;
    wire [23:0] colours;
    generate for (mode=0; mode<2; mode=mode+1) begin : renderers
        pixel_compositor #(.N(3), .VARIABLE_RADIUS(1), .DETAILED_ART(mode)) renderer (
            .x(x), .y(y), .video_on(1'b1), .heart_levels(12'd0),
            .radii(radii), .health(health), .state(2'd1),
            .cursor_x(10'd1000), .cursor_y(10'd1000), .slash_active(1'b0),
            .active(3'd0), .bomb(3'd0), .positions_x(48'd0), .positions_y(48'd0),
            .explosion_active(3'd0), .explosion_x(48'd0), .explosion_y(48'd0),
            .explosion_age(6'd0), .halves_active(halves_active), .halves_x(hx),
            .halves_y(hy), .effect_radii(captured_radii), .splash_active(3'd0),
            .splash_x(48'd0), .splash_y(48'd0), .splash_age(15'd0),
            .rgb(colours[mode*12+:12])
        );
    end endgenerate
    assign flat_rgb=colours[11:0];
    assign art_rgb=colours[23:12];
    task step;
        begin @(posedge clk); #1; @(negedge clk); end
    endtask
    task swipe;
        input [2:0] mask;
        begin
            slash=0; step; slash=1;
            contact=mask; step; contact=0; step;
        end
    endtask
    reg [4:0] palette_age = 0;
    wire juice_on;
    wire [11:0] juice_rgb;
    splash_renderer #(.N(3), .FRUIT_PALETTE(1)) juice (
        .x(x), .y(y), .active(3'b100),
        .positions_x({16'd4800,16'd3200,16'd1600}),
        .positions_y({3{16'd3200}}), .radii(captured_radii),
        .ages({3{palette_age}}), .pixel_on(juice_on), .rgb(juice_rgb)
    );
    integer i, dx, dy, radius;
    initial begin
        step; reset=0;
        swipe(7);
        if (halves_active !== 6'b001111 || health[5:4] !== 2)
            $fatal(1,"Watermelon split before final hit or small cuts missing");
        // Repeated held contact must not spawn juice/halves or reduce durability.
        contact=4; step; contact=0; step;
        if (halves_active !== 15 || health[5:4] !== 2) $fatal(1,"Held contact counted twice");
        swipe(4);
        if (halves_active !== 15 || health[5:4] !== 1) $fatal(1,"Second hit split watermelon");
        swipe(4);
        if (halves_active !== 63 || captured_radii !== radii) $fatal(1,"Final hit metadata lost");
        radii=0; // Recycled/live slot changes must not change existing pieces.
        for (i=0; i<3; i=i+1) begin
            radius=12+i*6;
            for (dy=-25; dy<=25; dy=dy+1)
                for (dx=-25; dx<=25; dx=dx+1) begin
                    x=100+i*100+dx; y=200+dy; #1;
                    if ((flat_rgb == 12'hF40) !== (dx*dx+dy*dy<=radius*radius))
                        $fatal(1,"Captured half radius mismatch slot=%0d",i);
                end
        end
        x=105; y=200; #1;
        if (art_rgb !== 12'hF40) $fatal(1,"Orange half palette");
        x=205; #1;
        if (art_rgb !== 12'hE23) $fatal(1,"Red half palette");
        x=305; #1;
        if (art_rgb !== 12'h5B3) $fatal(1,"Watermelon rind lost");
        x=300; #1;
        if (art_rgb !== 12'hF76) $fatal(1,"Watermelon cut flesh lost");
        if (!juice_on || juice_rgb !== 12'hF45) $fatal(1,"Watermelon juice palette");
        palette_age=8; #1;
        if (!juice_on || juice_rgb !== 12'h722) $fatal(1,"Watermelon juice fade");
        $display("PASS: variant effects sizes, captured metadata, palettes and three-hit watermelon");
        $finish;
    end
endmodule
