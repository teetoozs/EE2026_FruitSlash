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
