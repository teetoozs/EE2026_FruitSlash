// Lost hearts blink for 3 seconds and fade over the following half second.
module life_animation #(
    parameter CLOCK_HZ = 100000000
) (
    input             clk,
    input             reset,
    input      [ 2:0] lives,
    output reg [19:0] heart_levels
);
    localparam DIV_WIDTH = $clog2(CLOCK_HZ/1000)>0 ? $clog2(CLOCK_HZ/1000):1;
    reg [DIV_WIDTH-1:0] divider = 0;
    // Only six blink periods occur before fading; avoid a modulo divider per heart.
    function blink_on;
        input [11:0] elapsed;
        begin
            blink_on=(elapsed<250) || (elapsed>=500 && elapsed<750) ||
                     (elapsed>=1000 && elapsed<1250) || (elapsed>=1500 && elapsed<1750) ||
                     (elapsed>=2000 && elapsed<2250) || (elapsed>=2500 && elapsed<2750);
        end
    endfunction
    reg [2:0] previous_lives = 3;
    reg [11:0] age[0:4];
    integer i, j, k;
    initial begin
        for (j = 0; j < 5; j = j + 1) age[j] = 3500;
    end
    always @(posedge clk) begin
        if (reset) begin
            divider        <= 0;
            previous_lives <= lives;
            for (i = 0; i < 5; i = i + 1) age[i] <= 3500;
        end else begin
            previous_lives <= lives;
            if (divider == CLOCK_HZ / 1000 - 1) divider <= 0;
            else divider <= divider + 1'b1;
            for (i = 0; i < 5; i = i + 1) begin
                if (lives < previous_lives && i >= lives && i < previous_lives) age[i] <= 0;
                else if (divider == CLOCK_HZ / 1000 - 1 && age[i] < 3500) age[i] <= age[i] + 1'b1;
            end
        end
    end
    always @(*) begin
        heart_levels = 0;
        for (k = 0; k < 5; k = k + 1) begin
            if (k < lives) heart_levels[k*4+:4] = 15;
            else if (age[k] < 3000) heart_levels[k*4+:4] = blink_on(age[k]) ? 15 : 0;
            else if (age[k] < 3480) heart_levels[k*4+:4] = 15 - ((age[k] - 3000) >> 5);
        end
    end
endmodule
