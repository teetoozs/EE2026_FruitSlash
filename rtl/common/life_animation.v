// Lost hearts blink for 3 seconds and fade over the following half second.
module life_animation #(
    parameter CLOCK_HZ = 100000000
) (
    input             clk,
    input             reset,
    input      [ 1:0] lives,
    output reg [11:0] heart_levels
);
    reg [31:0] divider = 0;
    reg [1:0] previous_lives = 3;
    reg [11:0] age[0:2];
    integer i, j, k;
    initial begin
        for (j = 0; j < 3; j = j + 1) age[j] = 3500;
    end
    always @(posedge clk) begin
        if (reset) begin
            divider        <= 0;
            previous_lives <= lives;
            for (i = 0; i < 3; i = i + 1) age[i] <= 3500;
        end else begin
            previous_lives <= lives;
            if (divider == CLOCK_HZ / 1000 - 1) divider <= 0;
            else divider <= divider + 1'b1;
            for (i = 0; i < 3; i = i + 1) begin
                if (lives < previous_lives && i >= lives && i < previous_lives) age[i] <= 0;
                else if (divider == CLOCK_HZ / 1000 - 1 && age[i] < 3500) age[i] <= age[i] + 1'b1;
            end
        end
    end
    always @(*) begin
        heart_levels = 0;
        for (k = 0; k < 3; k = k + 1) begin
            if (k < lives) heart_levels[k*4+:4] = 15;
            else if (age[k] < 3000) heart_levels[k*4+:4] = (age[k] % 500 < 250) ? 15 : 0;
            else if (age[k] < 3480) heart_levels[k*4+:4] = 15 - ((age[k] - 3000) >> 5);
        end
    end
endmodule
