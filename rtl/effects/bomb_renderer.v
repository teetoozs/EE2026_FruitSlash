// Five seconds at 60 Hz. Full-screen grey flash, expanding smoke and shake.
module bomb_renderer #(parameter N=8)(
 input [9:0] x,y, input [N-1:0] active,
 input [N*16-1:0] origins_x,origins_y,
 input [8:0] age, output pixel_on, output reg [11:0] rgb
);
 assign pixel_on=|active;
 wire signed [12:0] shake_x=age[2] ? 13'sd9 : -13'sd9;
 wire signed [12:0] shake_y=age[1] ? 13'sd6 : -13'sd6;
 wire signed [12:0] sx=$signed({1'b0,x})+shake_x;
 wire signed [12:0] sy=$signed({1'b0,y})+shake_y;
 wire [3:0] smoke=(sx[6:3]^sy[6:3]^age[5:2]);
 integer i;
 reg signed [12:0] cx,cy,dx,dy;
 reg [12:0] ax,ay,distance;
 reg front;
 always @(*) begin
  front=0;cx=0;cy=0;dx=0;dy=0;ax=0;ay=0;distance=0;
  for(i=0;i<N;i=i+1) begin
   cx=$signed(origins_x[i*16+:16])>>>4;cy=$signed(origins_y[i*16+:16])>>>4;
   dx=sx-cx;dy=sy-cy;ax=dx<0 ? -dx:dx;ay=dy<0 ? -dy:dy;
   distance=(ax>ay ? ax:ay)+((ax>ay ? ay:ax)>>1);
   if(active[i] && distance<({4'b0,age}<<3)) front=1;
  end
 end
 reg [3:0] grey;
 always @(*) begin
  grey=0;
  if(|active) begin
   if(age<12) grey=age[1] ? 15:13;
   else if(age<240) grey=front ? (smoke<5 ? 13:smoke<11 ? 11:9) : 4;
   else grey=smoke<8 ? 8:6;
  end
  rgb={grey,grey,grey};
 end
endmodule
