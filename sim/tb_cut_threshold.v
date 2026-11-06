`timescale 1ns/1ps
module tb_cut_threshold;
reg clk=0;always #5 clk=~clk;
reg reset=1,event_in=0;
reg [9:0] x1=100,y1=100;
wire hit,busy;
slice_detector #(.N(1)) dut(.clk(clk),.reset(reset),.playing(1'b1),
 .blade_event(event_in),.slash_active(1'b1),.x0(10'd100),.y0(10'd100),.x1(x1),.y1(y1),
 .active(1'b1),.radii(5'd18),.positions_x(16'd1600),.positions_y(16'd1600),.hit_mask(hit),.busy(busy));
task check;
 input integer dx,dy;input expected;
 reg got;integer i;
 begin
 @(negedge clk);x1=100+dx;y1=100+dy;event_in=1;
 @(negedge clk);event_in=0;got=0;
 for(i=0;i<8;i=i+1) begin @(negedge clk);if(hit) got=1;end
 if(got!==expected) $fatal(1,"movement (%0d,%0d): expected %b got %b",dx,dy,expected,got);
 end
endtask
initial begin
 repeat(2) @(negedge clk);reset=0;
 check(0,0,0);check(1,0,0);check(3,0,0);check(2,2,0);
 check(4,0,1);check(0,-4,1);check(3,3,1);check(12,0,1);
 $display("PASS: stationary/tiny cuts rejected; 4-pixel and diagonal cuts accepted");$finish;
end
endmodule
