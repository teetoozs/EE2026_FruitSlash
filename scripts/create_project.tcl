# Run: vivado -mode batch -source scripts/create_project.tcl
set root [file normalize [file join [file dirname [info script]] ..]]
proc collect {dir pattern} {
 set result [glob -nocomplain -directory $dir $pattern]
 foreach sub [glob -nocomplain -directory $dir -types d *] {
  set result [concat $result [collect $sub $pattern]]
 }
 return $result
}
if {![info exists project_dir]} {set project_dir [file join $root build vivado]}
if {[file exists [file join $project_dir fruit_slash.xpr]]} {
 open_project [file join $project_dir fruit_slash.xpr]
} else {
 create_project fruit_slash $project_dir -part xc7a35tcpg236-1
}
set_property target_language Verilog [current_project]
add_files [collect [file join $root rtl] *.v]
add_files [glob [file join $root vendor *.v]]
add_files [glob [file join $root vendor *.vhd]]
add_files -fileset constrs_1 [file join $root constraints basys3.xdc]
set_property top fruit_slash_top [current_fileset]
add_files -fileset sim_1 [file join $root sim tb_core.v]
set_property top tb_core [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "Project: [file join $project_dir fruit_slash.xpr]. Run synthesis/implementation in Vivado."
