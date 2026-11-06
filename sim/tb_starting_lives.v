`timescale 1ns/1ps
module tb_starting_lives;
reg clk=0;always #5 clk=~clk;
reg reset=1,start=0,missed=0,hit=0,bomb=0;
reg [2:0] setting=3;
wire [2:0] lives;wire [1:0] state;
game_controller #(.N(1)) dut(.clk(clk),.reset(reset),.start_pressed(start),.starting_lives(setting),
 .pause(1'b0),.effects_busy(1'b0),.slash_active(1'b0),.hit_mask(hit),.bomb(bomb),.missed(missed),.bonus_hit(1'b0),.lives(lives),.state(state));
task step;begin @(posedge clk);#1;end endtask
integer n,j;
initial begin
 for(n=1;n<=5;n=n+1) begin
  @(negedge clk);reset=1;setting=n;step;
  @(negedge clk);reset=0;start=1;step;
  if(lives!=n || state!=1) $fatal(1,"starting lives %0d",n);
  @(negedge clk);start=0;setting=5;step;
  if(lives!=n) $fatal(1,"setting changed active round");
  for(j=n;j>0;j=j-1) begin
   @(negedge clk);missed=1;step;
   if(lives!=j-1) $fatal(1,"miss did not decrement");
   @(negedge clk);missed=0;step;
  end
  if(state!=3) $fatal(1,"game over missing");
 end
 @(negedge clk);reset=1;setting=5;step;
 @(negedge clk);reset=0;start=1;step;
 @(negedge clk);start=0;hit=1;bomb=1;step;
 if(lives!=0 || state!=3) $fatal(1,"bomb must remain instant kill");
 $display("PASS: 1-5 starting lives, locked round count, miss depletion, bomb instant kill");$finish;
end
endmodule
