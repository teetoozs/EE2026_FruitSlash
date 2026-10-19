# Getting started
1. Open this repository folder in VS Code.
2. Open Vivado 2025.2 (the version found on Titus's machine).
3. In its Tcl Console run:
   cd {C:/Users/titus/OneDrive/Documents/ChatGPT/EE2026/fruit-slash-fpga}
   source scripts/create_project.tcl
   Replace the first path with your own clone location.
4. Open build/vivado/fruit_slash.xpr for later sessions.
5. Edit rtl files in VS Code and save; Vivado references the same files.
6. Run simulation, synthesis, implementation, timing/DRC checks, then bitstream.
7. Connect VGA, OLED to JB and a supported wired mouse to the board USB host.
8. BTNC starts. SW3 enables button fallback. SW15 resets.
Do not commit build/. Provided OLED/PS2 modules are already included.
To run verification from a Vivado-enabled terminal:
vivado -mode batch -source scripts/check.tcl
## Git workflow
git switch main
git pull --ff-only
git switch -c feature/your-task
# edit, save, test
git add rtl/path/your_file.v sim/your_test.v
git commit -m "Describe a small working change"
git push -u origin feature/your-task
Open a pull request to main; list tests and interface changes.
No .bit files are merged together: all RTL connects through fruit_slash_top.
