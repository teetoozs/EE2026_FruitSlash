// Large fruit needs three distinct button-held swipes. Bombs stay one-hit.
// Cleared slots rearm so recycled fruit cannot inherit old damage.
module fruit_damage #(
    parameter N = 8
) (
    input                clk,
    reset,
    playing,
    slash_active,
    input      [  N-1:0] active,
    bomb,
    contact,
    input      [N*5-1:0] radii,
    output reg [  N-1:0] destroyed = 0,
    output     [N*2-1:0] health
);
    reg [1:0] damage[0:N-1];
    reg [N-1:0] struck = 0;
    integer i, j;
    genvar k;
    initial for (j = 0; j < N; j = j + 1) damage[j] = 0;
    generate
        for (k = 0; k < N; k = k + 1) begin : pack
            assign health[k*2+:2] = (radii[k*5+:5] == 24 && !bomb[k]) ? (2'd3 - damage[k]) : 2'd1;
        end
    endgenerate
    always @(posedge clk) begin
        destroyed <= 0;
        if (reset) begin
            struck <= 0;
            for (i = 0; i < N; i = i + 1) damage[i] <= 0;
        end else begin
            if (!slash_active) struck <= 0;
            for (i = 0; i < N; i = i + 1) begin
                if (!active[i]) begin
                    damage[i] <= 0;
                    struck[i] <= 0;
                end else if (playing && contact[i] && !struck[i]) begin
                    struck[i] <= 1;
                    if (bomb[i] || radii[i*5+:5] != 24 || damage[i] == 2) destroyed[i] <= 1;
                    else damage[i] <= damage[i] + 1'b1;
                end
            end
        end
    end
endmodule
