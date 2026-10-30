// 12 frozen frames, then 36 frames of fire, shockwave and eight flying fragments.
// Octagonal distance and diamond fragments avoid pixel multipliers.
module bomb_renderer #(parameter N = 8) (
    input [9:0] x,
    input [9:0] y,
    input [N-1:0] active,
    input [N*16-1:0] origins_x,
    input [N*16-1:0] origins_y,
    input [5:0] age,
    output reg pixel_on,
    output reg [11:0] rgb
);
    integer i;
    reg signed [15:0] qx, qy;
    reg signed [12:0] cx, cy, dx, dy;
    reg [12:0] ax, ay, major, minor, distance, sx, sy;
    reg [6:0] travel, ring_radius;
    reg [5:0] blast_age;
    reg [3:0] fragment_radius;
    always @(*) begin
        pixel_on = 0;
        rgb = 0;
        qx = 0;
        qy = 0;
        cx = 0;
        cy = 0;
        dx = 0;
        dy = 0;
        ax = 0;
        ay = 0;
        major = 0;
        minor = 0;
        distance = 0;
        sx = 0;
        sy = 0;
        blast_age = age >= 12 ? age - 6'd12 : 0;
        travel = 7'd8 + {blast_age, 1'b0};
        ring_radius = 7'd20 + {blast_age, 1'b0};
        fragment_radius = blast_age < 12 ? 6 : (blast_age < 24 ? 4 : 2);
        for (i = 0; i < N; i = i + 1) begin
            qx = origins_x[i*16+:16];
            qy = origins_y[i*16+:16];
            cx = qx >>> 4;
            cy = qy >>> 4;
            dx = $signed({1'b0, x}) - cx;
            dy = $signed({1'b0, y}) - cy;
            ax = dx < 0 ? -dx : dx;
            ay = dy < 0 ? -dy : dy;
            major = ax > ay ? ax : ay;
            minor = ax > ay ? ay : ax;
            distance = major + (minor >> 1);
            sx = ax > travel ? ax - travel : travel - ax;
            sy = ay > travel ? ay - travel : travel - ay;
            if (active[i]) begin
                if (age < 12) begin
                    // Keep the struck bomb visible at its captured location during hit stop.
                    if (distance <= 18) begin
                        pixel_on = 1;
                        rgb = distance >= 15 ? 12'hF80 : 12'h222;
                        if (ax <= 1 || ay <= 1) rgb = 12'hFFF;
                    end
                end else if (age < 48) begin
                    if (blast_age < 24 && distance >= ring_radius &&
                        distance <= ring_radius + 3) begin
                        pixel_on = 1;
                        rgb = blast_age < 12 ? 12'hFF8 : 12'hF60;
                    end
                    // Eight streaks extend toward the outward moving fragments.
                    if (blast_age < 16 && major >= travel / 2 && major <= travel &&
                        (minor <= 1 || major - minor <= 1)) begin
                        pixel_on = 1;
                        rgb = 12'hF80;
                    end
                    if ((blast_age < 24 || !(x[0] ^ y[0])) &&
                        (sx + ay <= fragment_radius || ax + sy <= fragment_radius ||
                         sx + sy <= fragment_radius)) begin
                        pixel_on = 1;
                        rgb = blast_age < 12 ? 12'hFF4 :
                              (blast_age < 24 ? 12'hF60 : 12'hA30);
                    end
                    if (blast_age < 8 && distance <= 26 - {blast_age, 1'b0}) begin
                        pixel_on = 1;
                        rgb = blast_age < 3 ? 12'hFFF : 12'hFC3;
                    end
                end
            end
        end
    end
endmodule
