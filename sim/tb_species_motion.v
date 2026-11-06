`timescale 1ns/1ps
module tb_species_motion;
reg clk=0;always #5 clk=~clk;
reg reset=1,tick=0,launch=0;
object_physics #(.N(1)) dut(.clk(clk),.reset(reset),.game_tick(tick),.playing(1'b1),.versus(1'b1),
 .launch(launch),.launch_bomb(1'b0),.launch_x(16'sd5120),.launch_y(16'sd1600),.launch_vx(16'sd80),.launch_vy(16'sd160),
 .difficulty(2'd0),.remove_mask(1'b0));
task step;begin @(posedge clk);#1;end endtask
task frame;begin @(negedge clk);tick=1;step;@(negedge clk);tick=0;step;end endtask
integer k;
initial begin
 for(k=0;k<16;k=k+1) begin
  @(negedge clk);reset=1;step;
  @(negedge clk);reset=0;force dut.random_state=k;launch=1;step;
  @(negedge clk);launch=0;repeat(4) step;
  if(dut.fruit_types==4 || dut.fruit_types>8) $fatal(1,"invalid fruit type");
  if(dut.vx[0]!=80 || dut.vy[0]!=160) $fatal(1,"manual launch differs from preview");
  frame;
  if(dut.vy[0]!=163) $fatal(1,"manual gravity differs from preview");
  release dut.random_state;
 end
 $display("PASS: all random selections exclude banana and preserve manual trajectory");$finish;
end
endmodule
