`timescale 1ns / 1ps
module tb_spawns_damage;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset = 1, slash = 1, contact = 0, active = 1, bomb = 0;
    wire destroyed;
    wire [1:0] health;
    fruit_damage #(
        .N(1)
    ) damage (
        .clk         (clk),
        .reset       (reset),
        .playing     (1'b1),
        .slash_active(slash),
        .active      (active),
        .bomb        (bomb),
        .contact     (contact),
        .radii       (5'd24),
        .destroyed   (destroyed),
        .health      (health)
    );
    task hit;
        begin
            @(negedge clk);
            contact = 1;
            @(negedge clk);
            contact = 0;
        end
    endtask
    task release_button;
        begin
            @(negedge clk);
            slash = 0;
            @(negedge clk);
            slash = 1;
        end
    endtask
    reg physics_reset = 1, tick = 0;
    wire pa, pb;
    wire [15:0] px, py;
    object_physics #(
        .N(1)
    ) physics (
        .clk        (clk),
        .reset      (physics_reset),
        .game_tick  (tick),
        .playing    (1'b1),
        .difficulty (2'd0),
        .remove_mask(1'b0),
        .active     (pa),
        .bomb       (pb),
        .positions_x(px),
        .positions_y(py)
    );
    integer origin;
    initial begin
        repeat (2) @(negedge clk);
        reset = 0;
        hit;
        if (health != 2 || destroyed) $fatal(1, "First hit");
        hit;
        if (health != 2 || destroyed) $fatal(1, "Repeated held swipe counted");
        release_button;
        hit;
        if (health != 1 || destroyed) $fatal(1, "Second hit");
        release_button;
        hit;
        if (!destroyed) $fatal(1, "Third hit must destroy");
        @(negedge clk);
        active = 0;
        @(negedge clk);
        active = 1;
        bomb   = 1;
        hit;
        if (!destroyed) $fatal(1, "Recycled bomb must be one hit");
        for (origin = 0; origin < 4; origin = origin + 1) begin
            @(negedge clk);
            physics_reset = 1;
            @(negedge clk);
            physics_reset        = 0;
            physics.random_state = (origin << 10) | 16'h0055;
            physics.spawn_count  = 65;
            tick                 = 1;
            @(negedge clk);
            tick = 0;
            if (!pa) $fatal(1, "Spawn missing");
            case (origin)
                0: if ($signed(py) != 500 * 16 || physics.vy[0] >= 0) $fatal(1, "Bottom spawn");
                1:
                if ($signed(py) != -24 * 16 || physics.vx[0] != 0 || physics.vy[0] <= 0)
                    $fatal(1, "Top spawn");
                2: if ($signed(px) != -24 * 16 || physics.vx[0] <= 0) $fatal(1, "Left spawn");
                3: if ($signed(px) != 664 * 16 || physics.vx[0] >= 0) $fatal(1, "Right spawn");
            endcase
            repeat (12) begin
                @(negedge clk);
                tick = 1;
                @(negedge clk);
                tick = 0;
            end
            if (!pa) $fatal(1, "Object removed before entering screen");
        end
        $display("PASS: directional spawns and multi-hit fruit");
        $finish;
    end
endmodule
