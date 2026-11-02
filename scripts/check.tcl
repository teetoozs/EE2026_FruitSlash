set root [file normalize [file join [file dirname [info script]] ..]]
set project_dir [file join $root build check_[clock seconds]]
if {[info exists ::env(FRUIT_SLASH_BUILD_ROOT)]} {
    set project_dir [file join $::env(FRUIT_SLASH_BUILD_ROOT) check_[clock seconds]]
}
source [file join $root scripts create_project.tcl]
cd $project_dir
set_property xsim.simulate.runtime all [get_filesets sim_1]
foreach {test marker} {
    tb_ui_equivalence {PASS: UI pixel equivalence}
    tb_bonus_scene {PASS: spawned bonus scene and resume}
    tb_slice_popups {PASS: white trail and slice popups}
    tb_bonus_view {PASS: bonus zoom and player-directed scars}
    tb_scaled_slice {PASS: scaled multi-fruit collision}
    tb_new_gameplay {PASS: waves misses bonus and wall splats}
    tb_effect_variants {PASS: variant effects}
    tb_bombs {PASS: bomb integration}
    tb_bomb_pixels {PASS: bomb pixels}
    tb_splash {PASS: splash animation}
    tb_effects {PASS: fruit halves}
    tb_core {PASS: swept hit}
    tb_geometry {PASS: geometry regression}
    tb_lives {PASS: life animation}
    tb_variants {PASS: variable fruit sizes and HUD}
    tb_spawns_damage {PASS: directional spawns and multi-hit fruit}
} {
    set_property top $test [get_filesets sim_1]
    launch_simulation -mode behavioral
    close_sim
    set logfile [file join $project_dir fruit_slash.sim sim_1 behav xsim simulate.log]
    set handle [open $logfile r]
    set sim_output [read $handle]
    close $handle
    if {[string first $marker $sim_output] < 0 || [string match {*Fatal:*} $sim_output]} {
        error "$test did not pass; inspect $logfile"
    }
}
synth_design -rtl -top fruit_slash_top -part xc7a35tcpg236-1
report_drc -file [file join $root build rtl_drc.txt]
close_project
