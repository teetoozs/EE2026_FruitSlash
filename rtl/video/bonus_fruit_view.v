module bonus_fruit_view(
 input clk,reset,active,cut,falling,
 input signed [15:0] position_x,position_y,
 input [5:0] radius, input [6:0] fall_age,
 input [9:0] x0,y0,x1,y1,x,y,
 output pixel_on, output reg [11:0] rgb
);
 reg [9:0] ax[0:7],ay[0:7],bx[0:7],by[0:7];
 reg [7:0] valid=0;reg [2:0] next_cut=0;
 integer i;
 always @(posedge clk) begin
  if(reset || !active) begin valid<=0;next_cut<=0;end
  else if(cut) begin
   ax[next_cut]<=x0;ay[next_cut]<=y0;bx[next_cut]<=x1;by[next_cut]<=y1;
   valid[next_cut]<=1;next_cut<=next_cut+1'b1;
  end
 end
 wire signed [12:0] center_x=position_x>>>4;
 wire signed [12:0] center_y=position_y>>>4;
 wire signed [12:0] screen_dx=$signed({1'b0,x})-center_x;
 // Split at the middle, move the halves outwards and use the same fruit texture.
 wire signed [12:0] separation=falling ? $signed({5'd0,fall_age,1'b0}) : 13'sd0;
 wire signed [12:0] dx=screen_dx<0 ? screen_dx+separation : screen_dx-separation;
 wire signed [12:0] dy=$signed({1'b0,y})-center_y;
 wire [12:0] absx=dx<0 ? -dx:dx,absy=dy<0 ? -dy:dy;
 wire [13:0] distance_squared=absx[6:0]*absx[6:0]+absy[6:0]*absy[6:0];
 wire [11:0] radius_squared=radius*radius;
 wire correct_half=!falling || (screen_dx<0 ? dx<0 : dx>=0);
 assign pixel_on=active && correct_half && absx<=radius && absy<=radius &&
                 distance_squared<=radius_squared;
 wire [7:0] scar;
 genvar k;
 generate for(k=0;k<8;k=k+1) begin:marks
  wire signed [10:0] vx=$signed({1'b0,bx[k]})-$signed({1'b0,ax[k]});
  wire signed [10:0] vy=$signed({1'b0,by[k]})-$signed({1'b0,ay[k]});
  wire signed [10:0] px=$signed({1'b0,x})-$signed({1'b0,ax[k]});
  wire signed [10:0] py=$signed({1'b0,y})-$signed({1'b0,ay[k]});
  wire signed [22:0] cross_product=px*vy-py*vx;
  wire [22:0] distance=cross_product<0 ? -cross_product:cross_product;
  wire [10:0] avx=vx<0 ? -vx:vx,avy=vy<0 ? -vy:vy;
  wire [12:0] thickness=({2'b0,avx}+{2'b0,avy})<<1;
  wire box_x=x>=(ax[k]<bx[k]?ax[k]:bx[k]) && x<=(ax[k]>bx[k]?ax[k]:bx[k]);
  wire box_y=y>=(ay[k]<by[k]?ay[k]:by[k]) && y<=(ay[k]>by[k]?ay[k]:by[k]);
  assign scar[k]=valid[k] && (avx!=0 || avy!=0) && box_x && box_y && distance<=thickness;
 end endgenerate
 always @(*) begin
  rgb=dy>($signed({1'b0,radius})>>>2) ? 12'hD60:12'hF92;
  if(dx< -12 && dy< -12) rgb=12'hFC7;
  if(distance_squared+{6'd0,radius,2'b0}>=radius_squared) rgb=12'hA40;
  if(falling && absx<=2) rgb=12'hFFE;
  if(!falling && |scar) rgb=12'hFFE;
 end
endmodule
