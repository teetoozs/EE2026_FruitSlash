// Titus: Sensei panel with animated life hearts, combo and difficulty bars.
// Text/end statistics remain to be implemented.
module sensei_panel (
    input         clk,
    input versus,aim_selected,input [3:0] aim_origin,aim_target,input [2:0] aim_speed,input [1:0] orientation,input [5:0] charge,input [6:0] cooldown,
    input signed [15:0] launch_x,launch_y,launch_vx,launch_vy,
    input         reset,
    input  [19:0] heart_levels,
    input  [ 2:0] lives,
    input  [ 1:0] difficulty,
    input  [ 1:0] state,
    input  [ 7:0] combo,
    input  [15:0] best_score,
    input  [ 2:0] multiplier,
    output [ 7:0] JB
);
    reg [2:0] div = 0;
    reg oled_clk = 0;
    always @(posedge clk) begin
        if (reset) begin
            div      <= 0;
            oled_clk <= 0;
        end else if (div == 7) begin
            div      <= 0;
            oled_clk <= ~oled_clk;
        end else div <= div + 1'b1;
    end
    // Snapshot multi-bit status into a mailbox held stable while the
    // OLED domain receives a synchronized request. No torn status buses.
    reg [145:0] mailbox = 0;
    reg request = 0;
    (* ASYNC_REG="TRUE" *) reg ack_meta = 0, ack_sync = 0;
    (* ASYNC_REG="TRUE" *) reg req_meta = 0, req_sync = 0;
    reg acknowledge = 0;
    reg [145:0] status = 0;
    always @(posedge clk) begin
        ack_meta <= acknowledge;
        ack_sync <= ack_meta;
        if (request == ack_sync) begin
            mailbox <= {heart_levels[19:12],lives[2],launch_x,launch_y,launch_vx,launch_vy,orientation,charge,versus,aim_selected,aim_origin,aim_target,aim_speed,cooldown,multiplier, best_score, heart_levels[11:0], lives[1:0], difficulty, state, combo};
            request <= ~request;
        end
    end
    always @(posedge oled_clk) begin
        req_meta <= request;
        req_sync <= req_meta;
        if (req_sync != acknowledge) begin
            status      <= mailbox;
            acknowledge <= req_sync;
        end
    end
    wire [12:0] index;
    wire [ 6:0] x = index % 96;
    wire [ 5:0] y = index / 96;
    wire [2:0] shown_lives={status[137],status[13:12]};
    wire [1:0] shown_difficulty=status[11:10];
    wire [19:0] shown_hearts={status[145:138],status[25:14]};
    wire [ 1:0] shown_state = status[9:8];
    wire [ 7:0] shown_combo = status[7:0];
    wire [15:0] shown_best = status[41:26];
    wire [ 2:0] shown_mult = status[44:42];
    reg  [15:0] colour;
    wire [ 4:0] heart;
    genvar h;
    generate
        for (h = 0; h < 5; h = h + 1) begin : hearts
            heart_pixel shape (
                .x       (status[64] ? {2'b0,x,1'b0}:{3'b0,x}),
                .y       (status[64] ? {3'b0,y,1'b0}:{4'b0,y}),
                .left    (status[64] ? 10'd96+h*10'd18:10'd4+h*10'd18),
                .top     (status[64] ? 10'd4:10'd15),
                .pixel_on(heart[h])
            );
        end
    endgenerate
    // ---- Text values (BCD from the OLED clock domain; font from ui_screens.v)
    wire [19:0] best_bcd, combo_bcd;
    bin2bcd best_conv  (.clk(oled_clk), .bin(shown_best),         .bcd(best_bcd));
    bin2bcd combo_conv (.clk(oled_clk), .bin({8'd0, shown_combo}), .bcd(combo_bcd));
    function [7:0] dgt;  // digit as ASCII, or a space when it is a leading zero
        input blank;
        input [3:0] d;
        dgt = blank ? 8'h20 : 8'h30 + d;
    endfunction
    wire [39:0] best_chars = {dgt(best_bcd[19:16] == 0, best_bcd[19:16]),
                              dgt(best_bcd[19:12] == 0, best_bcd[15:12]),
                              dgt(best_bcd[19:8]  == 0, best_bcd[11:8]),
                              dgt(best_bcd[19:4]  == 0, best_bcd[7:4]),
                              dgt(1'b0, best_bcd[3:0])};
    wire [23:0] combo_chars = {dgt(combo_bcd[11:8] == 0, combo_bcd[11:8]),
                               dgt(combo_bcd[11:4] == 0, combo_bcd[7:4]),
                               dgt(1'b0, combo_bcd[3:0])};
    wire t_best, t_level, t_combo, t_mult;
    text_line #(10, 0, 8, 3)  l_best  (.x({3'b0, x}), .y({4'b0, y}), .chars({"BEST ", best_chars}), .on(t_best));
    text_line #(7, 0, 8, 33)  l_level (.x({3'b0, x}), .y({4'b0, y}), .chars("ENDLESS"), .on(t_level));
    text_line #(9, 0, 8, 43)  l_combo (.x({3'b0, x}), .y({4'b0, y}), .chars({"COMBO ", combo_chars}), .on(t_combo));
    text_line #(7, 0, 8, 53)  l_mult  (.x({3'b0, x}), .y({4'b0, y}), .chars({"MULT X", 8'h30 + {5'd0, shown_mult}}), .on(t_mult));
 
    // ---- Wooden planks, gold frame, hearts, labelled text
    
    wire seam  = (y[3:0] == 4'd15);
    wire grain = (((x ^ {y[3:0], 2'b0}) & 7'd31) == 0);
    integer i;
    reg [3:0] brightness;
    always @(*) begin
        colour = y[4] ? 16'h7A85 : 16'h6A24;
        if (grain) colour = 16'h6204;
        if (seam)  colour = 16'h3922;
        if (x < 2 || x >= 94 || y < 2 || y >= 62) colour = 16'hFE45;
        brightness = 0;
        for (i = 0; i < 5; i = i + 1) begin
            brightness = shown_hearts[i*4+:4];
            if (heart[i]) colour = {brightness, brightness[3], 11'b0};
        end
        if (t_best)  colour = 16'hFE45;
        if (t_level) colour = 16'h07FF;
        if (t_combo) colour = 16'hFFFF;
        if (t_mult)  colour = 16'hFC00;
    end
    wire [15:0] versus_colour;
    versus_oled_view preview(.clk(oled_clk),.reset(reset),.selected(status[63]),
      .orientation(status[72:71]),.charge(status[70:65]),.cooldown(status[51:45]),
      .start_x(status[136:121]),.start_y(status[120:105]),.vx(status[104:89]),.vy(status[88:73]),
      .x(x),.y(y),.rgb(versus_colour));
    reg [15:0] display_colour;
    integer vh;
    always @(*) begin
        display_colour=status[64] ? versus_colour:colour;
        // Mini hearts in the 1v1 top-right strip; regular panel uses full-size hearts.
        if(status[64]) for(vh=0;vh<5;vh=vh+1)
            if(heart[vh] && shown_hearts[vh*4+:4]!=0)
                display_colour={shown_hearts[vh*4+:4],1'b0,11'b0};
    end
    assign JB[2] = 0;
    Oled_Display driver (
        .clk           (oled_clk),
        .reset         (reset),
        .frame_begin   (),
        .sending_pixels(),
        .sample_pixel  (),
        .pixel_index   (index),
        .pixel_data    (display_colour),
        .cs            (JB[0]),
        .sdin          (JB[1]),
        .sclk          (JB[3]),
        .d_cn          (JB[4]),
        .resn          (JB[5]),
        .vccen         (JB[6]),
        .pmoden        (JB[7])
    );
endmodule
// Compact six-pixel character pitch: 16 characters fit the 96-pixel OLED.
module oled_compact_text #(parameter LEN=1,X0=0,Y0=0)(
 input [6:0] x,input [5:0] y,input [LEN*8-1:0] chars,output pixel);
 wire inside=x>=X0 && x<X0+LEN*6 && y>=Y0 && y<Y0+7;
 wire [6:0] local_x=x-X0;
 wire [4:0] index=local_x/6;
 wire [2:0] col=local_x%6,row=y-Y0;
 wire [LEN*8-1:0] shifted=chars>>((LEN-1-index)*8);
 wire [4:0] bits;
 font5x7 font(.ch(shifted[7:0]),.row(row),.bits(bits));
 assign pixel=inside && col<5 && bits[4-col];
endmodule

module versus_oled_view(
 input clk,reset,selected,input [1:0] orientation,input [5:0] charge,input [6:0] cooldown,
 input signed [15:0] start_x,start_y,vx,vy,input [6:0] x,input [5:0] y,output reg [15:0] rgb);
 // Two 1-bit preview planes. One sequential integrator draws the next trajectory.
 (* ram_style="distributed" *) reg path[0:16383];
 reg display_bank=0,write_bank=1,valid=0;
 reg [1:0] state=0;
 reg [12:0] clear_address=0;
 reg [7:0] step_count=0;
 reg [64:0] last_inputs=0;
 wire [64:0] inputs_now={selected,start_x,start_y,vx,vy};
 reg signed [15:0] px=0,py=0,svx=0,svy=0;
 wire signed [20:0] scaled_px=px*21'sd15,scaled_py=py*21'sd13;
 wire signed [12:0] plot_x=(scaled_px>>>11)+13'sd10;
 wire signed [12:0] plot_y=(scaled_py>>>12)+13'sd9;
 always @(posedge clk) begin
  if(reset) begin state<=0;valid<=0;last_inputs<=0;end
  else case(state)
   0:if(inputs_now!=last_inputs || !valid) begin
      last_inputs<=inputs_now;write_bank<=~display_bank;clear_address<=0;state<=1;
      px<=start_x;py<=start_y;svx<=vx;svy<=vy;step_count<=0;
     end
   1:begin path[{write_bank,clear_address}]<=0;
      if(clear_address==8191) state<=2;else clear_address<=clear_address+1'b1;
     end
   2:begin
      if(last_inputs[64] && plot_x>=2 && plot_x<94 && plot_y>=2 && plot_y<43)
       path[{write_bank,plot_y[5:0],plot_x[6:0]}]<=1;
      px<=px+svx;py<=py+svy;svy<=svy<189 ? svy+16'sd3:16'sd192;
      step_count<=step_count+1'b1;
      if(step_count==191 || py>8704 || px< -1024 || px>11264) begin
       display_bank<=write_bank;valid<=1;state<=0;
      end
     end
  endcase
 end
 wire curve=valid && selected && path[{display_bank,y,x}];
 wire signed [20:0] scaled_start_x=start_x*21'sd15,scaled_start_y=start_y*21'sd13;
 wire signed [9:0] anchor_x=(scaled_start_x>>>11)+10'sd10;
 wire signed [9:0] anchor_y=(scaled_start_y>>>12)+10'sd9;
 wire signed [9:0] screen_dx=$signed({3'b0,x})-anchor_x;
 wire signed [9:0] screen_dy=$signed({4'b0,y})-anchor_y;
 reg signed [9:0] local_x,local_y;
 reg signed [15:0] tangent;
 always @(*) case(orientation)
  0:begin local_x=screen_dx;local_y=screen_dy;tangent=vx;end
  1:begin local_x=screen_dy;local_y=-screen_dx;tangent=vy;end
  2:begin local_x=-screen_dx;local_y=-screen_dy;tangent=-vx;end
  3:begin local_x=-screen_dy;local_y=screen_dx;tangent=-vy;end
 endcase
 // A small procedural ninja: local coordinates rotate with the launch edge.
 // Lean follows aim; hands rise as the player charges the throw.
 wire signed [9:0] head_x=local_x+(tangent>>>6);
 wire near_ninja=selected && local_x>=-9 && local_x<=9 && local_y>=-7 && local_y<=6;
 wire hood=(local_y>=-6 && local_y<=1 && head_x>=-5 && head_x<=5) &&
           !(local_y==-6 && (head_x<-3 || head_x>3));
 wire face=local_y>=-3 && local_y<=0 && head_x>=-4 && head_x<=4;
 wire eyes=(head_x==-2 || head_x==2) && local_y>=-2 && local_y<=-1;
 wire blush=(head_x==-3 || head_x==3) && local_y==0;
 wire torso=local_y>=2 && local_y<=4 && local_x>=-3 && local_x<=3;
 wire feet=local_y>=5 && local_y<=6 && ((local_x>=-4 && local_x<=-1)||(local_x>=1 && local_x<=4));
 wire signed [9:0] hand_y=10'sd2-$signed({8'b0,charge[5:4]});
 wire hands=local_y>=hand_y && local_y<=hand_y+1 &&
            ((local_x>=-7 && local_x<=-5)||(local_x>=5 && local_x<=7));
 wire scarf=(local_y==1 && head_x>=-5 && head_x<=5) ||
            (local_y>=2 && local_y<=3 && local_x>=4 && local_x<=7);
 wire instructions1,instructions2,power_text;
 oled_compact_text #(14,6,45) buttons(.x(x),.y(y),.chars("U:FRUIT R:BOMB"),.pixel(instructions1));
 oled_compact_text #(13,9,55) switches(.x(x),.y(y),.chars("L:EDGE SW1-15"),.pixel(instructions2));
 wire [7:0] power_digit=charge>=32 ? "3":charge>=16 ? "2":"1";
 oled_compact_text #(7,27,18) power(.x(x),.y(y),.chars({"POWER ",power_digit}),.pixel(power_text));
 always @(*) begin
  // Match the normal Sensei panel's wood and gold frame.
  rgb=y[4] ? 16'h7A85:16'h6A24;
  if(((x^{y[3:0],2'b0})&7'd31)==0) rgb=16'h6204;
  if(y[3:0]==15) rgb=16'h3922;
  if(curve && y<43) rgb=16'hFFE0;
  // Keep the power indicator centered and instructions in the bottom 20 rows.
  // Half-bright underlying wood/trajectory instead of an opaque rectangle.
  if(x>=24 && x<72 && y>=16 && y<33)
   rgb={1'b0,rgb[15:12],1'b0,rgb[10:6],1'b0,rgb[4:1]};
  if(power_text) rgb=16'hFFFF;
  if(x>=27 && x<69 && (y==27 || y==30)) rgb=16'h7BEF;
  if(x>=27 && x<27+((charge*7'd7)>>3) && y>=27 && y<31) rgb=16'hFFE0;
  // Ninja is foreground, including where it overlaps the power label/bar.
  if(near_ninja && y<43) begin
   if(hood || torso || feet) rgb=16'h194B;
   if(hood && head_x==-4 && local_y<-3) rgb=16'h4B55;
   if(face || hands) rgb=16'hFE52;
   if(eyes) rgb=16'h0841;
   if(blush) rgb=16'hFBAE;
   if(scarf) rgb=cooldown!=0 ? 16'hF800:16'h07FF;
   if(torso && local_y==3) rgb=16'hFFE0;
  end
  if(y>=43) rgb=16'h3922;
  if(instructions1 || instructions2) rgb=16'hFFFF;
  if(x==0 || x==95 || y==0 || y==63 || y==43) rgb=16'hFE45;
 end
endmodule
