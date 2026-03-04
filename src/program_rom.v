// ============================================================================
// Program ROM - 32 x 16-bit Instruction Memory
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
//   16 = PUSH         17 = POP          18 = CALL addr     19 = RET
//   1A = JC addr      1B = UTXD         1C = UTXS          1D = UBRD imm
//   1E = TSET imm     1F = TGET         20 = TCLR
// ============================================================================

module program_rom (
    input  wire [7:0]  addr,
    output wire [15:0] data
);

    reg [15:0] rom [0:31];

    assign data = rom[addr[4:0]];

    // ---- Demo Program: Showcase expanded microcontroller features ----
    //
    // Part 1 (addr 0x00-0x07): Count 1 to 5 on GPIO, then continue
    // Part 2 (addr 0x08-0x09): Subroutine call/return demo
    // Part 3 (addr 0x0A-0x0E): UART TX demo (send 'H')
    // Part 4 (addr 0x0F-0x14): Timer demo
    // Part 5 (addr 0x15-0x17): Final output and halt
    // Subroutine at addr 0x1C (28)

    initial begin : rom_init
        integer i;

        // Clear all ROM
        for (i = 0; i < 32; i = i + 1)
            rom[i] = 16'h0000;  // NOP

        // ---- Part 1: Count 1 to 5, output each ----
        rom[0]  = 16'h01_01;  // LDA  #1       ; acc = 1
        rom[1]  = 16'h08_00;  // STA  0x00     ; mem[0] = 1
        rom[2]  = 16'h0D_00;  // OUT           ; gpio_out = acc
        rom[3]  = 16'h12_00;  // INC           ; acc++
        rom[4]  = 16'h03_06;  // SUB  #6       ; acc - 6
        rom[5]  = 16'h0B_08;  // JZ   0x08     ; if zero, move to part 2
        rom[6]  = 16'h02_06;  // ADD  #6       ; restore acc
        rom[7]  = 16'h0A_02;  // JMP  0x02     ; loop

        // ---- Part 2: CALL/RET demo ----
        rom[8]  = 16'h18_1C;  // CALL 0x1C     ; call subroutine at addr 28
        rom[9]  = 16'h0D_00;  // OUT           ; gpio_out = result (6)

        // ---- Part 3: UART TX - send 'H' (0x48) ----
        rom[10] = 16'h1D_19;  // UBRD #25      ; set baud divider
        rom[11] = 16'h01_48;  // LDA  #0x48    ; 'H'
        rom[12] = 16'h1B_00;  // UTXD          ; start UART send
        rom[13] = 16'h1C_00;  // UTXS          ; read busy status
        rom[14] = 16'h0C_0D;  // JNZ  0x0D     ; wait until not busy

        // ---- Part 4: Timer demo ----
        rom[15] = 16'h1E_00;  // TSET #0       ; prescaler=0 (count every cycle)
        rom[16] = 16'h20_00;  // TCLR          ; clear timer counter
        rom[17] = 16'h00_00;  // NOP           ; let timer tick
        rom[18] = 16'h00_00;  // NOP           ; let timer tick more
        rom[19] = 16'h1F_00;  // TGET          ; acc = timer count
        rom[20] = 16'h0D_00;  // OUT           ; show timer value on GPIO

        // ---- Part 5: Final output and halt ----
        rom[21] = 16'h01_2A;  // LDA  #42      ; acc = 42 (final value)
        rom[22] = 16'h0D_00;  // OUT           ; gpio_out = 42
        rom[23] = 16'h0F_00;  // HLT           ; done!

        // ---- Subroutine at addr 0x1C (28): return 6 ----
        rom[28] = 16'h01_05;  // LDA  #5       ; acc = 5
        rom[29] = 16'h12_00;  // INC           ; acc = 6
        rom[30] = 16'h19_00;  // RET           ; return

        // ---- End of program ----
    end

endmodule
