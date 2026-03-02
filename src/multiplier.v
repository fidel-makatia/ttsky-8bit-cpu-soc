// ============================================================================
// Multiplier Module - 8x8 Combinational Hardware Multiplier
// ============================================================================
// Produces a 16-bit product from two 8-bit unsigned operands.
// Result is available combinationally (no clock needed).
// ============================================================================

module multiplier (
    input  wire [7:0]  a,        // Operand A
    input  wire [7:0]  b,        // Operand B
    output wire [15:0] product   // 16-bit unsigned product
);

    assign product = a * b;

endmodule
