# Getting started

FRUIT SLASH — GETTING STARTED

1. Install Git, VS Code and Vivado (preferably 2025.2).
   Accept the GitHub collaborator invitation.

2. Open a terminal in the folder where you want the project.
   Run:

git clone https://github.com/teetoozs/EE2026_FruitSlash.git
cd EE2026_FruitSlash
git switch -c feature/YOUR-NAME origin/codex/team-template
code .

Replace YOUR-NAME with your name.

3. Open Vivado. In the Tcl Console at the bottom, run:

cd {C:/YOUR/LOCAL/PATH/EE2026_FruitSlash}
source scripts/create_project.tcl

Replace the path with your cloned repository folder.
Use forward slashes / in the path.

4. The script creates and opens the Vivado project.
   Next time, open: build/vivado/fruit_slash.xpr

5. Edit your assigned files in VS Code and SAVE.
   Run simulation/synthesis in Vivado.

6. To upload your changes, run in the VS Code terminal:

git status
git add rtl/
git commit -m "Describe your changes"
git push -u origin feature/YOUR-NAME

7. Open a pull request on GitHub for team review.

Do not upload the build folder.
Do not change another member's module ports without discussing it.


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

## Refreshing Vivado after edits or a Git pull

### Existing source files changed

1. Save your changes in VS Code, or finish pulling/merging the team updates.
2. Return to Vivado and accept any source-file reload prompt. If an editor tab
   still shows old text, close and reopen that source tab.
3. Refresh the compilation order in Vivado's Tcl Console if needed:

```tcl
update_compile_order -fileset sources_1
```

This updates the source hierarchy; it does not rebuild the design. You do not
need to restart Vivado or recreate the project for ordinary source edits.
Vivado must reference the same repository files you edit in VS Code, rather
than an older copied set of sources.

### New source files were added

Use Add Sources in Vivado and leave Copy sources into project unchecked.
Alternatively, save your work, close the current project, and rerun the setup
script from the repository root in the Tcl Console:

```tcl
close_project
source scripts/create_project.tcl
```

The script reopens the local project and adds the current RTL/vendor files.
New testbenches or memory assets also need to be registered in the setup script;
it currently adds only sim/tb_core.v as its testbench.

### Update the running Basys 3 design

Reloading source does not update the hardware. After functional changes, rerun
simulation as appropriate, synthesis, implementation and Generate Bitstream,
then program the board with the new .bit file in Hardware Manager.
Formatting-only changes do not require reprogramming to preserve existing behaviour.
=======

