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
    wire bomb_busy;
    wire [N-1:0] explosion_active;
    wire [N*16-1:0] explosion_x, explosion_y;
    wire [5:0] explosion_age;
    wire gameplay_enabled = playing && !bomb_busy;
    wire [N-1:0] destroyed;
    wire [N*2-1:0] fruit_health;
    assign hit_mask = destroyed & active & {N{gameplay_enabled}};
    wire [1:0] state, lives;
    wire [11:0] heart_levels;
    life_animation hearts (
        .clk         (clk),
        .reset       (reset || new_round),
        .lives       (lives),
        .heart_levels(heart_levels)
    );
    wire [N*5-1:0] radii;
    genvar slot;
    generate
        for (slot = 0; slot < N; slot = slot + 1) begin : fruit_sizes
            assign radii[slot*5+:5] = bomb[slot] ? 5'd18 :
                                  (slot%3==0 ? 5'd12 : slot%3==1 ? 5'd18 : 5'd24);
        end
    endgenerate
    wire [15:0] score, best_score;
    fruit_damage #(
        .N(N)
    ) damage (
        .clk         (clk),
        .reset       (reset || new_round),
        .playing     (gameplay_enabled),
        .slash_active(slash_active),
        .active      (active),
        .bomb        (bomb),
        .contact     (raw_hit_mask),
        .radii       (radii),
        .destroyed   (destroyed),
        .health      (fruit_health)
    );
    wire [7:0] combo;
    game_controller #(
        .N(N)
    ) game (
        .clk          (clk),
        .reset        (reset),
        .start_pressed(pressed[0]),
        .pause        (sw_sync[2]),
        .effects_busy (bomb_busy),
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
        .game_tick  (game_tick && !slice_busy && !bomb_busy && !(|raw_hit_mask) && !(|destroyed)),
        .playing    (playing),
        .difficulty (sw_sync[1:0]),
        .remove_mask(hit_mask),
        .active     (active),
        .bomb       (bomb),
        .positions_x(positions_x),
        .positions_y(positions_y)
    );
    slice_detector #(
        .N(N),
        .VARIABLE_RADIUS(1)
    ) slicing (
        .radii       (radii),
        .clk         (clk),
        .reset       (reset || new_round),
        .playing     (gameplay_enabled),
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
    bomb_effects #(.N(N)) explosions (
        .clk(clk),
        .reset(reset || new_round),
        .game_tick(game_tick),
        .paused(sw_sync[2]),
        .hit_mask(hit_mask),
        .bomb(bomb),
        .positions_x(positions_x),
        .positions_y(positions_y),
        .busy(bomb_busy),
        .active(explosion_active),
        .origins_x(explosion_x),
        .origins_y(explosion_y),
        .age(explosion_age)
    );
    wire [N-1:0] splash_active;
    wire [N*16-1:0] splash_x, splash_y;
    wire [N*5-1:0] splash_age, effect_radii;
    wire [2*N-1:0] halves_active;
    wire [2*N*16-1:0] halves_x, halves_y;
    cut_effects #(
        .N(N),
        .VARIABLE_RADIUS(1)
    ) effects (
        .radii(radii),
        .effect_radii(effect_radii),
        .clk        (clk),
        .reset      (reset || new_round),
        .game_tick  (game_tick && !(|(hit_mask & bomb))),
        .playing    (gameplay_enabled),
        .hit_mask   (hit_mask),
        .bomb       (bomb),
        .positions_x(positions_x),
        .positions_y(positions_y),
        .splash_active(splash_active),
        .splash_x(splash_x),
        .splash_y(splash_y),
        .splash_age(splash_age),
        .halves_active(halves_active),
        .halves_x    (halves_x),
        .halves_y    (halves_y)
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
        .N(N),
        .DETAILED_ART(1),
        .VARIABLE_RADIUS(1)
    ) compositor (
        .effect_radii(effect_radii),
        .health      (fruit_health),
        .radii       (radii),
        .heart_levels(heart_levels),
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
        .splash_active(splash_active),
        .splash_x(splash_x),
        .splash_y(splash_y),
        .splash_age(splash_age),
        .halves_active(halves_active),
        .halves_x    (halves_x),
        .halves_y    (halves_y),
        .explosion_active(explosion_active),
        .explosion_x(explosion_x),
        .explosion_y(explosion_y),
        .explosion_age(explosion_age),
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
        .heart_levels(heart_levels),
        .clk         (clk),
        .reset       (reset),
        .lives       (lives),
        .difficulty  (sw_sync[1:0]),
        .state       (state),
        .combo       (combo),
        .JB          (JB)
    );
endmodule
