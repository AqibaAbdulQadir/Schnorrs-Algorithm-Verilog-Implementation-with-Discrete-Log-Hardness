`timescale 1ns/1ps

module sign_ver #(
    `include "parameters.vh"
)(
    input  wire        en,
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] msg,

    input  wire [len-1:0] s_in,
    input  wire [len-1:0] P_in,
    input  wire [len-1:0] R_in,

    output reg  valid_ver,
    output reg  done
);


    localparam VERIFY_START=0, VERIFY_SIGLET=1, VERIFY_CHALL=2, VERIFY_PUBC=3, VERIFY_MUL=4;

    reg [2:0] state;
    reg [(len<<1)-1:0] a_mul_norm, b_mul_norm;
    reg [len-1:0] a_mul, b_mul, r_mul;
    wire [len-1:0] res_mul;
    reg [len-1:0] base_exp, exp, mod_exp;
    wire [len-1:0] res_exp; 
    reg rst_exp, start_exp;
    wire done_exp;
    reg rst_prng, start_prng;
    wire done_prng;
    reg [31:0] seed_prng;
    wire [255:0]out_prng;
    reg rst_sha, start_sha, rd;
    wire [31:0] data;
    wire done_sha;
    reg [len-1:0] chall, s_left, s_right;


    mod_exp u_modexp (
        .clk(clk),
        .rst(rst_exp),
        .start(start_exp),
        .base_in(base_exp),
        .exp_in(exp),
        .r(mod_exp),
        .out(res_exp),
        .done(done_exp)
    );

    mod_mul u_mul (.a(a_mul), .b(b_mul), .r(r_mul), .c(res_mul));
    
    SHA256_0 sha(data, done_sha, clk, rst_sha, start_sha, rd);

    // -------------------------
    // PRNG
    // -------------------------
    wire [255:0] prng_out;
    wire prng_valid;
    reg prng_start;

    prng u_prng (
        .clk(clk),
        .rst(rst_prng),
        .start(start_prng),
        .inseed(seed_prng),
        .random_out(out_prng),
        .valid(done_prng)
    );

    always @(posedge clk or posedge rst) begin
        if (rst || !en) begin
            state <= VERIFY_START;
            done <= 0;
            valid_ver <= 0;
        end else begin
            case (state)
                VERIFY_START: begin
                    exp <= s_in;
                    base_exp <= g;
                    mod_exp <= p;
                    start_exp <= 0;
                    rst_exp <= 1;
                    state <= VERIFY_SIGLET;
                end
    
                VERIFY_SIGLET: begin
                    start_exp <= 1;
                    rst_exp <= 0;
                    if (done_exp) begin
                        s_left <= res_exp;
                        state <= VERIFY_CHALL;
                        start_exp <= 0;
                        rst_exp <= 1;
                        // any signals to initialise for hash below
                    end
                end
                
                VERIFY_CHALL: begin
                    // Neha's hash func (R||M)
                    exp <= 2317;
                    base_exp <= P_in;
                    mod_exp <= p;
                    state <= VERIFY_PUBC;  
                end
                
                VERIFY_PUBC: begin                 
                    start_exp <= 1;
                    rst_exp <= 0;
                    if (done_exp) begin
                        a_mul <= res_exp; // P^c mod p
                        b_mul <= R_in;
                        r_mul <= p;                    
                        start_exp <= 0;
                        rst_exp <= 1;
                        state <= VERIFY_MUL;
                    end    
                end
    
                VERIFY_MUL: begin
                    s_right <= res_mul; 
                    done <= 1;
                    valid_ver <= (s_left == res_mul); 
                end  
            endcase
        end
    end

endmodule
