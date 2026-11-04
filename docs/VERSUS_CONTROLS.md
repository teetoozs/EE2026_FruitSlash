# Two-player controls

Choose Versus by slicing the melon. Player 1 uses the mouse; Player 2 uses the board.

- SW5..SW11: first rising switch selects origin, from right to left. Subsequent rising switches choose aim in 7.5-degree increments relative to the origin. SW5 then SW9 gives 30 degrees left of vertical. Simultaneous rising switches choose the lowest index.
- Lower all seven direction switches to clear the origin. Throws otherwise retain the selection.
- SW1..SW4: highest active selects 0.75x, 1x, 1.25x, 1.5x speed. All off defaults to 1x.
- BTNU: fruit, 30 game-tick cooldown. BTNR: bomb, 120 game-tick cooldown. Bomb wins simultaneous presses.
- SW0: pause. BTND: quit confirmation. SW15: reset.
- SW3 button fallback is disabled during Versus because SW3 now selects speed.
- OLED shows origin, aim arrow, speed and cooldown. A throw captures its settings; later switch changes do not steer existing objects. Full object slots discard the throw.

## Timing changes
Score points are registered before accumulation; best score compares the registered score one cycle later. Spawn allocation visits one slot per system clock rather than cascading eight allocation decisions. No new design sources are needed: modules remain in existing linked files.

Simulation coverage: tb_versus_controls and tb_pipeline_versus. Synthesis/implementation must be run by the user to verify LUT count and timing; neither is guaranteed by simulation.
