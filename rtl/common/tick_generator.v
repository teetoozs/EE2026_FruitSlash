module tick_generator #(
    parameter DIVISOR = 1666667
) (
    input  clk,
    input  reset,
    output tick
);
    reg [31:0] count = 0;
    assign tick = !reset && count == DIVISOR - 1;
    always @(posedge clk)
        if (reset || tick) count <= 0;
        else count <= count + 1'b1;
endmodule
