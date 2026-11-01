# Validation
## Automated
Run scripts/check.tcl through Vivado. tb_core verifies:
- swept fast swipe, stationary hit, disabled blade and inactive objects
- multiple fruit hits in one cycle
- combo awarded once on release
- pause, simultaneous bomb damage and round restart
tb_effects verifies all eight simultaneous fruit cuts, separating/falling pieces,
semicircle pixels, pause, reset/restart, bomb filtering, slot reuse, expiration,
negative-coordinate rendering and blanking. It also checks splash capture, pause,
bomb filtering, replacement and exact 24-tick expiration.
tb_splash compares all animation ages against an independent eight-droplet pixel
reference, checking spread, downward drift, colour fade, dithering and clipping.
RTL elaboration additionally checks mixed-language MouseCtl/Ps2Interface binding.
tb_geometry compares 2-slot and 8-slot shared collision scans to a 64-bit
mathematical reference (200 randomized cases plus tangent, near-miss, zero-length,
long-swipe and negative-coordinate cases), checks reset cancellation, and checks
every pixel around the fruit mask against the original circle equation.
Run scripts/synthesize.tcl as well: only full synthesis reports hardware usage.
## Board acceptance (not yet performed)
- VGA stable on monitor; black during blanking.
- Wired mouse enumerates, cursor clamps to 639x479; left hold slices.
- SW3 fallback: direction buttons move, centre hold slices.
- Pause freezes objects but cursor still moves.
- Restart removes old objects/effects and clears score.
- OLED/7-segment/LED lives match bomb events.
- No repeated score from the same object.
- Difficulty changes do not overflow velocity/position.
- Run implementation, inspect timing/utilization/DRC before Generate Bitstream.
## Remaining tests
Physics bounds, full VGA line/frame timing, debounce, mouse protocol on hardware,
OLED mailbox/driver startup, long-run score saturation and integration stress.

## Bomb effects
- tb_bombs injects collision events into the actual fruit_slash_top integration and
  checks same-tick object removal, one-time damage, frozen physics/fruit effects,
  blocked additional cuts, manual pause, exact phase timing, automatic resume,
  simultaneous fatal bombs, restart gating and reset cancellation.
- tb_bomb_pixels checks the stationary hit-stop bomb, initial white flash, all eight
  fragment directions across every blast age, shockwave, extinction and signed clipping.
- Board acceptance: hit a bomb while objects move, pause during the explosion, then
  verify automatic resume; repeat on the final life and verify the blast finishes.

## Combined gameplay/effects regression
- tb_effect_variants checks that multi-hit watermelons split only on destruction,
  repeated held contacts do not split them, all three captured half sizes render
  correctly, recycled live radius changes do not resize pieces, and detailed
  orange/red/watermelon pieces retain their palettes and cut interiors.
- tb_bombs injects raw contacts through fruit_damage before checking bomb effects.
