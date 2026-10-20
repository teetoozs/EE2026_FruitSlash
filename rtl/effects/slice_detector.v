`timescale 1ns / 1ps
// Shared swept-segment engine: four cycles per object, not eight parallel
// 64-bit datapaths. The entire transaction emits ONE hit-mask pulse.
module slice_detector #(
    parameter N = 8
) (
    input                 clk,
    input                 reset,
    input                 playing,
    input                 blade_event,
    input                 slash_active,
    input      [     9:0] x0,
    y0,
    x1,
    y1,
    input      [   N-1:0] active,
    input      [N*16-1:0] positions_x,
    positions_y,
    output reg [   N-1:0] hit_mask = 0,
    output                busy
);
    localparam INDEX_WIDTH = N > 1 ? $clog2(N) : 1;
    localparam IDLE = 0, PREPARE = 1, PRODUCTS = 2, SQUARE = 3, DECIDE = 4;
    reg [2:0] stage = IDLE;
    reg [INDEX_WIDTH-1:0] index = 0;
    reg [N-1:0] saved_active = 0, accumulated = 0;
    reg [N*16-1:0] saved_x = 0, saved_y = 0;
    reg signed [10:0] ax = 0, ay = 0, bx = 0, by = 0, ux = 0, uy = 0;
    // Fruit pixels span -2048..2047. Subtracting a 10-bit cursor needs 13 bits.
    reg signed [12:0] wx = 0, wy = 0, ex = 0, ey = 0;
    reg signed [24:0] dot = 0, cross_value = 0;
    reg [21:0] length_squared = 0;
    reg [26:0] distance_a = 0, distance_b = 0, endpoint_distance = 0;
    reg [49:0] cross_squared = 0;
    reg [30:0] threshold = 0;
    reg endpoint = 0;
    wire qualifies = saved_active[index] &&
        (endpoint ? endpoint_distance <= 27'd324 :
                    cross_squared <= {19'd0, threshold});
    assign busy = stage != IDLE;

    always @(posedge clk) begin
        hit_mask <= 0;
        if (reset || !playing) begin
            stage       <= IDLE;
            accumulated <= 0;
            index       <= 0;
        end else begin
            case (stage)
                IDLE:
                if (blade_event && slash_active) begin
                    saved_active <= active;
                    saved_x      <= positions_x;
                    saved_y      <= positions_y;
                    ax           <= $signed({1'b0, x0});
                    ay           <= $signed({1'b0, y0});
                    bx           <= $signed({1'b0, x1});
                    by           <= $signed({1'b0, y1});
                    ux           <= $signed({1'b0, x1}) - $signed({1'b0, x0});
                    uy           <= $signed({1'b0, y1}) - $signed({1'b0, y0});
                    accumulated  <= 0;
                    index        <= 0;
                    stage        <= PREPARE;
                end
                PREPARE: begin
                    wx    <= ($signed(saved_x[index*16+:16]) >>> 4) - ax;
                    wy    <= ($signed(saved_y[index*16+:16]) >>> 4) - ay;
                    ex    <= ($signed(saved_x[index*16+:16]) >>> 4) - bx;
                    ey    <= ($signed(saved_y[index*16+:16]) >>> 4) - by;
                    stage <= PRODUCTS;
                end
                PRODUCTS: begin
                    dot            <= wx * ux + wy * uy;
                    cross_value    <= wx * uy - wy * ux;
                    length_squared <= ux * ux + uy * uy;
                    distance_a     <= wx * wx + wy * wy;
                    distance_b     <= ex * ex + ey * ey;
                    stage          <= SQUARE;
                end
                SQUARE: begin
                    cross_squared <= cross_value * cross_value;
                    threshold <= length_squared * 9'd324;
                    endpoint <= length_squared == 0 || dot <= 0 || dot >= $signed(
                        {3'b000, length_squared}
                    );
                    endpoint_distance <= (length_squared==0 || dot<=0)
                                       ? distance_a : distance_b;
                    stage <= DECIDE;
                end
                DECIDE: begin
                    if (qualifies) accumulated[index] <= 1'b1;
                    if (index == N - 1) begin
                        hit_mask <= accumulated | ({{(N - 1) {1'b0}}, qualifies} << index);
                        stage    <= IDLE;
                    end else begin
                        index <= index + 1'b1;
                        stage <= PREPARE;
                    end
                end
                default: stage <= IDLE;
            endcase
        end
    end
    // Events must not arrive while busy. Real mouse packets and the 60 Hz
    // fallback updates are much farther apart than this 33-cycle transaction.
endmodule
