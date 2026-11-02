// Independent combinational geometry per slot; no shared procedural scratch state.
module splash_renderer #(parameter N=8, parameter FRUIT_PALETTE=0)(
 input [9:0] x,y, input [N-1:0] active,
 input [N*16-1:0] positions_x,positions_y,
 input [N*5-1:0] ages,radii,
 output pixel_on, output reg [11:0] rgb
);
 wire [N-1:0] mask;
 wire [N*12-1:0] colours;
 genvar k;
 generate for(k=0;k<N;k=k+1) begin:drop
  wire signed [15:0] qx=positions_x[k*16+:16],qy=positions_y[k*16+:16];
  wire [4:0] age=ages[k*5+:5];
  wire signed [12:0] cx=qx>>>4,cy=(qy>>>4)+$signed({10'd0,age[4:2]});
  wire signed [12:0] dx=$signed({1'b0,x})-cx,dy=$signed({1'b0,y})-cy;
  // A diamond becomes a box in diagonal coordinates u=dx+dy, v=dx-dy.
  // This avoids nested absolute-value subtractors in the carry network.
  wire signed [13:0] u={dx[12],dx}+{dy[12],dy};
  wire signed [13:0] v={dx[12],dx}-{dy[12],dy};
  wire [13:0] au=u<0 ? -u:u, av=v<0 ? -v:v;
  wire [7:0] spread=8'd5+age;
  wire [7:0] radius=age<8 ? 3:age<16 ? 2:1;
  wire [7:0] core=age<8 ? 10:age<16 ? 7:4;
  wire u1=au>=spread-radius && au<=spread+radius;
  wire v1=av>=spread-radius && av<=spread+radius;
  wire u2=au>=(spread<<1)-radius && au<=(spread<<1)+radius;
  wire v2=av>=(spread<<1)-radius && av<=(spread<<1)+radius;
  assign mask[k]=active[k] && age<24 && (age<16 || !(x[0]^y[0])) &&
   ((au<=core && av<=core) || (u1&&v1) || (u2&&av<=radius) || (v2&&au<=radius));
  wire [11:0] base=radii[k*5+:5]==24 ? 12'hF45 :
    k%4==0 ? 12'hF90:k%4==1 ? 12'hF45:k%4==2 ? 12'h8F4:12'hD6F;
  assign colours[k*12+:12]=FRUIT_PALETTE ? (age<8 ? base:
    {1'b0,base[11:9],1'b0,base[7:5],1'b0,base[3:1]}) :
    (age<8 ? 12'hF90:age<16 ? 12'hD60:12'hA40);
 end endgenerate
 assign pixel_on=|mask;
 integer j;
 always @(*) begin rgb=0; for(j=0;j<N;j=j+1) if(mask[j]) rgb=colours[j*12+:12]; end
endmodule
