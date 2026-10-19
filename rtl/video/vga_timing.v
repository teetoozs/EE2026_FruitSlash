// Aloysius: 640x480, 800x525 total, 25 MHz pixel enable (~59.52 Hz).
// All registers remain in the 100 MHz domain.
module vga_timing(
 input clk,input reset,output [9:0] x,y,
 output video_on,output Hsync,Vsync
);
 reg [1:0] div=0;
 reg [9:0] h=0,v=0;
 assign x=h;assign y=v;
 assign video_on=h<640 && v<480;
 assign Hsync=!(h>=656 && h<752);
 assign Vsync=!(v>=490 && v<492);
 always @(posedge clk) begin
  if(reset) begin div<=0;h<=0;v<=0;end
  else begin
   div<=div+1'b1;
   if(div==3) begin
    if(h==799) begin h<=0;if(v==524)v<=0;else v<=v+1'b1;end
    else h<=h+1'b1;
   end
  end
 end
endmodule
