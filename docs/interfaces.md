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
- Combo counts fruits during a continuous hold; release adds 5*(combo-1).
  Base score=10 each, score saturates at 65535. Best survives round/reset.
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
