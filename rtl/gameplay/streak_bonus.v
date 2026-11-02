// Ten clean cuts earn five seconds of repeat swipes. Timer pauses with gameplay.
module streak_bonus #(parameter N=8, parameter TARGET=10, parameter TICKS=300)(
 input clk,reset,tick,playing,slash_active,blade_event,contact,
 input [9:0] x0,y0,x1,y1,
 input [N-1:0] hits,bomb,missed,
 output reg active=0, output reg award=0,
 output reg [8:0] remaining=0, output reg [7:0] streak=0
);
 integer i,cuts;
 reg latched=0;
 reg [3:0] cooldown=0;
 wire outside=(x1<176 || x1>464 || y1<96 || y1>384);
 reg moved=0;
 always @(*) begin cuts=0; for(i=0;i<N;i=i+1) if(hits[i]&&!bomb[i]) cuts=cuts+1; end
 always @(posedge clk) begin
  award<=0;
  if(reset) begin active<=0; remaining<=0; streak<=0; latched<=0; cooldown<=0; moved<=0; end
  else if(playing) begin
   if(blade_event) moved <= (x0!=x1 || y0!=y1);
   if(!slash_active || (blade_event && outside)) latched<=0;
   if(tick && cooldown!=0) cooldown<=cooldown-1'b1;
   if(active) begin
    if(tick) begin
     if(remaining<=1) begin active<=0;remaining<=0;end
     else remaining<=remaining-1'b1;
    end
    if(contact && slash_active && moved && !latched && cooldown==0) begin
     award<=1; latched<=1; cooldown<=6;
    end
   end else if((|(hits & bomb)) || (|missed)) streak<=0;
   else if(streak+cuts>=TARGET) begin
    active<=1; remaining<=TICKS; streak<=0; latched<=1; cooldown<=0;
   end else streak<=streak+cuts;
  end
 end
endmodule
