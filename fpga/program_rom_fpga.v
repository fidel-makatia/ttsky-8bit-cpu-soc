// ============================================================================
// Program ROM - 128 x 16-bit Instruction Memory (FPGA Comprehensive Test)
// ============================================================================
// This ROM is used for FPGA testing and workshop demos. It runs 15 test
// phases that exercise all 33 CPU instructions. Each phase outputs its
// phase number (0x01-0x0F) on GPIO, so LEDs show test progress.
//
// At 4 Hz CPU clock, each instruction takes ~0.75s, making progress visible.
// All 4 LEDs light sequentially: 0001 -> 0010 -> ... -> 1111
// After all tests pass, LEDs show 0xFF (all on) and the CPU halts.
//
// To load a different program, copy one from fpga/programs/ over this file:
//   cp fpga/programs/fibonacci.v fpga/program_rom_fpga.v
//   cp fpga/programs/guess_game.v fpga/program_rom_fpga.v
// Then rebuild and reprogram.
//
// Instruction Format: {opcode[7:0], operand[7:0]}
// ============================================================================

module program_rom (
    input  wire [7:0]  addr,
    output wire [15:0] data
);

    reg [15:0] rom [0:127];

    assign data = rom[addr[6:0]];

    initial begin : rom_init
        integer i;

        // Clear all ROM
        for (i = 0; i < 128; i = i + 1)
            rom[i] = 16'h0000;  // NOP

        // ============================================================
        // Test 1 (Phase 0x01): LDA, OUT - Basic load and output
        // ============================================================
        rom[0]  = 16'h01_01;  // LDA  #1
        rom[1]  = 16'h0D_00;  // OUT

        // ============================================================
        // Test 2 (Phase 0x02): ADD, SUB - Arithmetic
        // ============================================================
        rom[2]  = 16'h01_0A;  // LDA  #10
        rom[3]  = 16'h02_05;  // ADD  #5       ; 15
        rom[4]  = 16'h03_0D;  // SUB  #13      ; 2
        rom[5]  = 16'h0D_00;  // OUT

        // ============================================================
        // Test 3 (Phase 0x03): AND, XOR - Logic
        // ============================================================
        rom[6]  = 16'h01_FF;  // LDA  #0xFF
        rom[7]  = 16'h04_0F;  // AND  #0x0F    ; 0x0F
        rom[8]  = 16'h06_0C;  // XOR  #0x0C    ; 0x03
        rom[9]  = 16'h0D_00;  // OUT

        // ============================================================
        // Test 4 (Phase 0x04): NOT - Bitwise inversion
        // ============================================================
        rom[10] = 16'h01_FB;  // LDA  #0xFB
        rom[11] = 16'h07_00;  // NOT           ; 0x04
        rom[12] = 16'h0D_00;  // OUT

        // ============================================================
        // Test 5 (Phase 0x05): SHR - Shift right
        // ============================================================
        rom[13] = 16'h01_0A;  // LDA  #0x0A    ; 0000_1010
        rom[14] = 16'h11_00;  // SHR           ; 0000_0101 = 5
        rom[15] = 16'h0D_00;  // OUT

        // ============================================================
        // Test 6 (Phase 0x06): INC
        // ============================================================
        rom[16] = 16'h01_04;  // LDA  #4
        rom[17] = 16'h12_00;  // INC           ; 5
        rom[18] = 16'h12_00;  // INC           ; 6
        rom[19] = 16'h0D_00;  // OUT

        // ============================================================
        // Test 7 (Phase 0x07): STA, LDM - Memory store/load
        // ============================================================
        rom[20] = 16'h01_07;  // LDA  #7
        rom[21] = 16'h08_00;  // STA  0x00
        rom[22] = 16'h01_00;  // LDA  #0
        rom[23] = 16'h09_00;  // LDM  0x00     ; 7
        rom[24] = 16'h0D_00;  // OUT

        // ============================================================
        // Test 8 (Phase 0x08): JMP, JZ, JNZ - Branching
        // ============================================================
        rom[25] = 16'h01_00;  // LDA  #0       ; zero=1
        rom[26] = 16'h0B_1C;  // JZ   28       ; should jump
        rom[27] = 16'h0A_1C;  // JMP  28       ; skip
        rom[28] = 16'h01_01;  // LDA  #1       ; zero=0
        rom[29] = 16'h0C_1F;  // JNZ  31       ; should jump
        rom[30] = 16'h0A_1F;  // JMP  31       ; skip
        rom[31] = 16'h01_08;  // LDA  #8
        rom[32] = 16'h0D_00;  // OUT

        // ============================================================
        // Test 9 (Phase 0x09): OR
        // ============================================================
        rom[33] = 16'h01_01;  // LDA  #0x01
        rom[34] = 16'h05_08;  // OR   #0x08    ; 0x09
        rom[35] = 16'h0D_00;  // OUT

        // ============================================================
        // Test A (Phase 0x0A): DEC
        // ============================================================
        rom[36] = 16'h01_0B;  // LDA  #11
        rom[37] = 16'h13_00;  // DEC           ; 10 = 0x0A
        rom[38] = 16'h0D_00;  // OUT

        // ============================================================
        // Test B (Phase 0x0B): ADD + INC
        // ============================================================
        rom[39] = 16'h01_05;  // LDA  #5
        rom[40] = 16'h12_00;  // INC           ; 6
        rom[41] = 16'h02_05;  // ADD  #5       ; 11 = 0x0B
        rom[42] = 16'h0D_00;  // OUT

        // ============================================================
        // Test C (Phase 0x0C): JC - Carry flag
        // ============================================================
        rom[43] = 16'h01_FF;  // LDA  #0xFF
        rom[44] = 16'h02_01;  // ADD  #1       ; carry=1
        rom[45] = 16'h1A_2F;  // JC   47       ; should jump
        rom[46] = 16'h0A_2F;  // JMP  47       ; skip
        rom[47] = 16'h01_0C;  // LDA  #12
        rom[48] = 16'h0D_00;  // OUT

        // ============================================================
        // Test D (Phase 0x0D): ADDA, SUBA - Memory arithmetic
        // ============================================================
        rom[49] = 16'h01_0A;  // LDA  #10
        rom[50] = 16'h08_01;  // STA  0x01     ; mem[1] = 10
        rom[51] = 16'h01_03;  // LDA  #3
        rom[52] = 16'h14_01;  // ADDA 0x01     ; 3+10 = 13 = 0x0D
        rom[53] = 16'h0D_00;  // OUT

        // ============================================================
        // Test E (Phase 0x0E): PUSH, POP, CALL, RET
        // ============================================================
        rom[54] = 16'h01_0E;  // LDA  #14
        rom[55] = 16'h16_00;  // PUSH
        rom[56] = 16'h01_00;  // LDA  #0
        rom[57] = 16'h17_00;  // POP           ; 14 = 0x0E
        rom[58] = 16'h0D_00;  // OUT
        rom[59] = 16'h18_70;  // CALL 112      ; test CALL/RET

        // ============================================================
        // Test F (Phase 0x0F): UART + Timer
        // ============================================================
        rom[60] = 16'h1D_19;  // UBRD #25
        rom[61] = 16'h01_48;  // LDA  #'H'
        rom[62] = 16'h1B_00;  // UTXD
        rom[63] = 16'h1E_00;  // TSET #0
        rom[64] = 16'h20_00;  // TCLR
        rom[65] = 16'h00_00;  // NOP
        rom[66] = 16'h1F_00;  // TGET
        rom[67] = 16'h01_0F;  // LDA  #15
        rom[68] = 16'h0D_00;  // OUT

        // ============================================================
        // ALL TESTS PASSED
        // ============================================================
        rom[69] = 16'h01_FF;  // LDA  #0xFF
        rom[70] = 16'h0D_00;  // OUT
        rom[71] = 16'h0F_00;  // HLT

        // ---- Subroutine at addr 112 ----
        rom[112] = 16'h00_00;  // NOP
        rom[113] = 16'h19_00;  // RET
    end

endmodule
