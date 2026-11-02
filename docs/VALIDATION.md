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

## Fruit halves - 26 October 2026

On develop/effects, Vivado 2025.2 completed:
- tb_effects: PASS (eight simultaneous cuts, falling/separating halves, pixel masks,
  pause, reset/restart, bomb filtering, slot reuse, expiration and screen-edge clipping).
- tb_core and tb_geometry: PASS.
- Full top-level RTL elaboration: PASS, no errors or critical warnings.
- Technology-mapped synthesis: PASS, no errors or critical warnings.

Resource usage: 5,441 / 20,800 LUTs (26.16%), 2,395 / 41,600 flip-flops (5.76%),
13 / 90 DSPs (14.44%), no block RAM and no inferred latches.
Post-synthesis DRC reports only DSP pipelining advisories in the existing slicing engine.
Reports are under build/synth_1792943844; regression project is build/check_1792943826.

The split is vertical through the fruit centre. Each object slot owns one pair;
a newer cut in that slot replaces its previous pair. Pause/game over freezes effects,
and reset/new_round clears them. Cut-dependent direction, splats and explosions remain future work.
Placement/routing, timing closure, bitstream generation and board testing were not run.

## Animated juice splash - 26 October 2026

Added a 24-tick orange juice burst for every fruit cut, behind intact fruit and
falling halves. Eight droplets spread outward and drift down; the centre shrinks
and the last eight ticks use darker colour and checkerboard fading. Each object
slot captures its own origin and age; bombs do not spawn juice. New cuts replace
old splashes in reused slots. Pause/game over freezes age; restart clears splashes.
Persistent background decals and per-fruit palettes are not implemented yet.

Vivado 2025.2: tb_splash, tb_effects, tb_core and tb_geometry all PASS.
Full top-level elaboration and technology-mapped synthesis PASS with no errors or
critical warnings. Usage: 7,448 LUTs (35.81%), 2,635 flip-flops (6.33%), 13 DSPs
(14.44%), no inferred latches. Post-synthesis DRC has only the existing slicing
DSP pipelining advisories. Reports: build/synth_1792944933; regression project:
build/check_1792944910. Timing closure, bitstream and board tests remain outstanding.

## Bomb hit stop and explosion - 30 October 2026

Replaced the single yellow bomb flash with bomb_effects and bomb_renderer.
Every bomb in the accepted hit mask is captured at its original position. The
world freezes for the whole 48-tick cinematic: 12 ticks of stationary highlighted
bombs, then 36 ticks of white/orange fire, expanding octagonal shockwaves, eight
outward fragment directions and fading embers. Background is dimmed during it.
Nonfatal play resumes automatically. Fatal hits still finish animating before
restart is accepted; SW0 pauses the animation and SW15/reset cancels it.
Damage and object removal occur exactly once on the initial hit.

Vivado 2025.2: tb_bombs (actual top-level integration), tb_bomb_pixels, tb_splash,
tb_effects, tb_core and tb_geometry all PASS. Full RTL elaboration and mapped
synthesis PASS, with no errors or critical warnings. Post-synthesis DRC has only
existing slicing DSP pipelining advisories. Usage: 10,145 LUTs (48.77%), 2,815
flip-flops (6.77%), 13 DSPs (14.44%), no inferred latches.
Reports: build/synth_1793348606; regression project: build/check_1793348593.
Placement/routing, timing closure, bitstream generation and board testing have
not been performed for this change.

## Latest main integration - 1 November 2026

Merged origin/main at 7325373 into develop/effects, retaining the fruit halves,
juice splashes and bomb hit-stop/explosion sequence alongside directional spawns,
variable fruit sizes, detailed artwork, multi-hit watermelons and animated hearts.
Fruit destruction now drives effects through fruit_damage; watermelons split only
on their third distinct swipe. Cut effects capture each fruit's radius so reused
slots cannot resize falling pieces. Halves retain the slot palette and shading,
with watermelon rind/flesh; juice uses fruit colours and red watermelon juice.

Vivado 2025.2: all ten regression benches in scripts/check.tcl PASS, including
new tb_effect_variants coverage for final-hit activation, captured radii, half
silhouettes/colours and watermelon splash fading. RTL elaboration and mapped
synthesis PASS with zero errors or critical warnings. Post-synthesis DRC reports
only slicing DSP pipelining advisories. Usage: 13,304 LUTs (63.96%), 2,948
flip-flops (7.09%), 13 DSPs (14.44%), zero inferred latches.
Reports: build/synth_1793521373; regression project: build/check_1793521386.
Placement/routing, timing closure, bitstream generation and board testing remain
outstanding.
