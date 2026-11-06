`timescale 1ns/1ps
module tb_median_aim;
reg clk=0;always #5 clk=~clk;
reg reset=1;reg [14:0] switches=0;
wire [3:0] origin,target;wire selected;
wire signed [15:0] vx,vy;
versus_controls dut(.clk(clk),.reset(reset),.tick(1'b0),.enabled(1'b1),.switches(switches),
 .fruit_hold(1'b0),.bomb_hold(1'b0),.rotate_press(1'b0),.origin(origin),.target(target),.selected(selected),.velocity_x(vx),.velocity_y(vy));
task step;begin @(posedge clk);#1;end endtask
integer near_vx,near_vy;
initial begin
 step;@(negedge clk);reset=0;step;
 @(negedge clk);switches=15'b1<<4;step;
 if(origin!=4) $fatal(1,"origin");
 @(negedge clk);switches=(1<<4)|(1<<5);step;near_vx=-vx;near_vy=-vy;
 @(negedge clk);switches=(1<<4)|(1<<14);step;
 if(-vx<=near_vx || -vy<=near_vy) $fatal(1,"distance must lengthen range and airtime");
 @(negedge clk);switches=(1<<4)|(1<<5)|(1<<9)|(1<<14);step;
 if(target!=9 || dut.median_twice!=18) $fatal(1,"odd median");
 @(negedge clk);switches=(1<<4)|(1<<6)|(1<<9);step;
 if(dut.median_twice!=15 || dut.delta!=7) $fatal(1,"even median must preserve half switch");
 @(negedge clk);switches=(1<<6)|(1<<9);step;
 if(origin!=4 || !selected) $fatal(1,"lowering origin switch must retain origin");
 @(negedge clk);switches=0;step;if(selected) $fatal(1,"all off");
 @(negedge clk);switches=1<<12;step;if(origin!=12) $fatal(1,"new origin");
 $display("PASS: median aim, half-switch median, longer arc and retained origin");$finish;
end
endmodule
