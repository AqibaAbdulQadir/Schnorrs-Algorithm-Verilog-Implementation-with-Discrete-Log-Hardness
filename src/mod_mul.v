`timescale 1ns/1ps

module mod_mul #(
    `include "parameters.vh"
    ) (
    input  wire [len-1:0] a,
    input  wire [len-1:0] b,
    input  wire [len-1:0] r,
    output wire [len-1:0] c
);
    // c = (a * b) mod p
    // Too big; needs optimisation
    wire [(len<<1) - 1:0] product;
    assign product = a * b;
    assign c = product % r;

endmodule
