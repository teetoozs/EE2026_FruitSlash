set root [file normalize [file join [file dirname [info script]] ..]]
set project_dir [file join $root build implement_[clock seconds]]
source [file join $root scripts create_project.tcl]
cd $project_dir
synth_design -top fruit_slash_top -part xc7a35tcpg236-1 -directive AreaOptimized_high
report_utilization -hierarchical -file synthesis_utilization.rpt
report_timing_summary -file synthesis_timing.rpt
write_checkpoint -force synthesized.dcp
opt_design
place_design
phys_opt_design
route_design
report_utilization -file utilization.rpt
report_timing_summary -report_unconstrained -file timing.rpt
report_drc -file drc.rpt
write_checkpoint -force routed.dcp
# A completed route is not a timing pass. Fail explicitly if timing or DRC fails.
set setup_path [get_timing_paths -quiet -delay_type max -max_paths 1]
set hold_path [get_timing_paths -quiet -delay_type min -max_paths 1]
if {[llength $setup_path] && [get_property SLACK $setup_path] < 0} {
 error "Implementation has setup violations; inspect timing.rpt"
}
if {[llength $hold_path] && [get_property SLACK $hold_path] < 0} {
 error "Implementation has hold violations; inspect timing.rpt"
}
if {[llength [get_drc_violations -quiet -filter {SEVERITY == Error}]]} {
 error "Implementation has DRC errors; inspect drc.rpt"
}

close_project
