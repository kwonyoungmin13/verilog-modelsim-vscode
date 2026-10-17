`timescale 1ns/1ns

module mux2to1(
    input a,b,
    input s,
    output y
);

    assign #3 y = ~s? a : b;

endmodule