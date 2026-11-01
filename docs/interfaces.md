# Interface contract v3
- One 100 MHz domain for game/input/VGA logic. game_tick is an enable (~60 Hz).
- VGA uses a 25 MHz pixel enable: 800x525 total, 640x480 active (~59.52 Hz).
- OLED driver has a generated 6.25 MHz clock; status uses a bundled-data
  request/ack mailbox. Keep mailbox data stable until acknowledgement.
- Synchronous active-high reset for student modules; startup reset is automatic.
- Objects: N=8, slot i occupies [i*16 +: 16] of each position bus.
- Signed 16-bit Q12.4 positions and velocities. Pixel position = arithmetic >>4.
- Screen origin upper-left; positive y downward. Negative/offscreen positions legal.
- Top supplies a packed 5-bit radius per slot to renderer and collision engine.
  Fruit slots cycle through radii 12, 18, 24; bombs stay radius 18.
  Colours cycle orange, red, green, purple by slot. These are still circular
  placeholder fruit, not detailed sprites. Size/colour remain stable in flight.
  VARIABLE_RADIUS=1 enables the radius bus; default 0 preserves radius 18.
- life_animation supplies three 4-bit heart brightness levels. On life loss,
  only lost hearts blink at 2 Hz for 3 seconds, then fade over about 0.5 seconds.
  Remaining hearts stay lit; restarting restores all three. Animation continues
  while paused or on game-over. OLED snapshots these levels in its status mailbox.
- Physics owns active/bomb/position arrays. hit_mask is one bit per slot.
- Physics selects bottom/top/left/right origins at spawn using LFSR bits 11:10.
  Top drops have zero horizontal speed; sides launch inward with gravity.
- raw_hit_mask is geometric contact. fruit_damage filters repeated contacts
  during one held swipe and emits destroyed. The game/physics/effects hit_mask
  now uses destroyed, so three-hit watermelons score only on their final hit.
  Packed health uses two bits per slot; bombs and normal fruit have one HP.
  Physics is also frozen during contact/destruction delivery to prevent reuse.
- Slice detector now takes clk/reset and returns busy. It snapshots the blade
  segment/object bus and checks one slot in four clocks. With eight slots its
  one-cycle accumulated hit-mask arrives 32 clocks after acceptance.
- Do not send a blade_event while busy. Mouse packets and fallback updates are
  naturally much farther apart than the 330 ns busy transaction at 100 MHz.
- Top gates object game_tick while busy so slots cannot move/recycle mid-scan;
  a coincident game tick may be skipped. Hit output is masked with current
  active/playing flags. Reset, new round or pause aborts pending collisions.
- Removal wins over movement; a removed slot cannot be respawned that same cycle.
- Score adds all simultaneous fruits; lives subtract all simultaneous bomb hits.
- Blade_event accompanies each mouse packet (or fallback update). Coordinates
  form one swept segment. Do not resample it only on game_tick.
- Combo counts fruits during one continuous hold. The k-th fruit of a swipe
  scores 10*min(k, MAX_MULT), MAX_MULT=5, awarded immediately (no release bonus).
  Score saturates at 65535. Best survives round/reset.
- game_controller outputs multiplier[2:0] = multiplier the NEXT fruit will get
  (x1 at the start of a swipe, up to x5). Wired in the top as `multiplier`.
- Pause freezes physics/effects/scoring; pointer remains responsive.
- BTNC press starts/restarts only on title/game-over. During fallback gameplay,
  BTNC held slices. SW15 resets, SW3 selects fallback, SW2 pauses, SW1:0 difficulty.
- State encoding: 0 title, 1 play, 2 pause, 3 over.
- Effects currently retain only first simultaneous hit for a flash. This is a
  deliberate placeholder; final effects need a per-hit queue or independent slots.
- Compositor priority: background, intact objects, flash, cursor, top-right hearts.
  Debug state stripes on VGA and OLED have been removed.
  Full planned layer order is not yet implemented.
- Keep interface changes in this document and notify the consuming module owner.
- best_score[15:0] (session best) goes to the OLED panel (sensei_panel) and to
  ui_screens. OLED mailbox is now 45 bits: {multiplier, best_score, hearts,
  lives, difficulty, state, combo}; older fields keep their bit positions.
- Seven-segment display blanks leading zeros and caps the shown score at 9999.
- ui_screens (rtl/gameplay/ui_screens.v) draws the title, pause and game-over
  screens. It is a top VGA layer: output = ui_on ? ui_rgb : compositor rgb.
  Inputs: x, y, state, score, best_score, cursor_x/y, slash_active, btn_start.
  It also draws its own cursor marker in non-playing states. Nothing is drawn
  while state == 1 (playing).
- Title mode boards: slicing the SOLO or VERSUS board (cursor over it while
  slash_active) asserts start_req and sets mode (0 = solo, 1 = versus).
  start_req is ORed with BTNC into game_controller.start_pressed. BTNC with
  the cursor over no board starts solo. In fallback mode BTNC counts as a
  slice, so BTNC over the VERSUS board selects versus.
- mode is currently unused. The second game mode must read it.
- ui_screens also provides shared modules used by the OLED panel: bin2bcd,
  glyph35, font5x7, text_line and fancy_text.