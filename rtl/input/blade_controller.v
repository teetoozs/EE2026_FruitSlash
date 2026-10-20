// Aloysius: supplied MouseCtl uses 12-bit coordinates, despite old comments.
module blade_controller (
    input            clk,
    input            reset,
    input            game_tick,
    input            fallback,
    input      [4:0] held,
    inout            PS2Clk,
    inout            PS2Data,
    output reg [9:0] cursor_x = 320,
    output reg [9:0] cursor_y = 240,
    output reg [9:0] previous_x = 320,
    output reg [9:0] previous_y = 240,
    output reg       slash_active = 0,
    output reg       blade_event = 0
);
    wire [11:0] mx, my;
    wire left_button, new_event;
    reg  [ 2:0] config_step = 0;
    wire [11:0] config_value = (config_step == 0) ? 12'd639 : 12'd479;
    MouseCtl mouse (
        .clk      (clk),
        .rst      (reset),
        .xpos     (mx),
        .ypos     (my),
        .zpos     (),
        .left     (left_button),
        .middle   (),
        .right    (),
        .new_event(new_event),
        .value    (config_value),
        .setx     (1'b0),
        .sety     (1'b0),
        .setmax_x (config_step == 0),
        .setmax_y (config_step == 1),
        .ps2_clk  (PS2Clk),
        .ps2_data (PS2Data)
    );
    reg [9:0] fx = 320, fy = 240;
    reg old_fallback = 0;
    always @(posedge clk) begin
        blade_event <= 0;
        if (reset) begin
            config_step  <= 0;
            cursor_x     <= 320;
            cursor_y     <= 240;
            previous_x   <= 320;
            previous_y   <= 240;
            fx           <= 320;
            fy           <= 240;
            slash_active <= 0;
            old_fallback <= fallback;
        end else begin
            if (config_step < 2) config_step <= config_step + 1'b1;
            old_fallback <= fallback;
            if (fallback != old_fallback) begin
                // Mode change is not a physical swipe across the screen.
                slash_active <= 0;
                if (fallback) begin
                    cursor_x <= fx;
                    cursor_y <= fy;
                end else begin
                    cursor_x <= mx > 639 ? 639 : mx[9:0];
                    cursor_y <= my > 479 ? 479 : my[9:0];
                end
            end else if (fallback && game_tick) begin
                previous_x <= cursor_x;
                previous_y <= cursor_y;
                if (held[3] && !held[4] && fx >= 4) fx <= fx - 4;
                else if (held[4] && !held[3] && fx <= 635) fx <= fx + 4;
                if (held[1] && !held[2] && fy >= 4) fy <= fy - 4;
                else if (held[2] && !held[1] && fy <= 475) fy <= fy + 4;
                cursor_x     <= fx;
                cursor_y     <= fy;
                slash_active <= held[0];
                blade_event  <= 1;
            end else if (!fallback && new_event) begin
                previous_x   <= cursor_x;
                previous_y   <= cursor_y;
                cursor_x     <= mx > 639 ? 639 : mx[9:0];
                cursor_y     <= my > 479 ? 479 : my[9:0];
                slash_active <= left_button;
                blade_event  <= 1;
            end
        end
    end
    // TODO: trail history/fade, pointer sprite, explicit mode-entry recenter.
endmodule
