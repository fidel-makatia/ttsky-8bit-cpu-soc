// ============================================================================
// Register File / Data RAM - 32 x 8-bit
// ============================================================================
// Simple single-port synchronous RAM used as data memory.
// Upper region (0x10-0x1F) also used as hardware stack.
// ============================================================================

module regfile (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        we,        // Write enable
    input  wire [7:0]  addr,      // Address
    input  wire [7:0]  wdata,     // Write data
    output wire [7:0]  rdata      // Read data (combinational)
);

    // 32 bytes of data memory
    reg [7:0] mem [0:31];

    integer i;

    // Combinational read (data available same cycle as address change)
    assign rdata = mem[addr[4:0]];

    // Synchronous write with async reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                mem[i] <= 8'h00;
            end
        end else if (we) begin
            mem[addr[4:0]] <= wdata;
        end
    end

endmodule
