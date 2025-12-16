`timescale 1ns/1ps

module tb_mod_arith;
    `include "parameters.vh";
    reg [len-1:0] a, b;
    reg [len-1:0] v;
    wire [len-1:0] c_add, c_sub, c_mul, c_inv;

    // Instantiate your modules
//    mod_add add_inst (.a(a), .b(b), .r(p), .c(c_add));
    mod_mul mul_inst (.a(a), .b(b), .r(v), .c(c_mul));

    initial begin
        v = 2147483647;
        $display("Starting modular arithmetic testbench...");
        $display("SECP_P = %h", v);

        // Test 1: simple numbers
        a = 3; b = 4;
        #10;
        $display("Test 1: a=%d, b=%d -> add=%d, mul=%d, inv(a)=%d", 
                  a,b,c_add,c_mul,c_inv);

        // Test 2: a=1 (inverse exists), b=0
        a = 290987904; b = 794098883;
        #10;
        $display("Test 2: a=%d, b=%d -> add=%d, mul=%h, inv(a)=%d", 
                  a,b,c_add,c_mul,c_inv);
        $display("All tests done.");
        $finish;
    end

endmodule
