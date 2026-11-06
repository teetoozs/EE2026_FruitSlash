// Single RGB selector: original procedural arcade art and life HUD.
// DETAILED_ART=0 retains flat diagnostic masks for geometry regression.
module pixel_compositor #(
    parameter N = 8,
    parameter VARIABLE_RADIUS = 0,
    parameter DETAILED_ART = 0,
    parameter SIZE_SHIFT = 0
) (
    input clk,reset,
    input [9:0] raster_y,
    input         [     9:0] x,
    input         [     9:0] y,
    input                    video_on,
    input         [    11:0] heart_levels,
    input         [ N*5-1:0] radii,
    input         [ N*2-1:0] health,
    input         [     1:0] state,
    input         [     9:0] cursor_x,
    input         [     9:0] cursor_y,
    input                    slash_active,
    input         [   N-1:0] active,
    input         [   N-1:0] bomb,
    input         [N*16-1:0] positions_x,
    input         [N*16-1:0] positions_y,
    input [N-1:0] explosion_active,
    input [N*16-1:0] explosion_x,
    input [N*16-1:0] explosion_y,
    input [8:0] explosion_age,
    input         [N*5-1:0] effect_radii,
    input tri0 [N*2-1:0] cut_direction,
    input tri0 [N*4-1:0] fruit_types,effect_types,
    input tri0 [N*2-1:0] spins,effect_spins,
    input         [2*N-1:0] halves_active,
    input         [2*N*16-1:0] halves_x,
    input         [2*N*16-1:0] halves_y,
    input         [N-1:0] splash_active,
    input         [N*16-1:0] splash_x,
    input         [N*16-1:0] splash_y,
    input         [N*5-1:0] splash_age,
    input wall_on, input [11:0] wall_rgb,
    output reg    [    11:0] rgb
);

    wire splash_pixel;
    wire [11:0] splash_rgb;
    (* keep_hierarchy = "yes" *) splash_renderer #(.N(N), .FRUIT_PALETTE(DETAILED_ART)) juice (
        .x(x),
        .y(y),
        .active(splash_active),
        .positions_x(splash_x),
        .positions_y(splash_y),
        .ages(splash_age),
        .radii(effect_radii),
        .pixel_on(splash_pixel),
        .rgb(splash_rgb)
    );

    // Exact integer circle row widths: no per-fruit pixel multipliers.
    function [4:0] extent18;
        input [4:0] row;
        begin
            case (row)
                5'd0: extent18 = 5'd18;
                5'd1: extent18 = 5'd17;
                5'd2: extent18 = 5'd17;
                5'd3: extent18 = 5'd17;
                5'd4: extent18 = 5'd17;
                5'd5: extent18 = 5'd17;
                5'd6: extent18 = 5'd16;
                5'd7: extent18 = 5'd16;
                5'd8: extent18 = 5'd16;
                5'd9: extent18 = 5'd15;
                5'd10: extent18 = 5'd14;
                5'd11: extent18 = 5'd14;
                5'd12: extent18 = 5'd13;
                5'd13: extent18 = 5'd12;
                5'd14: extent18 = 5'd11;
                5'd15: extent18 = 5'd9;
                5'd16: extent18 = 5'd8;
                5'd17: extent18 = 5'd5;
                5'd18: extent18 = 5'd0;
                default: extent18 = 0;
            endcase
        end
    endfunction

    wire explosion_pixel;
    wire [11:0] explosion_rgb;
    bomb_renderer #(.N(N)) blast (
        .x(x),
        .y(y),
        .active(explosion_active),
        .origins_x(explosion_x),
        .origins_y(explosion_y),
        .age(explosion_age),
        .pixel_on(explosion_pixel),
        .rgb(explosion_rgb)
    );

    function [4:0] extent12;
        input [4:0] row;
        begin
            case (row)
                0: extent12 = 12;
                1: extent12 = 11;
                2: extent12 = 11;
                3: extent12 = 11;
                4: extent12 = 11;
                5: extent12 = 10;
                6: extent12 = 10;
                7: extent12 = 9;
                8: extent12 = 8;
                9: extent12 = 7;
                10: extent12 = 6;
                11: extent12 = 4;
                12: extent12 = 0;
                default: extent12 = 0;
            endcase
        end
    endfunction
    function [4:0] extent24;
        input [4:0] row;
        begin
            case (row)
                0: extent24 = 24;
                1: extent24 = 23;
                2: extent24 = 23;
                3: extent24 = 23;
                4: extent24 = 23;
                5: extent24 = 23;
                6: extent24 = 23;
                7: extent24 = 22;
                8: extent24 = 22;
                9: extent24 = 22;
                10: extent24 = 21;
                11: extent24 = 21;
                12: extent24 = 20;
                13: extent24 = 20;
                14: extent24 = 19;
                15: extent24 = 18;
                16: extent24 = 17;
                17: extent24 = 16;
                18: extent24 = 15;
                19: extent24 = 14;
                20: extent24 = 13;
                21: extent24 = 11;
                22: extent24 = 9;
                23: extent24 = 6;
                24: extent24 = 0;
                default: extent24 = 0;
            endcase
        end
    endfunction
    wire [2:0] heart;
    genvar h;
    generate
        for (h = 0; h < 3; h = h + 1) begin : hud
            heart_pixel #(
                .SCALE(1)
            ) shape (
                .x       (x),
                .y       (y),
                .left    (10'd514 + h * 10'd40),
                .top     (10'd16),
                .pixel_on(heart[h])
            );
        end
    endgenerate
    wire fruit_on;
    wire [11:0] fruit_rgb;
    scanline_fruits #(.N(N),.SIZE_SHIFT(SIZE_SHIFT),.VARIABLE_RADIUS(VARIABLE_RADIUS),.DETAILED_ART(DETAILED_ART)) fruit_layer(
      .clk(clk),.reset(reset),.raster_y(raster_y),.x(x),.scene_y(y),
      .active(active),.bomb(bomb),.positions_x(positions_x),.positions_y(positions_y),.radii(radii),
      .fruit_types(fruit_types),.spins(spins),.halves_active(halves_active),.halves_x(halves_x),.halves_y(halves_y),
      .effect_radii(effect_radii),.effect_types(effect_types),.effect_spins(effect_spins),.cut_direction(cut_direction),
      .pixel_on(fruit_on),.rgb(fruit_rgb));
    wire [5:0] wood_u=x[5:0];
    wire [6:0] wood_v=y[6:0]+(x[6] ? 7'd64:7'd0);
    wire [5:0] grain_phase=wood_u+{3'b0,y[6:4]}+(y[7] ? 6'd3:6'd0);
    wire grain=grain_phase[3:0]==0 || (grain_phase[4:0]==7 && y[3]);
    wire nail=(wood_u==6 || wood_u==57) && (wood_v==6 || wood_v==119);
    always @(*) begin
        rgb=y[5] ? 12'h642:12'h753;
        if(DETAILED_ART) begin
            rgb=x[6] ? 12'h964:12'hA75;
            if(grain) rgb=x[6] ? 12'h853:12'h964;
            if(wood_u<2 || wood_v<2) rgb=12'h532;
            else if(wood_u==2 || wood_v==2) rgb=12'hC97;
            if(nail) rgb=12'h555;
        end
        if(wall_on) rgb=wall_rgb;
        if(splash_pixel) rgb=splash_rgb;
        if(fruit_on) rgb=fruit_rgb;
        if(explosion_pixel) rgb=explosion_rgb;
        if(heart[0] && heart_levels[3:0]!=0) rgb={heart_levels[3:0],8'h22};
        if(heart[1] && heart_levels[7:4]!=0) rgb={heart_levels[7:4],8'h22};
        if(heart[2] && heart_levels[11:8]!=0) rgb={heart_levels[11:8],8'h22};
        if(!video_on) rgb=0;
    end
endmodule

// Ping-pong line buffer. At 100 MHz a VGA row lasts 3200 cycles.
// Worst case N=8, radius=24, scale=2: clear640 + 24*(setup1+98) + finish1 = 3017 cycles.
// Both transparent pixels and object priority are preserved; one shared shape unit.
module scanline_fruits #(parameter N=8,SIZE_SHIFT=1,VARIABLE_RADIUS=1,DETAILED_ART=1)(
 input clk,reset,input [9:0] raster_y,x,scene_y,
 input [N-1:0] active,bomb,input [N*16-1:0] positions_x,positions_y,
 input [N*5-1:0] radii,effect_radii,input [N*4-1:0] fruit_types,effect_types,
 input [N*2-1:0] spins,effect_spins,cut_direction,input [2*N-1:0] halves_active,
 input [2*N*16-1:0] halves_x,halves_y,output pixel_on,output [11:0] rgb);
 (* ram_style="distributed" *) reg [12:0] pixels[0:2047];
 reg [1:0] ready=0;
 reg [9:0] previous_row=1023,clear_x=0;
 reg bank=0;
 reg [1:0] state=0;
 reg [5:0] object_id=0;
 reg signed [12:0] target_y=0,center_x=0,center_y=0,draw_x=0,last_x=0;
 reg [4:0] radius=18;
 reg [3:0] kind=0;
 reg [1:0] spin=0,direction=0;
 reg is_bomb=0,is_half=0,half_odd=0;
 reg candidate_active;
 reg signed [15:0] candidate_x,candidate_y;
 reg [4:0] candidate_radius;
 reg [3:0] candidate_kind;
 reg [1:0] candidate_spin,candidate_direction;
 reg candidate_bomb;
 integer index;
 always @(*) begin
  index=0;candidate_active=0;candidate_x=0;candidate_y=0;candidate_radius=18;
  candidate_kind=0;candidate_spin=0;candidate_direction=0;candidate_bomb=0;
  if(object_id<N) begin
   index=object_id;candidate_active=active[index];candidate_bomb=bomb[index];
   candidate_x=positions_x[index*16+:16];candidate_y=positions_y[index*16+:16];
   candidate_radius=VARIABLE_RADIUS ? radii[index*5+:5]:18;
   candidate_kind=fruit_types[index*4+:4];candidate_spin=spins[index*2+:2];
  end else if(object_id<3*N) begin
   index=object_id-N;candidate_active=halves_active[index];
   candidate_x=halves_x[index*16+:16];candidate_y=halves_y[index*16+:16];
   candidate_radius=VARIABLE_RADIUS ? effect_radii[(index/2)*5+:5]:18;
   candidate_kind=effect_types[(index/2)*4+:4];candidate_spin=effect_spins[(index/2)*2+:2];
   candidate_direction=cut_direction[(index/2)*2+:2];
  end
 end
 wire signed [12:0] candidate_cx=candidate_x>>>4,candidate_cy=candidate_y>>>4;
 wire signed [12:0] candidate_span=$signed({8'b0,candidate_radius})<<<SIZE_SHIFT;
 wire candidate_row=target_y>=candidate_cy-candidate_span-(13'sd5<<<SIZE_SHIFT) && target_y<=candidate_cy+candidate_span+((13'sd1<<<SIZE_SHIFT)-1);
 wire signed [12:0] raw_dx=(draw_x-center_x)>>>SIZE_SHIFT,raw_dy=(target_y-center_y)>>>SIZE_SHIFT;
 reg signed [12:0] dx,dy;
 reg signed [13:0] side;
 reg [12:0] ax,ay,inner_y;
 reg [4:0] extent,inner_extent;
 reg body,stem;
    function [4:0] extent18;
        input [4:0] row;
        begin
            case (row)
                5'd0: extent18 = 5'd18;
                5'd1: extent18 = 5'd17;
                5'd2: extent18 = 5'd17;
                5'd3: extent18 = 5'd17;
                5'd4: extent18 = 5'd17;
                5'd5: extent18 = 5'd17;
                5'd6: extent18 = 5'd16;
                5'd7: extent18 = 5'd16;
                5'd8: extent18 = 5'd16;
                5'd9: extent18 = 5'd15;
                5'd10: extent18 = 5'd14;
                5'd11: extent18 = 5'd14;
                5'd12: extent18 = 5'd13;
                5'd13: extent18 = 5'd12;
                5'd14: extent18 = 5'd11;
                5'd15: extent18 = 5'd9;
                5'd16: extent18 = 5'd8;
                5'd17: extent18 = 5'd5;
                5'd18: extent18 = 5'd0;
                default: extent18 = 0;
            endcase
        end
    endfunction

    function [4:0] extent12;
        input [4:0] row;
        begin
            case (row)
                0: extent12 = 12;
                1: extent12 = 11;
                2: extent12 = 11;
                3: extent12 = 11;
                4: extent12 = 11;
                5: extent12 = 10;
                6: extent12 = 10;
                7: extent12 = 9;
                8: extent12 = 8;
                9: extent12 = 7;
                10: extent12 = 6;
                11: extent12 = 4;
                12: extent12 = 0;
                default: extent12 = 0;
            endcase
        end
    endfunction
    function [4:0] extent24;
        input [4:0] row;
        begin
            case (row)
                0: extent24 = 24;
                1: extent24 = 23;
                2: extent24 = 23;
                3: extent24 = 23;
                4: extent24 = 23;
                5: extent24 = 23;
                6: extent24 = 23;
                7: extent24 = 22;
                8: extent24 = 22;
                9: extent24 = 22;
                10: extent24 = 21;
                11: extent24 = 21;
                12: extent24 = 20;
                13: extent24 = 20;
                14: extent24 = 19;
                15: extent24 = 18;
                16: extent24 = 17;
                17: extent24 = 16;
                18: extent24 = 15;
                19: extent24 = 14;
                20: extent24 = 13;
                21: extent24 = 11;
                22: extent24 = 9;
                23: extent24 = 6;
                24: extent24 = 0;
                default: extent24 = 0;
            endcase
        end
    endfunction

 always @(*) begin
  dx=raw_dx;dy=raw_dy;
  case(direction)
   1:side=raw_dy;2:side=$signed({raw_dy[12],raw_dy})-$signed({raw_dx[12],raw_dx});
   3:side=$signed({raw_dy[12],raw_dy})+$signed({raw_dx[12],raw_dx});default:side=raw_dx;
  endcase
  if(DETAILED_ART && kind==4 && !is_bomb) case(spin)
   1:begin dx=raw_dy;dy=-raw_dx;end
   2:begin dx=-raw_dx;dy=-raw_dy;end
   3:begin dx=-raw_dy;dy=raw_dx;end
  endcase
  ax=dx<0 ? -dx:dx;ay=dy<0 ? -dy:dy;
  case(radius)
   12:extent=extent12(ay[4:0]);24:extent=extent24(ay[4:0]);default:extent=extent18(ay[4:0]);
  endcase
  body=ay<=radius && ax<=extent;inner_y=0;inner_extent=0;
  if(DETAILED_ART && !is_bomb) begin
   if(kind==4) begin
    inner_y=(dy+$signed({1'b0,radius}>>2))<0 ? -(dy+$signed({1'b0,radius}>>2)):(dy+$signed({1'b0,radius}>>2));
    inner_extent=radius==12 ? extent12(inner_y[4:0]):extent18(inner_y[4:0]);
    body=body && !(inner_y<radius && inner_extent>4 && ax+4<inner_extent);
   end
   if(kind==6 && dy<0) body=body && $signed({1'b0,ax})<=($signed({1'b0,radius})>>>2)+(((dy+$signed({1'b0,radius}))*13'sd3)>>>2);
  end
  if(is_half) body=body && (half_odd ? side>=0:side<0);
  stem=DETAILED_ART && !is_half && dy<-$signed({1'b0,radius}) &&
       dy>=-$signed({1'b0,radius})-5 && ax<=(kind==7 && !is_bomb ? 6:1);
 end
 wire [11:0] surface_rgb;
 fruit_surface surface(.dx(dx),.dy(dy),.radius({1'b0,radius}),.kind(kind),.bomb(is_bomb),
 .cut_edge(is_half && side>=-1 && side<=1),.rgb(surface_rgb));
 wire [11:0] colour=DETAILED_ART ? (stem ? (is_bomb ? 12'hFF8:12'h5B3):surface_rgb):is_bomb ? 12'h111:12'hF40;
 wire [12:0] current_pixel=pixels[{raster_y[0],x}];
 assign pixel_on=ready[raster_y[0]] && current_pixel[12] && x<640;
 assign rgb=current_pixel[11:0];
 always @(posedge clk) begin
  if(reset) begin ready<=0;state<=0;previous_row<=1023;end
  else if(raster_y!=previous_row) begin
   previous_row<=raster_y;bank<=raster_y==524 ? 1'b0:~raster_y[0];ready[raster_y==524 ? 1'b0:~raster_y[0]]<=0;
   // Row524 pre-renders row0 during vertical blank; normal rows render their successor.
   target_y<=raster_y>=479 ? 0:$signed({3'b0,scene_y})+13'sd1;
   clear_x<=0;object_id<=0;state<=1;
  end else case(state)
   1:begin
    pixels[{bank,clear_x}]<=0;
    if(clear_x==639) state<=2;else clear_x<=clear_x+1'b1;
   end
   2:begin
    if(object_id>=3*N) begin state<=0;ready[bank]<=1;end
    else if(candidate_active && candidate_row) begin
     center_x<=candidate_cx;center_y<=candidate_cy;radius<=candidate_radius;
     kind<=candidate_kind;spin<=candidate_spin;direction<=candidate_direction;is_bomb<=candidate_bomb;
     is_half<=object_id>=N;half_odd<=(object_id-N)%2;
     draw_x<=candidate_cx-candidate_span;last_x<=candidate_cx+candidate_span+((13'sd1<<<SIZE_SHIFT)-1);
     state<=3;
    end else object_id<=object_id+1'b1;
   end
   3:begin
    if(draw_x>=0 && draw_x<640 && (body || stem)) pixels[{bank,draw_x[9:0]}]<={1'b1,colour};
    if(draw_x==last_x) begin state<=2;object_id<=object_id+1'b1;end
    else draw_x<=draw_x+1'b1;
   end
  endcase
 end
endmodule

// Shared procedural 2.5D surface: nine identities, coloured rim, specular light.
module fruit_surface(input signed [12:0] dx,dy,input [5:0] radius,
 input [3:0] kind,input bomb,cut_edge,output reg [11:0] rgb);
 wire [12:0] ax=dx<0 ? -dx:dx,ay=dy<0 ? -dy:dy;
 wire signed [13:0] lighting=$signed({dx[12],dx})+$signed({dy[12],dy});
 wire signed [13:0] gx=$signed({dx[12],dx})+$signed({8'b0,radius}>>2);
 wire signed [13:0] gy=$signed({dy[12],dy})+$signed({8'b0,radius}>>2);
 (* use_dsp="yes" *) wire signed [15:0] gx_squared=$signed(gx[7:0])*$signed(gx[7:0]);
 (* use_dsp="yes" *) wire signed [15:0] gy_squared=$signed(gy[7:0])*$signed(gy[7:0]);
 wire [16:0] light_distance={1'b0,gx_squared}+{1'b0,gy_squared};
 wire [11:0] radius_squared=radius*radius;
 reg [11:0] base,bright,dark;
 function [11:0] blend;
 input [11:0] a,b;
 reg [4:0] rr,gg,bb;
 begin rr={1'b0,a[11:8]}+{1'b0,b[11:8]};gg={1'b0,a[7:4]}+{1'b0,b[7:4]};bb={1'b0,a[3:0]}+{1'b0,b[3:0]};blend={rr[4:1],gg[4:1],bb[4:1]};end
 endfunction
 always @(*) begin
  case(kind)
   0:begin base=12'hF82;bright=12'hFD8;dark=12'hB40;end // orange
   1:begin base=12'hE33;bright=12'hFA9;dark=12'h912;end // apple
   2:begin base=12'h7D3;bright=12'hCF8;dark=12'h382;end // lime
   3:begin base=12'hA4D;bright=12'hEAF;dark=12'h623;end // plum
   4:begin base=12'hFD3;bright=12'hFFB;dark=12'hC81;end // banana
   5:begin base=12'h5B3;bright=12'hAF8;dark=12'h263;end // watermelon
   6:begin base=12'hBD4;bright=12'hEF9;dark=12'h693;end // pear
   7:begin base=12'hDA3;bright=12'hFED;dark=12'h863;end // pineapple
   default:begin base=12'hA75;bright=12'hDC9;dark=12'h642;end // coconut
  endcase
  if(bomb) begin base=12'h556;bright=12'hCDF;dark=12'h223;end
  // Circular light falloff avoids flat diagonal or horizontal colour bands.
  rgb=base;
  if(light_distance<(radius_squared>>2)) rgb=blend(base,bright);
  else if(light_distance>(radius_squared+(radius_squared>>1))) rgb=dark;
  else if(light_distance>radius_squared) rgb=blend(base,dark);
  if(!bomb) begin
   if(kind==5 && ((dx[3:0]+{1'b0,dy[4:2]})&4'hF)<2) rgb=blend(rgb,dark);
   if(kind==7 && ((dx+dy)&7)==0 && ((dx-dy)&7)<2) rgb=blend(rgb,dark);
   if(kind==8 && (dx[2:0]^dy[3:1])==3 && dy[1]) rgb=blend(rgb,dark);
   if(kind==0 && dx[2:0]==2 && dy[2:0]==3) rgb=blend(rgb,12'hD61);
  end
  if(light_distance<(radius_squared>>4)) rgb=bright;
  if(light_distance<(radius_squared>>6)) rgb=bomb ? 12'hFFF:12'hFFE;
  if(cut_edge) rgb=kind==5 ? 12'hF57:kind==8 ? 12'hFFF:12'hFEA;
 end
endmodule
