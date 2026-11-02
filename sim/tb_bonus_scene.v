`timescale 1ns/1ps
module tb_bonus_scene;
 reg clk=0;always #5 clk=~clk;
 reg tick=0,contact=0;reg [7:0] hits=0;reg [4:0] presses=0;
 wire ps2c,ps2d;
 fruit_slash_top dut(.clk(clk),.sw(16'd0),.btnC(1'b0),.btnU(1'b0),.btnD(1'b0),
 .btnL(1'b0),.btnR(1'b0),.PS2Clk(ps2c),.PS2Data(ps2d));
 task step;begin @(posedge clk);#1;@(negedge clk);end endtask
 task frame;begin tick=1;step;tick=0;end endtask
 initial begin
  force dut.game_tick=tick;force dut.raw_hit_mask=hits;
  force dut.bonus_contact=contact;force dut.pressed=presses;force dut.slash_active=1;
  repeat(260) step;presses=1;step;presses=0;step;
  dut.objects.active=1;dut.objects.bomb=0;
  dut.bonus.streak=9;hits=1;step;hits=0;step;
  if(!dut.bonus_visible || dut.bonus_active || !dut.gameplay_enabled)
   $fatal(1,"Tenth cut must launch special fruit into normal play");
  repeat(10) frame;contact=1;step;contact=0;
  if(!dut.bonus_active || dut.gameplay_enabled) $fatal(1,"Special cut must freeze world");
  force dut.pixel_x=10'd600;force dut.pixel_y=10'd350;force dut.video_on=1;
  #1;if(dut.bonus_view_on || {dut.vgaRed,dut.vgaGreen,dut.vgaBlue}!==dut.rgb)
   $fatal(1,"Bonus must preserve wood scene outside fruit");
  repeat(30) frame;
  if(!dut.bonus_cutting || dut.bonus_radius!=54 || dut.bonus_remaining!=300)
   $fatal(1,"Bonus cutting should start after zoom");
  repeat(300) frame;
  if(!dut.bonus_falling || dut.gameplay_enabled) $fatal(1,"Freeze must continue during halves");
  repeat(90) frame;
  if(dut.bonus_visible || !dut.gameplay_enabled) $fatal(1,"Play must resume after falling halves");
  $display("PASS: spawned bonus scene and resume");$finish;
 end
 initial begin #1000000;$fatal(1,"Timeout");end
endmodule
