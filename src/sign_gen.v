`timescale 1ns/1ps

module sign_gen #(
    `include "parameters.vh"
)(
    input  wire        en,
    input  wire        clk,
    input  wire        rst,
    input  wire [len-1:0] priv_key,
    input  wire [31:0] msg,

    output reg  [len-1:0] s_out,
    output reg  [len-1:0] R_out,
    output reg  valid_sign
);

    localparam SIGNGEN_START=0, SIGNGEN_NONCE=1, SIGNGEN_PUBNONCE=2, SIGNGEN_CHALL=3, SIGNGEN_MUL=4, SIGNGEN_ADD=5;

    reg [2:0] state;

    // -------------------------
    // Registers
    // -------------------------
    //    reg [len-1:0] x;
    //    reg [len-1:0] pri_k, pub_k, nonce, R, c, s, v;
    reg [(len<<1)-1:0] a_add, b_add, r_add; 
    wire [(len<<1)-1:0] res_add;
    reg [(len<<1)-1:0] a_mul_norm, b_mul_norm;
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
    reg [len-1:0] chall, nonce;

    // -------------------------
    // mod_exp (shared)
    // -------------------------
    //    reg modexp_start;
    //    reg [len-1:0] modexp_base, modexp_exp;
    //    wire [len-1:0] modexp_out;
    //    wire modexp_done;

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

    mod_add u_add (.a(a_add), .b(b_add), .r(r_add), .c(res_add));
    
    SHA256_0 sha(data, done_sha, clk, rst_sha, start_sha, rd);

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
            state <= SIGNGEN_START;
            valid_sign <= 0;
        end else begin
            case (state)
                SIGNGEN_START: begin
                    rst_prng <= 1;
                    start_prng <= 0;
                    seed_prng <= msg[31:0];
                    state <= SIGNGEN_NONCE;
                end
                
                 SIGNGEN_NONCE: begin
                       rst_prng <= 0;
                       start_prng <= 1;
                       if (done_prng) begin
                           exp <= out_prng[len-1:0]; // store private nonce in exp
                           nonce <= out_prng[len-1:0];
                           base_exp <= g;
                           mod_exp <= p;
                           rst_exp <= 1;
                           start_exp <= 0;
                           state <= SIGNGEN_PUBNONCE;
                       end
                   end
    
                SIGNGEN_PUBNONCE: begin
                   rst_exp <= 0;
                   start_exp <= 1;
                   if (done_exp) begin
                        R_out <= res_exp;
                        state <= SIGNGEN_CHALL;
//                        data <= 
//                        data, done_sha, clk, rst_sha, start_sha, rd
                        // any signals to initialise for hash below
                    end
                end
                SIGNGEN_CHALL: begin
                    // Neha's hash func (R||M)
                    a_mul_norm <= 2317; // {{(len){1'b0}}, c}; // hash output
                    chall <= 2317; // challenge
                    b_mul_norm <= {{(len){1'b0}}, priv_key};   
                    state <= SIGNGEN_MUL;    
                end
                
                SIGNGEN_MUL: begin
                    a_add <= a_mul_norm * b_mul_norm;
                    b_add <= {{(len){1'b0}}, nonce};
                    r_add <= {{(len){1'b0}}, q};
                    state <= SIGNGEN_ADD;    
                end
                
                SIGNGEN_ADD: begin
                    s_out <= res_add;
                    valid_sign <= 1;
                end   
            endcase
        end
    end

endmodule

