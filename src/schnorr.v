`timescale 1ns/1ps

module schnorr #(
    `include "parameters.vh"
)(
    input  wire        clk,
    input  wire        rst,
//    input  wire [1:0]  mode,
    input  en_key,
    input  en_gen,
    input  en_ver,
    input  wire        start,
    input  wire [31:0] msg_gen,
    input  wire [31:0] msg_ver,

    input  wire [len-1:0] s_in,
    input  wire [len-1:0] P_in,
    input  wire [len-1:0] R_in,

    output wire  [len-1:0] s_out,
    output wire  [len-1:0] P_out,
    output wire  [len-1:0] R_out,

    output wire  valid_gen,
    output wire  valid_sign,
    output wire  valid_ver,
    output wire  done_ver
);

//    localparam IDLE   = 2'd0,
//               KEYGEN = 2'd1,
//               SIGN   = 2'd2,
//               VERIFY = 2'd3;

//    reg en_key, en_gen, en_ver;
    reg [1:0] state;
    wire [len-1:0] priv_key;

    key_gen  kg (en_key, clk, rst, priv_key, P_out, valid_gen);
    sign_gen sg (en_gen, clk, rst, priv_key, msg_gen, s_out, R_out, valid_sign);
    sign_ver sv (en_ver, clk, rst, msg_ver, s_in, P_in, R_in, valid_ver, done_ver);
    
//    always @(posedge clk or posedge rst) begin
//        if (rst) begin
//            state <= IDLE;
//            en_key <= 0;
//            en_gen <= 0;
//            en_ver <= 0;
//        end else begin
//            if (start) begin
//                if (en_key == 0)
//                    en_key <= 1;
//                else if (en_gen == 1)
//                    en_gen <= 1;
//                else if (mode == 2)
//                    en_ver <= 1;
//                end
//            end
//        end
endmodule

