// ============================================================================
// Program ROM - 32 x 16-bit Instruction Memory (reduced for TinyTapeout)
// ============================================================================
// This module is STUDENT-MODIFIABLE.
// Students can change the program by editing the initialization below.
//
// Instruction Format: {opcode[7:0], operand[7:0]}
//
// Opcode Quick Reference:
//   00 = NOP          01 = LDA imm      02 = ADD imm      03 = SUB imm
//   04 = AND imm      05 = OR  imm      06 = XOR imm      07 = NOT
//   08 = STA addr     09 = LDM addr     0A = JMP addr     0B = JZ  addr
//   0C = JNZ addr     0D = OUT          0E = IN            0F = HLT
//   10 = SHL          11 = SHR          12 = INC           13 = DEC
//   14 = ADDA addr    15 = SUBA addr
// ============================================================================

module program_rom (
    input  wire [7:0]  addr,
    output wire [15:0] data
);

    reg [15:0] rom [0:31];

    assign data = rom[addr[4:0]];

    // ---- Demo Program: Count 1 to 5, output each, then halt ----
    // This program demonstrates: LDA, OUT, INC, SUB, JNZ, HLT
    //
    // Assembly:
    //   0x00: LDA  1        ; acc = 1
    //   0x01: STA  0x00     ; store to mem[0] (unused, demo of STA)
    //   0x02: OUT           ; output acc to GPIO
    //   0x03: INC           ; acc = acc + 1
    //   0x04: SUB  6        ; acc = acc - 6 (check if acc > 5)
    //   0x05: JZ   0x08     ; if zero (acc was 6), jump to halt
    //   0x06: ADD  6        ; restore acc (undo the subtract)
    //   0x07: JMP  0x02     ; loop back to output
    //   0x08: HLT           ; done!

    initial begin : rom_init
        integer i;

        // Clear all ROM
        for (i = 0; i < 32; i = i + 1)
            rom[i] = 16'h0000;  // NOP

        // ---- Program starts here ----
        rom[0]  = 16'h01_01;  // LDA  #1       ; acc = 1
        rom[1]  = 16'h08_00;  // STA  0x00     ; mem[0] = 1 (store for later)
        rom[2]  = 16'h0D_00;  // OUT           ; gpio_out = acc
        rom[3]  = 16'h12_00;  // INC           ; acc = acc + 1
        rom[4]  = 16'h03_06;  // SUB  #6       ; acc = acc - 6
        rom[5]  = 16'h0B_08;  // JZ   0x08     ; if acc==0 (was 6), halt
        rom[6]  = 16'h02_06;  // ADD  #6       ; restore acc
        rom[7]  = 16'h0A_02;  // JMP  0x02     ; loop
        rom[8]  = 16'h0F_00;  // HLT           ; stop

        // ---- End of program ----
    end

endmodule
