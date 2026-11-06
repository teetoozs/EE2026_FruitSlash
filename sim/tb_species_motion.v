`timescale 1ns/1ps
module tb_species_motion;
reg clk=0;always #5 clk=~clk;
reg reset=1,tick=0,launch=0;
object_physics #(.N(1)) dut(.clk(clk),.reset(reset),.game_tick(tick),.playing(1'b1),.versus(1'b1),
 .launch(launch),.launch_bomb(1'b0),.launch_x(16'sd5120),.launch_y(16'sd1600),.launch_vx(16'sd80),.launch_vy(16'sd160),
 .difficulty(2'd0),.remove_mask(1'b0));
task step;begin @(posedge clk);#1;end endtask
task frame;begin @(negedge clk);tick=1;step;@(negedge clk);tick=0;step;end endtask
initial begin
 step;@(negedge clk);reset=0;force dut.random_state=16'd5;launch=1;step;
 @(negedge clk);launch=0;repeat(3) step;release dut.random_state;
 if(dut.fruit_types!=5 || dut.vx[0]!=70 || dut.vy[0]!=140) $fatal(1,"watermelon mass capture");
 frame;if(dut.vy[0]!=112) $fatal(1,"watermelon terminal speed");
 @(negedge clk);reset=1;step;@(negedge clk);reset=0;force dut.random_state=16'd4;launch=1;step;
 @(negedge clk);launch=0;repeat(3) step;release dut.random_state;
 if(dut.fruit_types!=4 || dut.vx[0]!=80) $fatal(1,"banana capture");
 frame;if(dut.spins!=1 || dut.vy[0]!=128) $fatal(1,"banana tumble and drag");
 $display("PASS: species identity, heavy launch, watermelon float and banana tumble");$finish;
end
endmodule
