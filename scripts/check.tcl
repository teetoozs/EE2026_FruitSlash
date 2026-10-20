set root [file normalize [file join [file dirname [info script]] ..]]
set project_dir [file join $root build check_[clock seconds]]
source [file join $root scripts create_project.tcl]
cd $project_dir
set_property xsim.simulate.runtime all [get_filesets sim_1]
foreach {test marker} {
    tb_core {PASS: swept hit}
    tb_geometry {PASS: geometry regression}
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
