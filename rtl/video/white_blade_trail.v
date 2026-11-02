// Bounded blade trail: Bresenham walks each swipe, retaining the latest 32 samples.
// A sample every four pixels gives a continuous thin stroke, without a framebuffer
// or parallel multipliers. Old samples fade over 12 game ticks after release.
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
    reg [9:0] points_x [0:31];
    reg [9:0] points_y [0:31];
    reg [3:0] life [0:31];
    reg [4:0] head = 0;
    reg walking = 0;
    reg [9:0] walk_x = 0, walk_y = 0, end_x = 0, end_y = 0;
    reg signed [11:0] dx = 0, dy = 0, error = 0;
    wire signed [12:0] twice_error = $signed(error) * 2;
    reg signed [11:0] next_error;
    reg [9:0] next_x, next_y;
    reg [1:0] spacing = 0;
    wire signed [11:0] distance_x = cursor_x >= previous_x ?
        $signed({2'b0, cursor_x}) - $signed({2'b0, previous_x}) :
        $signed({2'b0, previous_x}) - $signed({2'b0, cursor_x});
    wire signed [11:0] distance_y = cursor_y >= previous_y ?
        $signed({2'b0, cursor_y}) - $signed({2'b0, previous_y}) :
        $signed({2'b0, previous_y}) - $signed({2'b0, cursor_y});
    integer i, j;
    reg [9:0] abs_x, abs_y;
    reg [3:0] brightest;
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
            walking <= 0;
            head <= 0;
            spacing <= 0;
            for (i = 0; i < 32; i = i + 1) begin
                life[i] <= 0;
                points_x[i] <= 0;
                points_y[i] <= 0;
            end
        end else begin
            if (game_tick)
                for (i = 0; i < 32; i = i + 1)
                    if (life[i] != 0) life[i] <= life[i] - 1'b1;
            if (blade_event && slash_active) begin
                walk_x <= previous_x;
                walk_y <= previous_y;
                end_x <= cursor_x;
                end_y <= cursor_y;
                dx <= distance_x;
                dy <= -distance_y;
                error <= distance_x - distance_y;
                spacing <= 0;
                walking <= 1;
            end else if (!slash_active) walking <= 0;
            else if (walking) begin
                if (spacing == 0 || (walk_x == end_x && walk_y == end_y)) begin
                    points_x[head] <= walk_x;
                    points_y[head] <= walk_y;
                    life[head] <= 12;
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
    always @(*) begin
        brightest = 0;
        abs_x = 0;
        abs_y = 0;
        for (j = 0; j < 32; j = j + 1) begin
            abs_x = pixel_x > points_x[j] ? pixel_x - points_x[j] : points_x[j] - pixel_x;
            abs_y = pixel_y > points_y[j] ? pixel_y - points_y[j] : points_y[j] - pixel_y;
            if (abs_x <= 3 && abs_y <= 3 && {1'b0, abs_x} + {1'b0, abs_y} <= 4 &&
                life[j] > brightest) brightest = life[j];
        end
        pixel_on = enabled && brightest != 0;
        rgb = brightest >= 9 ? 12'hFFF : brightest >= 5 ? 12'hAAA : 12'h555;
    end
endmodule
