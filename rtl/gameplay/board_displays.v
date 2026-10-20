module board_displays (
    input             clk,
    input      [15:0] score,
    input      [ 1:0] lives,
    input      [ 1:0] state,
    output reg [ 3:0] an,
    output reg [ 7:0] seg,
    output     [15:0] led
);
    reg [16:0] scan = 0;
    reg [3:0] digit;
    integer decimal_score;
    always @(posedge clk) scan <= scan + 1'b1;
    assign led = {10'd0, state, 1'b0, (lives >= 3), (lives >= 2), (lives >= 1)};
    always @(*) begin
        decimal_score = score % 10000;
        digit         = 0;
        an            = 4'b1111;
        case (scan[16:15])
            0: begin
                an    = 4'b1110;
                digit = decimal_score % 10;
            end
            1: begin
                an    = 4'b1101;
                digit = (decimal_score / 10) % 10;
            end
            2: begin
                an    = 4'b1011;
                digit = (decimal_score / 100) % 10;
            end
            3: begin
                an    = 4'b0111;
                digit = decimal_score / 1000;
            end
        endcase
        case (digit)
            0: seg = 8'hC0;
            1: seg = 8'hF9;
            2: seg = 8'hA4;
            3: seg = 8'hB0;
            4: seg = 8'h99;
            5: seg = 8'h92;
            6: seg = 8'h82;
            7: seg = 8'hF8;
            8: seg = 8'h80;
            9: seg = 8'h90;
            default: seg = 8'hFF;
        endcase
    end
endmodule
