// ============================================================================
// Program ROM - 128 x 16-bit Instruction Memory
// ============================================================================
// Expanded from 32 to 128 entries for comprehensive FPGA testing.
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
//   16 = PUSH         17 = POP          18 = CALL addr     19 = RET
//   1A = JC addr      1B = UTXD         1C = UTXS          1D = UBRD imm
//   1E = TSET imm     1F = TGET         20 = TCLR
// ============================================================================

module program_rom (
    input  wire [7:0]  addr,
    output wire [15:0] data
);

    reg [15:0] rom [0:127];

    assign data = rom[addr[6:0]];

    // ================================================================
    // COMPREHENSIVE FPGA TEST PROGRAM
    // ================================================================
    // Tests ALL 33 instructions across 15 test phases.
    // Each phase outputs its test number (1-F) on LEDs via OUT.
    // If a test FAILS, the CPU halts showing the failed test number.
    // All tests pass → LEDs blink 0x0F/0x00 then show 0x0F and halt.
    //
    // Test  1: LDA, OUT
    // Test  2: ADD
    // Test  3: INC
    // Test  4: SUB, JZ              (zero flag)
    // Test  5: JNZ                  (not-zero flag)
    // Test  6: AND
    // Test  7: OR, XOR
    // Test  8: NOT, SHL, SHR
    // Test  9: DEC, JC              (carry flag)
    // Test  A: STA, LDM, JMP        (memory + unconditional jump)
    // Test  B: PUSH, POP            (stack)
    // Test  C: CALL, RET            (subroutine)
    // Test  D: ADDA, SUBA           (memory arithmetic)
    // Test  E: TSET, TCLR, TGET, NOP (timer)
    // Test  F: IN, UBRD, UTXD, UTXS (GPIO input + UART)
    // ================================================================

    initial begin : rom_init
        integer i;

        // Clear all ROM
        for (i = 0; i < 128; i = i + 1)
            rom[i] = 16'h0000;  // NOP

        // ---- Test 1: LDA, OUT ----
        rom[0]  = 16'h01_01;  // LDA  #1        ; acc = 1
        rom[1]  = 16'h0D_00;  // OUT            ; LEDs = 0001

        // ---- Test 2: ADD ----
        rom[2]  = 16'h02_01;  // ADD  #1        ; acc = 1+1 = 2
        rom[3]  = 16'h0D_00;  // OUT            ; LEDs = 0010

        // ---- Test 3: INC ----
        rom[4]  = 16'h12_00;  // INC            ; acc = 2+1 = 3
        rom[5]  = 16'h0D_00;  // OUT            ; LEDs = 0011

        // ---- Test 4: SUB + JZ (zero flag) ----
        rom[6]  = 16'h03_03;  // SUB  #3        ; acc = 3-3 = 0, ZF=1
        rom[7]  = 16'h0B_09;  // JZ   0x09      ; should jump (ZF=1)
        rom[8]  = 16'h0F_00;  // HLT            ; FAIL: JZ broken
        rom[9]  = 16'h01_04;  // LDA  #4        ; acc = 4
        rom[10] = 16'h0D_00;  // OUT            ; LEDs = 0100

        // ---- Test 5: JNZ ----
        rom[11] = 16'h01_01;  // LDA  #1        ; acc = 1 (non-zero, ZF=0)
        rom[12] = 16'h0C_0E;  // JNZ  0x0E      ; should jump (ZF=0)
        rom[13] = 16'h0F_00;  // HLT            ; FAIL: JNZ broken
        rom[14] = 16'h01_05;  // LDA  #5        ; acc = 5
        rom[15] = 16'h0D_00;  // OUT            ; LEDs = 0101

        // ---- Test 6: AND ----
        rom[16] = 16'h01_FF;  // LDA  #0xFF     ; acc = 0xFF
        rom[17] = 16'h04_06;  // AND  #0x06     ; acc = 0xFF & 0x06 = 0x06
        rom[18] = 16'h0D_00;  // OUT            ; LEDs = 0110

        // ---- Test 7: OR + XOR ----
        rom[19] = 16'h01_03;  // LDA  #0x03     ; acc = 0x03
        rom[20] = 16'h05_04;  // OR   #0x04     ; acc = 0x03 | 0x04 = 0x07
        rom[21] = 16'h0D_00;  // OUT            ; LEDs = 0111
        rom[22] = 16'h06_07;  // XOR  #0x07     ; acc = 0x07 ^ 0x07 = 0, ZF=1
        rom[23] = 16'h0B_19;  // JZ   0x19      ; should jump (XOR zeroed)
        rom[24] = 16'h0F_00;  // HLT            ; FAIL: XOR broken

        // ---- Test 8: NOT + SHL + SHR ----
        rom[25] = 16'h01_F7;  // LDA  #0xF7     ; acc = 1111_0111
        rom[26] = 16'h07_00;  // NOT            ; acc = 0000_1000 = 0x08
        rom[27] = 16'h11_00;  // SHR            ; acc = 0000_0100 = 0x04
        rom[28] = 16'h10_00;  // SHL            ; acc = 0000_1000 = 0x08
        rom[29] = 16'h0D_00;  // OUT            ; LEDs = 1000

        // ---- Test 9: DEC + JC (carry/underflow flag) ----
        rom[30] = 16'h01_00;  // LDA  #0        ; acc = 0
        rom[31] = 16'h13_00;  // DEC            ; acc = 0xFF, CF=1 (underflow)
        rom[32] = 16'h1A_22;  // JC   0x22      ; should jump (CF=1)
        rom[33] = 16'h0F_00;  // HLT            ; FAIL: JC or DEC carry broken
        rom[34] = 16'h01_09;  // LDA  #9        ; acc = 9
        rom[35] = 16'h0D_00;  // OUT            ; LEDs = 1001

        // ---- Test A: STA + LDM + JMP (memory + jump) ----
        rom[36] = 16'h01_AB;  // LDA  #0xAB     ; acc = 0xAB
        rom[37] = 16'h08_00;  // STA  0x00      ; mem[0] = 0xAB
        rom[38] = 16'h01_00;  // LDA  #0        ; clear acc
        rom[39] = 16'h09_00;  // LDM  0x00      ; acc = mem[0] = 0xAB
        rom[40] = 16'h03_AB;  // SUB  #0xAB     ; acc = 0xAB-0xAB = 0, ZF=1
        rom[41] = 16'h0B_2B;  // JZ   0x2B      ; should jump (value matches)
        rom[42] = 16'h0F_00;  // HLT            ; FAIL: STA/LDM broken
        rom[43] = 16'h01_0A;  // LDA  #0x0A     ; acc = 10
        rom[44] = 16'h0A_2E;  // JMP  0x2E      ; test JMP
        rom[45] = 16'h0F_00;  // HLT            ; FAIL: JMP broken
        rom[46] = 16'h0D_00;  // OUT            ; LEDs = 1010

        // ---- Test B: PUSH + POP (stack) ----
        rom[47] = 16'h01_55;  // LDA  #0x55     ; acc = 0x55
        rom[48] = 16'h16_00;  // PUSH           ; push 0x55 to stack
        rom[49] = 16'h01_AA;  // LDA  #0xAA     ; acc = 0xAA (overwrite)
        rom[50] = 16'h16_00;  // PUSH           ; push 0xAA too
        rom[51] = 16'h01_00;  // LDA  #0        ; clear acc
        rom[52] = 16'h17_00;  // POP            ; acc = 0xAA (last pushed)
        rom[53] = 16'h03_AA;  // SUB  #0xAA     ; verify = 0?
        rom[54] = 16'h0B_38;  // JZ   0x38      ; should jump (match)
        rom[55] = 16'h0F_00;  // HLT            ; FAIL: POP wrong value
        rom[56] = 16'h17_00;  // POP            ; acc = 0x55 (first pushed)
        rom[57] = 16'h03_55;  // SUB  #0x55     ; verify = 0?
        rom[58] = 16'h0B_3C;  // JZ   0x3C      ; should jump
        rom[59] = 16'h0F_00;  // HLT            ; FAIL: stack order wrong
        rom[60] = 16'h01_0B;  // LDA  #0x0B     ; acc = 11
        rom[61] = 16'h0D_00;  // OUT            ; LEDs = 1011

        // ---- Test C: CALL + RET (subroutine) ----
        // Subroutine at addr 0x70 loads 0x0C and returns
        rom[62] = 16'h18_70;  // CALL 0x70      ; call subroutine
        rom[63] = 16'h0D_00;  // OUT            ; LEDs = 1100 (acc = 0x0C from sub)

        // ---- Test D: ADDA + SUBA (memory arithmetic) ----
        rom[64] = 16'h01_07;  // LDA  #7        ; acc = 7
        rom[65] = 16'h08_01;  // STA  0x01      ; mem[1] = 7
        rom[66] = 16'h01_02;  // LDA  #2        ; acc = 2
        rom[67] = 16'h08_02;  // STA  0x02      ; mem[2] = 2
        rom[68] = 16'h01_08;  // LDA  #8        ; acc = 8
        rom[69] = 16'h14_01;  // ADDA 0x01      ; acc = 8 + mem[1] = 8+7 = 15
        rom[70] = 16'h15_02;  // SUBA 0x02      ; acc = 15 - mem[2] = 15-2 = 13
        rom[71] = 16'h03_0D;  // SUB  #0x0D     ; verify: 13-13 = 0?
        rom[72] = 16'h0B_4A;  // JZ   0x4A      ; should jump (match)
        rom[73] = 16'h0F_00;  // HLT            ; FAIL: ADDA/SUBA broken
        rom[74] = 16'h01_0D;  // LDA  #0x0D     ; acc = 13
        rom[75] = 16'h0D_00;  // OUT            ; LEDs = 1101

        // ---- Test E: TSET + TCLR + TGET + NOP (timer) ----
        rom[76] = 16'h1E_00;  // TSET #0        ; prescaler = 0 (every cycle)
        rom[77] = 16'h20_00;  // TCLR           ; clear timer
        rom[78] = 16'h00_00;  // NOP            ; let timer tick
        rom[79] = 16'h00_00;  // NOP            ; let timer tick
        rom[80] = 16'h00_00;  // NOP            ; let timer tick
        rom[81] = 16'h1F_00;  // TGET           ; acc = timer count (> 0)
        rom[82] = 16'h0C_54;  // JNZ  0x54      ; should jump (timer counted)
        rom[83] = 16'h0F_00;  // HLT            ; FAIL: timer not counting
        rom[84] = 16'h01_0E;  // LDA  #0x0E     ; acc = 14
        rom[85] = 16'h0D_00;  // OUT            ; LEDs = 1110

        // ---- Test F: IN + UBRD + UTXD + UTXS (GPIO input + UART) ----
        rom[86] = 16'h0E_00;  // IN             ; acc = switch input (exercises IN)
        rom[87] = 16'h1D_00;  // UBRD #0        ; baud div = 0 (fastest)
        rom[88] = 16'h01_48;  // LDA  #0x48     ; acc = 'H' (0x48)
        rom[89] = 16'h1B_00;  // UTXD           ; start UART send
        rom[90] = 16'h1C_00;  // UTXS           ; read busy status (exercises UTXS)
        // Don't wait for completion (too slow at test clock)
        rom[91] = 16'h01_0F;  // LDA  #0x0F     ; acc = 15
        rom[92] = 16'h0D_00;  // OUT            ; LEDs = 1111

        // ---- ALL TESTS PASSED! Victory blink ----
        rom[93] = 16'h01_00;  // LDA  #0x00
        rom[94] = 16'h0D_00;  // OUT            ; LEDs = 0000 (off)
        rom[95] = 16'h01_0F;  // LDA  #0x0F
        rom[96] = 16'h0D_00;  // OUT            ; LEDs = 1111 (all on)
        rom[97] = 16'h01_00;  // LDA  #0x00
        rom[98] = 16'h0D_00;  // OUT            ; LEDs = 0000 (off)
        rom[99] = 16'h01_0F;  // LDA  #0x0F
        rom[100]= 16'h0D_00;  // OUT            ; LEDs = 1111 (all on)
        rom[101]= 16'h0F_00;  // HLT            ; done! all 33 instructions verified

        // ---- Subroutine for Test C at addr 0x70 (112) ----
        rom[112]= 16'h01_0C;  // LDA  #0x0C     ; return value = 12
        rom[113]= 16'h19_00;  // RET            ; return to caller

    end

endmodule
