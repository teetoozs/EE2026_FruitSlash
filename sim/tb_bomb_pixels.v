`timescale 1ns/1ps
module tb_bomb_pixels;
 reg [9:0] x=0,y=0;reg [8:0] age=0;reg [1:0] active=1;
 wire on;wire [11:0] rgb;integer a,ix,iy;reg [11:0] old;
 bomb_renderer #(.N(2)) d(.x(x),.y(y),.age(age),.active(active),
 .origins_x({16'd3200,16'd3200}),.origins_y({16'd3200,16'd3200}),.pixel_on(on),.rgb(rgb));
 initial begin
  for(a=0;a<300;a=a+1) begin age=a;
   for(ix=0;ix<640;ix=ix+79) for(iy=0;iy<480;iy=iy+59) begin
    x=ix;y=iy;#1;
    if(!on || rgb[11:8]!==rgb[7:4] || rgb[7:4]!==rgb[3:0]) $fatal(1,"Blast must cover screen in grey");
   end
  end
  active=0;#1;if(on) $fatal(1,"Inactive blast");
  $display("PASS: bomb pixels full screen grey animation");$finish;
 end
endmodule
