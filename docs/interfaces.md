# Interface contract v1
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
- Hit mask is combinational from registered blade_event/coordinates plus current
  active flags; all consumers sample it at the next 100 MHz rising edge.
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
- Compositor priority: background, intact objects, flash, cursor, state stripe.
  Full planned layer order is not yet implemented.
- Keep interface changes in this document and notify the consuming module owner.
