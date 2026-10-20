# Validation
## Automated
Run scripts/check.tcl through Vivado. tb_core verifies:
- swept fast swipe, stationary hit, disabled blade and inactive objects
- multiple fruit hits in one cycle
- combo awarded once on release
- pause, simultaneous bomb damage and round restart
RTL elaboration additionally checks mixed-language MouseCtl/Ps2Interface binding.
tb_geometry compares 2-slot and 8-slot shared collision scans to a 64-bit
mathematical reference (200 randomized cases plus tangent, near-miss, zero-length,
long-swipe and negative-coordinate cases), checks reset cancellation, and checks
every pixel around the fruit and flash masks against the original circle equation.
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
