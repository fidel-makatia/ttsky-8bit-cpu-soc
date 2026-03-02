## How it works

This is a complete 8-bit accumulator-based microcontroller SoC with:

- **21-instruction ISA**: arithmetic (ADD, SUB, INC, DEC), logic (AND, OR, XOR, NOT), shifts (SHL, SHR), memory (LDA, STA, LDM, ADDA, SUBA), branching (JMP, JZ, JNZ), I/O (IN, OUT), and control (NOP, HLT)
- **3/4-stage FSM pipeline**: FETCH, DECODE, [MEM_READ], EXECUTE. The MEM_READ stage is only used for memory-to-ALU instructions (ADDA/SUBA)
- **32-word x 16-bit program ROM** with a hardcoded demo program (count 1 to 5)
- **32-byte x 8-bit data RAM** (register file)
- **8-bit GPIO** with latched output and pass-through input

The demo program loads the value 1 into the accumulator, outputs it to GPIO, increments, and loops until the value exceeds 5, then halts.

## How to test

1. Apply reset: hold `rst_n` low for at least 5 clock cycles
2. Release reset and assert `ena` (both high)
3. Observe `uo_out` pins counting: 1, 2, 3, 4, 5
4. `uio_out[0]` goes high when the CPU halts after outputting 5
5. Optionally connect switches to `ui_in` for GPIO input (used by the IN instruction)

## External hardware

- Connect 8 LEDs to `uo_out[7:0]` to visualize the count-to-5 pattern
- Connect 1 LED to `uio_out[0]` to indicate CPU halt status
- Optionally connect a DIP switch or buttons to `ui_in[7:0]` for GPIO input
