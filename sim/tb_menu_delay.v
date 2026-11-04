`timescale 1ns/1ps
module tb_menu_delay;
reg clk=0;always #5 clk=~clk;
reg reset=1,tick=0,trigger=0;wire busy,done,pixel;wire [11:0] rgb;
menu_cut_animation dut(clk,reset,tick,trigger,10'd128,10'd280,10'd128,10'd280,12'hF80,busy,done,pixel,rgb);
task step;begin @(posedge clk);#1;@(negedge clk);end endtask
integer i;
initial begin
step;reset=0;trigger=1;step;trigger=0;
if(!busy || done || !pixel) $fatal(1,"cut must animate before transitioning");
for(i=0;i<59;i=i+1) begin tick=1;step;tick=0;step;if(!busy || done) $fatal(1,"transition too early");end
tick=1;step;if(busy || !done) $fatal(1,"missing one-second transition");
tick=0;step;if(done) $fatal(1,"repeated transition");
trigger=1;step;trigger=0;reset=1;step;if(busy || done) $fatal(1,"reset cancellation");
$display("PASS: menu delay, one-shot completion and reset cancellation");$finish;
end
endmodule
