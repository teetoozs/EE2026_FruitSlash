# Interface contract v2
- One 100 MHz domain for game/input/VGA logic. game_tick is an enable (~60 Hz).
- VGA uses a 25 MHz pixel enable: 800x525 total, 640x480 active (~59.52 Hz).
- OLED driver has a generated 6.25 MHz clock; status uses a bundled-data
  request/ack mailbox. Keep mailbox data stable until acknowledgement.
- Synchronous active-high reset for student modules; startup reset is automatic.
- Objects: N=8, slot i occupies [i*16 +: 16] of each position bus.
- Signed 16-bit Q12.4 positions and velocities. Pixel position = arithmetic >>4.
- Screen origin upper-left; positive y downward. Negative/offscreen positions legal.
- Radius 18 pixels in starter. No fruit type bus yet: agree before adding one.
- Physics owns active/bomb/position arrays. hit_mask is one bit per slot.
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
- Combo counts fruits during a continuous hold; release adds 5*(combo-1).
  Base score=10 each, score saturates at 65535. Best survives round/reset.
- Pause freezes physics/effects/scoring; pointer remains responsive.
- BTNC press starts/restarts only on title/game-over. During fallback gameplay,
  BTNC held slices. SW15 resets, SW3 selects fallback, SW2 pauses, SW1:0 difficulty.
- State encoding: 0 title, 1 play, 2 pause, 3 over.
- Effects capture every fruit hit into two half slots (2*i left, 2*i+1 right).
  halves_x/halves_y are packed signed Q12.4 centres, 16 bits per piece;
  halves_active has 2*N bits. Splits are vertical through the centre.
  Pieces separate at +/-2 pixels/tick and accelerate downward by 0.25 pixels/tick^2.
  A new cut in the same object slot replaces its old pair. Pieces expire after
  90 ticks or when offscreen; pause freezes them and reset/new_round clears them.
  The bomb input filters fruit effects; bomb visuals live in bomb_effects/bomb_renderer.
- Each fruit cut also captures splash_x/splash_y (packed signed Q12.4 origins).
  splash_active has N bits; splash_age packs 5 bits per slot, ages 0 through 23.
  Eight droplets spread and drift down around a shrinking core, then dither/fade.
  Effects last 24 game ticks (~0.4 seconds). New cuts replace the splash in that
  slot, even on a coincident tick. Bombs do not create juice. Pause/game over freezes
  the splash age; reset/new_round clears it. Current juice palette is orange.
- Compositor priority: background, juice splashes, intact objects, fruit halves,
  dimming during a bomb cinematic, explosions, cursor, state stripe.
- bomb_effects snapshots all bomb hits and Q12.4 origins on acceptance. explosion_age
  is a shared 6-bit counter: 0..11 hit stop (0.2 seconds), 12..47 blast (0.6 seconds).
  explosion_active is one bit per captured bomb; busy is its reduction OR.
- The initial hit removes objects and deducts lives once. During bomb_busy, top-level
  hit masks and slice detection are blocked, physics ticks and fruit effects freeze,
  and game_controller holds score/combo via effects_busy. The bomb-hit tick itself
  also suppresses world movement. VGA timing and cursor input continue normally.
- Bomb animation advances on game_tick independently of playing, including game over.
  SW2 pauses the cinematic even after a fatal hit. Reset cancels it immediately.
  Start/restart is ignored while effects_busy; press again after the blast finishes.
  Nonfatal gameplay resumes automatically when the 48-tick sequence completes.
- The old effect_x/effect_y/ttl single-flash interface has been removed.
  Full planned layer order is not yet implemented.
- Keep interface changes in this document and notify the consuming module owner.
