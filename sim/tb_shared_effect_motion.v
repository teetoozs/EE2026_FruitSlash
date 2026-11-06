`timescale 1ns/1ps
module tb_shared_effect_motion;
reg clk=0;always #5 clk=~clk;
reg reset=1,tick=0,playing=1;reg [7:0] hit=0;
reg [127:0] px=0,py=0;wire [15:0] active;wire [255:0] hx,hy;
cut_effects dut(.clk(clk),.reset(reset),.game_tick(tick),.playing(playing),
 .blade_x0(10'd100),.blade_y0(10'd100),.blade_x1(10'd100),.blade_y1(10'd120),
 .hit_mask(hit),.bomb(8'd0),.radii(40'd0),.positions_x(px),.positions_y(py),
 .halves_active(active),.halves_x(hx),.halves_y(hy));
task step;begin @(posedge clk);#1;end endtask
integer i;reg [255:0] saved;
initial begin
 for(i=0;i<8;i=i+1) begin px[i*16+:16]=(100+i*60)*16;py[i*16+:16]=3200;end
 step;@(negedge clk);reset=0;hit=255;tick=1;step;
 @(negedge clk);hit=0;tick=0;repeat(20) step;
 if(active!=65535 || hx[15:0]!=1600 || hx[31:16]!=1600) $fatal(1,"capture must win over tick");
 @(negedge clk);tick=1;step;@(negedge clk);tick=0;repeat(20) step;
 for(i=0;i<8;i=i+1) begin
  if($signed(hx[(i*2)*16+:16])!=(100+i*60)*16-52 || $signed(hx[(i*2+1)*16+:16])!=(100+i*60)*16+52)
   $fatal(1,"shared movement missed pair %0d",i);
 end
 saved=hx;@(negedge clk);playing=0;tick=1;repeat(20) step;
 if(hx!==saved) $fatal(1,"pause");
 @(negedge clk);playing=1;tick=0;hit=255;step;@(negedge clk);hit=0;repeat(20) step;
 if(hx[15:0]!=1600 || hx[255:240]!=(100+7*60)*16) $fatal(1,"reused slots");
 $display("PASS: all eight cuts, shared movement, capture priority, pause and slot reuse");$finish;
end
endmodule
