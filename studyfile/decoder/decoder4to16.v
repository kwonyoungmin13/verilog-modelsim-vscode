`timescale 1ns/1ns

module decode4to16(
    input [3:0]A,
    input en,
    output [0:15]I
);

    wire [0:3]W;

    decoder2to4 d1 (A[3:2],en,W);

    decoder2to4 d2 (A[1:0],W[0],I[0:3]);
    decoder2to4 d3 (A[1:0],W[1],I[4:7]);
    decoder2to4 d4 (A[1:0],W[2],I[8:11]);
    decoder2to4 d5 (A[1:0],W[3],I[12:15]);

endmodule
