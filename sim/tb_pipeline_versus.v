`timescale 1ns/1ps
module tb_pipeline_versus;
reg clk=0;always #5 clk=~clk;
reg reset=1,start=0,slash=1;reg [7:0] hits=0,bombs=0;
wire [15:0] score,best;wire [1:0] state,lives;
game_controller game(.clk(clk),.reset(reset),.start_pressed(start),.pause(1'b0),.effects_busy(1'b0),.slash_active(slash),.hit_mask(hits),.bomb(bombs),.missed(8'd0),.bonus_hit(1'b0),.score(score),.best_score(best),.state(state),.lives(lives));
reg launch=0;reg signed [15:0] lx=16'sd9216,lvx=-80,lvy=-139;wire [7:0] active,kind;wire [127:0] px,py;
object_physics physics(.clk(clk),.reset(reset),.game_tick(1'b0),.playing(1'b1),.versus(1'b1),.launch(launch),.launch_bomb(1'b1),.launch_x(lx),.launch_y(16'sd8000),.launch_vx(lvx),.launch_vy(lvy),.difficulty(2'd0),.remove_mask(8'd0),.active(active),.bomb(kind),.positions_x(px),.positions_y(py));
task step;begin @(posedge clk);#1;end endtask
initial begin
step;@(negedge clk);reset=0;start=1;step;
@(negedge clk);start=0;hits=3;launch=1;step;
@(negedge clk);hits=1;launch=0;lx=0;lvx=0;step;
if(score!=2) $fatal(1,"first points");
@(negedge clk);hits=0;step;if(score!=3) $fatal(1,"consecutive points");
step;if(best!=3) $fatal(1,"best score");
if(active!=1 || kind!=1 || px[15:0]!=9216 || physics.vx[0]!=-80) $fatal(1,"captured throw");
@(negedge clk);hits=2;bombs=2;step;if(lives!=0 || state!=3) $fatal(1,"bomb fatal");
$display("PASS: pipelined scores, consecutive cuts, best score, captured throw, fatal bomb");$finish;
end
endmodule
