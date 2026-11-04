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
    input      [     1:0] difficulty,
    input      [   N-1:0] remove_mask,
    output reg [   N-1:0] active = 0,
    output reg [   N-1:0] bomb = 0,
    output reg [N-1:0] missed = 0,
    output     [N*16-1:0] positions_x,
    output     [N*16-1:0] positions_y
);
    reg signed [15:0] px[0:N-1], py[0:N-1], vx[0:N-1], vy[0:N-1];
    reg [15:0] random_state = 16'hACE1;
    reg [ 7:0] spawn_count = 0;
    integer i,slot;
    reg [3:0] remaining=0;
    reg [3:0] scan=0;
    reg manual=0,wave_bomb=0;
    reg signed [15:0] saved_x,saved_vx,saved_vy;
    wire [3:0] normal_count=random_state<=45875 ? 1:random_state<=58982 ? 2:3;
    reg [15:0] fruit_random;
    reg rare_wave;
    integer free_slots;
    reg [2:0] motion_phase = 0;
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
            remaining<=0;scan<=0;
            active       <= 0;
            bomb         <= 0;
            spawn_count  <= 0;
            motion_phase <= 0;
            random_state <= 16'hACE1;
        end else if (playing) begin
            active <= active & ~remove_mask;
            // Allocate one slot per clock instead of cascading eight priority chains.
            if(versus && launch && remaining==0) begin
                remaining<=1;scan<=0;manual<=1;wave_bomb<=launch_bomb;
                saved_x<=launch_x;saved_vx<=launch_vx;saved_vy<=launch_vy;
            end else if(remaining!=0) begin
                if(scan>=N) remaining<=0;
                else begin
                    scan<=scan+1'b1;
                    if(!active[scan] && !remove_mask[scan]) begin
                        active[scan]<=1;remaining<=remaining-1'b1;
                        bomb[scan]<=manual ? wave_bomb:rare_wave ? wave_bomb:(fruit_random[3:0]==0);
                        if(manual) begin
                            px[scan]<=saved_x;py[scan]<=16'sd8000;
                            vx[scan]<=saved_vx;vy[scan]<=saved_vy;
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
                motion_phase <= motion_phase == 4 ? 0 : motion_phase + 1'b1;
                random_state <= {
                    random_state[14:0],
                    random_state[15] ^ random_state[13] ^ random_state[12] ^ random_state[10]
                };
                for (i = 0; i < N; i = i + 1)
                if (active[i] && !remove_mask[i] && motion_phase != 4) begin
                    px[i] <= px[i] + vx[i];
                    py[i] <= py[i] + vy[i];
                    vy[i] <= vy[i] + 16'sd3;
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

module versus_controls(
 input clk,reset,tick,enabled,input [6:0] switches,input [3:0] speed_switches,
 input fruit_press,bomb_press,
 output reg launch=0,output reg bomb=0,
 output reg [2:0] origin=0,output reg [2:0] target=0,output reg selected=0,
 output reg [2:0] speed=2,output reg [6:0] cooldown=0,
 output reg signed [15:0] start_x,velocity_x,velocity_y);
 reg armed=0;
 reg [6:0] old_switches=0;
 wire [6:0] rising=switches & ~old_switches;
 integer i;reg found;reg [2:0] first;
 reg signed [4:0] angle;
 reg signed [15:0] base_x,base_y;
 always @(*) begin
 found=0;first=0;
 for(i=0;i<7;i=i+1) if(rising[i] && !found) begin found=1;first=i;end
 speed=speed_switches[3] ? 4:speed_switches[2] ? 3:speed_switches[1] ? 2:speed_switches[0] ? 1:2;
 angle=$signed({1'b0,target})-$signed({1'b0,origin});
 case(origin)
 0:start_x=16'sd9216;1:start_x=16'sd7936;2:start_x=16'sd6656;
 3:start_x=16'sd5120;4:start_x=16'sd3584;5:start_x=16'sd2304;default:start_x=16'sd1024;
 endcase
 // 7.5 degree increments; four positions give 30 degrees from vertical.
 case(angle<0 ? -angle:angle)
 0:begin base_x=0;base_y=160;end
 1:begin base_x=21;base_y=159;end
 2:begin base_x=41;base_y=155;end
 3:begin base_x=61;base_y=148;end
 4:begin base_x=80;base_y=139;end
 5:begin base_x=97;base_y=127;end
 default:begin base_x=113;base_y=113;end
 endcase
 case(speed)
 1:begin base_x=base_x-(base_x>>>2);base_y=base_y-(base_y>>>2);end
 3:begin base_x=base_x+(base_x>>>2);base_y=base_y+(base_y>>>2);end
 4:begin base_x=base_x+(base_x>>>1);base_y=base_y+(base_y>>>1);end
 default:begin end
 endcase
 velocity_x=angle>=0 ? -base_x:base_x;velocity_y=-base_y;
 end
 always @(posedge clk) begin
 launch<=0;old_switches<=switches;
 if(reset) begin armed<=(switches==0);selected<=0;origin<=0;target<=0;cooldown<=0;old_switches<=0;end
 else begin
 if(switches==0) begin selected<=0;armed<=1;origin<=0;target<=0;end
 else if(found) begin
  if(armed && !selected) begin origin<=first;target<=first;selected<=1;armed<=0;end
  else if(selected) target<=first;
 end
 if(tick && cooldown!=0) cooldown<=cooldown-1'b1;
 if(enabled && selected && switches!=0 && cooldown==0 && (fruit_press || bomb_press)) begin
  launch<=1;bomb<=bomb_press;cooldown<=bomb_press ? 120:30;
 end
 end
 end
endmodule
