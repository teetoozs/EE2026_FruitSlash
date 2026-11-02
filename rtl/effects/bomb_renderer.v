// Four-second cinematic at 60 Hz: cracks (0..179), burst (180..209), fade (210..239).
// Transparent outside the bomb/light so the frozen game remains visible.
module bomb_renderer #(parameter N=8, parameter RADIUS=18)(
 input [9:0] x,y, input [N-1:0] active,
 input [N*16-1:0] origins_x,origins_y,
 input [8:0] age, output reg pixel_on, output reg [11:0] rgb
);
 integer i;
 reg signed [12:0] cx,cy,dx,dy;
 reg [12:0] ax,ay,dist,minor,major,reach,width,travel,fx,fy;
 reg body,ray,crack,fragment;
 reg [8:0] phase;
 always @(*) begin
  pixel_on=0;rgb=0;cx=0;cy=0;dx=0;dy=0;ax=0;ay=0;dist=0;
  minor=0;major=0;reach=0;width=0;travel=0;fx=0;fy=0;
  body=0;ray=0;crack=0;fragment=0;phase=0;
  for(i=0;i<N;i=i+1) begin
   cx=$signed(origins_x[i*16+:16])>>>4;
   cy=$signed(origins_y[i*16+:16])>>>4;
   dx=$signed({1'b0,x})-cx;dy=$signed({1'b0,y})-cy;
   ax=dx<0 ? -dx:dx;ay=dy<0 ? -dy:dy;
   major=ax>ay ? ax:ay;minor=ax>ay ? ay:ax;
   dist=major+(minor>>1);
   body=major<=RADIUS && dist<=RADIUS+(RADIUS>>2);
   if(active[i] && age<240) begin
    if(age<180) begin
     // Staggered seams widen slowly; short tapered beams emerge from them.
     width=1+(age/60);
     reach=RADIUS+(age>>2);
     crack=age>=24 && (ax<=width ||
           (age>=60 && ay<=width) ||
           (age>=108 && (ax>ay ? ax-ay:ay-ax)<=width));
     ray=age>=48 && major>RADIUS && major<=reach &&
         (minor<=((major-RADIUS)>>3)+width) &&
         ((ay>ax) || age>=90);
     if(ray) begin pixel_on=1;rgb=12'hAAA;end
     if(body) begin
      pixel_on=1;
      rgb=dx<0 && dy<0 ? 12'h444:12'h222;
      if(dist>=RADIUS+(RADIUS>>2)-2) rgb=12'h555;
      if(crack) rgb=age<120 ? 12'hAAA:12'hDDD;
     end
     if(ax<=3 && dy < -RADIUS && dy>=-RADIUS-7) begin
      pixel_on=1;rgb=12'h777;
     end
    end else begin
     phase=age-180;
     travel=RADIUS+(phase>>1);
     // Brief local flash, followed by eight small grey shell fragments.
     if(phase<6 && dist<=RADIUS+(phase<<1)) begin
      pixel_on=1;rgb=12'hDDD;
     end
     fx=ax>travel ? ax-travel:travel-ax;
     fy=ay>travel ? ay-travel:travel-ay;
     fragment=(fx<=3 && ay<=3)||(fy<=3 && ax<=3)||(fx<=2 && fy<=2);
     if(fragment && (phase<30 || !(x[0]^y[0]))) begin
      pixel_on=1;rgb=phase<30 ? 12'hAAA:12'h666;
     end
    end
   end
  end
 end
endmodule
