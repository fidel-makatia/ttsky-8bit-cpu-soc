// ============================================================================
// Register File / Data RAM - 128 x 8-bit
// ============================================================================
// Simple single-port synchronous RAM used as data memory.
// Upper region (0x40-0x7F) also used as hardware stack.
// ============================================================================

module regfile (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        we,        // Write enable
    input  wire [7:0]  addr,      // Address
    input  wire [7:0]  wdata,     // Write data
    output reg  [7:0]  rdata      // Read data
);

    // 128 bytes of data memory
    reg [7:0] mem [0:127];

    integer i;

    // Synchronous read and write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata <= 8'h00;
            for (i = 0; i < 128; i = i + 1) begin
                mem[i] <= 8'h00;
            end
        end else begin
            if (we) begin
                mem[addr[6:0]] <= wdata;
            end
            rdata <= mem[addr[6:0]];
        end
    end

endmodule
