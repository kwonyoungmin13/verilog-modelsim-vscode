`timescale 1 ns / 1 ns

module mux4to1 (
    input [3:0] J,
    input [1:0] s,
    output y
);
    assign #3 y = J[s];
endmodule
