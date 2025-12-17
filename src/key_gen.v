`timescale 1ns/1ps

module key_gen #(
    `include "parameters.vh"
)(
    input  wire        en,
    input  wire        clk,
    input  wire        rst,
    output reg  [len-1:0] priv_key,
    output reg  [len-1:0] P_out,
    output reg  valid_gen
);

    localparam KEYGEN_START=0, KEYGEN_PRIV=1, KEYGEN_PUB=2;

    reg [1:0] state;
    reg [len-1:0] base_exp, exp, mod_exp;
    wire [len-1:0] res_exp; 
    reg rst_exp, start_exp;
    wire done_exp;
    reg rst_prng, start_prng;
    wire done_prng;
    reg [31:0] seed_prng;
    wire [255:0]out_prng;

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

    prng u_prng (
        .clk(clk),
        .rst(rst_prng),
        .start(start_prng),
        .inseed(seed_prng),
        .random_out(out_prng),
        .valid(done_prng)
    );

    always @(posedge clk, posedge rst) begin
        if (rst || !en) begin
            state <= KEYGEN_START;
            valid_gen <= 0;
        end else begin
            case (state)
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
                    end
                end
                
                endcase
        end
    end

endmodule

