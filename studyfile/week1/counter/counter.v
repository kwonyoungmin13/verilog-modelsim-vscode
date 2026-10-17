`timescale 1ns/1ns

module counter(
    input clk , reset,
    output reg [3:0]count
);

    always @(posedge clk or posedge reset) begin
        if(reset) count <= 4'd0;
        else count <= count + 4'd1;
    end

endmodule
