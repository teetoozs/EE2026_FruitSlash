`timescale 1ns / 1ps
module tb_bombs;
    reg clk = 0;
    always #5 clk = ~clk;
    reg frame_tick = 0;
    reg [7:0] injected_hits = 0;
    reg [4:0] presses = 0;
    reg [15:0] switches = 0;
    wire ps2clk, ps2data;
    fruit_slash_top dut (
        .clk(clk),
        .sw(16'd0),
        .btnC(1'b0),
        .btnU(1'b0),
        .btnD(1'b0),
        .btnL(1'b0),
        .btnR(1'b0),
        .PS2Clk(ps2clk),
        .PS2Data(ps2data)
    );
    task step;
        begin @(posedge clk); #1; @(negedge clk); end
    endtask
    task frame;
        begin
            frame_tick = 1;
            step;
            frame_tick = 0;
        end
    endtask
    task seed_objects;
        begin
            dut.objects.active = 8'b111;
            dut.objects.bomb = 8'b010;
            dut.objects.px[0] = 1600;
            dut.objects.py[0] = 3200;
            dut.objects.px[1] = 3200;
            dut.objects.py[1] = 3200;
            dut.objects.px[2] = 4800;
            dut.objects.py[2] = 3200;
            dut.objects.vx[2] = 32;
            dut.objects.vy[2] = 16;
        end
    endtask
    reg [255:0] saved_halves;
    reg [39:0] saved_splash;
    integer i;
    initial begin
        force dut.game_tick = frame_tick;
        force dut.raw_hit_mask = injected_hits;
        force dut.pressed = presses;
        force dut.sw_sync = switches;
        repeat (260) step;
        presses = 1;
        step;
        presses = 0;
        step;
        seed_objects;
        // Coincident game tick and mixed fruit/bomb cut must remove both, with no movement.
        injected_hits = 3;
        frame;
        injected_hits = 0;
        if (!dut.bomb_busy || dut.explosion_active !== 2 || dut.explosion_age !== 0)
            $fatal(1, "Bomb capture failed");
        if (dut.active !== 4 || dut.lives !== 2 || dut.score !== 10)
            $fatal(1, "Initial removal, score or life event lost");
        if (dut.explosion_x[31:16] !== 3200 || dut.objects.px[2] !== 4800)
            $fatal(1, "Hit tick moved world or captured wrong origin");
        saved_halves = dut.halves_x;
        saved_splash = dut.splash_age;
        // New hit attempts are blocked throughout the cinematic.
        injected_hits = 4;
        repeat (11) frame;
        if (dut.explosion_age !== 11 || dut.objects.px[2] !== 4800 || dut.score !== 10)
            $fatal(1, "Freeze phase or collision gating failed");
        if (dut.halves_x !== saved_halves || dut.splash_age !== saved_splash)
            $fatal(1, "Fruit effects must freeze too");
        // Manual pause stops the explosion clock, without applying additional damage.
        switches[2] = 1;
        repeat (6) frame;
        if (dut.explosion_age !== 11 || dut.lives !== 2) $fatal(1, "Pause failed");
        switches[2] = 0;
        step;
        frame;
        if (dut.explosion_age !== 12) $fatal(1, "Blast must begin after 12 ticks");
        repeat (35) frame;
        if (!dut.bomb_busy || dut.explosion_age !== 47) $fatal(1, "Blast ended early");
        injected_hits = 0;
        frame;
        if (dut.bomb_busy) $fatal(1, "Explosion must finish at 48 ticks");
        frame;
        if (dut.objects.px[2] !== 4832) $fatal(1, "World must resume after explosion");
        // Two simultaneous bombs consume the last two lives; both effects must finish.
        seed_objects;
        dut.objects.bomb = 3;
        injected_hits = 3;
        step;
        injected_hits = 0;
        if (dut.lives !== 0 || dut.state !== 3 || dut.explosion_active !== 3)
            $fatal(1, "Fatal simultaneous bombs failed");
        presses = 1;
        step;
        presses = 0;
        if (dut.state !== 3 || !dut.bomb_busy) $fatal(1, "Restart must wait for cinematic");
        repeat (48) frame;
        if (dut.bomb_busy || dut.state !== 3 || dut.lives !== 0)
            $fatal(1, "Fatal explosion stuck or repeated damage");
        presses = 1;
        step;
        presses = 0;
        step;
        if (dut.state !== 1 || dut.lives !== 3 || dut.explosion_active !== 0)
            $fatal(1, "Restart failed");
        seed_objects;
        injected_hits = 2;
        step;
        injected_hits = 0;
        switches[15] = 1;
        step;
        if (dut.bomb_busy || dut.explosion_active !== 0 || dut.state !== 0)
            $fatal(1, "Reset must cancel explosion");
        $display("PASS: bomb integration freeze, pause, resume, simultaneous hits, fatal hit, restart");
        $finish;
    end
    initial begin #1000000; $fatal(1, "Timeout"); end
endmodule
