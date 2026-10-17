`timescale 1ns/1ps

module mux_tb;
    reg [3:0] data;
    reg [1:0] sel;
    wire y;
    integer pattern;
    integer selection;

    mux dut (
        .data(data),
        .sel(sel),
        .y(y)
    );

    initial begin
        data = 4'b0000;
        sel = 2'b00;

        // Check every data pattern and every selector: 16 x 4 = 64 cases.
        for (pattern = 0; pattern < 16; pattern = pattern + 1) begin
            data = pattern;
            for (selection = 0; selection < 4; selection = selection + 1) begin
                sel = selection;
                #1;
                if (y !== data[selection])
                    $fatal(1, "mux: data=%b sel=%0d expected=%b got=%b",
                           data, selection, data[selection], y);
            end
        end

        $display("PASS: mux all 64 input and select combinations");
        $finish;
    end
endmodule
