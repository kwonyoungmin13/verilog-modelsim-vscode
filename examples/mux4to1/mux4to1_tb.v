`timescale 1 ns / 1 ns

module mux4to1_tb;
    reg [3:0] J;
    reg [1:0] s;
    wire y;

    mux4to1 UUT (
        .J(J),
        .s(s),
        .y(y)
    );

    initial begin
        J = 4'b1010;
        s = 2'b00;

        #20;
        s = 2'b01;

        #20;
        s = 2'b10;

        #20;
        s = 2'b11;

        #20;
        J = 4'b0101;
        s = 2'b00;

        #20;
        s = 2'b01;

        #20;
        s = 2'b10;

        #20;
        s = 2'b11;

        #20;
        $stop;
    end
endmodule
