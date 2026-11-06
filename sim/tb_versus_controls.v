`timescale 1ns/1ps
module tb_versus_controls;
reg clk=0;always #5 clk=~clk;
reg reset=1,tick=0,enabled=1,fh=0,bh=0,rotate=0;
reg [14:0] switches=0;
wire launch,bomb,selected;wire [3:0] origin,target;wire [2:0] speed;
wire [6:0] cooldown;wire [1:0] edge_id;wire [5:0] charge;
wire signed [15:0] x,y,vx,vy;
versus_controls dut(.clk(clk),.reset(reset),.tick(tick),.enabled(enabled),.switches(switches),
 .fruit_hold(fh),.bomb_hold(bh),.rotate_press(rotate),.launch(launch),.bomb(bomb),
 .origin(origin),.target(target),.selected(selected),.speed(speed),.cooldown(cooldown),
 .orientation(edge_id),.charge(charge),.start_x(x),.start_y(y),.velocity_x(vx),.velocity_y(vy));
wire [7:0] active,bombs;wire [127:0] px,py;
object_physics phys(.clk(clk),.reset(reset),.game_tick(1'b0),.playing(enabled),.versus(1'b1),
 .launch(launch),.launch_bomb(bomb),.launch_x(x),.launch_y(y),.launch_vx(vx),.launch_vy(vy),
 .difficulty(2'd0),.remove_mask(8'd0),.active(active),.bomb(bombs),.positions_x(px),.positions_y(py));
task step;begin @(posedge clk);#1;end endtask
task frame;begin @(negedge clk);tick=1;step;@(negedge clk);tick=0;step;end endtask
task rotate_edge;begin @(negedge clk);rotate=1;step;@(negedge clk);rotate=0;step;end endtask
integer i;integer launched=0;
always @(posedge clk) if(launch) launched=launched+1;
initial begin
 step;@(negedge clk);reset=0;step;
 for(i=0;i<15;i=i+1) begin
  @(negedge clk);switches=0;step;@(negedge clk);switches=15'b1<<i;step;
  if(!selected || origin!=i || target!=i) $fatal(1,"switch position %0d",i);
 end
 @(negedge clk);switches=0;step;@(negedge clk);switches=1;step;
 if(x!=9600 || y!=8000 || vy>=0) $fatal(1,"bottom start");
 @(negedge clk);switches=3;step;
 if(-vx<=-vy) $fatal(1,"near switch must be shallow");
 @(negedge clk);switches=15'b100000000000001;step;
 if(-vy<=-vx) $fatal(1,"far switch must be steep");
 @(negedge clk);switches=0;step;@(negedge clk);switches=1;step;
 @(negedge clk);fh=1;step;repeat(70) frame;
 if(launch || charge!=48 || vy!= -200) $fatal(1,"charge saturation or premature throw");
 @(negedge clk);fh=0;step;if(!launch || bomb) $fatal(1,"release throw");
 repeat(12) step;
 if(active!=1 || px[15:0]!=9600 || py[15:0]!=8000 || phys.vy[0]!= -200) $fatal(1,"capture");
 if(launched!=1) $fatal(1,"duplicate throw");
 repeat(25) frame;
 rotate_edge;if(edge_id!=1 || x!= -320 || vx<=0) $fatal(1,"left");
 rotate_edge;if(edge_id!=2 || y!= -320 || vy<=0) $fatal(1,"top");
 rotate_edge;if(edge_id!=3 || x!=10560 || vx>=0) $fatal(1,"right");
 rotate_edge;if(edge_id!=0) $fatal(1,"wrap");
 @(negedge clk);bh=1;step;repeat(2) frame;
 @(negedge clk);bh=0;step;if(!launch || !bomb || charge>=48) $fatal(1,"tap bomb");
 repeat(12) step;if(launched!=2) $fatal(1,"bomb duplicate");
 @(negedge clk);enabled=0;fh=1;step;repeat(100) frame;
 @(negedge clk);enabled=1;step;repeat(4) frame;
 if(launch || dut.charging) $fatal(1,"pause phantom throw");
 $display("PASS: 15 origins, charge cap, release-only launch, four edges, snapshot and pause");$finish;
end
initial begin #100000;$fatal(1,"timeout");end
endmodule
