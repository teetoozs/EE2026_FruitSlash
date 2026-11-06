# 1v1 controls

- SW0 pauses. SW1 through SW15 select launch position and aim.
- Turn all aiming switches off, then turn one on: that first switch selects the origin along the current edge. A later switch turned on changes the aim: nearby indices throw shallowly along the edge, distant indices throw steeply inward. One selected switch throws straight inward. Lowest switch wins simultaneous changes.
- BTNL rotates the edge clockwise: bottom, left, top, right. Rotate before charging.
- Hold BTNU for fruit or BTNR for bomb; release to launch once. Charge reaches its cap after 48 game ticks (about 0.8 seconds). Bomb wins if both buttons start together. Both must be released before the next charge.
- OLED shows edge, charge bar, green origin/cyan target markers and button instructions.
- SW15 no longer resets the game. Use the existing return-to-menu/restart controls; power cycling resets the board.
- Pausing cancels an unfinished charge; release buttons before resuming a new throw.

Launch speed is bounded to 12.5 pixels per motion update in the inward direction, with bounded tangential aim. Large fruit receives 7/8 of the launch velocity; small fruit has stronger horizontal drag and a lower falling terminal speed. Gravity is identical for all fruit. Slice displacement controls bounded fragment impulse; large fragments receive half the impulse. These are arcade approximations, not a physical mass/drag simulation.

No synthesis or implementation was run for these changes. Hardware playtesting must confirm the desired difficulty and implementation reports must confirm resource/timing limits.

Fruit identities now include orange, apple, lime, plum, banana, watermelon, pear, pineapple and coconut. Banana orientation advances in quarter-turns; watermelon has a deliberately floaty arcade terminal speed, not a claim that heavier objects experience less gravity. The special fruit randomly selects one of these nine identities.
