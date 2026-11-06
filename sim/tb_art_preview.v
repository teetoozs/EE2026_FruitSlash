`timescale 1ns/1ps
module tb_art_preview;
reg clk=0;always #5 clk=~clk;
reg reset=1;
reg [9:0] x=0,y=0,raster=524;wire [11:0] rgb;
reg [143:0] px=0,py=0;reg [35:0] kinds=0;reg [44:0] radii=0;
reg [8:0] bombs=9'b100000000;
pixel_compositor #(.N(9),.DETAILED_ART(1),.VARIABLE_RADIUS(1),.SIZE_SHIFT(1)) dut(
 .clk(clk),.reset(reset),.raster_y(raster),.x(x),.y(y),.video_on(1'b1),.heart_levels(12'd0),.radii(radii),.health(18'd0),.state(2'd1),
 .cursor_x(10'd0),.cursor_y(10'd0),.slash_active(1'b0),.active(9'h1ff),.bomb(bombs),.fruit_types(kinds),.spins(18'd0),
 .positions_x(px),.positions_y(py),.explosion_active(9'd0),.explosion_x(144'd0),.explosion_y(144'd0),.explosion_age(9'd0),
 .effect_radii(45'd0),.halves_active(18'd0),.halves_x(288'd0),.halves_y(288'd0),.splash_active(9'd0),
 .splash_x(144'd0),.splash_y(144'd0),.splash_age(45'd0),.wall_on(1'b0),.wall_rgb(12'd0),.rgb(rgb));
reg event_in=0;wire trail_on;wire [11:0] trail_rgb;
white_blade_trail trail(.clk(clk),.reset(reset),.game_tick(1'b0),.enabled(1'b1),.blade_event(event_in),.slash_active(1'b1),
 .previous_x(10'd210),.previous_y(10'd225),.cursor_x(10'd370),.cursor_y(10'd65),
 .pixel_x(x),.pixel_y(y),.pixel_on(trail_on),.rgb(trail_rgb));
integer i,j,k,f;reg [11:0] colour;
initial begin
 for(i=0;i<9;i=i+1) begin
  px[i*16+:16]=(100+(i%3)*220)*16;py[i*16+:16]=(95+(i/3)*150)*16;
  kinds[i*4+:4]=i>=4 ? i+1:i;radii[i*5+:5]=18;
 end
 #20;reset=0;#10;event_in=1;#10;event_in=0;#2000;
 // A 45-degree stroke must be connected through its wide middle.
 for(i=0;i<65;i=i+1) begin x=280+i;y=155-i;#1;
  if(!trail_on) $fatal(1,"diagonal trail gap at %0d",i);
 end
 repeat(3200) @(negedge clk);
 f=$fopen("build/fruit_art_preview.ppm","w");$fwrite(f,"P3\n640 480\n255\n");
 for(j=0;j<480;j=j+1) begin
  raster=j;
  for(k=0;k<640;k=k+1) begin
   x=k;y=j;#1;colour=trail_on ? trail_rgb:rgb;
   $fwrite(f,"%0d %0d %0d ",colour[11:8]*17,colour[7:4]*17,colour[3:0]*17);
   repeat(4) @(negedge clk);
  end
  $fwrite(f,"\n");
 repeat(640) @(negedge clk);
 end
 $fclose(f);$display("PASS: shared fruit renderer and continuous diagonal slash");$finish;
end
endmodule
