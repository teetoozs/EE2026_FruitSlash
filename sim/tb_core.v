`timescale 1ns / 1ps
module tb_core;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset = 1, start = 0, pause = 0, slash = 0;
    reg [1:0] hits = 0, bombs = 0;
    wire [1:0] state, lives;
    wire [15:0] score, best;
    wire [7:0] combo;
    wire playing, new_round;
    game_controller #(
        .N(2)
    ) game (
        .clk          (clk),
        .reset        (reset),
        .start_pressed(start),
        .pause        (pause),
        .slash_active (slash),
        .hit_mask     (hits),
        .bomb         (bombs),
        .state        (state),
        .playing      (playing),
        .new_round    (new_round),
        .score        (score),
        .best_score   (best),
        .lives        (lives),
        .combo        (combo)
    );
    reg [9:0] x0 = 0, y0 = 100, x1 = 200, y1 = 100;
    reg event_valid = 0, active_slice = 1;
    wire detector_busy;
    reg [1:0] active = 2'b11;
    reg [31:0] px = {16'd1600, 16'd1600};
    reg [31:0] py = {16'd3200, 16'd1600};
    wire [1:0] detected;
    slice_detector #(
        .N(2)
    ) detector (
        .clk         (clk),
        .reset       (reset),
        .busy        (detector_busy),
        .playing     (1'b1),
        .blade_event (event_valid),
        .slash_active(active_slice),
        .x0          (x0),
        .y0          (y0),
        .x1          (x1),
        .y1          (y1),
        .active      (active),
        .positions_x (px),
        .positions_y (py),
        .hit_mask    (detected)
    );
    task step;
        begin
            @(posedge clk);
            #1;
        end
    endtask
    task check_slice;
        input [1:0] expected;
        integer cycles;
        begin
            @(negedge clk);
            event_valid = 1;
            step;
            @(negedge clk);
            event_valid = 0;
            cycles      = 0;
            while (detector_busy && cycles < 20) begin
                step;
                cycles = cycles + 1;
            end
            if (cycles >= 20) $fatal(1, "Detector timeout");
            if (detected !== expected)
                $fatal(1, "Slice mismatch: expected %b got %b", expected, detected);
            step;
            if (detected !== 0) $fatal(1, "Hit mask must be one pulse");
        end
    endtask

    initial begin
        step;
        @(negedge clk);
        reset = 0;
        check_slice(2'b01);
        active_slice = 0;
        check_slice(2'b00);
        active_slice = 1;
        x0           = 100;
        x1           = 100;
        check_slice(2'b01);
        active = 0;
        check_slice(2'b00);
        active = 3;
        @(negedge clk);
        reset = 1;
        step;
        @(negedge clk);
        reset = 0;
        start = 1;
        step;
        @(negedge clk);
        start = 0;
        slash = 1;
        hits  = 3;
        step;
        if (score !== 20 || combo !== 2) $fatal(1, "Simultaneous fruit scoring failed");
        @(negedge clk);
        hits  = 0;
        slash = 0;
        step;
        if (score !== 25 || combo !== 0) $fatal(1, "Release combo bonus failed");
        @(negedge clk);
        pause = 1;
        step;
        if (playing !== 0 || state !== 2) $fatal(1, "Pause failed");
        @(negedge clk);
        pause = 0;
        step;
        @(negedge clk);
        bombs = 3;
        hits  = 3;
        step;
        if (lives !== 1) $fatal(1, "Two simultaneous bombs must remove two lives");
        @(negedge clk);
        hits = 1;
        step;
        if (lives !== 0 || state !== 3) $fatal(1, "Game over failed");
        @(negedge clk);
        hits  = 0;
        start = 1;
        step;
        if (lives !== 3 || score !== 0 || state !== 1) $fatal(1, "Restart failed");
        $display("PASS: swept hit, simultaneous cuts, combo, pause, bombs, restart");
        $finish;
    end
    initial begin
        #10000;
        $fatal(1, "Timeout");
    end
endmodule
