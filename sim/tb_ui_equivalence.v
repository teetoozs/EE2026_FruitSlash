`timescale 1ns/1ps
module tb_ui_equivalence;
 reg clk=0;always #5 clk=~clk;
 reg [9:0] x=0,y=0;reg [1:0] state=0;
 reg [15:0] score=449,best=449;
 wire on_a,on_b;wire [11:0] rgb_a,rgb_b;
 ui_screens a(.clk(clk),.x(x),.y(y),.state(state),.score(score),.best_score(best),
 .cursor_x(10'd175),.cursor_y(10'd280),.slash_active(1'b0),.btn_start(1'b0),.ui_on(on_a),.ui_rgb(rgb_a));
 reference_ui_screens b(.clk(clk),.x(x),.y(y),.state(state),.score(score),.best_score(best),
 .cursor_x(10'd175),.cursor_y(10'd280),.slash_active(1'b0),.btn_start(1'b0),.ui_on(on_b),.ui_rgb(rgb_b));
 integer st,ix,iy,scenario;
 initial begin
  for(scenario=0;scenario<3;scenario=scenario+1) begin
   score=scenario==0 ? 449:scenario==1 ? 65535:0;
   best=scenario==0 ? 449:65535;
   repeat(40) @(negedge clk);
   for(st=0;st<4;st=st+1) begin
    state=st;
    for(iy=0;iy<480;iy=iy+1) for(ix=0;ix<640;ix=ix+1) begin
     x=ix;y=iy;@(negedge clk);
     if(on_a!==on_b || rgb_a!==rgb_b)
      $fatal(1,"UI mismatch state=%0d x=%0d y=%0d expected=%h got=%h",st,ix,iy,rgb_b,rgb_a);
    end
   end
  end
  $display("PASS: UI pixel equivalence");$finish;
 end
endmodule
