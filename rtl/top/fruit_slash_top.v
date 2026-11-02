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
    // SW15 reset; SW3 fallback; SW0 pause; SW2:1 difficulty.
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
    wire [8:0] explosion_age;
    wire bonus_active, bonus_award, bonus_contact, bonus_busy;
    wire bonus_visible, bonus_accepting, bonus_cutting, bonus_falling;
    wire [15:0] bonus_x, bonus_y;
    wire [5:0] bonus_radius;
    wire [6:0] bonus_fall_age;
    wire [8:0] bonus_remaining;
    wire [7:0] streak;
    wire [N-1:0] missed;
    wire gameplay_enabled = playing && !bomb_busy && !bonus_active;
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
    // Hold the visible cursor and hearts with the world during the cinematic.
    reg [9:0] frozen_cursor_x = 0, frozen_cursor_y = 0;
    reg frozen_slash = 0;
    reg [11:0] frozen_hearts = 0;
    always @(posedge clk) begin
        if (!bomb_busy) begin
            frozen_cursor_x <= cursor_x;
            frozen_cursor_y <= cursor_y;
            frozen_slash <= slash_active;
            frozen_hearts <= heart_levels;
        end
    end
    wire [N*5-1:0] radii;
    genvar slot;
    generate
        for (slot = 0; slot < N; slot = slot + 1) begin : fruit_sizes
            assign radii[slot*5+:5] = bomb[slot] ? 5'd18 :
                                  (slot%2==0 ? 5'd12 : 5'd18);
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
    wire [2:0] multiplier;
    wire ui_on, ui_start, game_mode;
    wire [11:0] ui_rgb;
    wire [9:0] pixel_x, pixel_y;
    ui_screens ui (
        .clk(clk), .x(pixel_x), .y(pixel_y), .state(state),
        .score(score), .best_score(best_score),
        .cursor_x(cursor_x), .cursor_y(cursor_y),
        .slash_active(slash_active), .btn_start(pressed[0]),
        .ui_on(ui_on), .ui_rgb(ui_rgb),
        .mode(game_mode), .start_req(ui_start)
    );
    game_controller #(
        .N(N)
    ) game (
        .clk          (clk),
        .reset        (reset),
        .start_pressed(pressed[0] || ui_start),
        .pause        (sw_sync[0]),
        .effects_busy (bomb_busy),
        .missed(missed), .bonus_hit(bonus_award),
        .slash_active (slash_active),
        .hit_mask     (hit_mask),
        .bomb         (bomb),
        .state        (state),
        .playing      (playing),
        .new_round    (new_round),
        .score        (score),
        .best_score   (best_score),
        .lives        (lives),
        .combo        (combo),
        .multiplier   (multiplier)
    );
    object_physics #(
        .N(N)
    ) objects (
        .clk        (clk),
        .reset      (reset || new_round),
        .game_tick  (game_tick && !slice_busy && !bomb_busy && !(|raw_hit_mask) && !(|destroyed) && !bonus_contact),
        .playing    (gameplay_enabled),
        .difficulty (sw_sync[2:1]),
        .remove_mask(hit_mask),
        .missed(missed),
        .active     (active),
        .bomb       (bomb),
        .positions_x(positions_x),
        .positions_y(positions_y)
    );
    slice_detector #(
        .N(N),
        .VARIABLE_RADIUS(1), .SIZE_SHIFT(1)
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
        .paused(sw_sync[0]),
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
    wire wall_on;
    wire [11:0] wall_rgb;
    wall_splats #(.N(N)) wall(.clk(clk),.reset(reset||new_round),.tick(game_tick),
      .playing(gameplay_enabled),.hits(hit_mask),.bomb(bomb),.px(positions_x),.py(positions_y),
      .x(pixel_x),.y(pixel_y),.pixel_on(wall_on),.rgb(wall_rgb));
    streak_bonus #(.N(N)) bonus(.clk(clk),.reset(reset||new_round||state==3),
      .tick(game_tick && !(bonus_busy && !bonus_active)),
      .playing(playing&&!bomb_busy),.slash_active(slash_active),.blade_event(blade_event),
      .contact(bonus_contact),.x0(previous_x),.y0(previous_y),.x1(cursor_x),.y1(cursor_y),
      .hits(hit_mask),.bomb(bomb),.missed(missed),.active(bonus_active),.award(bonus_award),
      .remaining(bonus_remaining),.streak(streak),
      .visible(bonus_visible),.accepting(bonus_accepting),.cutting(bonus_cutting),
      .falling(bonus_falling),.position_x(bonus_x),.position_y(bonus_y),
      .radius(bonus_radius),.fall_age(bonus_fall_age));
    slice_detector #(.N(1),.VARIABLE_RADIUS(1),.SIZE_SHIFT(1)) bonus_slice(
      .clk(clk),.reset(reset||new_round),.playing(playing&&!bomb_busy&&bonus_accepting),
      .blade_event(blade_event),.slash_active(slash_active),.x0(previous_x),.y0(previous_y),
      .x1(cursor_x),.y1(cursor_y),.active(bonus_accepting),.radii(bonus_radius[5:1]),
      .positions_x(bonus_x),.positions_y(bonus_y),.hit_mask(bonus_contact),.busy(bonus_busy));
    wire bonus_view_on, blast_view_on;
    wire [11:0] bonus_view_rgb, blast_view_rgb;
    bonus_fruit_view bonus_view(.clk(clk),.reset(reset||new_round),.active(bonus_visible),
      .falling(bonus_falling),.position_x(bonus_x),.position_y(bonus_y),
      .radius(bonus_radius),.fall_age(bonus_fall_age),.cut(bonus_award),.x0(previous_x),.y0(previous_y),.x1(cursor_x),.y1(cursor_y),
      .x(pixel_x),.y(pixel_y),.pixel_on(bonus_view_on),.rgb(bonus_view_rgb));
    bomb_renderer #(.N(N), .RADIUS(36)) full_blast(.x(pixel_x),.y(pixel_y),.active(explosion_active),
      .origins_x(explosion_x),.origins_y(explosion_y),.age(explosion_age),
      .pixel_on(blast_view_on),.rgb(blast_view_rgb));
    // Timer remains a small overlay; the wood/world are never replaced.
    wire bonus_bar=bonus_cutting && pixel_y>=410 && pixel_y<418 &&
                   pixel_x>=170 && pixel_x<170+bonus_remaining;
    wire bonus_cursor=(pixel_x==cursor_x && pixel_y+6>=cursor_y && pixel_y<=cursor_y+6) ||
                      (pixel_y==cursor_y && pixel_x+6>=cursor_x && pixel_x<=cursor_x+6);
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
        .DETAILED_ART(1), .SIZE_SHIFT(1),
        .VARIABLE_RADIUS(1)
    ) compositor (
        .effect_radii(effect_radii),
        .health      (fruit_health),
        .radii       (radii),
        .heart_levels(bomb_busy ? frozen_hearts : heart_levels),
        .wall_on(wall_on), .wall_rgb(wall_rgb),
        .x           (pixel_x),
        .y           (pixel_y),
        .video_on    (video_on),
        .state       (state),
        .cursor_x    (bomb_busy ? frozen_cursor_x : cursor_x),
        .cursor_y    (bomb_busy ? frozen_cursor_y : cursor_y),
        .slash_active(bomb_busy ? frozen_slash : slash_active),
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
        .explosion_active({N{1'b0}}),
        .explosion_x(explosion_x),
        .explosion_y(explosion_y),
        .explosion_age(explosion_age),
        .rgb         (rgb)
    );
    wire trail_on, popup_on;
    wire [11:0] trail_rgb, popup_rgb;
    white_blade_trail white_trail(
      .clk(clk),.reset(reset||new_round),.game_tick(game_tick),
      .enabled(playing&&!bomb_busy),.blade_event(blade_event),.slash_active(slash_active),
      .previous_x(previous_x),.previous_y(previous_y),.cursor_x(cursor_x),.cursor_y(cursor_y),
      .pixel_x(pixel_x),.pixel_y(pixel_y),.pixel_on(trail_on),.rgb(trail_rgb));
    slice_popups popups(.clk(clk),.reset(reset||new_round),.tick(game_tick),
      .playing(playing),.bomb_busy(bomb_busy),.bonus_active(bonus_active),.bonus_award(bonus_award),
      .combo(combo),.x(pixel_x),.y(pixel_y),.pixel_on(popup_on),.rgb(popup_rgb));
    assign {vgaRed, vgaGreen, vgaBlue} = !video_on ? 12'h000 :
      bomb_busy ? (blast_view_on ? blast_view_rgb : rgb) : popup_on ? popup_rgb :
      (trail_on && pixel_y>=48) ? trail_rgb : ui_on ? ui_rgb : bonus_bar ? 12'hFF4 :
      bonus_visible && bonus_cursor ? (slash_active ? 12'hF00 : 12'hFFF) :
      bonus_view_on ? bonus_view_rgb : rgb;
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
        .difficulty  (sw_sync[2:1]),
        .state       (state),
        .combo       (combo),
        .best_score  (best_score),
        .multiplier  (multiplier),
        .JB          (JB)
    );
endmodule
