`timescale 1ns/1ps
module tb_scanline_equivalence;
reg clk=0;always #5 clk=~clk;
reg reset=1;reg [9:0] row=524,x=0,y=0;
reg [7:0] active=255,bomb=8'b10000000;
reg [127:0] px=0,py=0;reg [255:0] hx=0,hy=0;
reg [31:0] kinds=0;reg [15:0] spins=0,dirs=0,halves=0;reg [39:0] radii=0;
wire [11:0] actual,expected;
pixel_compositor #(.N(8),.SIZE_SHIFT(1),.VARIABLE_RADIUS(1),.DETAILED_ART(1)) dut(.clk(clk),.reset(reset),.raster_y(row),.x(x),.y(y),.video_on(1'b1),.heart_levels(12'd0),
 .radii(radii),.health(16'd0),.state(2'd1),.cursor_x(10'd0),.cursor_y(10'd0),.slash_active(1'b0),
 .active(active),.bomb(bomb),.positions_x(px),.positions_y(py),.fruit_types(kinds),.spins(spins),
 .explosion_active(8'd0),.explosion_x(128'd0),.explosion_y(128'd0),.explosion_age(9'd0),
 .effect_radii(radii),.cut_direction(dirs),.effect_types(kinds),.effect_spins(spins),
 .halves_active(halves),.halves_x(hx),.halves_y(hy),.splash_active(8'd0),.splash_x(128'd0),.splash_y(128'd0),
 .splash_age(40'd0),.wall_on(1'b0),.wall_rgb(12'd0),.rgb(actual));
pixel_compositor_ref #(.N(8),.SIZE_SHIFT(1),.VARIABLE_RADIUS(1),.DETAILED_ART(1)) reference(.clk(clk),.reset(reset),.raster_y(row),.x(x),.y(y),.video_on(1'b1),.heart_levels(12'd0),
 .radii(radii),.health(16'd0),.state(2'd1),.cursor_x(10'd0),.cursor_y(10'd0),.slash_active(1'b0),
 .active(active),.bomb(bomb),.positions_x(px),.positions_y(py),.fruit_types(kinds),.spins(spins),
 .explosion_active(8'd0),.explosion_x(128'd0),.explosion_y(128'd0),.explosion_age(9'd0),
 .effect_radii(radii),.cut_direction(dirs),.effect_types(kinds),.effect_spins(spins),
 .halves_active(halves),.halves_x(hx),.halves_y(hy),.splash_active(8'd0),.splash_x(128'd0),.splash_y(128'd0),
 .splash_age(40'd0),.wall_on(1'b0),.wall_rgb(12'd0),.rgb(expected));
integer i,j,t,yy,errors=0;
task step;begin @(posedge clk);#1;end endtask
task check_row;
 input integer target;
 begin
  @(negedge clk);row=target==0 ? 524:target-1;y=target==0 ? 0:target-1;
  repeat(3190) step;
  if(dut.fruit_layer.state!=0) $fatal(1,"scanline missed deadline row %0d",target);
  @(negedge clk);row=target;y=target;
  for(j=0;j<640;j=j+1) begin
   x=j;#1;
   if(actual!==expected) begin
    if(errors<8) $display("mismatch x%0d y%0d got%h expected%h",j,target,actual,expected);
    errors=errors+1;
   end
  end
 end
endtask
initial begin
 for(i=0;i<8;i=i+1) begin
  px[i*16+:16]=(70+i*68)*16;py[i*16+:16]=100*16;
  hx[(i*2)*16+:16]=(70+i*68)*16;hx[(i*2+1)*16+:16]=(80+i*68)*16;
  hy[(i*2)*16+:16]=200*16;hy[(i*2+1)*16+:16]=200*16;
  kinds[i*4+:4]=i;spins[i*2+:2]=i%4;dirs[i*2+:2]=i%4;radii[i*5+:5]=18;
 end
 step;@(negedge clk);reset=0;
 check_row(0);
 for(t=0;t<9;t=t+1) check_row(58+t*10);
 halves=16'hffff;
 for(t=0;t<9;t=t+1) check_row(158+t*10);
 // Worst-case scheduler load: all 24 surfaces share a row, radius48 on screen.
 for(i=0;i<8;i=i+1) begin
  radii[i*5+:5]=24;hy[(2*i)*16+:16]=1600;hy[(2*i+1)*16+:16]=1600;
 end
 check_row(100);
 if(errors!=0) $fatal(1,"pixel mismatches %0d",errors);
 $display("PASS: scanline pixel equivalence, transparency, halves, wrap and worst-case deadline");$finish;
end
endmodule
