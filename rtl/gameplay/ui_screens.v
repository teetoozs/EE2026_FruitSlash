// Sherwin: title / pause / game-over screens for the 640x480 VGA output.
// Self-contained: bitmap font (plain + chunky outlined), score digits, three layouts,
// slice-to-choose mode boards. Output is a top layer: when ui_on is high, show ui_rgb.
// State encoding: 0 title, 1 play, 2 pause, 3 over. A live score HUD is drawn while playing.
// mode: 0 = single player, 1 = second mode (versus). start_req: slice a board = start now.
 
// ---------------------------------------------------------------- binary -> BCD
// Continuous double-dabble: one result every 17 clocks, no dividers.
module bin2bcd (
    input             clk,
    input      [15:0] bin,
    output reg [19:0] bcd = 0
);
    reg [15:0] sh_bin = 0;
    reg [19:0] sh_bcd = 0;
    reg [4:0] cnt = 0;
    reg [19:0] adj;
    integer k;
    always @(*) begin
        adj = sh_bcd;
        for (k = 0; k < 5; k = k + 1)
            if (sh_bcd[k*4+:4] >= 5) adj[k*4+:4] = sh_bcd[k*4+:4] + 4'd3;
    end
    always @(posedge clk) begin
        if (cnt == 16) begin
            bcd    <= sh_bcd;
            sh_bin <= bin;
            sh_bcd <= 0;
            cnt    <= 0;
        end else begin
            {sh_bcd, sh_bin} <= {adj, sh_bin} << 1;
            cnt <= cnt + 1'b1;
        end
    end
endmodule
 
// ---------------------------------------------------------------- 5x7 glyph ROM
// 35 bits = 7 rows of 5; row 0 (top) is the most significant 5 bits, bit 4 = left column.
module glyph35 (
    input      [ 7:0] ch,
    output reg [34:0] g
);
    always @(*) begin
        case (ch)
            "A": g = {5'b01110, 5'b10001, 5'b10001, 5'b11111, 5'b10001, 5'b10001, 5'b10001};
            "B": g = {5'b11110, 5'b10001, 5'b10001, 5'b11110, 5'b10001, 5'b10001, 5'b11110};
            "C": g = {5'b01110, 5'b10001, 5'b10000, 5'b10000, 5'b10000, 5'b10001, 5'b01110};
            "D": g = {5'b11110, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b11110};
            "E": g = {5'b11111, 5'b10000, 5'b10000, 5'b11110, 5'b10000, 5'b10000, 5'b11111};
            "F": g = {5'b11111, 5'b10000, 5'b10000, 5'b11110, 5'b10000, 5'b10000, 5'b10000};
            "G": g = {5'b01110, 5'b10001, 5'b10000, 5'b10111, 5'b10001, 5'b10001, 5'b01111};
            "H": g = {5'b10001, 5'b10001, 5'b10001, 5'b11111, 5'b10001, 5'b10001, 5'b10001};
            "I": g = {5'b01110, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b01110};
            "L": g = {5'b10000, 5'b10000, 5'b10000, 5'b10000, 5'b10000, 5'b10000, 5'b11111};
            "M": g = {5'b10001, 5'b11011, 5'b10101, 5'b10101, 5'b10001, 5'b10001, 5'b10001};
            "N": g = {5'b10001, 5'b11001, 5'b10101, 5'b10011, 5'b10001, 5'b10001, 5'b10001};
            "O": g = {5'b01110, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b01110};
            "P": g = {5'b11110, 5'b10001, 5'b10001, 5'b11110, 5'b10000, 5'b10000, 5'b10000};
            "R": g = {5'b11110, 5'b10001, 5'b10001, 5'b11110, 5'b10100, 5'b10010, 5'b10001};
            "S": g = {5'b01111, 5'b10000, 5'b10000, 5'b01110, 5'b00001, 5'b00001, 5'b11110};
            "T": g = {5'b11111, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00100};
            "U": g = {5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b01110};
            "V": g = {5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b01010, 5'b00100};
            "W": g = {5'b10001, 5'b10001, 5'b10001, 5'b10101, 5'b10101, 5'b10101, 5'b01010};
            "X": g = {5'b10001, 5'b10001, 5'b01010, 5'b00100, 5'b01010, 5'b10001, 5'b10001};
            "Y": g = {5'b10001, 5'b10001, 5'b01010, 5'b00100, 5'b00100, 5'b00100, 5'b00100};
            "!": g = {5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00000, 5'b00100};
            "0": g = {5'b01110, 5'b10001, 5'b10011, 5'b10101, 5'b11001, 5'b10001, 5'b01110};
            "1": g = {5'b00100, 5'b01100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b01110};
            "2": g = {5'b01110, 5'b10001, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b11111};
            "3": g = {5'b11110, 5'b00001, 5'b00001, 5'b01110, 5'b00001, 5'b00001, 5'b11110};
            "4": g = {5'b00010, 5'b00110, 5'b01010, 5'b10010, 5'b11111, 5'b00010, 5'b00010};
            "5": g = {5'b11111, 5'b10000, 5'b11110, 5'b00001, 5'b00001, 5'b10001, 5'b01110};
            "6": g = {5'b00110, 5'b01000, 5'b10000, 5'b11110, 5'b10001, 5'b10001, 5'b01110};
            "7": g = {5'b11111, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b01000, 5'b01000};
            "8": g = {5'b01110, 5'b10001, 5'b10001, 5'b01110, 5'b10001, 5'b10001, 5'b01110};
            "9": g = {5'b01110, 5'b10001, 5'b10001, 5'b01111, 5'b00001, 5'b00010, 5'b01100};
            default: g = 35'd0;
        endcase
    end
endmodule
 
// Row of a glyph (used by the OLED panel). Row 0 is the top row.
module font5x7 (
    input  [7:0] ch,
    input  [2:0] row,
    output [4:0] bits
);
    wire [34:0] g;
    glyph35 rom (.ch(ch), .g(g));
    assign bits = g[(6-row)*5+:5];
endmodule
 
// ---------------------------------------------------------------- plain text line
// Character cell is 8<<K pixels wide, glyph is 5x7 scaled by 1<<K.
// chars: first character in the most significant byte (string literal order).
module text_line #(
    parameter LEN = 1,
    parameter K = 0,
    parameter X0 = 0,
    parameter Y0 = 0
) (
    input  [      9:0] x,
    input  [      9:0] y,
    input  [LEN*8-1:0] chars,
    output             on
);
    wire in_box = (x >= X0) && (x < X0 + (LEN * 8 << K)) && (y >= Y0) && (y < Y0 + (7 << K));
    wire [ 9:0] dx = x - X0;
    wire [ 9:0] dy = y - Y0;
    wire [ 9:0] ci = dx >> (K + 3);
    wire [ 2:0] col = (dx >> K);
    wire [ 2:0] row = (dy >> K);
    wire [LEN*8-1:0] shifted = chars >> ((LEN - 1 - ci) * 8);
    wire [ 7:0] ch = shifted[7:0];
    wire [ 4:0] bits;
    font5x7 f (
        .ch  (ch),
        .row (row),
        .bits(bits)
    );
    wire [4:0] hit = (bits << col) & 5'b10000;
    assign on = in_box && (hit != 0);
endmodule
 
// ---------------------------------------------------------------- chunky outlined text
// Each character cell is 8 font-pixels wide and 9 tall (a 1 font-pixel outline around the
// 5x7 glyph), each font-pixel being 1<<K screen pixels. The outline is built inside the
// glyph grid, so only one ROM lookup per pixel is needed.
//   fill    : glyph body        edge_on : outline
//   cidx    : character index   grow    : glyph row 0..6 (for top-to-bottom shading)
module fancy_text #(
    parameter LEN = 1,
    parameter K = 0,
    parameter X0 = 0,
    parameter Y0 = 0
) (
    input  [      9:0] x,
    input  [      9:0] y,
    input  [LEN*8-1:0] chars,
    output             fill,
    output             edge_on,
    output [      3:0] cidx,
    output [      2:0] grow
);
    wire in_box = (x >= X0) && (x < X0 + (LEN * 8 << K)) && (y >= Y0) && (y < Y0 + (9 << K));
    wire [ 9:0] dx = x - X0;
    wire [ 9:0] dy = y - Y0;
    wire [ 9:0] ci = dx >> (K + 3);
    wire [ 3:0] col = (dx >> K) & 10'd7;
    wire [ 3:0] row = (dy >> K);
    wire [LEN*8-1:0] shifted = chars >> ((LEN - 1 - ci) * 8);
    wire [34:0] g;
    glyph35 rom (.ch(shifted[7:0]), .g(g));
 
    // Padded grid: 9 rows x 7 cols, glyph at rows 1..7, cols 1..5. Index = r*7 + c.
    reg [62:0] F, D;
    integer r, c, dr, dc;
    always @(*) begin
        F = 63'd0;
        D = 63'd0;
        for (r = 0; r < 7; r = r + 1)
            for (c = 0; c < 5; c = c + 1) F[(r+1)*7+(c+1)] = g[(6-r)*5+(4-c)];
        for (r = 0; r < 9; r = r + 1)
            for (c = 0; c < 7; c = c + 1)
                for (dr = -1; dr <= 1; dr = dr + 1)
                    for (dc = -1; dc <= 1; dc = dc + 1)
                        if (r + dr >= 0 && r + dr <= 8 && c + dc >= 0 && c + dc <= 6)
                            D[r*7+c] = D[r*7+c] | F[(r+dr)*7+(c+dc)];
    end
    wire pick = in_box && (col < 7) && (row < 9);
    wire [5:0] idx = row * 7 + col;
    wire fbit = F[idx];
    wire dbit = D[idx];
    assign fill    = pick && fbit;
    assign edge_on = pick && dbit && !fbit;
    assign cidx    = ci[3:0];
    assign grow    = row - 1;
endmodule
 
// ---------------------------------------------------------------- the screens
module ui_screens (
    input             clk,
    input      [ 9:0] x,
    input      [ 9:0] y,
    input      [ 1:0] state,
    input      [15:0] score,
    input      [15:0] best_score,
    input      [ 9:0] cursor_x,
    input      [ 9:0] cursor_y,
    input             slash_active,
    input             btn_start,
    output reg        ui_on  = 0,
    output reg [11:0] ui_rgb = 0,
    output reg        mode   = 0,
    output            start_req
);
    // ---------------- digits as ASCII, leading zeros blanked
    wire [19:0] sc_bcd, bs_bcd;
    bin2bcd sc_conv (.clk(clk), .bin(score),      .bcd(sc_bcd));
    bin2bcd bs_conv (.clk(clk), .bin(best_score), .bcd(bs_bcd));
    function [39:0] num5;
        input [19:0] b;
        begin
            num5[39:32] = (b[19:16] != 0) ? 8'h30 + b[19:16] : 8'h20;
            num5[31:24] = (b[19:12] != 0) ? 8'h30 + b[15:12] : 8'h20;
            num5[23:16] = (b[19: 8] != 0) ? 8'h30 + b[11: 8] : 8'h20;
            num5[15: 8] = (b[19: 4] != 0) ? 8'h30 + b[ 7: 4] : 8'h20;
            num5[ 7: 0] = 8'h30 + b[3:0];
        end
    endfunction
 
    // ---------------- colour palettes: 0 red 1 orange 2 yellow 3 green 4 purple
    //                  5 cream 6 gold 7 hot red. tone 0 light, 1 mid, 2 dark.
    function [11:0] pal;
        input [3:0] p;
        input [2:0] gr;  // glyph row 0..6
        reg [1:0] t;
        begin
            t = (gr < 2) ? 2'd0 : (gr < 5) ? 2'd1 : 2'd2;
            case (p)
                0: pal = (t == 0) ? 12'hF88 : (t == 1) ? 12'hF33 : 12'hB11;
                1: pal = (t == 0) ? 12'hFB5 : (t == 1) ? 12'hF80 : 12'hC50;
                2: pal = (t == 0) ? 12'hFF8 : (t == 1) ? 12'hFD2 : 12'hCA0;
                3: pal = (t == 0) ? 12'h9F6 : (t == 1) ? 12'h6D2 : 12'h4A1;
                4: pal = (t == 0) ? 12'hC8F : (t == 1) ? 12'h94E : 12'h62B;
                5: pal = (t == 0) ? 12'hFFF : (t == 1) ? 12'hFEC : 12'hDC9;
                6: pal = (t == 0) ? 12'hFE8 : (t == 1) ? 12'hFC0 : 12'hC80;
                default: pal = (t == 0) ? 12'hF77 : (t == 1) ? 12'hF22 : 12'hB00;
            endcase
        end
    endfunction
    function [3:0] m5;  // v mod 5 for v in 0..11
        input [3:0] v;
        m5 = (v >= 10) ? v - 4'd10 : (v >= 5) ? v - 4'd5 : v;
    endfunction
    localparam [11:0] OUTLINE = 12'h210;
 
    // Live gameplay score, reusing the existing decimal converter and glyph ROM.
    wire hud_score_on;
    text_line #(.LEN(11), .K(1), .X0(16), .Y0(16)) gameplay_score (
        .x(x), .y(y), .chars({"SCORE ", num5(sc_bcd)}), .on(hud_score_on)
    );
    wire hud_pause_hint;
    text_line #(.LEN(12), .K(0), .X0(16), .Y0(36)) gameplay_pause_hint (
        .x(x), .y(y), .chars("SW0 TO PAUSE"), .on(hud_pause_hint)
    );
    wire hud_panel = x >= 8 && x < 196 && y >= 8 && y < 50;

    // ---------------- Title text (state 0)
    wire [3:0] c_fr, c_sl, c_sg, c_bt, c_so, c_ss, c_vs, c_sv, c_hn;
    wire [2:0] r_fr, r_sl, r_sg, r_bt, r_so, r_ss, r_vs, r_sv, r_hn;
    wire f_fr, e_fr, f_sl, e_sl, f_sg, e_sg, f_bt, e_bt, f_so, e_so;
    wire f_ss, e_ss, f_vs, e_vs, f_sv, e_sv, f_hn, e_hn;
    fancy_text #(5, 3, 40, 20)   t_fruit (.x(x), .y(y), .chars("FRUIT"), .fill(f_fr), .edge_on(e_fr), .cidx(c_fr), .grow(r_fr));
    fancy_text #(5, 3, 270, 95)  t_slash (.x(x), .y(y), .chars("SLASH"), .fill(f_sl), .edge_on(e_sl), .cidx(c_sl), .grow(r_sl));
    fancy_text #(21, 1, 152, 182) t_sign (.x(x), .y(y), .chars("SLASH A BOARD TO PLAY"), .fill(f_sg), .edge_on(e_sg), .cidx(c_sg), .grow(r_sg));
    fancy_text #(10, 1, 240, 440) t_tbest (.x(x), .y(y), .chars({"BEST ", num5(bs_bcd)}), .fill(f_bt), .edge_on(e_bt), .cidx(c_bt), .grow(r_bt));
    fancy_text #(4, 2, 111, 320) t_solo  (.x(x), .y(y), .chars("SOLO"), .fill(f_so), .edge_on(e_so), .cidx(c_so), .grow(r_so));
    fancy_text #(8, 1, 111, 360) t_solos (.x(x), .y(y), .chars("1 PLAYER"), .fill(f_ss), .edge_on(e_ss), .cidx(c_ss), .grow(r_ss));
    fancy_text #(6, 2, 369, 320) t_vs    (.x(x), .y(y), .chars("VERSUS"), .fill(f_vs), .edge_on(e_vs), .cidx(c_vs), .grow(r_vs));
    fancy_text #(5, 1, 425, 360) t_vss   (.x(x), .y(y), .chars("1 V 1"), .fill(f_sv), .edge_on(e_sv), .cidx(c_sv), .grow(r_sv));
    fancy_text #(22, 1, 144, 410) t_hint (.x(x), .y(y), .chars("OR PRESS BTNC FOR SOLO"), .fill(f_hn), .edge_on(e_hn), .cidx(c_hn), .grow(r_hn));
 
    // ---------------- Pause text (state 2)
    wire [3:0] c_pa, c_ps, c_ph;
    wire [2:0] r_pa, r_ps, r_ph;
    wire f_pa, e_pa, f_ps, e_ps, f_ph, e_ph;
    fancy_text #(6, 3, 128, 150)  t_paused (.x(x), .y(y), .chars("PAUSED"), .fill(f_pa), .edge_on(e_pa), .cidx(c_pa), .grow(r_pa));
    fancy_text #(11, 2, 144, 235) t_pscore (.x(x), .y(y), .chars({"SCORE ", num5(sc_bcd)}), .fill(f_ps), .edge_on(e_ps), .cidx(c_ps), .grow(r_ps));
    fancy_text #(19, 1, 168, 290) t_presm  (.x(x), .y(y), .chars("LOWER SW0 TO RESUME"), .fill(f_ph), .edge_on(e_ph), .cidx(c_ph), .grow(r_ph));
 
    // ---------------- Game-over text (state 3)
    wire [3:0] c_go, c_gs, c_gb, c_gn, c_gh;
    wire [2:0] r_go, r_gs, r_gb, r_gn, r_gh;
    wire f_go, e_go, f_gs, e_gs, f_gb, e_gb, f_gn, e_gn, f_gh, e_gh;
    fancy_text #(9, 3, 32, 50)    t_over  (.x(x), .y(y), .chars("GAME OVER"), .fill(f_go), .edge_on(e_go), .cidx(c_go), .grow(r_go));
    fancy_text #(11, 2, 144, 160) t_gscore (.x(x), .y(y), .chars({"SCORE ", num5(sc_bcd)}), .fill(f_gs), .edge_on(e_gs), .cidx(c_gs), .grow(r_gs));
    fancy_text #(11, 2, 144, 205) t_gbest  (.x(x), .y(y), .chars({"BEST  ", num5(bs_bcd)}), .fill(f_gb), .edge_on(e_gb), .cidx(c_gb), .grow(r_gb));
    fancy_text #(9, 2, 176, 255)  t_gnew   (.x(x), .y(y), .chars("NEW BEST!"), .fill(f_gn), .edge_on(e_gn), .cidx(c_gn), .grow(r_gn));
    fancy_text #(19, 1, 168, 375) t_gretry (.x(x), .y(y), .chars("PRESS BTNC TO RETRY"), .fill(f_gh), .edge_on(e_gh), .cidx(c_gh), .grow(r_gh));
    wire new_best = (score != 0) && (score >= best_score);
 
    // ---------------- Mode boards (title): slice one to choose and start at once
    localparam LX0 = 60,  LX1 = 290, RX0 = 350, RX1 = 580, BY0 = 215, BY1 = 395;
    wire hov_l = (cursor_x >= LX0) && (cursor_x < LX1) && (cursor_y >= BY0) && (cursor_y < BY1);
    wire hov_r = (cursor_x >= RX0) && (cursor_x < RX1) && (cursor_y >= BY0) && (cursor_y < BY1);
    assign start_req = (state == 2'd0) && slash_active && (hov_l || hov_r);
    always @(posedge clk) begin
        if (state == 2'd0) begin
            if (slash_active && hov_r) mode <= 1'b1;
            else if ((slash_active && hov_l) || btn_start) mode <= 1'b0;
        end
    end
 
    // Wood pattern (horizontal planks with seams and grain, matching the background).
    wire [11:0] wood = (y[3:0] == 4'd15) ? 12'h321 :
                       ((((x ^ {y[3:0], 1'b0}) & 10'd15) == 0) && y[2]) ? 12'h532 :
                       y[4] ? 12'h643 : 12'h754;
 
    // Board frames
    wire in_l = (x >= LX0) && (x < LX1) && (y >= BY0) && (y < BY1);
    wire in_r = (x >= RX0) && (x < RX1) && (y >= BY0) && (y < BY1);
    wire bord_l = in_l && ((x < LX0 + 5) || (x >= LX1 - 5) || (y < BY0 + 5) || (y >= BY1 - 5));
    wire bord_r = in_r && ((x < RX0 + 5) || (x >= RX1 - 5) || (y < BY0 + 5) || (y >= BY1 - 5));
    wire gold_l = in_l && ((x < LX0 + 7) || (x >= LX1 - 7) || (y < BY0 + 7) || (y >= BY1 - 7));
    wire gold_r = in_r && ((x < RX0 + 7) || (x >= RX1 - 7) || (y < BY0 + 7) || (y >= BY1 - 7));
 
    // Fruit icons (simple shaded circles): orange on the left board, melon on the right.
    wire signed [10:0] sx = {1'b0, x};
    wire signed [10:0] sy = {1'b0, y};
    wire signed [10:0] lx = sx - 11'sd175, ly = sy - 11'sd280;
    wire signed [10:0] rx = sx - 11'sd465, ry = sy - 11'sd280;
    wire signed [21:0] l2 = lx * lx + ly * ly;
    wire signed [21:0] r2 = rx * rx + ry * ry;
    wire signed [10:0] hlx = lx + 11'sd11, hly = ly + 11'sd11;
    wire signed [10:0] hrx = rx + 11'sd11, hry = ry + 11'sd11;
    wire signed [21:0] hl2 = hlx * hlx + hly * hly;
    wire signed [21:0] hr2 = hrx * hrx + hry * hry;
    wire orange = (l2 <= 900);
    wire melon  = (r2 <= 900);
    wire leaf   = (lx >= -1) && (lx <= 10) && (ly >= -37) && (ly <= -30);
 
    // ---------------- Plaque (pause / game over): wood with dark-red and gold frame
    wire [9:0] qx0 = (state == 2'd2) ? 10'd110 : 10'd120;
    wire [9:0] qx1 = (state == 2'd2) ? 10'd530 : 10'd520;
    wire [9:0] qy0 = (state == 2'd2) ? 10'd140 : 10'd140;
    wire [9:0] qy1 = (state == 2'd2) ? 10'd340 : 10'd350;
    wire in_q   = (state[1]) && (x >= qx0) && (x < qx1) && (y >= qy0) && (y < qy1);
    wire bord_q = in_q && ((x < qx0 + 5) || (x >= qx1 - 5) || (y < qy0 + 5) || (y >= qy1 - 5));
    wire gold_q = in_q && ((x < qx0 + 7) || (x >= qx1 - 7) || (y < qy0 + 7) || (y >= qy1 - 7));
 
    // ---------------- Cursor marker (a diamond), drawn on top in every non-playing state
    wire signed [10:0] cdx = {1'b0, x} - {1'b0, cursor_x};
    wire signed [10:0] cdy = {1'b0, y} - {1'b0, cursor_y};
    wire [10:0] adx = cdx[10] ? -cdx : cdx;
    wire [10:0] ady = cdy[10] ? -cdy : cdy;
    wire [11:0] man = adx + ady;
    wire cur_fill = (state != 2'd1) && (man <= 5);
    wire cur_edge = (state != 2'd1) && (man <= 8);
 
    // ---------------- Layer priority (later assignments win)
    reg        next_on;
    reg [11:0] next_rgb;
    always @* begin
        next_on  = 1'b0;
        next_rgb = 12'h000;
        // dimmed backdrop for pause and game over (50% dither)
        if (state[1] && (x[0] ^ y[0])) begin
            next_on  = 1'b1;
            next_rgb = 12'h100;
        end
        case (state)
            2'd0: begin
                if (in_l) begin
                    next_on = 1; next_rgb = wood;
                    if (gold_l) next_rgb = 12'hFC0;
                    if (bord_l) next_rgb = hov_l ? 12'hF33 : 12'h811;
                    if (orange) begin
                        next_rgb = (l2 > 650) ? 12'hC50 : 12'hF80;
                        if (hl2 <= 40) next_rgb = 12'hFD8;
                    end
                    if (leaf) next_rgb = 12'h3B2;
                end
                if (in_r) begin
                    next_on = 1; next_rgb = wood;
                    if (gold_r) next_rgb = 12'hFC0;
                    if (bord_r) next_rgb = hov_r ? 12'hF33 : 12'h811;
                    if (melon) begin
                        next_rgb = x[3] ? 12'h175 : 12'h4C3;
                        if (r2 > 650) next_rgb = 12'h052;
                        if (hr2 <= 40) next_rgb = 12'h9F9;
                    end
                end
                if (e_fr || e_sl || e_sg || e_bt || e_so || e_ss || e_vs || e_sv || e_hn) begin
                    next_on = 1; next_rgb = OUTLINE;
                end
                if (f_fr) begin next_on = 1; next_rgb = pal(c_fr, r_fr); end
                if (f_sl) begin next_on = 1; next_rgb = pal(m5(c_sl + 4'd2), r_sl); end
                if (f_sg) begin next_on = 1; next_rgb = pal(4'd5, r_sg); end
                if (f_bt) begin next_on = 1; next_rgb = pal(4'd6, r_bt); end
                if (f_so) begin next_on = 1; next_rgb = pal(4'd1, r_so); end
                if (f_ss) begin next_on = 1; next_rgb = pal(4'd5, r_ss); end
                if (f_vs) begin next_on = 1; next_rgb = pal(4'd3, r_vs); end
                if (f_sv) begin next_on = 1; next_rgb = pal(4'd5, r_sv); end
                if (f_hn) begin next_on = 1; next_rgb = pal(4'd5, r_hn); end
            end
            2'd1: begin
                if (hud_panel) begin
                    next_on = 1'b1;
                    next_rgb = hud_score_on ? 12'hFE8 : hud_pause_hint ? 12'hFFF : 12'h210;
                end
            end
            2'd2: begin
                if (in_q) begin
                    next_on = 1; next_rgb = wood;
                    if (gold_q) next_rgb = 12'hFC0;
                    if (bord_q) next_rgb = 12'h811;
                end
                if (e_pa || e_ps || e_ph) begin next_on = 1; next_rgb = OUTLINE; end
                if (f_pa) begin next_on = 1; next_rgb = pal(m5(c_pa), r_pa); end
                if (f_ps) begin next_on = 1; next_rgb = pal(4'd5, r_ps); end
                if (f_ph) begin next_on = 1; next_rgb = pal(4'd5, r_ph); end
            end
            2'd3: begin
                if (in_q) begin
                    next_on = 1; next_rgb = wood;
                    if (gold_q) next_rgb = 12'hFC0;
                    if (bord_q) next_rgb = 12'h811;
                end
                if (e_go || e_gs || e_gb || (new_best && e_gn) || e_gh) begin next_on = 1; next_rgb = OUTLINE; end
                if (f_go) begin next_on = 1; next_rgb = pal(4'd7, r_go); end
                if (f_gs) begin next_on = 1; next_rgb = pal(4'd5, r_gs); end
                if (f_gb) begin next_on = 1; next_rgb = pal(4'd6, r_gb); end
                if (new_best && f_gn) begin next_on = 1; next_rgb = pal(m5(c_gn), r_gn); end
                if (f_gh) begin next_on = 1; next_rgb = pal(4'd5, r_gh); end
            end
            default: ;
        endcase
        if (cur_edge) begin next_on = 1; next_rgb = OUTLINE; end
        if (cur_fill) begin next_on = 1; next_rgb = 12'hFE8; end
    end
 
    // One register stage: a pixel lasts four 100 MHz clocks, so this is invisible.
    always @(posedge clk) begin
        ui_on  <= next_on;
        ui_rgb <= next_rgb;
    end
endmodule