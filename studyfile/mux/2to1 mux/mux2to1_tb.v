`timescale 1ns/1ps

module mux2to1_tb;
    reg a;
    reg b;
    reg s;
    wire y;
    integer vector;

    mux2to1 dut (
        .a(a),
        .b(b),
        .s(s),
        .y(y)
    );

    task check_output;
        input expected;
        begin
            if (y !== expected)
                $fatal(1, "FAIL at %0t: s=%b a=%b b=%b expected=%b y=%b",
                       $time, s, a, b, expected, y);
        end
    endtask

    initial begin
        a = 0;
        b = 0;
        s = 0;

        // All eight combinations of {s, a, b}.
        // Wait longer than the DUT's 3 ns propagation delay before checking.
        for (vector = 0; vector < 8; vector = vector + 1) begin
            {s, a, b} = vector[2:0];
            #5;
            check_output(s ? b : a);
        end

        // Select changes: y must retain its old value before 3 ns.
        a = 0;
        b = 1;
        s = 0;
        #5;
        check_output(0);

        s = 1;
        #2; check_output(0);
        #2; check_output(1);

        s = 0;
        #2; check_output(1);
        #2; check_output(0);

        // Selected input a changes while s=0, with the same 3 ns delay.
        a = 1;
        #2; check_output(0);
        #2; check_output(1);

        // Unselected input b must not change y while s=0.
        b = 0;
        #5;
        check_output(1);

        // Select b, then change it while s=1.
        s = 1;
        #2; check_output(1);
        #2; check_output(0);

        b = 1;
        #2; check_output(0);
        #2; check_output(1);

        // Unselected input a must not change y while s=1.
        a = 0;
        #5;
        check_output(1);

        $display("PASS: mux2to1 all 8 combinations, input/select changes, and 3 ns delay");
        $finish;
    end
endmodule
