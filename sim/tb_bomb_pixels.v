`timescale 1ns / 1ps
module tb_bomb_pixels;
    reg [9:0] x = 200, y = 200;
    reg [1:0] active = 1;
    reg [31:0] px = {16'd6400, 16'd3200};
    reg [31:0] py = {16'd3200, 16'd3200};
    reg [5:0] age = 0;
    wire visible;
    wire [11:0] rgb;
    bomb_renderer #(.N(2)) dut (
        .x(x),
        .y(y),
        .active(active),
        .origins_x(px),
        .origins_y(py),
        .age(age),
        .pixel_on(visible),
        .rgb(rgb)
    );
    integer a, p, travel;
    integer vx [0:7];
    integer vy [0:7];
    initial begin
        vx[0]=1; vy[0]=0; vx[1]=-1; vy[1]=0;
        vx[2]=0; vy[2]=1; vx[3]=0; vy[3]=-1;
        vx[4]=1; vy[4]=1; vx[5]=-1; vy[5]=1;
        vx[6]=1; vy[6]=-1; vx[7]=-1; vy[7]=-1;
        for (a = 0; a < 12; a = a + 1) begin
            age = a;
            x = 210; y = 210; #1;
            if (!visible || rgb !== 12'hF80) $fatal(1, "Frozen bomb rim moved");
            x = 220; y = 200; #1;
            if (visible) $fatal(1, "Frozen bomb grew");
        end
        age = 12; x = 200; y = 200; #1;
        if (!visible || rgb !== 12'hFFF) $fatal(1, "Missing initial flash");
        for (a = 12; a < 48; a = a + 1) begin
            age = a;
            travel = 8 + 2*(a-12);
            for (p = 0; p < 8; p = p + 1) begin
                x = 200 + vx[p]*travel;
                y = 200 + vy[p]*travel;
                #1;
                if (!visible) $fatal(1, "Missing fragment direction %0d at age %0d", p, a);
            end
        end
        age = 22; x = 241; y = 200; #1;
        if (!visible || rgb !== 12'hFF8) $fatal(1, "Missing expanding shockwave");
        age = 47; x = 200; y = 200; #1;
        if (visible) $fatal(1, "Centre must clear as fragments fly out");
        age = 48; x = 278; #1;
        if (visible) $fatal(1, "Expired explosion visible");
        active = 2; age = 12; x = 400; y = 200; #1;
        if (!visible) $fatal(1, "Second explosion slot missing");
        active = 1; px[15:0] = -16'sd64; age = 0; x = 0; #1;
        if (!visible) $fatal(1, "Signed clipping failed");
        active = 0; #1;
        if (visible) $fatal(1, "Inactive explosion visible");
        $display("PASS: bomb pixels frozen bomb, flash, eight directions, shockwave, fade, clipping");
        $finish;
    end
endmodule
