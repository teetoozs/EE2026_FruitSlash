// 16 by 14 pixel heart, optionally scaled by a power of two.
module heart_pixel #(
    parameter SCALE = 0
) (
    input  [9:0] x,
    y,
    input  [9:0] left,
    top,
    output       pixel_on
);
    wire [ 9:0] hx = (x - left) >> SCALE;
    wire [ 9:0] hy = (y - top) >> SCALE;
    reg  [15:0] row;
    always @(*) begin
        case (hy)
            0: row = 16'h3C3C;
            1: row = 16'h7E7E;
            2, 3, 4, 5: row = 16'hFFFF;
            6: row = 16'h7FFE;
            7: row = 16'h3FFC;
            8: row = 16'h1FF8;
            9: row = 16'h0FF0;
            10: row = 16'h07E0;
            11: row = 16'h03C0;
            12: row = 16'h0180;
            default: row = 0;
        endcase
    end
    assign pixel_on = x >= left && y >= top && hx < 16 && hy < 14 && row[hx[3:0]];
endmodule
