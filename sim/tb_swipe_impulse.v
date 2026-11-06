`timescale 1ns/1ps
module tb_swipe_impulse;
reg clk=0;always #5 clk=~clk;
reg reset=1;reg [1:0] hit=0;reg [9:0] x1=108;
cut_effects #(.N(2),.VARIABLE_RADIUS(1)) dut(.clk(clk),.reset(reset),.game_tick(1'b0),.playing(1'b1),
 .blade_x0(10'd100),.blade_y0(10'd100),.blade_x1(x1),.blade_y1(10'd100),
 .hit_mask(hit),.bomb(2'b0),.radii({5'd18,5'd12}),.positions_x(32'd0),.positions_y(32'd0));
task step;begin @(posedge clk);#1;end endtask
integer slow;
initial begin
 step;@(negedge clk);reset=0;hit=3;step;
 slow=-dut.vy[0];
 if(dut.vy[0]>=0 || dut.vy[1]<=0 || -dut.vy[2]>=slow) $fatal(1,"split normal/mass response");
 @(negedge clk);hit=0;step;@(negedge clk);x1=300;hit=3;step;
 if(-dut.vy[0]<=slow || -dut.vy[0]!=96 || dut.vx[0]!=48) $fatal(1,"swipe speed/cap");
 if(dut.vx[2]!=24 || dut.vy[2]!= -48) $fatal(1,"heavy impulse");
 $display("PASS: directional fragments, swipe impulse cap and mass response");$finish;
end
endmodule
