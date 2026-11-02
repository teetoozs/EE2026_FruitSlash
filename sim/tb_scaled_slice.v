`timescale 1ns/1ps
module tb_scaled_slice;
 reg clk=0;always #5 clk=~clk;
 reg reset=1,event_in=0;reg [9:0] yy=130;
 wire [1:0] hit;wire busy;
 slice_detector #(.N(2),.VARIABLE_RADIUS(1),.SIZE_SHIFT(1)) d(
 .clk(clk),.reset(reset),.playing(1'b1),.blade_event(event_in),.slash_active(1'b1),
 .x0(10'd0),.y0(yy),.x1(10'd300),.y1(yy),.active(2'b11),.radii({5'd18,5'd18}),
 .positions_x({16'd3200,16'd1600}),.positions_y({16'd1600,16'd1600}),.hit_mask(hit),.busy(busy));
 task swipe;begin @(negedge clk);event_in=1;@(negedge clk);event_in=0;wait(!busy);#1;end endtask
 initial begin
  repeat(2) @(negedge clk);reset=0;swipe;
  if(hit!==3) $fatal(1,"One swept slice must hit both doubled fruits at offset 30");
  yy=137;swipe;
  if(hit!==0) $fatal(1,"Offset 37 must miss radius 36");
  $display("PASS: scaled multi-fruit collision");$finish;
 end
 initial begin #10000;$fatal(1,"Timeout");end
endmodule
