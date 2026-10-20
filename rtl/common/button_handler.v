// Stable-level debounce plus one-cycle press events. 100 MHz, 10 ms.
module button_handler #(
    parameter WAIT_CYCLES = 1000000
) (
    input            clk,
    input            reset,
    input      [4:0] raw,
    output reg [4:0] held = 0,
    output reg [4:0] pressed = 0
);
    (* ASYNC_REG="TRUE" *) reg [4:0] meta = 0, sync = 0;
    reg [19:0] count[0:4];
    integer i;
    initial for (i = 0; i < 5; i = i + 1) count[i] = 0;
    always @(posedge clk) begin
        meta    <= raw;
        sync    <= meta;
        pressed <= 0;
        if (reset) begin
            held <= 0;
            for (i = 0; i < 5; i = i + 1) count[i] <= 0;
        end else
            for (i = 0; i < 5; i = i + 1) begin
                if (sync[i] == held[i]) count[i] <= 0;
                else if (count[i] == WAIT_CYCLES - 1) begin
                    count[i] <= 0;
                    held[i]  <= sync[i];
                    if (sync[i]) pressed[i] <= 1;
                end else count[i] <= count[i] + 1'b1;
            end
    end
endmodule
