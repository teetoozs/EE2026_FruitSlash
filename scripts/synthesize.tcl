# Full technology-mapped synthesis, unlike check.tcl's RTL elaboration.
set root [file normalize [file join [file dirname [info script]] ..]]
if {[info exists ::env(FRUIT_SLASH_BUILD_ROOT)]} {
 set project_dir [file join $::env(FRUIT_SLASH_BUILD_ROOT) synth_[clock seconds]]
} else {
 set project_dir [file join $root build synth_[clock seconds]]
}
source [file join $root scripts create_project.tcl]
cd $project_dir
synth_design -top fruit_slash_top -part xc7a35tcpg236-1
report_utilization -hierarchical -file [file join $project_dir utilization_hierarchical.rpt]
report_utilization -file [file join $project_dir utilization.rpt]
report_drc -file [file join $project_dir synthesis_drc.rpt]
write_checkpoint -force [file join $project_dir fruit_slash_synth.dcp]
close_project
