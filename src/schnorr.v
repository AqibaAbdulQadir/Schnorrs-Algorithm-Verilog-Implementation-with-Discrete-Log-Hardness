`timescale 1ns/1ps

module schnorr #(
    `include "parameters.vh"
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [1:0]  mode,
    input  wire        start,
    input  wire [31:0] msg,

    input  wire [len-1:0] s_in,
    input  wire [len-1:0] P_in,
    input  wire [len-1:0] R_in,

    output reg  [len-1:0] s_out,
    output reg  [len-1:0] P_out,
    output reg  [len-1:0] R_out,

    output reg  valid_gen,
    output reg  valid_sign,
    output reg  valid_ver,
    output reg  done
);

    // -------------------------
    // Modes
    // -------------------------
    localparam MODE_IDLE   = 2'd0,
               MODE_KEYGEN = 2'd1,
               MODE_SIGN   = 2'd2,
               MODE_VERIFY = 2'd3;

    // -------------------------
    // FSM states
    // -------------------------
    localparam IDLE=0, KEYGEN_START=1, KEYGEN_PRIV=2, KEYGEN_PUB=3, KEYGEN_END=4,
               SIGNGEN_START=5, SIGNGEN_NONCE=6, SIGNGEN_PUBNONCE=7, SIGNGEN_CHALL=8, SIGNGEN_MUL=9, SIGNGEN_ADD=10, SIGNGEN_END=11,
               VERIFY_START=12, VERIFY_SIGLET=13, VERIFY_CHALL=14, VERIFY_PUBC=15, VERIFY_MUL=16, VERIFY_END=17;

    reg [4:0] state;

    // -------------------------
    // Registers
    // -------------------------
    //    reg [len-1:0] x;
    //    reg [len-1:0] pri_k, pub_k, nonce, R, c, s, v;
    reg [(len<<1)-1:0] a_add, b_add, r_add; 
    wire [(len<<1)-1:0] res_add;
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
    reg [len-1:0] priv_key, nonce, chall, s_left, s_right;

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

    // -------------------------
    // mod_mul / mod_add
    // -------------------------
    //    wire [len-1:0] xe;
    mod_mul u_mul (.a(a_mul), .b(b_mul), .r(r_mul), .c(res_mul));

    //    wire [len-1:0] ks;
    mod_add u_add (.a(a_add), .b(b_add), .r(r_add), .c(res_add));
    
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

    // -------------------------
    // FSM
    // -------------------------
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            valid_gen <= 0;
            valid_sign <= 0;
            valid_ver <= 0;
        end else begin
    //            done <= 0;
    //            valid_gen <= 0;
    //            valid_sign <= 0;
    //            valid_ver <= 0;

            case (state)
                IDLE: begin
                    if (start) begin
                        if (mode == 0)
                            state <= KEYGEN_START;
                        else if (mode == 1)
                            state <= SIGNGEN_START;
                        else if (mode == 2)
                            state <= VERIFY_START;
                    end
                end
    
                // -------- KEYGEN --------
                KEYGEN_START: begin
                    rst_prng <= 1;
                    start_prng <= 0;
                    seed_prng <= 32'h86FEBEA1;
                    state <= KEYGEN_PRIV;
                end
                
                 KEYGEN_PRIV: begin
                       rst_prng <= 0;
                       start_prng <= 1;
                       if (done_prng) begin
                           exp <= out_prng[len-1:0]; // store private key in exp
                           priv_key <= out_prng[len-1:0];
                           base_exp <= g;
                           mod_exp <= p;
                           rst_exp <= 1;
                           start_exp <= 0;
                           state <= KEYGEN_PUB;
                       end
                   end
    
                KEYGEN_PUB: begin
                   rst_exp <= 0;
                   start_exp <= 1;
                   if (done_exp) begin
                        P_out <= res_exp;
                        valid_gen <= 1;
                        done <= 1;
                        state <= KEYGEN_END;
                    end
                end
                
                KEYGEN_END: begin
                    if (rst) state <= IDLE;
                end
                
                // -------- SIGN --------
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
                    done <= 1;
                    valid_sign <= 1;
                    state <= SIGNGEN_END;
                end
                
                SIGNGEN_END: begin
                    if (rst) state <= IDLE;
                end    
    
                // -------- VERIFY --------
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
                    state <= VERIFY_END;
                end
                
                VERIFY_END: begin
                    if (rst) state <= IDLE;
                end    
            endcase
        end
    end

endmodule

