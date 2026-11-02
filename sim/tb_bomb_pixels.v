`timescale 1ns/1ps
module tb_bomb_pixels;
 reg [9:0] x=200,y=200;reg [8:0] age=0;reg [1:0] active=1;
 wire on;wire [11:0] rgb;integer a;
 bomb_renderer #(.N(2),.RADIUS(36)) d(.x(x),.y(y),.age(age),.active(active),
 .origins_x({16'd6400,16'd3200}),.origins_y({16'd3200,16'd3200}),.pixel_on(on),.rgb(rgb));
 initial begin
  #1;if(!on || rgb!==12'h222) $fatal(1,"Stationary shell missing");
  age=30;#1;if(rgb!==12'hAAA) $fatal(1,"First crack missing");
  age=150;#1;if(rgb!==12'hDDD) $fatal(1,"Crack must brighten");
  x=203;age=30;#1;if(rgb===12'hAAA) $fatal(1,"Early seam too wide");
  age=150;#1;if(rgb!==12'hDDD) $fatal(1,"Seam did not open");
  x=200;y=150;age=30;#1;if(on) $fatal(1,"Light emerged too early");
  age=150;#1;if(!on || rgb!==12'hAAA) $fatal(1,"Pale light missing");
  x=200;y=200;age=180;#1;if(!on || rgb!==12'hDDD) $fatal(1,"Local burst missing");
  x=246;age=200;#1;if(!on) $fatal(1,"Shell fragment missing");
  x=400;y=200;active=2;age=0;#1;if(!on) $fatal(1,"Second bomb origin lost");
  active=1;
  for(a=0;a<240;a=a+1) begin
   age=a;x=0;y=0;#1;if(on) $fatal(1,"Effect must not cover distant scene");
   x=300;y=200;#1;if(on) $fatal(1,"Effect exceeds compact radius");
  end
  age=240;x=200;y=200;#1;if(on) $fatal(1,"Effect outlived four seconds");
  active=0;age=0;#1;if(on) $fatal(1,"Inactive blast");
  $display("PASS: bomb pixels gradual cracks, pale light, compact burst");$finish;
 end
endmodule
