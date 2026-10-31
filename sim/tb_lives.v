`timescale 1ns / 1ps
module tb_lives;
    reg clk = 0, reset = 1;
    always #5 clk = ~clk;
    reg  [ 1:0] lives = 3;
    wire [11:0] levels;
    life_animation #(
        .CLOCK_HZ(1000)
    ) dut (
        .clk         (clk),
        .reset       (reset),
        .lives       (lives),
        .heart_levels(levels)
    );
    initial begin
        repeat (2) @(negedge clk);
        reset = 0;
        #1;
        if (levels !== 12'hFFF) $fatal(1, "Initial hearts");
        lives = 2;
        @(negedge clk);
        if (levels !== 12'hFFF) $fatal(1, "Lost heart starts visible");
        repeat (250) @(negedge clk);
        if (levels !== 12'h0FF) $fatal(1, "Blink off");
        repeat (2750) @(negedge clk);
        if (levels !== 12'hFFF) $fatal(1, "Fade starts at 3 seconds");
        repeat (256) @(negedge clk);
        if (levels !== 12'h7FF) $fatal(1, "Half fade");
        repeat (244) @(negedge clk);
        if (levels !== 12'h0FF) $fatal(1, "Lost heart disappears");
        lives = 0;
        repeat (3501) @(negedge clk);
        if (levels !== 0) $fatal(1, "Multiple losses");
        lives = 3;
        #1;
        if (levels !== 12'hFFF) $fatal(1, "Restart restores hearts");
        $display("PASS: life animation");
        $finish;
    end
endmodule
