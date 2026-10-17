`timescale 1ns/1ns

module decoder2to4(
    input [1:0]A,
    input en,
    output [0:3]I
);

    assign I = en ? 4'b1111 :
               (A == 2'd0) ? 4'b0111 :
               (A == 2'd1) ? 4'b1011 :
               (A == 2'd2) ? 4'b1101 :
               (A == 2'd3) ? 4'b1110 : 4'bxxxx;

endmodule
