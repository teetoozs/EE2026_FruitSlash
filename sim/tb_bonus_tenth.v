`timescale 1ns/1ps
module tb_bonus_tenth;
reg clk=0;always #5 clk=~clk;
reg reset=1,tick=0,slash=0,contact=0;
wire burst,falling,active,award;wire [8:0] remaining;
streak_bonus dut(.clk(clk),.reset(reset),.tick(tick),.playing(1'b1),.slash_active(slash),.blade_event(1'b1),.contact(contact),.x0(10'd310),.y0(10'd240),.x1(10'd330),.y1(10'd240),.hits(8'd0),.bomb(8'd0),.missed(8'd0),.burst(burst),.falling(falling),.active(active),.award(award),.remaining(remaining));
task step;begin @(posedge clk);#1;@(negedge clk);end endtask
integer i;
initial begin
step;reset=0;dut.state=3;dut.remaining=300;dut.bonus_cuts=0;
for(i=0;i<10;i=i+1) begin
slash=0;contact=0;tick=1;repeat(7) step;tick=0;
slash=1;contact=1;step;
if(!award) $fatal(1,"cut not awarded");
if(i<9 && burst) $fatal(1,"early burst");
end
if(!burst || !falling || remaining!=0) $fatal(1,"tenth cut must end timer");
tick=1;repeat(30) step;if(active) $fatal(1,"burst must finish");
$display("PASS: ten accepted cuts trigger early burst and resume");$finish;
end
endmodule
