set root [file normalize [file join [file dirname [info script]] ..]]
set project_dir [file join $root build popup_font_check]
source [file join $root scripts create_project.tcl]
cd $project_dir
set_property top tb_slice_popups [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
launch_simulation -mode behavioral
close_sim
set f [open [file join $project_dir fruit_slash.sim sim_1 behav xsim simulate.log] r]
set result [read $f]
close $f
if {[string first {PASS: white trail and slice popups} $result]<0 || [string match {*Fatal:*} $result]} {error {Popup test failed}}
close_project
