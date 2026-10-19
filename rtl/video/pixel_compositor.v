// Aloysius owns the single final RGB selector. This is diagnostic art,
// not the promised final sprites, text screens or procedural wood.
module pixel_compositor #(parameter N=8)(
 input [9:0] x,y,input video_on,input [1:0] state,
 input [9:0] cursor_x,cursor_y,input slash_active,
 input [N-1:0] active,bomb,input [N*16-1:0] positions_x,positions_y,
 input signed [15:0] effect_x,effect_y,input [5:0] ttl,
 output reg [11:0] rgb
);
 integer i,dx,dy,cx,cy;
 reg signed [15:0] qx,qy;
 always @(*) begin
  rgb=y[5]?12'h642:12'h753;
  dx=0;dy=0;cx=0;cy=0;qx=0;qy=0;
  for(i=0;i<N;i=i+1) begin
   qx=positions_x[i*16+:16];qy=positions_y[i*16+:16];
   cx=qx>>>4;cy=qy>>>4;dx=$signed({1'b0,x})-cx;dy=$signed({1'b0,y})-cy;
   if(active[i] && dx*dx+dy*dy<=324) rgb=bomb[i]?12'h111:12'hF40;
  end
  dx=$signed({1'b0,x})-effect_x;dy=$signed({1'b0,y})-effect_y;
  if(ttl!=0 && dx*dx+dy*dy<900) rgb=12'hFF0;
  dx=$signed({1'b0,x})-$signed({1'b0,cursor_x});
  dy=$signed({1'b0,y})-$signed({1'b0,cursor_y});
  if((dx>=-6 && dx<=6 && dy==0)||(dy>=-6 && dy<=6 && dx==0))
   rgb=slash_active?12'hF00:12'hFFF;
  // Diagnostic state bar: title blue, playing green, paused yellow, over red.
  if(y<12) case(state)
   0:rgb=12'h00F;1:rgb=12'h0F0;2:rgb=12'hFF0;3:rgb=12'hF00;
  endcase
  if(!video_on) rgb=0;
 end
endmodule
