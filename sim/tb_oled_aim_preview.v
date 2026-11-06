`timescale 1ns/1ps
module tb_oled_aim_preview;
reg clk=0;always #5 clk=~clk;
reg reset=1;reg [1:0] edge_id=0;reg [6:0] x=0;reg [5:0] y=0;
reg signed [15:0] sx=8000,sy=8000,vx=-100,vy=-160;
wire [15:0] rgb;
versus_oled_view dut(.clk(clk),.reset(reset),.selected(1'b1),.orientation(edge_id),.charge(6'd40),.cooldown(7'd0),
 .start_x(sx),.start_y(sy),.vx(vx),.vy(vy),.x(x),.y(y),.rgb(rgb));
integer e,i,j,f,tx,ty,px,py,ivx,ivy,k;
initial begin
 #20;reset=0;
 for(e=0;e<4;e=e+1) begin
  edge_id=e;
  case(e)
   0:begin sx=8000;sy=8000;vx=-100;vy=-160;end
   1:begin sx=-320;sy=6000;vx=160;vy=-100;end
   2:begin sx=2400;sy=-320;vx=100;vy=160;end
   3:begin sx=10560;sy=2000;vx=-160;vy=100;end
  endcase
  repeat(17000) @(negedge clk);
  if(!dut.valid || dut.last_inputs!={1'b1,sx,sy,vx,vy}) $fatal(1,"preview stale");
  px=sx;py=sy;ivx=vx;ivy=vy;
  for(k=0;k<30;k=k+1) begin
   tx=((px*15)>>>11)+10;ty=((py*13)>>>12)+9;
   if(tx>=2 && tx<94 && ty>=2 && ty<43 && !dut.path[{dut.display_bank,ty[5:0],tx[6:0]}]) $fatal(1,"missing predicted point");
   px=px+ivx;py=py+ivy;ivy=ivy<189 ? ivy+3:192;
  end
  case(e)
   0:f=$fopen("build/oled_aim_bottom.ppm","w");
   1:f=$fopen("build/oled_aim_left.ppm","w");
   2:f=$fopen("build/oled_aim_top.ppm","w");
   3:f=$fopen("build/oled_aim_right.ppm","w");
  endcase
  $fwrite(f,"P3\n96 64\n255\n");
  for(j=0;j<64;j=j+1) begin for(i=0;i<96;i=i+1) begin
   x=i;y=j;#1;$fwrite(f,"%0d %0d %0d ",rgb[15:11]*255/31,rgb[10:5]*255/63,rgb[4:0]*255/31);
  end $fwrite(f,"\n");end
  $fclose(f);
 end
 $display("PASS: OLED live orientation, trajectory physics and rendered layout");$finish;
end
endmodule
