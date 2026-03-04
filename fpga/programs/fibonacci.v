// ============================================================================
// Program ROM - Fibonacci Sequence on LEDs
// ============================================================================
// Computes Fibonacci numbers and outputs each to GPIO.
// At 4 Hz CPU clock, each number is visible for ~3 seconds on LEDs.
//
// Sequence (8-bit): 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, ...
// After 233 it wraps (8-bit overflow) and keeps going forever.
//
// LED3-LED0 show gpio_out[3:0] (lower nibble)
// PMOD JA pins 1-4 show gpio_out[7:4] (upper nibble)
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
            rom[i] = 16'h0000;  // NOP

        // ---- Initialize: prev=0, curr=1 ----
        rom[0]  = 16'h01_00;  // LDA  #0       ; acc = 0
        rom[1]  = 16'h08_00;  // STA  0x00     ; mem[0] = 0 (prev)
        rom[2]  = 16'h01_01;  // LDA  #1       ; acc = 1
        rom[3]  = 16'h08_01;  // STA  0x01     ; mem[1] = 1 (curr)

        // ---- Loop: display curr, compute next ----
        rom[4]  = 16'h09_01;  // LDM  0x01     ; acc = curr
        rom[5]  = 16'h0D_00;  // OUT           ; display on LEDs
        rom[6]  = 16'h14_00;  // ADDA 0x00     ; acc = curr + prev = next
        rom[7]  = 16'h08_02;  // STA  0x02     ; mem[2] = next (temp)
        rom[8]  = 16'h09_01;  // LDM  0x01     ; acc = curr
        rom[9]  = 16'h08_00;  // STA  0x00     ; mem[0] = curr (becomes prev)
        rom[10] = 16'h09_02;  // LDM  0x02     ; acc = next
        rom[11] = 16'h08_01;  // STA  0x01     ; mem[1] = next (becomes curr)
        rom[12] = 16'h0A_04;  // JMP  0x04     ; loop forever
    end

endmodule
