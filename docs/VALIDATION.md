# Directional spawns and artwork — 31 October 2026

- All five behavioral tests passed, including directional spawn coordinates,
  inward velocities, offscreen entry survival, three separate hits for large
  fruit, held-swipe suppression, and recycled-slot bomb behaviour.
- Full synthesis passed: 4730/20800 logic LUTs (22.74%), 909 CARRY4 and 13 DSPs.
- Created a fresh project at %LOCALAPPDATA%/FruitSlashVivado/current referencing
  this repository to avoid accidentally rebuilding the older separate clone.
- Artwork uses original procedural shaded fruit, leaves/fuses, watermelon
  stripes/cracks/durability pips and wooden planks. Not copied game assets.
- No placement/routing timing closure, bitstream generation or board test was
  performed for this revision. Follow OCT31_UPDATE.md to build/program it.

# Display update — 22 October 2026

- All four behavioral tests passed: core, geometry, life animation and variants.
- Tests cover 3-second blinking, fade, simultaneous life loss, restart,
  exact 12/18/24-radius masks, tangent/miss collision and VGA heart placement.
- Full synthesis: 3006/20800 LUTs (14.45%), 1607 FFs, 573 CARRY4,
  13/90 DSPs; zero synthesis errors or critical warnings.
- Build was run outside OneDrive after a locked .Xil directory interrupted
  an earlier attempt. check.tcl now accepts FRUIT_SLASH_BUILD_ROOT too.
- Placement/routing, timing closure and physical board appearance have not
  been verified for this update. Regenerate the project sources and bitstream.

# Starter validation — 19 October 2026

Tool: installed Vivado 2025.2 on Titus's machine.

- Core behavioral simulation: PASS. Swept and stationary collision, disabled
  blade/inactive slots, simultaneous fruit score, release combo, pause, two-bomb
  damage, game over and restart.
- Full top-level RTL elaboration: PASS, zero errors/critical warnings.
- Supplied MouseCtl and Ps2Interface VHDL entities bind successfully.
- Basys3 XDC parses successfully.
- Student source whitespace check passes; supplied vendor whitespace is retained.

Warnings: supplied OLED zero replication; temporary loop variables optimized away.
RTL-stage DRC reports incomplete PS2 input/output buffering. Check these again
after full synthesis/implementation; RTL elaboration is not the physical netlist.

Not performed: technology-mapped synthesis, utilization/timing closure, placement,
routing, bitstream generation or testing on the board/monitor/mouse/OLED.
Do not describe this starter as hardware verified or as the finished game.

## Resource optimization — 20 October 2026

Full technology-mapped synthesis now passes on xc7a35tcpg236-1 with zero errors
or critical warnings. Eight object slots are retained.

| Resource | Used | Available |
|---|---:|---:|
| LUT as Logic | 2702 | 20800 |
| CARRY4 | 518 | 8150 |
| DSP48E1 | 13 | 90 |
| Flip-flops | 1525 | 41600 |

The old eight-way 64-bit collision arithmetic is replaced by a shared,
width-bounded, clocked engine. Rendering uses exact circle-width lookup tables.
Core tests and the new mathematical geometry regression pass, including eight
slots, simultaneous hits, tangent/near-miss/zero-length swipes, negative fruit
positions, 200 randomized cases, reset abort and exact fruit/flash pixel masks.

Run scripts/synthesize.tcl to reproduce resource reports and a synthesis DCP.
OneDrive-related writable-directory errors were avoided using a local temporary
build root. Post-synthesis DRC has DSP pipelining advisories; no resource-overuse
errors. Placement/routing, timing closure, bitstream generation and board tests
remain to be performed. The earlier 19 October limitations describe the old run.
