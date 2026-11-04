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
            "G": g={5'b01110,5'b10001,5'b10000,5'b10111,5'b10001,5'b10001,5'b01110};
            "J": g={5'b00111,5'b00010,5'b00010,5'b00010,5'b10010,5'b10010,5'b01100};
            "K": g={5'b10001,5'b10010,5'b10100,5'b11000,5'b10100,5'b10010,5'b10001};
            "Q": g={5'b01110,5'b10001,5'b10001,5'b10001,5'b10101,5'b10010,5'b01101};
            "Z": g={5'b11111,5'b00001,5'b00010,5'b00100,5'b01000,5'b10000,5'b11111};
            ".": g={5'b00000,5'b00000,5'b00000,5'b00000,5'b00000,5'b00110,5'b00110};
            ":": g={5'b00000,5'b00110,5'b00110,5'b00000,5'b00110,5'b00110,5'b00000};
            "-": g={5'b00000,5'b00000,5'b00000,5'b11111,5'b00000,5'b00000,5'b00000};
            "?": g={5'b01110,5'b10001,5'b00001,5'b00010,5'b00100,5'b00000,5'b00100};
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
    input blade_event,tick,reset,menu_locked,
    output menu_busy,
    input [9:0] previous_x,previous_y,
    output reg        ui_on  = 0,
    output reg [11:0] ui_rgb = 0,
    output reg        mode   = 0,
    output reg        start_req=0
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

    // Mutually exclusive text rectangles share one glyph/outline datapath.
    reg [4:0] text_region;
    reg [9:0] text_dx, text_dy;
    reg [7:0] text_char;
    reg [3:0] text_index;
    reg [175:0] text_chars;
    wire shared_fill, shared_edge;
    wire [2:0] shared_row;
    fancy_text #(1,0,0,0) shared_text (
        .x(text_dx), .y(text_dy), .chars(text_char),
        .fill(shared_fill), .edge_on(shared_edge), .cidx(), .grow(shared_row));
    // ---------------- Title text (state 0)
    wire [3:0] c_fr, c_sl, c_sg, c_bt, c_so, c_ss, c_vs, c_sv, c_hn;
    wire [2:0] r_fr, r_sl, r_sg, r_bt, r_so, r_ss, r_vs, r_sv, r_hn;
    wire f_fr, e_fr, f_sl, e_sl, f_sg, e_sg, f_bt, e_bt, f_so, e_so;
    wire f_ss, e_ss, f_vs, e_vs, f_sv, e_sv, f_hn, e_hn;
    assign f_fr=(text_region==1) && shared_fill;
    assign e_fr=(text_region==1) && shared_edge;
    assign c_fr=text_index;
    assign r_fr=shared_row;
    assign f_sl=(text_region==2) && shared_fill;
    assign e_sl=(text_region==2) && shared_edge;
    assign c_sl=text_index;
    assign r_sl=shared_row;
    assign f_sg=(text_region==3) && shared_fill;
    assign e_sg=(text_region==3) && shared_edge;
    assign c_sg=text_index;
    assign r_sg=shared_row;
    assign f_bt=(text_region==4) && shared_fill;
    assign e_bt=(text_region==4) && shared_edge;
    assign c_bt=text_index;
    assign r_bt=shared_row;
    assign f_so=(text_region==5) && shared_fill;
    assign e_so=(text_region==5) && shared_edge;
    assign c_so=text_index;
    assign r_so=shared_row;
    assign f_ss=(text_region==6) && shared_fill;
    assign e_ss=(text_region==6) && shared_edge;
    assign c_ss=text_index;
    assign r_ss=shared_row;
    assign f_vs=(text_region==7) && shared_fill;
    assign e_vs=(text_region==7) && shared_edge;
    assign c_vs=text_index;
    assign r_vs=shared_row;
    assign f_sv=(text_region==8) && shared_fill;
    assign e_sv=(text_region==8) && shared_edge;
    assign c_sv=text_index;
    assign r_sv=shared_row;
    assign f_hn=(text_region==9) && shared_fill;
    assign e_hn=(text_region==9) && shared_edge;
    assign c_hn=text_index;
    assign r_hn=shared_row;
 
    // ---------------- Pause text (state 2)
    wire [3:0] c_pa, c_ps, c_ph;
    wire [2:0] r_pa, r_ps, r_ph;
    wire f_pa, e_pa, f_ps, e_ps, f_ph, e_ph;
    assign f_pa=(text_region==10) && shared_fill;
    assign e_pa=(text_region==10) && shared_edge;
    assign c_pa=text_index;
    assign r_pa=shared_row;
    assign f_ps=(text_region==11) && shared_fill;
    assign e_ps=(text_region==11) && shared_edge;
    assign c_ps=text_index;
    assign r_ps=shared_row;
    assign f_ph=(text_region==12) && shared_fill;
    assign e_ph=(text_region==12) && shared_edge;
    assign c_ph=text_index;
    assign r_ph=shared_row;
 
    // ---------------- Game-over text (state 3)
    wire [3:0] c_go, c_gs, c_gb, c_gn, c_gh;
    wire [2:0] r_go, r_gs, r_gb, r_gn, r_gh;
    wire f_go, e_go, f_gs, e_gs, f_gb, e_gb, f_gn, e_gn, f_gh, e_gh;
    assign f_go=(text_region==13) && shared_fill;
    assign e_go=(text_region==13) && shared_edge;
    assign c_go=text_index;
    assign r_go=shared_row;
    assign f_gs=(text_region==14) && shared_fill;
    assign e_gs=(text_region==14) && shared_edge;
    assign c_gs=text_index;
    assign r_gs=shared_row;
    assign f_gb=(text_region==15) && shared_fill;
    assign e_gb=(text_region==15) && shared_edge;
    assign c_gb=text_index;
    assign r_gb=shared_row;
    assign f_gn=(text_region==16) && shared_fill;
    assign e_gn=(text_region==16) && shared_edge;
    assign c_gn=text_index;
    assign r_gn=shared_row;
    assign f_gh=(text_region==17) && shared_fill;
    assign e_gh=(text_region==17) && shared_edge;
    assign c_gh=text_index;
    assign r_gh=shared_row;
    always @(*) begin
        text_region=0;text_dx=0;text_dy=0;text_char=8'h20;
        text_index=0;text_chars=0;
        if(state==2'd0 && x>=10'd40 && x<10'd360 &&
           y>=10'd20 && y<10'd92) begin
            text_region=5'd1;
            text_dx=((x-10'd40)>>3) & 10'd7;
            text_dy=(y-10'd20)>>3;
            text_index=(x-10'd40)>>6;
            text_chars="FRUIT";
            text_char=text_chars[(5-1-((x-10'd40)>>6))*8+:8];
        end
        if(state==2'd0 && x>=10'd270 && x<10'd590 &&
           y>=10'd95 && y<10'd167) begin
            text_region=5'd2;
            text_dx=((x-10'd270)>>3) & 10'd7;
            text_dy=(y-10'd95)>>3;
            text_index=(x-10'd270)>>6;
            text_chars="SLASH";
            text_char=text_chars[(5-1-((x-10'd270)>>6))*8+:8];
        end
        if(state==2'd0 && x>=10'd152 && x<10'd488 &&
           y>=10'd182 && y<10'd200) begin
            text_region=5'd3;
            text_dx=((x-10'd152)>>1) & 10'd7;
            text_dy=(y-10'd182)>>1;
            text_index=(x-10'd152)>>4;
            text_chars=" SLASH FRUIT TO ENTER";
            text_char=text_chars[(21-1-((x-10'd152)>>4))*8+:8];
        end
        if(state==2'd0 && x>=10'd240 && x<10'd400 &&
           y>=10'd440 && y<10'd458) begin
            text_region=5'd4;
            text_dx=((x-10'd240)>>1) & 10'd7;
            text_dy=(y-10'd440)>>1;
            text_index=(x-10'd240)>>4;
            text_chars={"BEST ", num5(bs_bcd)};
            text_char=text_chars[(10-1-((x-10'd240)>>4))*8+:8];
        end
        if(state==2'd0 && x>=10'd64 && x<10'd192 &&
           y>=10'd332 && y<10'd368) begin
            text_region=5'd5;
            text_dx=((x-10'd64)>>2) & 10'd7;
            text_dy=(y-10'd332)>>2;
            text_index=(x-10'd64)>>5;
            text_chars="SOLO";
            text_char=text_chars[(4-1-((x-10'd64)>>5))*8+:8];
        end
        if(state==2'd0 && x>=10'd64 && x<10'd192 &&
           y>=10'd376 && y<10'd394) begin
            text_region=5'd6;
            text_dx=((x-10'd64)>>1) & 10'd7;
            text_dy=(y-10'd376)>>1;
            text_index=(x-10'd64)>>4;
            text_chars="1 PLAYER";
            text_char=text_chars[(8-1-((x-10'd64)>>4))*8+:8];
        end
        if(state==2'd0 && x>=10'd224 && x<10'd416 &&
           y>=10'd332 && y<10'd368) begin
            text_region=5'd7;
            text_dx=((x-10'd224)>>2) & 10'd7;
            text_dy=(y-10'd332)>>2;
            text_index=(x-10'd224)>>5;
            text_chars="VERSUS";
            text_char=text_chars[(6-1-((x-10'd224)>>5))*8+:8];
        end
        if(state==2'd0 && x>=10'd280 && x<10'd360 &&
           y>=10'd376 && y<10'd394) begin
            text_region=5'd8;
            text_dx=((x-10'd280)>>1) & 10'd7;
            text_dy=(y-10'd376)>>1;
            text_index=(x-10'd280)>>4;
            text_chars="1 V 1";
            text_char=text_chars[(5-1-((x-10'd280)>>4))*8+:8];
        end
        if(state==2'd0 && x>=10'd144 && x<10'd496 &&
           y>=10'd410 && y<10'd428) begin
            text_region=5'd9;
            text_dx=((x-10'd144)>>1) & 10'd7;
            text_dy=(y-10'd410)>>1;
            text_index=(x-10'd144)>>4;
            text_chars="HOLD CLICK AND SWIPE  ";
            text_char=text_chars[(22-1-((x-10'd144)>>4))*8+:8];
        end
        if(state==2'd2 && x>=10'd128 && x<10'd512 &&
           y>=10'd150 && y<10'd222) begin
            text_region=5'd10;
            text_dx=((x-10'd128)>>3) & 10'd7;
            text_dy=(y-10'd150)>>3;
            text_index=(x-10'd128)>>6;
            text_chars="PAUSED";
            text_char=text_chars[(6-1-((x-10'd128)>>6))*8+:8];
        end
        if(state==2'd2 && x>=10'd144 && x<10'd496 &&
           y>=10'd235 && y<10'd271) begin
            text_region=5'd11;
            text_dx=((x-10'd144)>>2) & 10'd7;
            text_dy=(y-10'd235)>>2;
            text_index=(x-10'd144)>>5;
            text_chars={"SCORE ", num5(sc_bcd)};
            text_char=text_chars[(11-1-((x-10'd144)>>5))*8+:8];
        end
        if(state==2'd2 && x>=10'd168 && x<10'd472 &&
           y>=10'd290 && y<10'd308) begin
            text_region=5'd12;
            text_dx=((x-10'd168)>>1) & 10'd7;
            text_dy=(y-10'd290)>>1;
            text_index=(x-10'd168)>>4;
            text_chars="LOWER SW0 TO RESUME";
            text_char=text_chars[(19-1-((x-10'd168)>>4))*8+:8];
        end
        if(state==2'd3 && x>=10'd32 && x<10'd608 &&
           y>=10'd50 && y<10'd122) begin
            text_region=5'd13;
            text_dx=((x-10'd32)>>3) & 10'd7;
            text_dy=(y-10'd50)>>3;
            text_index=(x-10'd32)>>6;
            text_chars="GAME OVER";
            text_char=text_chars[(9-1-((x-10'd32)>>6))*8+:8];
        end
        if(state==2'd3 && x>=10'd144 && x<10'd496 &&
           y>=10'd160 && y<10'd196) begin
            text_region=5'd14;
            text_dx=((x-10'd144)>>2) & 10'd7;
            text_dy=(y-10'd160)>>2;
            text_index=(x-10'd144)>>5;
            text_chars={"SCORE ", num5(sc_bcd)};
            text_char=text_chars[(11-1-((x-10'd144)>>5))*8+:8];
        end
        if(state==2'd3 && x>=10'd144 && x<10'd496 &&
           y>=10'd205 && y<10'd241) begin
            text_region=5'd15;
            text_dx=((x-10'd144)>>2) & 10'd7;
            text_dy=(y-10'd205)>>2;
            text_index=(x-10'd144)>>5;
            text_chars={"BEST  ", num5(bs_bcd)};
            text_char=text_chars[(11-1-((x-10'd144)>>5))*8+:8];
        end
        if(state==2'd3 && x>=10'd176 && x<10'd464 &&
           y>=10'd255 && y<10'd291) begin
            text_region=5'd16;
            text_dx=((x-10'd176)>>2) & 10'd7;
            text_dy=(y-10'd255)>>2;
            text_index=(x-10'd176)>>5;
            text_chars="NEW BEST!";
            text_char=text_chars[(9-1-((x-10'd176)>>5))*8+:8];
        end
        if(state==2'd3 && x>=10'd168 && x<10'd472 &&
           y>=10'd375 && y<10'd393) begin
            text_region=5'd17;
            text_dx=((x-10'd168)>>1) & 10'd7;
            text_dy=(y-10'd375)>>1;
            text_index=(x-10'd168)>>4;
            text_chars="PRESS BTNC TO RETRY";
            text_char=text_chars[(19-1-((x-10'd168)>>4))*8+:8];
        end
    end
    wire new_best = (score != 0) && (score >= best_score);
 
    // ---------------- Mode boards (title): slice one to choose and start at once
    localparam LX0 = 60,  LX1 = 290, RX0 = 350, RX1 = 580, BY0 = 215, BY1 = 395;
    wire hov_l,hov_r;
    wire unused_l,unused_r;
    menu_fruit_target #(.CX(128),.CY(280),.R(30)) left_target(
      .clk(clk),.trigger(blade_event),.x(x),.y(y),.x0(previous_x),.y0(previous_y),.x1(cursor_x),.y1(cursor_y),.pixel(unused_l),.hit(hov_l));
    menu_fruit_target #(.CX(320),.CY(280),.R(30)) right_target(
      .clk(clk),.trigger(blade_event),.x(x),.y(y),.x0(previous_x),.y0(previous_y),.x1(cursor_x),.y1(cursor_y),.pixel(unused_r),.hit(hov_r));
    reg was_slashing=0;
    wire mode_cut=state==0 && !menu_locked && !menu_busy && blade_event==0 &&
      slash_active && was_slashing && (previous_x!=cursor_x || previous_y!=cursor_y) && (hov_l || hov_r);
    wire menu_done,menu_fx;wire [11:0] menu_fx_rgb;
    menu_cut_animation mode_animation(.clk(clk),.reset(reset || state!=0),.tick(tick),
      .trigger(mode_cut),.cx(mode ? 10'd320:10'd128),.cy(10'd280),
      .colour(mode ? 12'h5B3:12'hF80),.x(x),.y(y),.busy(menu_busy),.done(menu_done),.pixel(menu_fx),.rgb(menu_fx_rgb));
    always @(posedge clk) begin
      was_slashing<=slash_active;start_req<=0;
      if(reset) mode<=0;
      else begin
       if(mode_cut) mode<=hov_r;
       if(menu_done && state==0) start_req<=1;
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
    wire signed [10:0] lx = sx - 11'sd128, ly = sy - 11'sd280;
    wire signed [10:0] rx = sx - 11'sd320, ry = sy - 11'sd280;
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
                if ((orange || leaf) && !(menu_busy && !mode)) begin
                    next_on = 1; next_rgb = wood;
                    if (gold_l) next_rgb = 12'hFC0;
                    if (bord_l) next_rgb = hov_l ? 12'hF33 : 12'h811;
                    if (orange) begin
                        next_rgb = (l2 > 650) ? 12'hC50 : 12'hF80;
                        if (hl2 <= 40) next_rgb = 12'hFD8;
                    end
                    if (leaf) next_rgb = 12'h3B2;
                end
                if (melon && !(menu_busy && mode)) begin
                    next_on = 1; next_rgb = wood;
                    if (gold_r) next_rgb = 12'hFC0;
                    if (bord_r) next_rgb = hov_r ? 12'hF33 : 12'h811;
                    if (melon && !(menu_busy && mode)) begin
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


        if(menu_fx && state==0) begin next_on=1;next_rgb=menu_fx_rgb;end
    end
 
    // One register stage: a pixel lasts four 100 MHz clocks, so this is invisible.
    always @(posedge clk) begin
        ui_on  <= next_on;
        ui_rgb <= next_rgb;
    end
endmodule
// Settings and a procedural katana cursor share the existing source file.
module cursor_settings(
 input clk,reset,back,tick,blade_event,menu_locked,input [1:0] state,
 output menu_busy,
 input [9:0] x,y,cx,cy,px,py,input held,
 output reg [1:0] sensitivity=0,output reg opened=0,
 output panel_on,output reg [11:0] panel_rgb,
 output reg sword_on,output reg [11:0] sword_rgb
);
 wire settings_done,settings_fx;wire [11:0] settings_fx_rgb;
 reg last_held=0;
 reg [2:0] swing=0;
 wire click=held && !last_held;
 wire button_hover,settings_fruit;
 menu_fruit_target #(.CX(512),.CY(280),.R(30)) settings_target(
   .clk(clk),.trigger(blade_event),.x(x),.y(y),.x0(px),.y0(py),.x1(cx),.y1(cy),.pixel(settings_fruit),.hit(button_hover));
 wire settings_cut=!opened && !menu_locked && !menu_busy && held && last_held && (cx!=px || cy!=py) && button_hover;
 wire gain_hover=cx>=176 && cx<464 && cy>=220 && cy<264;
 wire back_hover=cx>=240 && cx<400 && cy>=320 && cy<352;
 always @(posedge clk) begin
  last_held<=held;
  if(reset) begin opened<=0;sensitivity<=0;swing<=0;end
  else begin
   if(back || state!=0) opened<=0;
   else if(settings_done) opened<=1;
   else if(click) begin
    if(opened && back_hover) opened<=0;
    else if(opened && gain_hover) sensitivity<=sensitivity+1'b1;
   end
   if(!held) swing<=0;
   else if(tick && (cx!=px || cy!=py)) swing<=swing+1'b1;
  end
 end

 menu_cut_animation settings_animation(.clk(clk),.reset(reset||back||state!=0),.tick(tick),
 .trigger(settings_cut),.cx(10'd512),.cy(10'd280),.colour(12'hD35),.x(x),.y(y),
 .busy(menu_busy),.done(settings_done),.pixel(settings_fx),.rgb(settings_fx_rgb));
 wire title_text,gain_text,back_text,settings_text;
 wire [127:0] gain_label=sensitivity==0 ? "SENSITIVITY 1X   ":
   sensitivity==1 ? "SENSITIVITY 0.5X ":sensitivity==2 ? "SENSITIVITY 2X   ":"SENSITIVITY 4X   ";
 text_line #(.LEN(8),.K(1),.X0(256),.Y0(144)) settings_title(.x(x),.y(y),.chars("SETTINGS"),.on(title_text));
 text_line #(.LEN(16),.K(1),.X0(192),.Y0(232)) gain_label_text(.x(x),.y(y),.chars(gain_label),.on(gain_text));
 text_line #(.LEN(4),.K(1),.X0(288),.Y0(328)) back_label(.x(x),.y(y),.chars("BACK"),.on(back_text));
 text_line #(.LEN(8),.K(1),.X0(448),.Y0(340)) settings_label(.x(x),.y(y),.chars("SETTINGS"),.on(settings_text));
 wire settings_box=x>=240 && x<400 && y>=430 && y<454;
 assign panel_on=state==0 && (opened || (settings_fruit && !menu_busy) || settings_text || settings_fx);
 always @(*) begin
  panel_rgb=12'h321;
  if(opened) begin
   if(x>=176 && x<464 && y>=220 && y<264) panel_rgb=gain_hover ? 12'h963:12'h642;
   if(x>=240 && x<400 && y>=320 && y<352) panel_rgb=back_hover ? 12'h963:12'h642;
   if(title_text || gain_text || back_text) panel_rgb=12'hFEA;
  end else begin
   panel_rgb=x<512 && y<280 ? 12'hF8A:12'hC24;
   if(settings_fruit && x[2:0]==3 && y[2:0]==3) panel_rgb=12'hFE8;
   if(settings_text) panel_rgb=12'hFEA;
   if(settings_fx) panel_rgb=settings_fx_rgb;
  end
 end
 wire signed [11:0] dx=$signed({2'b0,x})-$signed({2'b0,cx});
 wire signed [11:0] dy=$signed({2'b0,y})-$signed({2'b0,cy});
 // Tilt the drawn blade during movement, with the grip anchored to the cursor.
 wire signed [11:0] across=held ? dx+(swing[2] ? -(dy>>>1):(dy>>>1)):dx;
 always @(*) begin
  sword_on=0;sword_rgb=0;
  if(across>=-2 && across<=2 && dy>=-27 && dy<=-4) begin
   sword_on=1;sword_rgb=held ? (across==2 ? 12'hFFF:12'hBCD):12'h421;
  end
  if(across>=-5 && across<=5 && dy>=-3 && dy<=-1) begin sword_on=1;sword_rgb=12'hDA4;end
  if(across>=-2 && across<=2 && dy>=0 && dy<=9) begin sword_on=1;sword_rgb=dy[1] ? 12'hA43:12'h321;end
 end
endmodule

// Convex octagonal fruit mask with sampled swipe intersection.
module menu_fruit_target #(parameter CX=0,CY=0,R=30)(
 input clk,trigger,input [9:0] x,y,x0,y0,x1,y1,output pixel,output reg hit=0);
 wire signed [11:0] dx=$signed({2'b0,x})-CX,dy=$signed({2'b0,y})-CY;
 wire [11:0] ax=dx<0 ? -dx:dx,ay=dy<0 ? -dy:dy;
 assign pixel=ax<=R && ay<=R && ax+ay<=R+(R>>1);
 reg busy=0;reg [4:0] step=0;
 reg signed [15:0] walk_x=0,walk_y=0;
 reg signed [10:0] delta_x=0,delta_y=0;
 wire signed [11:0] tx=(walk_x>>>4)-CX,ty=(walk_y>>>4)-CY;
 wire [11:0] adx=tx<0 ? -tx:tx,ady=ty<0 ? -ty:ty;
 always @(posedge clk) begin
 hit<=0;
 if(trigger) begin
  walk_x<=$signed({2'b0,x0,4'b0});walk_y<=$signed({2'b0,y0,4'b0});
  delta_x<=$signed({1'b0,x1})-$signed({1'b0,x0});
  delta_y<=$signed({1'b0,y1})-$signed({1'b0,y0});
  step<=0;busy<=1;
 end else if(busy) begin
  if(adx<=R && ady<=R && adx+ady<=R+(R>>1)) begin hit<=1;busy<=0;end
  else if(step==16) busy<=0;
  else begin walk_x<=walk_x+delta_x;walk_y<=walk_y+delta_y;step<=step+1'b1;end
 end
 end
endmodule

// BTND asks first; a fresh click or BTNC confirms. BTND again cancels.
module quit_confirmation(
 input clk,reset,request,confirm_button,input [1:0] state,
 input held,input [9:0] cx,cy,x,y,
 output reg opened=0,output reg confirmed=0,
 output pixel_on,output reg [11:0] rgb);
 reg previous_held=0;
 wire click=held && !previous_held;
 wire menu_hover=cx>=208 && cx<432 && cy>=360 && cy<400;
 wire menu_box=state==2 && !opened && x>=208 && x<432 && y>=360 && y<400;
 wire menu_text;
 text_line #(.LEN(9),.K(1),.X0(248),.Y0(372)) menu_label(.x(x),.y(y),.chars("MAIN MENU"),.on(menu_text));
 wire yes_hover=cx>=128 && cx<304 && cy>=256 && cy<304;
 wire no_hover=cx>=336 && cx<512 && cy>=256 && cy<304;
 always @(posedge clk) begin
  previous_held<=held;confirmed<=0;
  if(reset || state==0) opened<=0;
  else if(opened) begin
   if(request || (click && no_hover)) opened<=0;
   else if(confirm_button || (click && yes_hover)) begin opened<=0;confirmed<=1;end
  end else if(request || (state==2 && click && menu_hover)) opened<=1;
 end
 wire question,yes_text,no_text;
 text_line #(.LEN(13),.K(1),.X0(216),.Y0(192)) q(.x(x),.y(y),.chars("QUIT TO MENU?"),.on(question));
 text_line #(.LEN(4),.K(1),.X0(184),.Y0(272)) a(.x(x),.y(y),.chars("QUIT"),.on(yes_text));
 text_line #(.LEN(6),.K(1),.X0(376),.Y0(272)) b(.x(x),.y(y),.chars("CANCEL"),.on(no_text));
 assign pixel_on=menu_box || (opened && x>=96 && x<544 && y>=160 && y<336);
 always @(*) begin
  rgb=12'h321;
  if(x>=128 && x<304 && y>=256 && y<304) rgb=yes_hover ? 12'hD43:12'h822;
  if(x>=336 && x<512 && y>=256 && y<304) rgb=no_hover ? 12'h5A5:12'h353;
  if(question || yes_text || no_text) rgb=12'hFFE;
  if(menu_box) begin
   rgb=menu_hover ? 12'h963:12'h642;
   if(menu_text) rgb=12'hFFE;
  end
 end
endmodule

// About one second at the existing ~60 Hz frame tick. Small arithmetic masks only.
module menu_cut_animation(input clk,reset,tick,trigger,input [9:0] cx,cy,x,y,
 input [11:0] colour,output reg busy=0,output reg done=0,output pixel,output [11:0] rgb);
 reg [5:0] age=0;
 always @(posedge clk) begin
 done<=0;
 if(reset) begin busy<=0;age<=0;end
 else if(trigger && !busy) begin busy<=1;age<=0;end
 else if(busy && tick) begin
 if(age==59) begin busy<=0;done<=1;end else age<=age+1'b1;
 end
 end
 wire signed [11:0] dx=$signed({2'b0,x})-$signed({2'b0,cx});
 wire signed [11:0] dy=$signed({2'b0,y})-$signed({2'b0,cy});
 wire [11:0] ax=dx<0 ? -dx:dx,ay=dy<0 ? -dy:dy;
 wire [11:0] spread=12'd15+{7'd0,age[5:1]};
 wire splat=ax+ay<spread || (ax<4 && ay<spread+16) || (ay<3 && ax<spread+18);
 wire signed [11:0] piece_x=dx<0 ? dx+$signed({6'd0,age}) : dx-$signed({6'd0,age});
 wire signed [11:0] piece_y=dy-$signed({6'd0,age});
 wire [11:0] apx=piece_x<0 ? -piece_x:piece_x,apy=piece_y<0 ? -piece_y:piece_y;
 wire pieces=apx<30 && apy<30 && apx+apy<43 && (dx<0 ? piece_x<0:piece_x>=0);
 assign pixel=busy && (splat || pieces);
 assign rgb=pieces ? (apx<2 ? 12'hFFE:colour):{1'b0,colour[11:9],1'b0,colour[7:5],1'b0,colour[3:1]};
endmodule
