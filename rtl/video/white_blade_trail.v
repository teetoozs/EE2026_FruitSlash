// Compact blade trail for the Basys3.
// Thirty-two Bresenham samples form a bright 256-pixel tapered slash.
// Eight-pixel sample spacing and Chebyshev coverage keep diagonals smooth while
// the narrow bright core and tapered ends keep the cut sharp.
module white_blade_trail (
    input clk,
    input reset,
    input game_tick,
    input enabled,
    input blade_event,
    input slash_active,
    input [9:0] previous_x,
    input [9:0] previous_y,
    input [9:0] cursor_x,
    input [9:0] cursor_y,
    input [9:0] pixel_x,
    input [9:0] pixel_y,
    output reg pixel_on,
    output reg [11:0] rgb
);
    localparam POINTS = 32;
    reg [9:0] points_x [0:POINTS-1];
    reg [9:0] points_y [0:POINTS-1];
    reg [3:0] life [0:POINTS-1];
    reg [4:0] head = 0;
    reg walking = 0;
    reg [9:0] walk_x = 0, walk_y = 0, end_x = 0, end_y = 0;
    reg signed [11:0] dx = 0, dy = 0, error = 0;
    reg signed [11:0] next_error;
    reg [9:0] next_x, next_y;
    reg [2:0] spacing = 0;
    wire signed [12:0] twice_error = $signed(error) * 2;
    wire signed [11:0] distance_x = cursor_x >= previous_x ?
        $signed({2'b0, cursor_x}) - $signed({2'b0, previous_x}) :
        $signed({2'b0, previous_x}) - $signed({2'b0, cursor_x});
    wire signed [11:0] distance_y = cursor_y >= previous_y ?
        $signed({2'b0, cursor_y}) - $signed({2'b0, previous_y}) :
        $signed({2'b0, previous_y}) - $signed({2'b0, cursor_y});

    integer i, j;
    always @(*) begin
        next_x = walk_x;
        next_y = walk_y;
        next_error = error;
        if (twice_error >= dy) begin
            next_error = next_error + dy;
            if (walk_x != end_x) next_x = walk_x < end_x ? walk_x + 1'b1 : walk_x - 1'b1;
        end
        if (twice_error <= dx) begin
            next_error = next_error + dx;
            if (walk_y != end_y) next_y = walk_y < end_y ? walk_y + 1'b1 : walk_y - 1'b1;
        end
    end

    always @(posedge clk) begin
        if (reset || !enabled) begin
            head <= 0;
            walking <= 0;
            spacing <= 0;
            for (i = 0; i < POINTS; i = i + 1) begin
                points_x[i] <= 0;
                points_y[i] <= 0;
                life[i] <= 0;
            end
        end else begin
            if (game_tick)
                for (i = 0; i < POINTS; i = i + 1)
                    if (life[i] != 0) life[i] <= life[i] - 1'b1;
            if (blade_event && slash_active && (cursor_x != previous_x || cursor_y != previous_y)) begin
                walk_x <= previous_x;
                walk_y <= previous_y;
                end_x <= cursor_x;
                end_y <= cursor_y;
                dx <= distance_x;
                dy <= -distance_y;
                error <= distance_x - distance_y;
                spacing <= 0;
                walking <= 1;
            end else if (!slash_active) begin
                walking <= 0;
            end else if (walking) begin
                if (spacing == 0 || (walk_x == end_x && walk_y == end_y)) begin
                    points_x[head] <= walk_x;
                    points_y[head] <= walk_y;
                    // Fifteen game ticks gives the silver cut time to fade
                    // through several shades instead of blinking off.
                    life[head] <= 15;
                    head <= head + 1'b1;
                end
                spacing <= spacing + 1'b1;
                walk_x <= next_x;
                walk_y <= next_y;
                error <= next_error;
                if (walk_x == end_x && walk_y == end_y) walking <= 0;
            end
        end
    end

    // One subtraction per axis; fixed thresholds avoid a dynamic radius
    // and a 32-way priority chain. The faint outer band joins 8-pixel samples.
    wire [POINTS-1:0] edge_hits;
    wire [POINTS-1:0] shade_hits;
    wire [POINTS-1:0] silver_hits;
    wire [POINTS-1:0] white_hits;
    genvar g;
    generate for (g = 0; g < POINTS; g = g + 1) begin : pixel_sample
        localparam [4:0] SLOT = g;
        wire [4:0] age = head - 5'd1 - SLOT;
        wire [9:0] offset_x = pixel_x - points_x[g];
        wire [9:0] offset_y = pixel_y - points_y[g];
        wire x4 = offset_x <= 10'd4 || offset_x >= 10'd1020;
        wire y4 = offset_y <= 10'd4 || offset_y >= 10'd1020;
        wire x2 = offset_x <= 10'd2 || offset_x >= 10'd1022;
        wire y2 = offset_y <= 10'd2 || offset_y >= 10'd1022;
        wire x1 = offset_x <= 10'd1 || offset_x == 10'd1023;
        wire y1 = offset_y <= 10'd1 || offset_y == 10'd1023;
        wire near_tip = age < 3 || age > 28;
        wire active = life[g] != 0;
        assign edge_hits[g] = active && ((!near_tip && x4 && y4) ||
                                          (near_tip && x2 && y2));
        assign shade_hits[g] = active && life[g] >= 4 && x4 && y4;
        assign silver_hits[g] = active && life[g] >= 7 && x2 && y2 && !near_tip;
        assign white_hits[g] = active && life[g] >= 11 && x1 && y1 && !near_tip;
    end endgenerate

    always @(*) begin
        pixel_on = enabled && !reset && (|edge_hits);
        if (|white_hits) rgb = 12'hFFF;
        else if (|silver_hits) rgb = 12'hEFF;
        else if (|shade_hits) rgb = 12'hCDE;
        else rgb = 12'h678;
    end
endmodule