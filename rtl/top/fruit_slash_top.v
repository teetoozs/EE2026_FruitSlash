module fruit_slash_top (
    input         clk,
    input  [15:0] sw,
    input         btnC,
    input         btnU,
    input         btnD,
    input         btnL,
    input         btnR,
    inout         PS2Clk,
    inout         PS2Data,
    output [ 3:0] vgaRed,
    output [ 3:0] vgaGreen,
    output [ 3:0] vgaBlue,
    output        Hsync,
    output        Vsync,
    output [ 7:0] JB,
    output [15:0] led,
    output [ 3:0] an,
    output [ 7:0] seg
);
    localparam N = 8;
    // SW15 reset; SW3 fallback; SW2 pause; SW1:0 difficulty.
    (* ASYNC_REG="TRUE" *) reg [15:0] sw_meta = 0, sw_sync = 0;
    reg [7:0] power_count = 0;
    always @(posedge clk) begin
        sw_meta <= sw;
        sw_sync <= sw_meta;
        if (power_count != 255) power_count <= power_count + 1'b1;
    end
    wire reset = (power_count != 255) || sw_sync[15];
    wire [4:0] held, pressed;
    button_handler buttons (
        .clk    (clk),
        .reset  (reset),
        .raw    ({btnR, btnL, btnD, btnU, btnC}),
        .held   (held),
        .pressed(pressed)
    );
    wire game_tick;
    tick_generator tick (
        .clk  (clk),
        .reset(reset),
        .tick (game_tick)
    );
    wire [9:0] cursor_x, cursor_y, previous_x, previous_y;
    wire slash_active, blade_event;
    blade_controller blade (
        .clk         (clk),
        .reset       (reset),
        .game_tick   (game_tick),
        .fallback    (sw_sync[3]),
        .held        (held),
        .PS2Clk      (PS2Clk),
        .PS2Data     (PS2Data),
        .cursor_x    (cursor_x),
        .cursor_y    (cursor_y),
        .previous_x  (previous_x),
        .previous_y  (previous_y),
        .slash_active(slash_active),
        .blade_event (blade_event)
    );
    wire [N-1:0] active, bomb, hit_mask, raw_hit_mask;
    wire slice_busy;
    wire [N*16-1:0] positions_x, positions_y;
    wire playing, new_round;
    assign hit_mask = raw_hit_mask & active & {N{playing}};
    wire [1:0] state, lives;
    wire [15:0] score, best_score;
    wire [7:0] combo;
    game_controller #(
        .N(N)
    ) game (
        .clk          (clk),
        .reset        (reset),
        .start_pressed(pressed[0]),
        .pause        (sw_sync[2]),
        .slash_active (slash_active),
        .hit_mask     (hit_mask),
        .bomb         (bomb),
        .state        (state),
        .playing      (playing),
        .new_round    (new_round),
        .score        (score),
        .best_score   (best_score),
        .lives        (lives),
        .combo        (combo)
    );
    object_physics #(
        .N(N)
    ) objects (
        .clk        (clk),
        .reset      (reset || new_round),
        .game_tick  (game_tick && !slice_busy),
        .playing    (playing),
        .difficulty (sw_sync[1:0]),
        .remove_mask(hit_mask),
        .active     (active),
        .bomb       (bomb),
        .positions_x(positions_x),
        .positions_y(positions_y)
    );
    slice_detector #(
        .N(N)
    ) slicing (
        .clk         (clk),
        .reset       (reset || new_round),
        .playing     (playing),
        .blade_event (blade_event),
        .slash_active(slash_active),
        .x0          (previous_x),
        .y0          (previous_y),
        .x1          (cursor_x),
        .y1          (cursor_y),
        .active      (active),
        .positions_x (positions_x),
        .positions_y (positions_y),
        .hit_mask    (raw_hit_mask),
        .busy        (slice_busy)
    );
    wire signed [15:0] effect_x, effect_y;
    wire [5:0] ttl;
    cut_effects #(
        .N(N)
    ) effects (
        .clk        (clk),
        .reset      (reset || new_round),
        .game_tick  (game_tick),
        .playing    (playing),
        .hit_mask   (hit_mask),
        .positions_x(positions_x),
        .positions_y(positions_y),
        .effect_x   (effect_x),
        .effect_y   (effect_y),
        .ttl        (ttl)
    );
    wire [9:0] pixel_x, pixel_y;
    wire video_on;
    wire [11:0] rgb;
    vga_timing timing (
        .clk     (clk),
        .reset   (reset),
        .x       (pixel_x),
        .y       (pixel_y),
        .video_on(video_on),
        .Hsync   (Hsync),
        .Vsync   (Vsync)
    );
    pixel_compositor #(
        .N(N)
    ) compositor (
        .x           (pixel_x),
        .y           (pixel_y),
        .video_on    (video_on),
        .state       (state),
        .cursor_x    (cursor_x),
        .cursor_y    (cursor_y),
        .slash_active(slash_active),
        .active      (active),
        .bomb        (bomb),
        .positions_x (positions_x),
        .positions_y (positions_y),
        .effect_x    (effect_x),
        .effect_y    (effect_y),
        .ttl         (ttl),
        .rgb         (rgb)
    );
    assign {vgaRed, vgaGreen, vgaBlue} = rgb;
    board_displays board (
        .clk  (clk),
        .score(score),
        .lives(lives),
        .state(state),
        .an   (an),
        .seg  (seg),
        .led  (led)
    );
    sensei_panel oled (
        .clk       (clk),
        .reset     (reset),
        .lives     (lives),
        .difficulty(sw_sync[1:0]),
        .state     (state),
        .combo     (combo),
        .JB        (JB)
    );
endmodule
