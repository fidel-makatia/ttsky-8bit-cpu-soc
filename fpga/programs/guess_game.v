// ============================================================================
// Program ROM - "Guess the Number" Game
// ============================================================================
// An 8-bit guessing game using 4 switches and 4 LEDs.
//
// How to play:
//   1. On reset (BTN0), LEDs flash 1001 = "Ready"
//   2. Set all switches DOWN (off), LEDs show 0110 = "Go!"
//   3. Flip ANY switch to start the round (this seeds the random number)
//   4. LEDs go dark — a secret number (1-15) has been picked
//   5. Set switches SW3-SW0 to your guess (binary 0001-1111)
//   6. Hints appear on LEDs:
//        LED3 only (1000) = too HIGH
//        LED0 only (0001) = too LOW
//   7. Adjust switches and wait for next hint (~6 seconds per check)
//   8. Correct guess: LEDs flash! Then show your score (wins count)
//   9. Game resets to step 1 for next round
//
// Memory map:
//   mem[0] = target number (1-15)
//   mem[1] = score (wins count)
//
// At 4 Hz, each game loop iteration takes ~6 seconds.
// The timer free-runs as a randomness source — seeded by player timing.
// ============================================================================

module program_rom (
    input  wire [7:0]  addr,
    output wire [15:0] data
);

    reg [15:0] rom [0:127];

    assign data = rom[addr[6:0]];

    initial begin : rom_init
        integer i;

        for (i = 0; i < 128; i = i + 1)
            rom[i] = 16'h0000;

        // ---- Setup (addr 0-3) ----
        rom[0]  = 16'h1E_00;  // TSET #0       ; timer at max speed
        rom[1]  = 16'h20_00;  // TCLR          ; start counting
        rom[2]  = 16'h01_00;  // LDA  #0
        rom[3]  = 16'h08_01;  // STA  0x01     ; score = 0

        // ---- New Round: show "ready" (addr 4-5) ----
        rom[4]  = 16'h01_09;  // LDA  #0x09    ; 1001 = "ready"
        rom[5]  = 16'h0D_00;  // OUT

        // ---- Wait for all switches OFF (addr 6-8) ----
        rom[6]  = 16'h0E_00;  // IN
        rom[7]  = 16'h04_0F;  // AND  #0x0F
        rom[8]  = 16'h0C_06;  // JNZ  6        ; loop until all off

        // ---- Show "go!" (addr 9-10) ----
        rom[9]  = 16'h01_06;  // LDA  #0x06    ; 0110 = "go!"
        rom[10] = 16'h0D_00;  // OUT

        // ---- Wait for ANY switch ON (addr 11-13) ----
        rom[11] = 16'h0E_00;  // IN
        rom[12] = 16'h04_0F;  // AND  #0x0F
        rom[13] = 16'h0B_0B;  // JZ   11       ; loop until any on

        // ---- Pick random target (addr 14-17) ----
        rom[14] = 16'h1F_00;  // TGET          ; acc = timer (random)
        rom[15] = 16'h04_0F;  // AND  #0x0F    ; 4-bit: 0-15
        rom[16] = 16'h0B_0E;  // JZ   14       ; no zeros, try again
        rom[17] = 16'h08_00;  // STA  0x00     ; mem[0] = target

        // ---- LEDs off: guessing starts (addr 18-19) ----
        rom[18] = 16'h01_00;  // LDA  #0
        rom[19] = 16'h0D_00;  // OUT           ; LEDs dark

        // ---- Game Loop (addr 20-27) ----
        rom[20] = 16'h0E_00;  // IN            ; read switches
        rom[21] = 16'h04_0F;  // AND  #0x0F    ; mask to 4 bits
        rom[22] = 16'h15_00;  // SUBA 0x00     ; acc = guess - target
        rom[23] = 16'h0B_40;  // JZ   64       ; WIN!
        rom[24] = 16'h1A_30;  // JC   48       ; too low

        // ---- Too HIGH (addr 25-27) ----
        rom[25] = 16'h01_08;  // LDA  #0x08    ; 1000
        rom[26] = 16'h0D_00;  // OUT
        rom[27] = 16'h0A_14;  // JMP  20       ; check again

        // ---- Too LOW (addr 48 = 0x30) ----
        rom[48] = 16'h01_01;  // LDA  #0x01    ; 0001
        rom[49] = 16'h0D_00;  // OUT
        rom[50] = 16'h0A_14;  // JMP  20       ; check again

        // ---- WIN! (addr 64 = 0x40) ----
        // Flash celebration
        rom[64] = 16'h01_0F;  // LDA  #0x0F    ; all on
        rom[65] = 16'h0D_00;  // OUT
        rom[66] = 16'h01_00;  // LDA  #0x00    ; all off
        rom[67] = 16'h0D_00;  // OUT
        rom[68] = 16'h01_0F;  // LDA  #0x0F    ; all on
        rom[69] = 16'h0D_00;  // OUT
        rom[70] = 16'h01_00;  // LDA  #0x00    ; all off
        rom[71] = 16'h0D_00;  // OUT
        rom[72] = 16'h01_0F;  // LDA  #0x0F    ; all on
        rom[73] = 16'h0D_00;  // OUT

        // Increment score
        rom[74] = 16'h09_01;  // LDM  0x01     ; acc = score
        rom[75] = 16'h12_00;  // INC           ; score++
        rom[76] = 16'h08_01;  // STA  0x01     ; save score
        rom[77] = 16'h0D_00;  // OUT           ; show score on LEDs

        // Pause (NOPs so player can see score)
        rom[78] = 16'h00_00;  // NOP
        rom[79] = 16'h00_00;  // NOP
        rom[80] = 16'h00_00;  // NOP
        rom[81] = 16'h00_00;  // NOP

        // Next round
        rom[82] = 16'h0A_04;  // JMP  4        ; new round
    end

endmodule
