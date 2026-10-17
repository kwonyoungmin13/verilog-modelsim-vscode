`timescale 1ns/1ps

module tb_count();

    reg reset , clk;
    wire [3:0]count;
    counter c1(clk,reset,count);

    initial begin
        clk = 0;
        reset = 0;

        #10 
        reset = 1;

        #10 
        reset = 0;

        #100.5
        reset = 1;

        #10 $stop;
    end

    always #25 clk = ~clk;
endmodule
