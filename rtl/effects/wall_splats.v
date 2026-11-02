module wall_splats #(parameter N=8, parameter LIFE=480)(
 input clk, reset, tick, playing,
 input [N-1:0] hits, bomb,
 input [N*16-1:0] px, py,
 input [9:0] x,y,
 output pixel_on, output reg [11:0] rgb
);
 reg signed [15:0] sx[0:N-1], sy[0:N-1];
 reg [9:0] life[0:N-1];
 integer i,j;
 always @(posedge clk) begin
  if(reset) for(i=0;i<N;i=i+1) begin life[i]<=0; sx[i]<=0; sy[i]<=0; end
  else if(playing) for(i=0;i<N;i=i+1) begin
   if(tick && life[i]!=0) life[i]<=life[i]-1'b1;
   if(hits[i] && !bomb[i]) begin life[i]<=LIFE; sx[i]<=px[i*16+:16]; sy[i]<=py[i*16+:16]; end
  end
 end
 wire [N-1:0] mask;
 genvar k;
 generate for(k=0;k<N;k=k+1) begin:shape
  wire signed [12:0] dx=$signed({1'b0,x})-(sx[k]>>>4);
  wire signed [12:0] dy=$signed({1'b0,y})-(sy[k]>>>4);
  wire [12:0] ax=dx<0 ? -dx:dx, ay=dy<0 ? -dy:dy;
  assign mask[k]=(life[k]!=0) && (life[k]>120 || !(x[0]^y[0])) &&
    ((ax+(ay>>1)<30 && ay<35) || (ax<7 && ay<52) || (ay<5 && ax<49) ||
     (ax>28 && ax<37 && ay>25 && ay<32));
 end endgenerate
 assign pixel_on=|mask;
 always @(*) begin
  rgb=0;
  for(j=0;j<N;j=j+1) if(mask[j]) case(j%4)
   0:rgb=12'hA42; 1:rgb=12'hA13; 2:rgb=12'h482; default:rgb=12'h735;
  endcase
 end
endmodule
