`timescale 1ns/1ps
module tb_slice_popups;
 reg clk=0; always #5 clk=~clk;
 reg reset=1,tick=0,playing=1,bomb_busy=0,active=0,award=0;
 reg [7:0] combo=0;
 reg [9:0] x=164,y=64;
 wire on; wire [11:0] rgb;
 slice_popups dut(clk,reset,tick,playing,bomb_busy,active,award,combo,x,y,on,rgb);
 reg event_in=0,slash=0;
 wire trail_on; wire [11:0] trail_rgb;
 white_blade_trail trail(clk,reset,tick,playing,event_in,slash,
   10'd100,10'd100,10'd140,10'd100,10'd120,10'd100,trail_on,trail_rgb);
 task step; begin @(posedge clk); #1; end endtask
 task pulse_tick; begin @(negedge clk);tick=1;step;@(negedge clk);tick=0;end endtask
 integer i;
 initial begin
  step; @(negedge clk);reset=0;combo=3;step;
  if(dut.popup_combo!=3 || dut.combo_age!=45) $fatal(1,"combo not captured");
  repeat(40) step;
  if(!on) $fatal(1,"combo glyph not visible");
  if(dut.combo_digits!=20'h00003) $fatal(1,"combo decimal");
  @(negedge clk);active=1;step;
  if(dut.bonus_slices!=0) $fatal(1,"bonus start");
  repeat(3) begin @(negedge clk);award=1;step;@(negedge clk);award=0;step;end
  repeat(40) step;
  if(!on) $fatal(1,"bonus glyph not visible");
  if(dut.bonus_slices!=3 || dut.bonus_digits!=20'h00003) $fatal(1,"bonus count");
  @(negedge clk);playing=0;
  repeat(50) pulse_tick;
  if(dut.bonus_slices!=3 || dut.bonus_age!=45 || on) $fatal(1,"pause");
  @(negedge clk);playing=1;active=0;step;
  repeat(45) pulse_tick;
  if(dut.bonus_age!=0) $fatal(1,"expiry");
  @(negedge clk);active=1;step;
  if(dut.bonus_slices!=0) $fatal(1,"second round reset");
  @(negedge clk);slash=1;event_in=1;step;
  @(negedge clk);event_in=0;
  repeat(50) step;
  if(!trail_on || trail_rgb!=12'hfff) $fatal(1,"white continuous trail");
  @(negedge clk);slash=0;
  repeat(12) pulse_tick;
  if(trail_on) $fatal(1,"trail expiry");
  @(negedge clk);reset=1;step;
  if(dut.bonus_slices!=0 || on || trail_on) $fatal(1,"reset");
  $display("PASS: white trail and slice popups"); $finish;
 end
 initial begin #100000; $fatal(1,"timeout"); end
endmodule
