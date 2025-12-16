module prng (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [31:0] inseed,
    output reg [255:0] random_out,
    output reg         valid
);

    wire [31:0] lfsr_out;
    reg  [2:0]  count;   // 0-7
    reg  [31:0] seed;

    lfsr u_lfsr (
        .clk(clk),
        .rst(rst),
        .seed(seed),
        .rnd(lfsr_out)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            random_out <= 256'd0;
            count      <= 3'd0;
            valid      <= 1'b0;
            seed       <= inseed;
        end else if (start) begin
            random_out <= {random_out[223:0], lfsr_out};
            count <= count + 1'b1;
            seed <= seed ^ count;

            if (count == 3'd7) begin
                valid <= 1'b1;   // 256 bits collected
                count <= 3'd0;   // optional: auto-reset
            end else begin
                valid <= 1'b0;
            end
        end else begin
            valid <= 1'b0;
        end
    end

endmodule
