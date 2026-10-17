`timescale 1 ns / 1 ns

module cla_tb;
    reg [3:0] A;
    reg [3:0] B;
    reg cin;
    wire cout;
    wire [3:0] S;

    cla UUT (
        .A(A),
        .B(B),
        .cin(cin),
        .cout(cout),
        .S(S)
    );

    initial begin
        A = 4'b0000;
        B = 4'b0000;
        cin = 0;

        #20;
        A = 4'b0000;
        B = 4'b0000;
        cin = 1;

        #20;
        A = 4'b0001;
        B = 4'b0001;
        cin = 0;

        #20;
        A = 4'b0011;
        B = 4'b0000;
        cin = 1;

        #20;
        A = 4'b0110;
        B = 4'b0000;
        cin = 1;

        #20;
        A = 4'b0111;
        B = 4'b0001;
        cin = 0;

        #20;
        A = 4'b1111;
        B = 4'b0000;
        cin = 1;

        #20;
        A = 4'b1111;
        B = 4'b0001;
        cin = 0;

        #20;
        A = 4'b1010;
        B = 4'b0101;
        cin = 0;

        #20;
        A = 4'b1111;
        B = 4'b1111;
        cin = 1;

        #20;
        $stop;
    end
endmodule
