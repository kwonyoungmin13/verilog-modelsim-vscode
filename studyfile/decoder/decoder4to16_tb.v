`timescale 1 ns / 1 ns

module decoder4to16_tb;
    reg [3:0] A;
    reg en;
    wire [0:15] I;

    decode4to16 UUT (
        .A(A),
        .en(en),
        .I(I)
    );

    initial begin
        en = 0;
        A = 4'b0000;

        #20;
        A = 4'b0001;

        #20;
        A = 4'b0010;

        #20;
        A = 4'b0011;

        #20;
        A = 4'b0100;

        #20;
        A = 4'b0101;

        #20;
        A = 4'b0110;

        #20;
        A = 4'b0111;

        #20;
        A = 4'b1000;

        #20;
        A = 4'b1001;

        #20;
        A = 4'b1010;

        #20;
        A = 4'b1011;

        #20;
        A = 4'b1100;

        #20;
        A = 4'b1101;

        #20;
        A = 4'b1110;

        #20;
        A = 4'b1111;

        #20;
        en = 1;
        A = 4'b0000;

        #20;
        A = 4'b1111;

        #20;
        $stop;
    end
endmodule
