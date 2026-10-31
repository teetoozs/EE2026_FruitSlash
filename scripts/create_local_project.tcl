# Use this entry point to keep Vivado build/cache files outside OneDrive.
# RTL remains referenced from this repository; do not copy individual modules.
set project_dir [file normalize [file join $::env(LOCALAPPDATA) FruitSlashVivado current]]
source [file join [file dirname [info script]] create_project.tcl]
