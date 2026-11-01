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
<<<<<<< HEAD
    input  [15:0] best_score,
    input  [ 2:0] multiplier,
=======
>>>>>>> origin/main
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
<<<<<<< HEAD
    reg [44:0] mailbox = 0;
=======
    reg [25:0] mailbox = 0;
>>>>>>> origin/main
    reg request = 0;
    (* ASYNC_REG="TRUE" *) reg ack_meta = 0, ack_sync = 0;
    (* ASYNC_REG="TRUE" *) reg req_meta = 0, req_sync = 0;
    reg acknowledge = 0;
<<<<<<< HEAD
    reg [44:0] status = 0;
=======
    reg [25:0] status = 0;
>>>>>>> origin/main
    always @(posedge clk) begin
        ack_meta <= acknowledge;
        ack_sync <= ack_meta;
        if (request == ack_sync) begin
<<<<<<< HEAD
            mailbox <= {multiplier, best_score, heart_levels, lives, difficulty, state, combo};
=======
            mailbox <= {heart_levels, lives, difficulty, state, combo};
>>>>>>> origin/main
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
    wire [15:0] shown_best = status[41:26];
    wire [ 2:0] shown_mult = status[44:42];
    reg  [15:0] colour;
    wire [ 2:0] heart;
    genvar h;
    generate
        for (h = 0; h < 3; h = h + 1) begin : hearts
            heart_pixel shape (
                .x       ({3'b0, x}),
                .y       ({4'b0, y}),
                .left    (10'd8 + h * 10'd30),
<<<<<<< HEAD
                .top     (10'd12),
=======
                .top     (10'd10),
>>>>>>> origin/main
                .pixel_on(heart[h])
            );
        end
    endgenerate
<<<<<<< HEAD
    // ---- Text values (BCD from the OLED clock domain; font from ui_screens.v)
    wire [19:0] best_bcd, combo_bcd;
    bin2bcd best_conv  (.clk(oled_clk), .bin(shown_best),         .bcd(best_bcd));
    bin2bcd combo_conv (.clk(oled_clk), .bin({8'd0, shown_combo}), .bcd(combo_bcd));
    function [7:0] dgt;  // digit as ASCII, or a space when it is a leading zero
        input blank;
        input [3:0] d;
        dgt = blank ? 8'h20 : 8'h30 + d;
    endfunction
    wire [39:0] best_chars = {dgt(best_bcd[19:16] == 0, best_bcd[19:16]),
                              dgt(best_bcd[19:12] == 0, best_bcd[15:12]),
                              dgt(best_bcd[19:8]  == 0, best_bcd[11:8]),
                              dgt(best_bcd[19:4]  == 0, best_bcd[7:4]),
                              dgt(1'b0, best_bcd[3:0])};
    wire [23:0] combo_chars = {dgt(combo_bcd[11:8] == 0, combo_bcd[11:8]),
                               dgt(combo_bcd[11:4] == 0, combo_bcd[7:4]),
                               dgt(1'b0, combo_bcd[3:0])};
    wire t_best, t_level, t_combo, t_mult;
    text_line #(10, 0, 8, 3)  l_best  (.x({3'b0, x}), .y({4'b0, y}), .chars({"BEST ", best_chars}), .on(t_best));
    text_line #(7, 0, 8, 33)  l_level (.x({3'b0, x}), .y({4'b0, y}), .chars({"LEVEL ", 8'h31 + {6'd0, shown_difficulty}}), .on(t_level));
    text_line #(9, 0, 8, 43)  l_combo (.x({3'b0, x}), .y({4'b0, y}), .chars({"COMBO ", combo_chars}), .on(t_combo));
    text_line #(7, 0, 8, 53)  l_mult  (.x({3'b0, x}), .y({4'b0, y}), .chars({"MULT X", 8'h30 + {5'd0, shown_mult}}), .on(t_mult));
 
    // ---- Wooden planks, gold frame, hearts, labelled text
    
    wire seam  = (y[3:0] == 4'd15);
    wire grain = (((x ^ {y[3:0], 2'b0}) & 7'd31) == 0);
    integer i;
    reg [3:0] brightness;
    always @(*) begin
        colour = y[4] ? 16'h7A85 : 16'h6A24;
        if (grain) colour = 16'h6204;
        if (seam)  colour = 16'h3922;
        if (x < 2 || x >= 94 || y < 2 || y >= 62) colour = 16'hFE45;
=======
    integer i;
    reg [3:0] brightness;
    always @(*) begin
        colour     = 16'h0000;
>>>>>>> origin/main
        brightness = 0;
        for (i = 0; i < 3; i = i + 1) begin
            brightness = status[14+i*4+:4];
            if (heart[i]) colour = {brightness, brightness[3], 11'b0};
        end
<<<<<<< HEAD
        if (t_best)  colour = 16'hFE45;
        if (t_level) colour = 16'h07FF;
        if (t_combo) colour = 16'hFFFF;
        if (t_mult)  colour = 16'hFC00;
=======
        if (y >= 32 && y < 40 && x < ({6'd0, shown_difficulty} + 8'd1) * 8'd20) colour = 16'h07FF;
        if (y >= 48 && y < 56 && x < (shown_combo > 20 ? 96 : shown_combo * 4)) colour = 16'hFFE0;
>>>>>>> origin/main
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