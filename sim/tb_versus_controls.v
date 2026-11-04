`timescale 1ns/1ps
module tb_versus_controls;
reg clk=0;always #5 clk=~clk;
reg reset=1,tick=0;reg [6:0] switches=0;reg [3:0] speed=0;reg fruit=0,bomb=0;
wire launch,kind,selected;wire [2:0] origin,target,level;wire [6:0] cooldown;
wire signed [15:0] x,vx,vy;
versus_controls dut(clk,reset,tick,1'b1,switches,speed,fruit,bomb,launch,kind,origin,target,selected,level,cooldown,x,vx,vy);
task step;begin @(posedge clk);#1;end endtask
initial begin
step;@(negedge clk);reset=0;switches=1;step;
if(!selected || origin!=0 || vx!=0 || vy!=-160) $fatal(1,"vertical origin");
@(negedge clk);switches=17;step;
if(origin!=0 || target!=4 || vx!=-80 || vy!=-139) $fatal(1,"30 degree aim");
@(negedge clk);fruit=1;step;if(!launch || kind) $fatal(1,"fruit");
step;if(launch) $fatal(1,"cooldown");
@(negedge clk);fruit=0;speed=8;step;
if(level!=4 || vx!=-120) $fatal(1,"speed");
@(negedge clk);switches=0;step;if(selected) $fatal(1,"clear origin");
@(negedge clk);switches=64;step;if(origin!=6) $fatal(1,"new origin");
$display("PASS: versus origin, aim, speed, launch and cooldown");$finish;
end
endmodule
