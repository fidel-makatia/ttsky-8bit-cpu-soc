// ============================================================================
// Register File / Data RAM - 32 x 8-bit (reduced for TinyTapeout)
// ============================================================================
// Simple single-port synchronous RAM used as data memory.
// ============================================================================

module regfile (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        we,        // Write enable
    input  wire [7:0]  addr,      // Address
    input  wire [7:0]  wdata,     // Write data
    output reg  [7:0]  rdata      // Read data
);

    // 32 bytes of data memory
    reg [7:0] mem [0:31];

    integer i;

    // Synchronous read and write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata <= 8'h00;
            for (i = 0; i < 32; i = i + 1) begin
                mem[i] <= 8'h00;
            end
        end else begin
            if (we) begin
                mem[addr[4:0]] <= wdata;
            end
            rdata <= mem[addr[4:0]];
        end
    end

endmodule
