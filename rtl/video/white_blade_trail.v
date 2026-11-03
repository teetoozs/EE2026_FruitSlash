// Compact blade trail for the Basys3.
// Sixteen Bresenham samples form a 64-pixel silver blade. The outer samples
// are one pixel wide and the middle is two pixels wide, giving both tips a
// clean point without the 64-way per-pixel hardware used by the earlier trail.
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
    localparam POINTS = 16;
    reg [9:0] points_x [0:POINTS-1];
    reg [9:0] points_y [0:POINTS-1];
    reg [3:0] life [0:POINTS-1];
    reg [3:0] head = 0;
    reg [4:0] valid_count = 0;
    reg walking = 0;
    reg [9:0] walk_x = 0, walk_y = 0, end_x = 0, end_y = 0;
    reg signed [11:0] dx = 0, dy = 0, error = 0;
    reg signed [11:0] next_error;
    reg [9:0] next_x, next_y;
    reg [1:0] spacing = 0;
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
            valid_count <= 0;
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
                    life[head] <= 10;
                    head <= head + 1'b1;
                    if (valid_count < POINTS) valid_count <= valid_count + 1'b1;
                end
                spacing <= spacing + 1'b1;
                walk_x <= next_x;
                walk_y <= next_y;
                error <= next_error;
                if (walk_x == end_x && walk_y == end_y) walking <= 0;
            end
        end
    end

    // Palette flags are cheaper than comparing sixteen RGB values.
    // Together they create a white highlight, silver body and blue-grey edge.
    reg [9:0] abs_x, abs_y;
    reg [4:0] distance;
    reg [3:0] age_rank, radius;
    reg highlight, silver, shadow;
    always @(*) begin
        abs_x = 0;
        abs_y = 0;
        distance = 0;
        age_rank = 0;
        radius = 0;
        highlight = 0;
        silver = 0;
        shadow = 0;
        for (j = 0; j < POINTS; j = j + 1) begin
            age_rank = head - 1'b1 - j[3:0];
            if (age_rank == 0 || age_rank == 15) radius = 0;
            else if (age_rank < 3 || age_rank > 12) radius = 1;
            else radius = 2;
            if (life[j] < 4) radius = radius >> 1;
            abs_x = pixel_x > points_x[j] ? pixel_x - points_x[j] : points_x[j] - pixel_x;
            abs_y = pixel_y > points_y[j] ? pixel_y - points_y[j] : points_y[j] - pixel_y;
            distance = {1'b0, abs_x} + {1'b0, abs_y};
            if (age_rank < valid_count && life[j] != 0 && distance <= radius) begin
                shadow = 1;
                if (distance <= 1) silver = 1;
                if (distance == 0 || (distance == 1 && pixel_y <= points_y[j])) highlight = 1;
            end
        end
        pixel_on = enabled && !reset && shadow;
        if (highlight) rgb = 12'hFFF;
        else if (silver) rgb = 12'hCDE;
        else rgb = 12'h789;
    end
endmodule
