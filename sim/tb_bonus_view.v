`timescale 1ns/1ps
module tb_bonus_view;
 reg clk=0;always #5 clk=~clk;
 reg reset=1,active=1,cut=0;reg [9:0] x=320,y=240;
 reg [9:0] x0=200,y0=240,x1=440,y1=240;
 wire on;wire [11:0] rgb;
 bonus_fruit_view d(.clk(clk),.reset(reset),.active(active),.cut(cut),.x0(x0),.y0(y0),
 .x1(x1),.y1(y1),.x(x),.y(y),.pixel_on(on),.rgb(rgb));
 initial begin
  @(negedge clk);reset=0;#1;if(!on || rgb==12'hFFE) $fatal(1,"Fresh fruit");
  cut=1;@(negedge clk);cut=0;#1;
  if(rgb!=12'hFFE) $fatal(1,"Horizontal cut missing");
  y=260;#1;if(rgb==12'hFFE) $fatal(1,"Cut not following player direction");
  x0=320;y0=120;x1=320;y1=360;cut=1;@(negedge clk);cut=0;#1;
  if(rgb!=12'hFFE) $fatal(1,"Second vertical cut missing");
  x=175;#1;if(on) $fatal(1,"Fruit circle boundary");
  active=0;@(negedge clk);active=1;x=320;y=240;#1;
  if(rgb==12'hFFE) $fatal(1,"New bonus retained old scars");
  $display("PASS: bonus zoom and player-directed scars");$finish;
 end
endmodule
