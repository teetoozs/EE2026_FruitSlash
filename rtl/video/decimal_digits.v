// Iterative double-dabble: five decimal digits, no division in the pixel path.
// A snapshot is converted in 16 clocks; published digits always belong together.
module decimal_digits (
    input clk,
    input reset,
    input [15:0] value,
    output reg [19:0] digits = 0
);
    reg [15:0] snapshot = 0, remaining = 0;
    reg [19:0] work = 0;
    reg [4:0] count = 0;
    reg [19:0] adjusted;
    integer i;
    always @(*) begin
        adjusted = work;
        for (i = 0; i < 5; i = i + 1)
            if (work[i*4+:4] >= 5) adjusted[i*4+:4] = work[i*4+:4] + 4'd3;
    end
    always @(posedge clk) begin
        if (reset) begin
            snapshot <= 0;
            remaining <= 0;
            work <= 0;
            count <= 0;
            digits <= 0;
        end else if (count != 0) begin
            work <= {adjusted[18:0], remaining[15]};
            remaining <= {remaining[14:0], 1'b0};
            count <= count - 1'b1;
            if (count == 1) digits <= {adjusted[18:0], remaining[15]};
        end else if (value != snapshot) begin
            snapshot <= value;
            remaining <= value;
            work <= 0;
            count <= 16;
        end
    end
endmodule
