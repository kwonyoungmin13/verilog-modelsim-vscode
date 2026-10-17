`timescale 1ns/1ps

module counter_tb;
    reg clk;
    reg reset;
    reg enable;
    wire [3:0] count;
    integer i;

    counter dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .count(count)
    );

    // Clock period: 10 ns.
    always #5 clk = ~clk;

    task check_count;
        input [3:0] expected;
        begin
            if (count !== expected)
                $fatal(1, "counter: expected %0d, got %0d at %0t",
                       expected, count, $time);
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        enable = 0;

        // Reset clears the counter on a rising clock edge.
        @(posedge clk); #1;
        check_count(4'd0);

        // Enable counting and check all values, including 15 -> 0 wraparound.
        @(negedge clk);
        reset = 0;
        enable = 1;
        for (i = 1; i <= 17; i = i + 1) begin
            @(posedge clk); #1;
            check_count(i % 16);
        end

        // Disabling the counter holds its current nonzero value.
        @(negedge clk);
        enable = 0;
        repeat (2) begin
            @(posedge clk); #1;
            check_count(4'd1);
        end

        // Reset takes priority even when enable is high.
        @(negedge clk);
        reset = 1;
        enable = 1;
        @(posedge clk); #1;
        check_count(4'd0);

        $display("PASS: counter reset, enable, hold, and wraparound");
        $finish;
    end
endmodule
