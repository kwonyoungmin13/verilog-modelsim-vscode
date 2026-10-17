`timescale 1 ns / 1 ns

module decoder2to4_tb;
    reg [1:0] A;
    reg en;
    wire [0:3] I;

    decoder2to4 UUT (
        .A(A),
        .en(en),
        .I(I)
    );

    initial begin
        en = 0;
        A = 2'b00;

        #20;
        A = 2'b01;

        #20;
        A = 2'b10;

        #20;
        A = 2'b11;

        #20;
        en = 1;
        A = 2'b00;

        #20;
        A = 2'b01;

        #20;
        A = 2'b10;

        #20;
        A = 2'b11;

        #20;
        $stop;
    end
endmodule
