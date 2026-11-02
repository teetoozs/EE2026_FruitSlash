// Display-only counters: gameplay remains the authority for accepted cuts.
module slice_popups (
 input clk, reset, tick, playing, bomb_busy, bonus_active, bonus_award,
 input [7:0] combo,
 input [9:0] x,y,
 output pixel_on,
 output [11:0] rgb
);
 reg [7:0] previous_combo=0, popup_combo=0;
 reg [5:0] combo_age=0, bonus_age=0;
 reg was_bonus=0;
 reg [15:0] bonus_slices=0;
 wire [19:0] combo_digits, bonus_digits;
 decimal_digits c(.clk(clk),.reset(reset),.value({8'b0,popup_combo}),.digits(combo_digits));
 decimal_digits b(.clk(clk),.reset(reset),.value(bonus_slices),.digits(bonus_digits));
 always @(posedge clk) begin
  if(reset) begin
   previous_combo<=0; popup_combo<=0; combo_age<=0;
   was_bonus<=0; bonus_slices<=0; bonus_age<=0;
  end else begin
   previous_combo<=combo;
   was_bonus<=bonus_active;
   if(playing && !bomb_busy) begin
    if(combo>=2 && combo!=previous_combo) begin popup_combo<=combo; combo_age<=45; end
    else if(tick && combo_age!=0) combo_age<=combo_age-1'b1;
    if(bonus_active && !was_bonus) begin
     bonus_slices<=bonus_award ? 16'd1 : 16'd0;
     bonus_age<=45;
    end else begin
     if(bonus_award && bonus_slices!=16'hffff) bonus_slices<=bonus_slices+1'b1;
     if(bonus_active || bonus_award) bonus_age<=45;
     else if(tick && bonus_age!=0) bonus_age<=bonus_age-1'b1;
    end
   end
  end
 end
 reg [159:0] line_text;
 reg [7:0] character;
 wire [9:0] local_x=x-160, local_y=y-64;
 wire region=x>=160 && x<480 && y>=64 && y<80;
 wire show_bonus=bonus_active || bonus_age!=0;
 wire glyph;
 wire [4:0] font_bits;
 font5x7 font(.ch(character),.row(local_y[3:1]),.bits(font_bits));
 assign glyph=(local_x[3:1]<5 && local_y[3:1]<7) && font_bits[4-local_x[3:1]];
 always @(*) begin
  line_text="COMBO X000!         ";
  // Explicit byte positions avoid string padding changing the digit offsets.
  if(show_bonus)
   line_text={"BONUS SLICES  ",4'h3,bonus_digits[19:16],4'h3,bonus_digits[15:12],
       4'h3,bonus_digits[11:8],4'h3,bonus_digits[7:4],4'h3,bonus_digits[3:0],"  "};
  else
   line_text={"COMBO X",4'h3,combo_digits[11:8],4'h3,combo_digits[7:4],4'h3,combo_digits[3:0],"!         "};
  character=8'h20;
  if(region) character=line_text[159-(local_x>>4)*8-:8];
 end
 assign pixel_on=!reset && playing && !bomb_busy && (show_bonus || combo_age!=0) && region && glyph;
 assign rgb=show_bonus ? 12'hFF4 : 12'hFE3;
endmodule
