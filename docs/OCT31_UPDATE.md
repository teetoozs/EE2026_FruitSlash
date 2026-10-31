# October 31 gameplay update

The workspace repository contains the hearts and stripe removal changes.
The separate C:/Users/titus/EE2026_FruitSlash clone was found to still contain
the old Sensei panel. Building that copy will not include these updates.

To use this repository, close the old Vivado project and run this in Tcl Console:

```tcl
source {C:/Users/titus/OneDrive/Documents/ChatGPT/EE2026/fruit-slash-fpga/scripts/create_local_project.tcl}
```

This creates a project under %LOCALAPPDATA%/FruitSlashVivado/current, referencing
the updated sources here. Generate a new bitstream and program fruit_slash_top.bit.
Pulling code or opening a project does not reprogram the board.

## Behaviour

- Pseudo-random bottom arcs, vertical top drops, left throws and right throws.
- Size 24 fruit are watermelons requiring three separate button-held swipes.
  Release and press again between hits; a held stationary blade cannot consume
  multiple health points. Cracks and three pips show remaining health.
- Normal fruit and bombs still respond to one hit. Score/removal events occur
  only on destruction; damaging a watermelon does not score multiple fruits.
- Three hearts appear on OLED and VGA. Lost hearts blink for 3 seconds then
  fade for roughly half a second. The old state stripes are absent.
- Original procedural arcade artwork: wooden planks/grain, shaded fruit,
  highlights, leaves, watermelon stripes, and lit bomb fuses.
  These are not imported Fruit Ninja assets or a full replica of its animation.
- No 1v1/slingshot changes are included in this update.
