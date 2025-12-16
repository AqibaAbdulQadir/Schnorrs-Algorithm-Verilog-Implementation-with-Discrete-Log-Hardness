module lfsr (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] seed,
    output reg  [31:0] rnd
);

    wire feedback;
    assign feedback = rnd[31] ^ rnd[21] ^ rnd[1] ^ rnd[0];

    always @(posedge clk or posedge rst) begin
        if (rst)
            rnd <= seed;
        else
            rnd <= {rnd[30:0], feedback};
    end

endmodule
