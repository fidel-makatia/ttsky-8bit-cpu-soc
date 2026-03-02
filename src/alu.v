// ============================================================================
// ALU Module - 8-bit Arithmetic Logic Unit
// ============================================================================
// This module is STUDENT-MODIFIABLE.
// You may add new operations or change existing behavior.
//
// ALU Operations (alu_op encoding):
//   4'h0 : NOP  - Pass through A unchanged
//   4'h1 : ADD  - A + B
//   4'h2 : SUB  - A - B
//   4'h3 : AND  - A & B
//   4'h4 : OR   - A | B
//   4'h5 : XOR  - A ^ B
//   4'h6 : NOT  - ~A
//   4'h7 : SHL  - A << 1 (shift left)
//   4'h8 : SHR  - A >> 1 (shift right)
//   4'h9 : INC  - A + 1
//   4'hA : DEC  - A - 1
//   default: Pass through A
// ============================================================================

module alu (
    input  wire [7:0] a,          // Operand A (accumulator value)
    input  wire [7:0] b,          // Operand B (immediate or memory data)
    input  wire [3:0] alu_op,     // ALU operation select
    output reg  [7:0] result,     // ALU result
    output wire       zero_flag,  // Result is zero
    output wire       carry_flag  // Carry/borrow out
);

    // Internal 9-bit result for carry detection
    reg [8:0] result_wide;

    always @(*) begin
        result_wide = 9'd0;
        case (alu_op)
            4'h0: result_wide = {1'b0, a};           // NOP / pass-through
            4'h1: result_wide = {1'b0, a} + {1'b0, b}; // ADD
            4'h2: result_wide = {1'b0, a} - {1'b0, b}; // SUB
            4'h3: result_wide = {1'b0, a & b};        // AND
            4'h4: result_wide = {1'b0, a | b};        // OR
            4'h5: result_wide = {1'b0, a ^ b};        // XOR
            4'h6: result_wide = {1'b0, ~a};           // NOT
            4'h7: result_wide = {a[7], a[6:0], 1'b0}; // SHL (carry = MSB)
            4'h8: result_wide = {a[0], 1'b0, a[7:1]}; // SHR (carry = LSB)
            4'h9: result_wide = {1'b0, a} + 9'd1;    // INC
            4'hA: result_wide = {1'b0, a} - 9'd1;    // DEC
            default: result_wide = {1'b0, a};         // Default: pass-through
        endcase
        result = result_wide[7:0];
    end

    assign zero_flag  = (result == 8'h00);
    assign carry_flag = result_wide[8];

endmodule
