# LUT optimization after the 27,280-LUT report

The gameplay compositor now uses a double-buffered scanline renderer. One shape and shading circuit renders the next scanline serially into two 1024x13 distributed-RAM banks. Transparency and object/fragment ordering are preserved. At eight slots and the supported maximum 48-pixel screen radius, a worst-case line needs at most 3017 clocks, below the 3200 clocks per VGA line at 100 MHz. The final blanking row prepares visible row zero. The background, UI and bright trail remain live layers.

Fragment movement uses one indexed arithmetic path over 16 clocks per game update. All simultaneous cuts still capture in parallel; new cuts cancel pending movement for their reused slots. Horizontal velocities are signed 9 bits, vertical velocities signed 10 bits, sufficient for the bounded impulses and 90-frame lifetime.

New checks: `tb_scanline_equivalence` (with `sim/reference/pixel_compositor_ref.v`) compares old/new pixels including overlap, transparent holes, halves, row-zero wrap and worst-case deadlines. `tb_shared_effect_motion` checks simultaneous cuts, pause and reuse. The old combinational-renderer tests require raster timing to test the new interface; use the scanline regression for rendered geometry.

Design sources remain in the existing files already linked to Vivado. No synthesis/implementation has been run for these optimizations, so savings and timing are not yet measured. Run synthesis in the existing project and export a fresh hierarchical utilization report before deciding whether further reductions are necessary.
