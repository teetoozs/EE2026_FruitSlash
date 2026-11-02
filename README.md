# Fruit Slash — Basys 3 team starter

One integrated Verilog design, VGA game screen, wired mouse/button fallback,
and a Pmod OLED status panel. This is a connected starter, not the completed
four-feature submission. Advanced features are explicitly documented as TODOs.

## Start here

- [Setup and Git workflow](docs/GETTING_STARTED.md)
- [Shared interfaces and timing](docs/interfaces.md)
- [Feature owners and remaining work](docs/ownership.md)
- [Verification and board checklist](docs/test_plan.md)
- [Supplied mouse/OLED modules](vendor/README.md)

## Controls

| Control | Function |
|---|---|
| BTNC | Start/restart on title/game-over |
| Mouse left hold | Slice during play |
| SW3 | Button fallback: U/D/L/R move, C held slices |
| SW0 | Pause/resume |
| SW2:1 | Difficulty |
| SW15 | Reset to title |

## Implemented starter behaviour

- 640x480 VGA with wooden planks, shaded fruit, leaves, bomb fuses and animated heart HUD.
- Supplied VHDL MouseCtl integration, pointer crosshair and fallback buttons.
- Eight fruit/bomb slots with bottom/top/side launches and LFSR spawning.
- Fruit radii 12/18/24; large watermelons need three separate held swipes.
- Swept-segment/circle slicing, object removal and simultaneous hit masks.
- Score, per-stroke combo bonus, three lives, pause, restart and session best.
- Two falling pieces per destroyed fruit, preserving size, slot colour and watermelon rind.
- Bomb hit stop, expanding shockwave and eight-direction fragments; fatal hits finish animating.
- Animated juice bursts with spreading droplets and a shrinking, fading centre.
- OLED animated hearts, difficulty/combo bars and seven-segment score.

## Not yet implemented

Finished title/pause/game-over text, fonts/sprites, blade trails, cut-direction-dependent fruit
splits, persistent splats, multiplier and end statistics.
See ownership.md. Fruit halves and bomb explosions support all eight hit slots. A new fruit cut in a reused slot replaces its previous halves. Hardware acceptance and implementation timing must be checked.

## Build

Use Vivado 2025.2 or agree a common team version. Source
`scripts/create_project.tcl` in Vivado, then build `fruit_slash_top`.
The generated project is `build/vivado_refreshed/fruit_slash.xpr`.
Run `scripts/check.tcl` for simulation and RTL elaboration.
Run `scripts/synthesize.tcl` for full technology-mapped synthesis and utilization
reports. RTL elaboration alone does not prove the design fits the FPGA.
Generated results stay in ignored `build/`; source files remain in the repository.

Keep this repository private until course/vendor redistribution rules are checked.
