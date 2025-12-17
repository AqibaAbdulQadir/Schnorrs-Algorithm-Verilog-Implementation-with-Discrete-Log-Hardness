`timescale 1ns/1ps

module tb_schnorr;
    `include "parameters.vh";
    reg         clk;
    reg         rst;
//    reg   [1:0] mode;
    reg  en_key, en_gen, en_ver;
    reg  start;
    wire valid1, valid2, valid3, done;
    wire [len-1:0] P_out, s, R_out;
    reg  [len-1:0] P_in, s_in, R_in;
    reg  [31:0] msg;

    // Instantiate PRNG
    schnorr uut (
        .clk(clk),
        .rst(rst),
        .msg_gen(msg),
        .msg_ver(msg),
        .start(start),
//        .mode(mode),
        .en_key(en_key),
        .en_gen(en_gen),
        .en_ver(en_ver),
        .P_out(P_out),
        .P_in(P_in),
        .s_out(s),
        .s_in(s_in),
        .R_out(R_out),
        .R_in(R_in),
        .valid_gen(valid1),
        .valid_sign(valid2),
        .valid_ver(valid3),
        .done_ver(done)
    );

    always #5 clk = ~clk;   // 100 MHz clock (10 ns period)

    // -------------------------
    // Test sequence
    // -------------------------
    initial begin
        // Initialize
        clk   = 0;
        rst   = 1;
        start = 1;
        en_key = 1;
        #20;
        rst = 0;
        wait (valid1 == 1);

        // Display result
        $display("=================================================");
        $display("KEY GENERATION");
        $display("Private Key(x): %h", uut.priv_key);
        $display("Public Key(P): %h", P_out);
        $display("=================================================");
        #20;
        
        // reset
        rst   = 1;
        msg = 32'hABCDEF45;
        en_key = 0;
        en_gen = 1;

        #20;
        rst = 0;
        wait (valid2 == 1);

        // Display result
        $display("=================================================");
        $display("SIGNATURE GENERATION");
        $display("Siglet(s): %h", s);
        $display("Nonce(r): %h", uut.sg.nonce);
        $display("Commitment(R): %h", R_out);
        $display("Challenge(c): %h", uut.sg.chall);
        $display("=================================================");

        // Stop simulation
        #20;

        // reset
        rst   = 1;
        msg = 32'hABCDEF45;
        en_gen = 0;
        en_ver = 1;
        P_in = P_out;
        s_in = s;
        R_in = R_out;

        #20;
        rst = 0;
        wait (done == 1);

        // Display result
        $display("=================================================");
        $display("SIGNATURE VERIFICATION");
        $display("Valid Signal: %h", valid3);
        $display("g^s: %h", uut.sv.s_right);
        $display("P^c*R: %h", uut.sv.s_left);
        $display("=================================================");
        en_ver = 0;

        // Stop simulation
        #20
        
        $stop;
    end

endmodule
