`timescale 1ns/1ps

module mod_exp #(
    `include "parameters.vh"
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             start,
    input  wire [len-1:0]   base_in,
    input  wire [len-1:0]   exp_in,
    input  wire [len-1:0]   r,          // modulus
    output reg  [len-1:0]   out,
    output reg              done
);

    // =====================
    // State encoding
    // =====================
    localparam IDLE   = 3'd0,
               INIT   = 3'd1,
               CHECK  = 3'd2,
               MULRES = 3'd3,
               MULRES_WAIT = 3'd4,
               SQUARE = 3'd5,
               SQUARE_WAIT = 3'd6,
               SHIFT  = 3'd7,
               DONE   = 4'd8;

    reg [3:0] state;

    // =====================
    // Internal registers
    // =====================
    reg [len-1:0] base;
    reg [len-1:0] exp;
    reg [len-1:0] result;

    // =====================
    // mod_mul interface
    // =====================
    reg  [len-1:0] mul_a, mul_b;
    wire [len-1:0] mul_c;

    mod_mul u_mod_mul (
        .a(mul_a),
        .b(mul_b),
        .r(r),
        .c(mul_c)
    );

    // =====================
    // FSM
    // =====================
    always @(posedge clk) begin
        if (rst) begin
            state  <= IDLE;
            done   <= 1'b0;
            out    <= {len{1'b0}};
            base   <= {len{1'b0}};
            exp    <= {len{1'b0}};
            result <= {len{1'b0}};
        end else begin
            case (state)
                // -----------------
                IDLE: begin
                    done <= 1'b0;
                    if (start)
                        state <= INIT;
                end

                // -----------------
                INIT: begin
                    base   <= base_in;
                    exp    <= exp_in;
                    result <= {{(len-1){1'b0}}, 1'b1}; // result = 1
                    state  <= CHECK;
                end

                // -----------------
                CHECK: begin
                    if (exp == 0)
                        state <= DONE;
                    else if (exp[0])
                        state <= MULRES;
                    else
                        state <= SQUARE;
                end

                // -----------------
                // result = result * base mod r
                MULRES: begin
                    mul_a  <= result;
                    mul_b  <= base;
                    state  <= MULRES_WAIT;
                    
                end
                
                MULRES_WAIT: begin
                    result <= mul_c;
                    state  <= SQUARE;
                end
                

                // -----------------
                // base = base * base mod r
                SQUARE: begin
                    mul_a <= base;
                    mul_b <= base;
                    state  <= SQUARE_WAIT;
                end
                
                SQUARE_WAIT: begin
                    base  <= mul_c;
                    state <= SHIFT;
                end

                // -----------------
                SHIFT: begin
                    exp   <= exp >> 1;
                    state <= CHECK;
                end

                // -----------------
                DONE: begin
                    out  <= result;
                    done <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule
