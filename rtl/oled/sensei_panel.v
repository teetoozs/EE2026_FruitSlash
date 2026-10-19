// Titus: diagnostic Sensei panel. Three life blocks, combo bar,
// difficulty bands and state stripe. TODO: hearts/text/end statistics.
module sensei_panel(
 input clk,input reset,input [1:0] lives,difficulty,state,
 input [7:0] combo,output [7:0] JB
);
 reg [2:0] div=0;
 reg oled_clk=0;
 always @(posedge clk) begin
  if(reset) begin div<=0;oled_clk<=0;end
  else if(div==7) begin div<=0;oled_clk<=~oled_clk;end
  else div<=div+1'b1;
 end
 // Snapshot multi-bit status into a mailbox held stable while the
 // OLED domain receives a synchronized request. No torn status buses.
 reg [13:0] mailbox=0;
 reg request=0;
 (* ASYNC_REG="TRUE" *) reg ack_meta=0,ack_sync=0;
 (* ASYNC_REG="TRUE" *) reg req_meta=0,req_sync=0;
 reg acknowledge=0;
 reg [13:0] status=0;
 always @(posedge clk) begin
  ack_meta<=acknowledge;ack_sync<=ack_meta;
  if(request==ack_sync) begin
   mailbox<={lives,difficulty,state,combo};
   request<=~request;
  end
 end
 always @(posedge oled_clk) begin
  req_meta<=request;req_sync<=req_meta;
  if(req_sync!=acknowledge) begin status<=mailbox;acknowledge<=req_sync;end
 end
 wire [12:0] index;
 wire [6:0] x=index%96;
 wire [5:0] y=index/96;
 wire [1:0] shown_lives=status[13:12],shown_difficulty=status[11:10];
 wire [1:0] shown_state=status[9:8];
 wire [7:0] shown_combo=status[7:0];
 reg [15:0] colour;
 always @(*) begin
  colour=16'h0000;
  if(y<6) case(shown_state)
   0:colour=16'h001F;1:colour=16'h07E0;2:colour=16'hFFE0;3:colour=16'hF800;
  endcase
  if(y>=12 && y<24 && ((x>=6&&x<24&&shown_lives>=1)||
   (x>=36&&x<54&&shown_lives>=2)||(x>=66&&x<84&&shown_lives>=3)))
    colour=16'hF800;
  if(y>=32 && y<40 && x<({6'd0,shown_difficulty}+8'd1)*8'd20) colour=16'h07FF;
  if(y>=48 && y<56 && x<(shown_combo>20?96:shown_combo*4)) colour=16'hFFE0;
 end
 assign JB[2]=0;
 Oled_Display driver(.clk(oled_clk),.reset(reset),.frame_begin(),
 .sending_pixels(),.sample_pixel(),.pixel_index(index),.pixel_data(colour),
 .cs(JB[0]),.sdin(JB[1]),.sclk(JB[3]),.d_cn(JB[4]),
 .resn(JB[5]),.vccen(JB[6]),.pmoden(JB[7]));
endmodule
