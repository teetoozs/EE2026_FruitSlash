// Ten clean cuts launch a bonus fruit. Only cutting that fruit starts the bonus.
module streak_bonus #(parameter N=8, parameter TARGET=10, parameter TICKS=300)(
 input clk,reset,tick,playing,slash_active,blade_event,contact,
 input [9:0] x0,y0,x1,y1,
 input [N-1:0] hits,bomb,missed,
 output reg [3:0] fruit_type=0,
 output active, visible, accepting, cutting, falling,
 output reg burst=0,
 output reg award=0,
 output reg [8:0] remaining=0, output reg [7:0] streak=0,
 output reg signed [15:0] position_x=0, position_y=0,
 output reg [5:0] radius=36, output reg [6:0] fall_age=0
);
 localparam IDLE=0,FLY=1,ZOOM=2,CUT=3,FALL=4;
 reg [2:0] state=IDLE;
 // Keep special-fruit selection advancing in menus and across round resets.
 reg [31:0] random_kind=32'h91B7_D351;
 always @(posedge clk)
 random_kind<={random_kind[30:0],random_kind[31]^random_kind[21]^random_kind[1]^random_kind[0]};
 reg signed [15:0] velocity_y=0;
 reg [5:0] zoom_age=0;
 reg latched=0,moved=0;
 reg [3:0] cooldown=0;
 integer i,cuts;
 reg [3:0] bonus_cuts=0;
 reg [5:0] base_radius=42;
 wire [3:0] chosen_kind=random_kind[2:0]>=4 ? {1'b0,random_kind[2:0]}+4'd1:{1'b0,random_kind[2:0]};
 wire small_kind=chosen_kind==0 || chosen_kind==2 || chosen_kind==3 || chosen_kind==4;
 assign active=state==ZOOM || state==CUT || state==FALL;
 assign visible=state!=IDLE;
 assign accepting=state==FLY || state==CUT;
 assign cutting=state==CUT;
 assign falling=state==FALL;
 wire outside=(x1<266 || x1>374 || y1<186 || y1>294);
 always @(*) begin cuts=0;for(i=0;i<N;i=i+1) if(hits[i]&&!bomb[i]) cuts=cuts+1;end
 always @(posedge clk) begin
  award<=0;
  if(reset) begin
   state<=IDLE;remaining<=0;streak<=0;bonus_cuts<=0;burst<=0;latched<=0;cooldown<=0;moved<=0;
   position_x<=0;position_y<=0;radius<=36;fall_age<=0;zoom_age<=0;velocity_y<=0;
  end else if(playing) begin
   if(blade_event) moved<=(x0!=x1 || y0!=y1);
   if(!slash_active || (blade_event && outside)) latched<=0;
   if(tick && cooldown!=0) cooldown<=cooldown-1'b1;
   // A simultaneous bomb takes priority over starting the bonus.
   if(|(hits & bomb)) begin state<=IDLE;remaining<=0;streak<=0;end
   else case(state)
    IDLE: begin
     if(|missed) streak<=0;
     else if(streak+cuts>=TARGET) begin
      fruit_type<=chosen_kind;base_radius<=small_kind ? 30:42;
      state<=FLY;streak<=0;burst<=0;position_x<=16'sd2560;position_y<=16'sd8000;
      velocity_y<=-16'sd112;radius<=small_kind ? 30:42;latched<=0;fall_age<=0;
     end else streak<=streak+cuts;
    end
    FLY: begin
     if(contact && slash_active) begin
      state<=ZOOM;zoom_age<=0;latched<=1;remaining<=0;
     end else if(tick) begin
      position_x<=position_x+16'sd16;
      position_y<=position_y+velocity_y;velocity_y<=velocity_y+16'sd2;
      if(position_y>16'sd8640 && velocity_y>0) state<=IDLE;
     end
    end
    ZOOM: if(tick) begin
     if(zoom_age==29) begin
      state<=CUT;position_x<=16'sd5120;position_y<=16'sd3840;
      radius<=base_radius+6;remaining<=TICKS;bonus_cuts<=0;latched<=1;cooldown<=0;moved<=0;
     end else begin
      zoom_age<=zoom_age+1'b1;
      position_x<=position_x+((16'sd5120-position_x)>>>3);
      position_y<=position_y+((16'sd3840-position_y)>>>3);
      radius<=base_radius+(zoom_age>>2);
     end
    end
    CUT: begin
     if(tick) begin
      if(remaining<=1) begin
       state<=FALL;remaining<=0;fall_age<=0;velocity_y<=-16'sd48;
      end else remaining<=remaining-1'b1;
     end
     if(bonus_cuts<10 && remaining>1 && contact && slash_active && moved && !latched && cooldown==0) begin
      award<=1;latched<=1;cooldown<=6;bonus_cuts<=bonus_cuts+1'b1;
      if(bonus_cuts==9) begin state<=FALL;burst<=1;remaining<=0;fall_age<=0;end
     end
    end
    FALL: if(tick) begin
     if(!burst) begin position_y<=position_y+velocity_y;velocity_y<=velocity_y+16'sd4;end
     fall_age<=fall_age+1'b1;
     if(fall_age==(burst ? 29:89)) begin state<=IDLE;radius<=36;end
    end
    default:state<=IDLE;
   endcase
  end
 end
endmodule
