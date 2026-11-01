// Titus: Sensei panel with animated life hearts, combo and difficulty bars.
// Text/end statistics remain to be implemented.
module sensei_panel (
    input         clk,
    input         reset,
    input  [11:0] heart_levels,
    input  [ 1:0] lives,
    input  [ 1:0] difficulty,
    input  [ 1:0] state,
    input  [ 7:0] combo,
    output [ 7:0] JB
);
    reg [2:0] div = 0;
    reg oled_clk = 0;
    always @(posedge clk) begin
        if (reset) begin
            div      <= 0;
            oled_clk <= 0;
        end else if (div == 7) begin
            div      <= 0;
            oled_clk <= ~oled_clk;
        end else div <= div + 1'b1;
    end
    // Snapshot multi-bit status into a mailbox held stable while the
    // OLED domain receives a synchronized request. No torn status buses.
    reg [25:0] mailbox = 0;
    reg request = 0;
    (* ASYNC_REG="TRUE" *) reg ack_meta = 0, ack_sync = 0;
    (* ASYNC_REG="TRUE" *) reg req_meta = 0, req_sync = 0;
    reg acknowledge = 0;
    reg [25:0] status = 0;
    always @(posedge clk) begin
        ack_meta <= acknowledge;
        ack_sync <= ack_meta;
        if (request == ack_sync) begin
            mailbox <= {heart_levels, lives, difficulty, state, combo};
            request <= ~request;
        end
    end
    always @(posedge oled_clk) begin
        req_meta <= request;
        req_sync <= req_meta;
        if (req_sync != acknowledge) begin
            status      <= mailbox;
            acknowledge <= req_sync;
        end
    end
    wire [12:0] index;
    wire [ 6:0] x = index % 96;
    wire [ 5:0] y = index / 96;
    wire [ 1:0] shown_lives = status[13:12], shown_difficulty = status[11:10];
    wire [ 1:0] shown_state = status[9:8];
    wire [ 7:0] shown_combo = status[7:0];
    reg  [15:0] colour;
    wire [ 2:0] heart;
    genvar h;
    generate
        for (h = 0; h < 3; h = h + 1) begin : hearts
            heart_pixel shape (
                .x       ({3'b0, x}),
                .y       ({4'b0, y}),
                .left    (10'd8 + h * 10'd30),
                .top     (10'd10),
                .pixel_on(heart[h])
            );
        end
    endgenerate
    integer i;
    reg [3:0] brightness;
    always @(*) begin
        colour     = 16'h0000;
        brightness = 0;
        for (i = 0; i < 3; i = i + 1) begin
            brightness = status[14+i*4+:4];
            if (heart[i]) colour = {brightness, brightness[3], 11'b0};
        end
        if (y >= 32 && y < 40 && x < ({6'd0, shown_difficulty} + 8'd1) * 8'd20) colour = 16'h07FF;
        if (y >= 48 && y < 56 && x < (shown_combo > 20 ? 96 : shown_combo * 4)) colour = 16'hFFE0;
    end
    assign JB[2] = 0;
    Oled_Display driver (
        .clk           (oled_clk),
        .reset         (reset),
        .frame_begin   (),
        .sending_pixels(),
        .sample_pixel  (),
        .pixel_index   (index),
        .pixel_data    (colour),
        .cs            (JB[0]),
        .sdin          (JB[1]),
        .sclk          (JB[3]),
        .d_cn          (JB[4]),
        .resn          (JB[5]),
        .vccen         (JB[6]),
        .pmoden        (JB[7])
    );
endmodule
