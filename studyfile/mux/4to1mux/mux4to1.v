`timescale 1ns/1ps

module mux4to1 (
    input [3:0]J,
    input [1:0]s,
    output y
);

    assign #3 y = J[s];

endmodule
