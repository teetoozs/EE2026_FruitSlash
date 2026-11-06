// Titus: eight slots; signed 16-bit Q12.4 centres/velocities.
// One owner writes slots; remove_mask overrides movement and slot reuse.
module object_physics #(
    parameter N = 8, parameter WAVE_SIZE = 3
) (
    input                 clk,
    input                 reset,
    input                 game_tick,
    input                 playing,
    input tri0 versus,launch,launch_bomb,
    input signed [15:0] launch_x,launch_vx,launch_vy,
    input tri0 signed [15:0] launch_y,
    input      [     1:0] difficulty,
    input      [   N-1:0] remove_mask,
    output reg [N*4-1:0] fruit_types=0,
    output reg [N*2-1:0] spins=0,
    output reg [   N-1:0] active = 0,
    output reg [   N-1:0] bomb = 0,
    output reg [N-1:0] missed = 0,
    output     [N*16-1:0] positions_x,
    output     [N*16-1:0] positions_y
);
    reg signed [15:0] px[0:N-1], py[0:N-1], vx[0:N-1], vy[0:N-1];
    // Free-running counter makes each human-timed start choose a different LFSR seed.
    reg [15:0] entropy_counter = 0;
    always @(posedge clk) entropy_counter <= entropy_counter + 1'b1;
    reg [15:0] random_state = 16'hACE1;
    reg [ 7:0] spawn_count = 0;
    integer i,slot;
    reg [3:0] remaining=0;
    reg [3:0] scan=0;
    reg manual=0,wave_bomb=0;
    reg signed [15:0] saved_x,saved_y,saved_vx,saved_vy;
    wire [3:0] normal_count=random_state<=45875 ? 1:random_state<=58982 ? 2:3;
    reg [15:0] fruit_random;
    reg rare_wave;
    integer free_slots;
    reg [2:0] motion_phase = 0;
    reg [2:0] spin_count=0;
    wire [3:0] new_kind=manual ? random_state[3:0]:fruit_random[3:0];
    wire [3:0] spawn_kind=new_kind>8 ? new_kind-9:new_kind;
    wire spawn_heavy=spawn_kind==1 || spawn_kind>=5;
    // Four motion updates per five game ticks: exactly 20% slower on average.
    function [15:0] advance_random;
        input [15:0] value;
        reg [15:0] v;
        integer j;
        begin
            v=value;
            for(j=0;j<8;j=j+1)
                v={v[14:0],v[15]^v[13]^v[12]^v[10]};
            advance_random=v;
        end
    endfunction
    initial
        for (i = 0; i < N; i = i + 1) begin
            px[i] = 0;
            py[i] = 0;
            vx[i] = 0;
            vy[i] = 0;
        end
    genvar k;
    generate
        for (k = 0; k < N; k = k + 1) begin : pack
            assign positions_x[k*16+:16] = px[k];
            assign positions_y[k*16+:16] = py[k];
        end
    endgenerate
    always @(posedge clk) begin
        missed <= 0;
        if (reset) begin
            remaining<=0;scan<=0;fruit_types<=0;spins<=0;spin_count<=0;
            active       <= 0;
            bomb         <= 0;
            spawn_count  <= 0;
            motion_phase <= 0;
            random_state <= (entropy_counter ^ 16'hACE1) | 16'h0001;
        end else if (playing) begin
            active <= active & ~remove_mask;
            // Allocate one slot per clock instead of cascading eight priority chains.
            if(versus && launch && remaining==0) begin
                remaining<=1;scan<=0;manual<=1;wave_bomb<=launch_bomb;
                saved_x<=launch_x;saved_y<=launch_y;saved_vx<=launch_vx;saved_vy<=launch_vy;
            end else if(remaining!=0) begin
                if(scan>=N) remaining<=0;
                else begin
                    scan<=scan+1'b1;
                    if(!active[scan] && !remove_mask[scan]) begin
                        active[scan]<=1;remaining<=remaining-1'b1;
                        fruit_types[scan*4+:4]<=spawn_kind;
                        spins[scan*2+:2]<=0;
                        bomb[scan]<=manual ? wave_bomb:rare_wave ? wave_bomb:(fruit_random[3:0]==0);
                        if(manual) begin
                            px[scan]<=saved_x;py[scan]<=saved_y;
                            // Large fruit gets less velocity from the same launch impulse.
                            vx[scan]<=spawn_heavy && !wave_bomb ? saved_vx-(saved_vx>>>3):saved_vx;
                            vy[scan]<=spawn_heavy && !wave_bomb ? saved_vy-(saved_vy>>>3):saved_vy;
                        end else begin
                            case (fruit_random[11:10])
                                0: begin
                                    px[scan] <= (16'd120 + {8'd0,fruit_random[7:0]}) << 4;
                                    py[scan] <= 16'sd8000;
                                    vx[scan] <= fruit_random[9] ? (16'sd12 + $signed({12'd0,fruit_random[3:0]})) : -(16'sd12 + $signed({12'd0,fruit_random[3:0]}));
                                    vy[scan] <= -16'sd152 - $signed({12'd0,fruit_random[7:4]}) - $signed({12'd0,difficulty,2'b00});
                                end
                                1: begin
                                    px[scan] <= (16'd120 + {8'd0,fruit_random[7:0]}) << 4;
                                    py[scan] <= -16'sd768;
                                    vx[scan] <= 0;
                                    vy[scan] <= 16'sd16 + $signed({12'd0,fruit_random[7:4]});
                                end
                                2: begin
                                    px[scan] <= -16'sd768;
                                    py[scan] <= (16'd150 + {10'd0,fruit_random[5:0]}) << 4;
                                    vx[scan] <= 16'sd80 + $signed({11'd0,fruit_random[4:0]});
                                    vy[scan] <= -16'sd48 - $signed({11'd0,fruit_random[8:4]});
                                end
                                3: begin
                                    px[scan] <= 16'sd11008;
                                    py[scan] <= (16'd150 + {10'd0,fruit_random[5:0]}) << 4;
                                    vx[scan] <= -16'sd80 - $signed({11'd0,fruit_random[4:0]});
                                    vy[scan] <= -16'sd48 - $signed({11'd0,fruit_random[8:4]});
                                end
                            endcase

                            fruit_random<=advance_random(fruit_random);
                        end
                    end
                end
            end
            if (game_tick) begin
                spin_count<=spin_count+1'b1;
                motion_phase <= motion_phase == 4 ? 0 : motion_phase + 1'b1;
                random_state <= {
                    random_state[14:0],
                    random_state[15] ^ random_state[13] ^ random_state[12] ^ random_state[10]
                };
                for (i = 0; i < N; i = i + 1)
                if (active[i] && !remove_mask[i] && motion_phase != 4) begin
                    if(spin_count==0 && fruit_types[i*4+:4]==4)
                        spins[i*2+:2]<=vx[i]<0 ? spins[i*2+:2]-1'b1:spins[i*2+:2]+1'b1;
                    px[i] <= px[i] + vx[i];
                    py[i] <= py[i] + vy[i];
                    // Same gravity for every mass; light fruit has more air drag.
                    if(fruit_types[i*4+:4]==5 && !bomb[i] && vy[i]>=16'sd109) vy[i]<=16'sd112;
                    else if((fruit_types[i*4+:4]==0 || fruit_types[i*4+:4]==2 || fruit_types[i*4+:4]==3 || fruit_types[i*4+:4]==4) && !bomb[i] && vy[i]>=16'sd125) vy[i]<=16'sd128;
                    else if(vy[i]<16'sd189) vy[i] <= vy[i] + 16'sd3;
                    else vy[i]<=16'sd192;
                    if((fruit_types[i*4+:4]==0 || fruit_types[i*4+:4]==2 || fruit_types[i*4+:4]==3 || fruit_types[i*4+:4]==4) && !bomb[i] && motion_phase==0) begin
                        if(vx[i]>0) vx[i]<=vx[i]-1'b1;
                        else if(vx[i]<0) vx[i]<=vx[i]+1'b1;
                    end
                    if (py[i] > 16'sd8704 || px[i] < -16'sd1024 || px[i] > 16'sd11264) begin
                        active[i] <= 0;
                        missed[i] <= !bomb[i];
                    end
                end
                if (!versus && spawn_count >= (8'd65 - {6'd0,difficulty}*8'd10) && remaining==0) begin
                    spawn_count<=0;scan<=0;manual<=0;
                    remaining<=random_state<3277 ? 5:(normal_count>WAVE_SIZE ? WAVE_SIZE:normal_count);
                    rare_wave<=random_state<3277;wave_bomb<=random_state[5];fruit_random<=random_state;
                end else if(!versus) spawn_count<=spawn_count+1'b1;
            end
        end
    end
    // Spawn counts include a possible bomb; insufficient free slots cap the wave.
endmodule

// First switch after all-off selects position; later rising switches aim.
// Bottom -> left -> top -> right is clockwise around the screen.
module versus_controls(
 input clk,reset,tick,enabled,input [14:0] switches,
 input fruit_hold,bomb_hold,rotate_press,
 output reg launch=0,output reg bomb=0,
 output reg [3:0] origin=0,target=0,output reg selected=0,
 output [2:0] speed,output reg [6:0] cooldown=0,
 output reg [1:0] orientation=0,output reg [5:0] charge=0,
 output reg signed [15:0] start_x,start_y,velocity_x,velocity_y);
 reg armed=0,charging=0,charging_bomb=0,waiting_release=0;
 reg [14:0] old_switches=0;
 wire [14:0] rising=switches & ~old_switches;
 wire held=charging_bomb ? bomb_hold:fruit_hold;
 integer i;reg found;reg [3:0] first;
 reg signed [5:0] delta;
 reg signed [15:0] tangent,forward,along_x,along_y;
 assign speed=charge>=48 ? 4:charge>=32 ? 3:charge>=16 ? 2:1;
 always @(*) begin
  found=0;first=0;
  for(i=0;i<15;i=i+1) if(rising[i] && !found) begin found=1;first=i;end
  delta=$signed({2'b0,target})-$signed({2'b0,origin});
  // Distance is inverse to angle from the inward normal: close = shallow.
  case(delta<0 ? -delta:delta)
   0:begin forward=160;tangent=0;end
   1,2:begin forward=48;tangent=144;end
   3,4:begin forward=64;tangent=128;end
   5,6:begin forward=80;tangent=112;end
   7,8:begin forward=96;tangent=96;end
   9,10:begin forward=112;tangent=80;end
   11,12:begin forward=128;tangent=48;end
   default:begin forward=144;tangent=16;end
  endcase
  if(charge>=32) begin forward=forward+(forward>>>2);tangent=tangent+(tangent>>>2);end
  else if(charge>=16) begin forward=forward+(forward>>>3);tangent=tangent+(tangent>>>3);end
  if(delta>=0) tangent=-tangent;
  along_x=16'sd9600-$signed({12'b0,origin})*16'sd640;
  along_y=16'sd6720-$signed({12'b0,origin})*16'sd416;
  case(orientation)
   0:begin start_x=along_x;start_y=8000;velocity_x=tangent;velocity_y=-forward;end
   1:begin start_x=-320;start_y=along_y;velocity_x=forward;velocity_y=tangent;end
   2:begin start_x=10240-along_x;start_y=-320;velocity_x=-tangent;velocity_y=forward;end
   3:begin start_x=10560;start_y=7680-along_y;velocity_x=-forward;velocity_y=-tangent;end
  endcase
 end
 always @(posedge clk) begin
  launch<=0;old_switches<=switches;
  if(reset) begin
   armed<=(switches==0);selected<=0;origin<=0;target<=0;cooldown<=0;
   old_switches<=0;orientation<=0;charge<=0;charging<=0;waiting_release<=0;
  end else begin
   if(switches==0) begin selected<=0;armed<=1;origin<=0;target<=0;end
   else if(found) begin
    if(armed && !selected) begin origin<=first;target<=first;selected<=1;armed<=0;end
    else if(selected) target<=first;
   end
   if(enabled && rotate_press && !charging) orientation<=orientation+1'b1;
   if(tick && cooldown!=0) cooldown<=cooldown-1'b1;
   if(!enabled) begin charging<=0;charge<=0;waiting_release<=1;end
   else if(waiting_release) begin
    if(!fruit_hold && !bomb_hold) waiting_release<=0;
   end else if(charging) begin
    if(!selected || switches==0) begin charging<=0;charge<=0;waiting_release<=1;end
    else if(!held) begin
     launch<=1;bomb<=charging_bomb;charging<=0;waiting_release<=1;
     cooldown<=charging_bomb ? 90:20;
     // Keep charge stable through the receiver's launch capture next clock.
    end else if(tick && charge<48) charge<=charge+1'b1;
   end else if(selected && switches!=0 && cooldown==0 && (fruit_hold || bomb_hold)) begin
    charging<=1;charging_bomb<=bomb_hold;charge<=0;
   end
  end
 end
endmodule
