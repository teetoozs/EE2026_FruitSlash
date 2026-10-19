# Feature ownership
| Owner | Files / responsibility | Advanced work still required |
|---|---|---|
| Sherwin Chang | rtl/gameplay | Real menu/UI data, high-score policy, multiplier, stats |
| Titus Chia | rtl/physics and rtl/oled | Fruit types, launch waves, OLED text/hearts/summary |
| Aloysius Lim | rtl/input and rtl/video | Trail, fonts/sprites, title/pause/over layouts, background |
| Shen Yuncong | rtl/effects | Independent halves, cut direction, explosions, persistent splats |
Top-level integration is shared: review interface changes with affected owners.
Sherwin owns UI *state/content*. Aloysius owns VGA pixel rendering.
Titus alone owns OLED pixels; Sherwin supplies game values.
Provided vendor modules are not student feature contributions.
