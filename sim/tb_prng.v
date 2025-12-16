`timescale 1ns/1ps

module tb_prng;

    reg         clk;
    reg         rst;
    reg         start;
    wire [255:0] random_out;
    wire        valid;
    reg [31:0] seed;

    // Instantiate PRNG
    prng uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .inseed(seed),
        .random_out(random_out),
        .valid(valid)
    );

    // -------------------------
    // Clock generation
    // -------------------------
    always #5 clk = ~clk;   // 100 MHz clock (10 ns period)

    // -------------------------
    // Test sequence
    // -------------------------
    initial begin
        // Initialize
        clk   = 0;
        rst   = 1;
        start = 0;
        seed = 32'hA5A5_F00D;

        // Hold reset
        #20;
        rst = 0;

        // Start PRNG
        #10;
        start = 1;

        // Wait for valid output
        wait (valid == 1);

        // Display result
        $display("=================================================");
        $display("PRNG OUTPUT (256-bit):");
        $display("%h", random_out);
        $display("=================================================");

        // Stop simulation
        #20;
        $stop;
    end

endmodule
