## How it works

This is a complete 8-bit accumulator-based microcontroller SoC with:

- **35-instruction ISA**: arithmetic (ADD, SUB, INC, DEC, MUL, MULH), logic (AND, OR, XOR, NOT), shifts (SHL, SHR), memory (LDA, STA, LDM, ADDA, SUBA), branching (JMP, JZ, JNZ, JC), stack (PUSH, POP, CALL, RET), I/O (IN, OUT), peripherals (TSET, TGET, TCLR, UTXD, UTXS, UBRD), and control (NOP, HLT)
- **3/4-stage FSM pipeline**: FETCH, DECODE, [MEM_READ], EXECUTE. The MEM_READ stage is used for memory-to-ALU instructions (ADDA/SUBA) and stack reads (POP/RET)
- **128-word x 16-bit program ROM** with a hardcoded demo program
- **128-byte x 8-bit data RAM** (shared with hardware stack)
- **Hardware stack**: 7-bit stack pointer, grows downward from 0x7F, supports PUSH/POP/CALL/RET for subroutines
- **8x8 hardware multiplier**: combinational unsigned multiply with 16-bit result (MUL gets low byte, MULH gets high byte)
- **8-bit timer/counter**: free-running counter with programmable 8-bit prescaler
- **UART transmitter**: 8-N-1 serial output with programmable baud rate divisor
- **8-bit GPIO** with latched output and pass-through input

The demo program counts 1 to 5 on GPIO, calls a subroutine (demonstrating CALL/RET), performs a hardware multiply, sends 'H' over UART, reads the timer, then halts.

## How to test

1. Apply reset: hold `rst_n` low for at least 5 clock cycles
2. Release reset and assert `ena` (both high)
3. Observe `uo_out` pins counting: 1, 2, 3, 4, 5
4. After counting, the program demonstrates CALL/RET (GPIO shows 6), MUL (GPIO shows 21), UART TX, and timer read
5. `uio_out[0]` goes high when the CPU halts
6. `uio_out[1]` carries the UART TX serial output
7. Optionally connect switches to `ui_in` for GPIO input (used by the IN instruction)

## External hardware

- Connect 8 LEDs to `uo_out[7:0]` to visualize GPIO output
- Connect 1 LED to `uio_out[0]` to indicate CPU halt status
- Connect a USB-UART adapter RX to `uio_out[1]` for serial output (configure baud rate via UBRD instruction)
- Optionally connect a DIP switch or buttons to `ui_in[7:0]` for GPIO input
