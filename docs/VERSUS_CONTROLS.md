# 1v1 controls

- SW0 pauses. SW1 through SW15 select launch position and aim.
- With all aiming switches down, the first switch raised selects the origin. If several rise together, the lowest index wins.
- The origin stays captured until ALL aiming switches are down, even if its own switch is lowered.
- Aim uses the median of the other active switch indices. For an even count, it averages the two middle indices, retaining half-switch precision. With none, aim is straight inward.
- A larger distance between origin and median increases tangential velocity and inward velocity, making the bottom-launched arc longer. Example: origin SW5, other switches SW6/SW10/SW15 gives median SW10.
- BTNL rotates clockwise: bottom, left, top, right. It also works while charging.
- Hold BTNU for fruit or BTNR for bomb, then release to launch once. Charge reaches its cap after 48 game ticks (about 0.8 seconds). Bomb wins if both buttons start together. Both must be released before charging again.
- OLED shows a live trajectory and rotating ninja, central translucent power display, and a bottom 20-pixel instruction area. It uses the same initial velocity, gravity and terminal speed as manual throws. Preview regeneration takes roughly 1.4 ms; curves are clipped to the panel and dimmed behind the central power display; the ninja is drawn above its text and bar.
- Pausing cancels an unfinished charge; release buttons before starting another throw.

Manual throws preserve the displayed launch velocity for every species. Maximum inward speed is about 10.4 pixels per motion update, with bounded tangential velocity. All manual objects use gravity 3/16 pixel per update squared and terminal downward speed 12 pixels per update. Regular-mode arcade drag and species-dependent terminal speeds remain separate. Large sliced fragments retain their reduced impulse.

Banana is excluded from regular and special fruit selection. Available fruit are orange, apple, lime, plum, watermelon, pear, pineapple and coconut.

No synthesis or implementation was run for these changes. Check the new utilization and timing reports when building the bitstream.

There is no throw cooldown in 1v1: tap/release repeatedly for rapid throws, or hold to charge. The existing eight simultaneous object slots still apply; throws while all slots are occupied cannot spawn another object.

Settings now include starting lives (1-5, default 3) and a draggable Easy/Medium/Hard slider. Medium is the default. Movement cadence is 64/80/92 updates per 100 game ticks, giving 80%/100%/115% of the previous default speed. Difficulty affects regular and 1v1 fruit/bomb motion; arc geometry, charge timing, effect timers and spawn interval stay unchanged. The aiming preview shows geometry rather than flight timing. SW1-SW15 remain reserved for aiming.
