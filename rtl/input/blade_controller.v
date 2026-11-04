// Aloysius: supplied MouseCtl uses 12-bit coordinates, despite old comments.
module blade_controller (
    input            clk,
    input            reset,
    input            game_tick,
    input            fallback,
    input [1:0] sensitivity,
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
    reg [1:0] old_sensitivity=0;
    wire [1:0] gain = sensitivity==1 ? 0 : sensitivity==2 ? 2 : sensitivity==3 ? 3:1;
    wire [11:0] max_x = gain==0 ? 1278:gain==2 ? 319:gain==3 ? 159:639;
    wire [11:0] max_y = gain==0 ? 958:gain==2 ? 239:gain==3 ? 119:479;
    wire [11:0] config_value = config_step==0 ? max_x:max_y;
    wire [13:0] scaled_x= gain==0 ? mx>>1 : gain==2 ? {mx,1'b0}:gain==3 ? {mx,2'b0}:mx;
    wire [13:0] scaled_y= gain==0 ? my>>1 : gain==2 ? {my,1'b0}:gain==3 ? {my,2'b0}:my;
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
            old_sensitivity<=sensitivity;
            if(old_sensitivity!=sensitivity) config_step<=0;
            else if (config_step < 2) config_step <= config_step + 1'b1;
            old_fallback <= fallback;
            if (fallback != old_fallback) begin
                // Mode change is not a physical swipe across the screen.
                slash_active <= 0;
                if (fallback) begin
                    cursor_x <= fx;
                    cursor_y <= fy;
                end else begin
                    cursor_x <= scaled_x > 639 ? 639 : scaled_x[9:0];
                    cursor_y <= scaled_y > 479 ? 479 : scaled_y[9:0];
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
                cursor_x     <= scaled_x > 639 ? 639 : scaled_x[9:0];
                cursor_y     <= scaled_y > 479 ? 479 : scaled_y[9:0];
                slash_active <= left_button;
                blade_event  <= 1;
            end
        end
    end
    // TODO: trail history/fade, pointer sprite, explicit mode-entry recenter.
endmodule
