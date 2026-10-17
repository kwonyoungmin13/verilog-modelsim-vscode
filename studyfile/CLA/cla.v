`timescale 1ns/1ns

module cla(
    input [3:0]A,
    input [3:0]B,
    input cin,
    output cout,
    output [3:0]S
);

    wire [3:0]P;
    wire [3:0]G;
    wire c1,c2,c3;

    assign P = A^B;
    assign G = A&B;
    
    assign c1 = G[0] | P[0]&cin;
    assign c2 = G[1] | G[0]&P[1] | P[1]&P[0]&cin;
    assign c3 = G[2] | G[1]&P[2] | G[0]&P[2]&P[1] | P[2]&P[1]&P[0]&cin;
    assign cout = G[3] | G[2]&P[3] | G[1]&P[3]&P[2] | G[0]&P[3]&P[2]&P[1] | P[3]&P[2]&P[1]&P[0]&cin;

    assign S[0] = P[0] ^ cin;
    assign S[1] = P[1] ^ c1;
    assign S[2] = P[2] ^ c2;
    assign S[3] = P[3] ^ c3;

endmodule