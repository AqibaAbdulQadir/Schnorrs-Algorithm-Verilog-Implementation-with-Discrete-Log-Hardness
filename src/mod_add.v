`timescale 1ns/1ps


module mod_add #(
    `include "parameters.vh"
)(
    input  wire [(len<<1)-1:0] a,
    input  wire [(len<<1)-1:0] b,
    input  wire [(len<<1)-1:0] r,
    output wire [(len<<1)-1:0] c
);
    // c = (a + b) mod r
    wire [(len<<1):0] sum;  
    assign sum = a + b;
    assign c = sum % r;

endmodule
