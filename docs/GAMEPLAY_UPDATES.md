# Larger fruit and streak bonus

- Fruit and bomb diameters are doubled; slice collision and fruit halves use the same scale.
- Waves request 1/2/3 objects with approximately 70%/20%/10% probability. Each uses a separate pseudo-random trajectory. A wave can contain at most one bomb.
- Each uncut fruit that leaves the screen costs one life; exiting bombs cost no life. Cuts take priority over an exit in the same update.
- Ten fruit cuts without a miss or bomb hit trigger a five-second golden bonus melon. Normal objects freeze during the bonus.
- Repeated moving swipes through the bonus fruit earn 25 points each. Release or leave its area between hits; stationary contact does not score. A 100 ms cooldown limits scoring.
- The bar below the bonus melon shows remaining time. Pausing freezes its timer.
- Cuts leave coloured wall splats for eight seconds, with a dither fade during the last two seconds. Each object slot retains its most recent splat.
- Regular watermelons are disabled; the timed golden streak bonus remains. Motion advances on four out of five game ticks, slowing travel by 20% while preserving arc geometry.

After a pull that adds modules, run in the **open Vivado Tcl Console**:

```tcl
add_files -norecurse [glob C:/Users/titus/EE2026_FruitSlash/rtl/*/*.v]
update_compile_order -fileset sources_1
```

## Zoom and fatal bombs
The timed bonus is a zoomed orange with up to eight recent swipe scars. Bomb hits instantly end the round. A grey screen-filling blast and shaking smoke run for 300 ticks (five unpaused seconds), then the final-score screen appears. SW0 pauses the cinematic; reset cancels it.
