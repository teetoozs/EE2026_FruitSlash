// Juice burst: eight spreading droplets and a shrinking central splash.
// Shared shape with optional fruit colours; large watermelons use red juice.
module splash_renderer #(parameter N = 8, parameter FRUIT_PALETTE = 0) (
    input [9:0] x,
    input [9:0] y,
    input [N-1:0] active,
    input [N*16-1:0] positions_x,
    input [N*16-1:0] positions_y,
    input [N*5-1:0] ages,
    input [N*5-1:0] radii,
    output reg pixel_on,
    output reg [11:0] rgb
);
    integer i;
    reg signed [15:0] qx, qy;
    reg signed [12:0] cx, cy, dx, dy;
    reg [12:0] ax, ay, sx, sy;
    reg [4:0] age;
    reg [5:0] spread;
    reg [3:0] radius, core;
    reg [11:0] juice_colour;
    always @(*) begin
        juice_colour = 12'hF90;
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
        sx = 0;
        sy = 0;
        age = 0;
        spread = 0;
        radius = 0;
        core = 0;
        for (i = 0; i < N; i = i + 1) begin
            qx = positions_x[i*16+:16];
            qy = positions_y[i*16+:16];
            age = ages[i*5+:5];
            cx = qx >>> 4;
            cy = (qy >>> 4) + $signed({10'd0, age[4:2]});
            dx = $signed({1'b0, x}) - cx;
            dy = $signed({1'b0, y}) - cy;
            ax = dx < 0 ? -dx : dx;
            ay = dy < 0 ? -dy : dy;
            spread = 6'd5 + {1'b0, age};
            radius = age < 8 ? 3 : (age < 16 ? 2 : 1);
            core = age < 8 ? 10 : (age < 16 ? 7 : 4);
            sx = ax > spread ? ax - spread : spread - ax;
            sy = ay > spread ? ay - spread : spread - ay;
            // Manhattan-distance diamonds require only adds/comparisons, no multipliers.
            if (active[i] && age < 24 && (age < 16 || !(x[0] ^ y[0])) &&
                (ax + ay <= core || sx + ay <= radius || ax + sy <= radius ||
                 sx + sy <= radius)) begin
                pixel_on = 1;
                rgb = age < 8 ? 12'hF90 : (age < 16 ? 12'hD60 : 12'hA40);
                if (FRUIT_PALETTE) begin
                    case (i % 4)
                        0: juice_colour = 12'hF90;
                        1: juice_colour = 12'hF45;
                        2: juice_colour = 12'h8F4;
                        default: juice_colour = 12'hD6F;
                    endcase
                    if (radii[i*5+:5] == 24) juice_colour = 12'hF45;
                    rgb = age < 8 ? juice_colour :
                          {1'b0, juice_colour[11:9], 1'b0, juice_colour[7:5],
                           1'b0, juice_colour[3:1]};
                end
            end
        end
    end
endmodule
