module bonus_fruit_view(
 input clk,reset,active,cut,falling,
 input tri0 burst, input tick,
 input tri0 [3:0] fruit_type,
 input signed [15:0] position_x,position_y,
 input [5:0] radius, input [6:0] fall_age,
 input [9:0] x0,y0,x1,y1,x,y,
 output pixel_on, output reg [11:0] rgb
);
 reg [9:0] ax[0:9],ay[0:9];
 reg [1:0] direction[0:9];
 wire signed [10:0] cut_dx=$signed({1'b0,x1})-$signed({1'b0,x0});
 wire signed [10:0] cut_dy=$signed({1'b0,y1})-$signed({1'b0,y0});
 wire [10:0] cut_ax=cut_dx<0 ? -cut_dx:cut_dx,cut_ay=cut_dy<0 ? -cut_dy:cut_dy;
 reg [9:0] valid=0;reg [3:0] next_cut=0;
 reg [2:0] flash=0;
 always @(posedge clk) begin
 if(reset || !active) flash<=0;
 else if(cut) flash<=6;
 else if(tick && flash!=0) flash<=flash-1'b1;
 end
 integer i;
 always @(posedge clk) begin
  if(reset || !active) begin valid<=0;next_cut<=0;end
  else if(cut && next_cut<10 && (x0!=x1 || y0!=y1)) begin
   ax[next_cut]<=x0;ay[next_cut]<=y0;direction[next_cut]<=cut_ax>({1'b0,cut_ay}<<1) ? 0:cut_ay>({1'b0,cut_ax}<<1) ? 1:(cut_dx[10]^cut_dy[10]) ? 2:3;
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
 wire signed [12:0] inner_dy=dy+$signed({1'b0,radius}>>2);
 wire [12:0] inner_ay=inner_dy<0 ? -inner_dy:inner_dy;
 wire [13:0] inner_squared=absx[6:0]*absx[6:0]+inner_ay[6:0]*inner_ay[6:0];
 wire [5:0] inner_radius=radius-6'd8;
 wire [11:0] inner_radius_squared=inner_radius*inner_radius;
 wire fruit_pixel=active && correct_half && absx<=radius && absy<=radius &&
                 distance_squared<=radius_squared &&
                 (fruit_type!=4 || inner_squared>=inner_radius_squared) &&
                 (fruit_type!=6 || dy>=0 || $signed({1'b0,absx})<=($signed({1'b0,radius})>>>2)+(((dy+$signed({1'b0,radius}))*13'sd3)>>>2));
 wire [12:0] burst_x=screen_dx<0 ? -screen_dx:screen_dx;
 wire [12:0] burst_y=dy<0 ? -dy:dy;
 wire [12:0] travel=13'd8+{3'd0,fall_age,3'b0};
 wire [12:0] bx_delta=burst_x>travel ? burst_x-travel:travel-burst_x;
 wire [12:0] by_delta=burst_y>travel ? burst_y-travel:travel-burst_y;
 wire particles=(bx_delta<5 && burst_y<5)||(by_delta<5 && burst_x<5)||(bx_delta<4 && by_delta<4);
 wire [13:0] radial=burst_x+burst_y;
 wire ring=radial>=travel && radial<travel+8;
 wire cut_sparks=flash!=0 && !falling && radial>radius && radial<radius+24 &&
                 (burst_x<3 || burst_y<3 || (burst_x>burst_y ? burst_x-burst_y:burst_y-burst_x)<3);
 assign pixel_on=active && (burst ? (fall_age<3 ? radial<180:(particles||ring)):(fruit_pixel||cut_sparks));
 wire [9:0] scar;
 genvar k;
 generate for(k=0;k<10;k=k+1) begin:marks
  wire signed [10:0] px=$signed({1'b0,x})-$signed({1'b0,ax[k]});
  wire signed [10:0] py=$signed({1'b0,y})-$signed({1'b0,ay[k]});
  // Quantize the swipe to horizontal, vertical or either diagonal.
  // This avoids twenty per-pixel multipliers for ten persistent marks.
  wire signed [11:0] line_error=direction[k]==0 ? py:direction[k]==1 ? px:
    direction[k]==2 ? $signed({px[10],px})+$signed({py[10],py}):$signed({px[10],px})-$signed({py[10],py});
  wire [11:0] distance=line_error<0 ? -line_error:line_error;
  assign scar[k]=valid[k] && distance<=3;

 end endgenerate
 wire [11:0] surface_rgb;
 fruit_surface skin(.dx(dx),.dy(dy),.radius(radius),.kind(fruit_type),.bomb(1'b0),.cut_edge(1'b0),.rgb(surface_rgb));
 always @(*) begin
  rgb=surface_rgb;
  if(falling && absx<=2) rgb=12'hFFE;
  if(!falling && |scar) rgb=flash!=0 ? 12'hFFF:12'hFFE;
  if(flash!=0 && distance_squared+{5'd0,radius,3'b0}>=radius_squared) rgb=12'hFF8;
  if(cut_sparks) rgb=12'hFFF;
  if(burst) rgb=fall_age<3 || ring ? 12'hFFF:12'hFC4;
 end
endmodule
