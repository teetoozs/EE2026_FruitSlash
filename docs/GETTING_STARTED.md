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
