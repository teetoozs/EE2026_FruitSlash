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
