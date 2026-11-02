`timescale 1ns/1ps
module tb_new_gameplay;
 reg clk=0; always #5 clk=~clk;
 reg reset=1,tick=0,playing=1,start=0,slash=1,event_in=0,contact=0;
 reg [2:0] hits=0,bomb=0,missed=0;
 reg [9:0] x0=200,y0=240,x1=320,y1=240;
 wire bonus,award,visible,accepting,cutting,falling; wire [15:0] bx,by; wire [5:0] radius; wire [6:0] fall_age; wire [8:0] remaining; wire [7:0] streak;
 streak_bonus #(.N(3),.TARGET(3),.TICKS(12)) b(.clk(clk),.reset(reset),.tick(tick),
 .playing(playing),.slash_active(slash),.blade_event(event_in),.contact(contact),
 .x0(x0),.y0(y0),.x1(x1),.y1(y1),.hits(hits),.bomb(bomb),.missed(missed),
 .active(bonus),.award(award),.visible(visible),.accepting(accepting),.cutting(cutting),.falling(falling),.position_x(bx),.position_y(by),.radius(radius),.fall_age(fall_age),.remaining(remaining),.streak(streak));
 wire [1:0] lives,state; wire [15:0] score;
 game_controller #(.N(3)) g(.clk(clk),.reset(reset),.start_pressed(start),.pause(1'b0),
 .effects_busy(1'b0),.slash_active(slash),.hit_mask(hits),.bomb(bomb),.missed(missed),
 .bonus_hit(award),.lives(lives),.state(state),.score(score));
 wire [2:0] active,pbomb,pmiss; wire [47:0] px,py;
 reg [2:0] remove=0;
 object_physics #(.N(3)) p(.clk(clk),.reset(reset),.game_tick(tick),.playing(playing),
 .difficulty(2'b0),.remove_mask(remove),.active(active),.bomb(pbomb),.missed(pmiss),
 .positions_x(px),.positions_y(py));
 wire wall_on; wire [11:0] wall_rgb;
 wall_splats #(.N(3),.LIFE(4)) w(.clk(clk),.reset(reset),.tick(tick),.playing(playing),
 .hits(hits),.bomb(bomb),.px({3{16'd5120}}),.py({3{16'd3840}}),
 .x(10'd320),.y(10'd240),.pixel_on(wall_on),.rgb(wall_rgb));
 task step; begin @(posedge clk); #1; end endtask
 task frame; begin @(negedge clk);tick=1;step;@(negedge clk);tick=0;end endtask
 initial begin
  step; @(negedge clk);reset=0;start=1;step;@(negedge clk);start=0;
  p.spawn_count=65;p.random_state=16'hF055; frame;
  if(active!==3'b111) $fatal(1,"Wave must spawn three objects together");
  // Fruit escapes, bomb escapes, and a sliced fruit escapes on same tick.
  p.py[0]=9000;p.py[1]=9000;p.py[2]=9000;p.bomb=3'b010;remove=3'b100;
  frame;if(pmiss!==3'b001) $fatal(1,"Only uncut nonbomb fruit counts as missed");
  step;if(pmiss!==0) $fatal(1,"Miss must be a one-clock pulse");remove=0;
  @(negedge clk);missed=1;step;@(negedge clk);missed=0;
  if(lives!==2) $fatal(1,"Miss must deduct one life");
  @(negedge clk);hits=3'b111;step;@(negedge clk);hits=0;
  if(bonus || !visible || !accepting || radius!=36 || !wall_on)
   $fatal(1,"Streak must spawn a fruit without starting the bonus");
  repeat(8) frame;
  if(by>=8000 || bonus) $fatal(1,"Bonus fruit must fly through normal play");
  contact=1;step;@(negedge clk);contact=0;
  if(!bonus || accepting || remaining!=0) $fatal(1,"Contact must trigger zoom before timer");
  playing=0;frame;if(radius!=36) $fatal(1,"Pause changed zoom");playing=1;
  repeat(30) frame;
  if(!cutting || bx!=5120 || by!=3840 || radius!=54 || remaining!=12)
   $fatal(1,"Zoom must centre fruit and increase radius by exactly 50 percent");
  // Release and make a moving swipe; one award, no stationary farming.
  slash=0;step;@(negedge clk);slash=1;event_in=1;step;
  @(negedge clk);event_in=0;contact=1;step;
  if(!award) $fatal(1,"Bonus swipe should award points");
  @(negedge clk);contact=0;step;if(score!=85) $fatal(1,"Three fruits plus bonus should score 85");
  @(negedge clk);contact=1;step;if(award) $fatal(1,"Held contact scored twice");
  @(negedge clk);contact=0;playing=0;frame;
  if(remaining!=12) $fatal(1,"Pause must freeze bonus timer");
  playing=1;repeat(6) frame;
  slash=0;step;@(negedge clk);slash=1;event_in=1;step;
  @(negedge clk);event_in=0;contact=1;step;
  if(!award) $fatal(1,"Second swipe after cooldown must score");
  @(negedge clk);contact=0;step;
  if(score!=110) $fatal(1,"Repeated bonus hit must add another 25 points");
  repeat(6) frame;
  if(!bonus || !falling || accepting || remaining!=0) $fatal(1,"Timer must start falling halves");
  playing=0;frame;if(fall_age!=0) $fatal(1,"Pause changed falling halves");playing=1;
  repeat(90) frame;
  if(bonus || visible || wall_on) $fatal(1,"Bonus must end after halves leave");
  @(negedge clk);hits=1;bomb=1;missed=2;step;
  if(lives!=0 || state!=3 || streak!=0) $fatal(1,"Bomb plus miss must saturate lives and end round");
  $display("PASS: waves misses bonus and wall splats");$finish;
 end
 initial begin #100000; $fatal(1,"Timeout");end
endmodule
