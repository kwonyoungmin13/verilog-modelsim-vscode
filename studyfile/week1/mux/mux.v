`timescale 1ns/1ps

// 4-to-1 multiplexer: sel chooses one bit from data.
module mux (
    input  wire [3:0] data,
    input  wire [1:0] sel,
    output wire       y
);
    assign y = data[sel];
endmodule
