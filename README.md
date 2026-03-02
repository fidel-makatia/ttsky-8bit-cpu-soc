![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# TTSky 8-bit CPU SoC

A complete 8-bit microcontroller **fabricated on a real silicon chip** through the [TinyTapeout](https://tinytapeout.com) SKY26a shuttle using the SkyWater SKY130 130nm process. This is not a simulation or an FPGA -- this design gets manufactured into actual silicon at a real foundry.

**Shuttle:** SKY26a | **Process:** SkyWater SKY130 (130nm) | **Tile size:** 1x2 | **Utilization:** 76.7% | **Clock:** 5 MHz

---

## What Is This?

This is a **System-on-Chip (SoC)** -- an entire computer built as a single chip. It contains everything a simple computer needs: a processor that executes instructions, memory to store programs and data, input/output pins to talk to the outside world, a serial port (UART) for communication, and a hardware timer for measuring time.

Think of it like a tiny Arduino -- except instead of buying a premade chip, we designed the processor itself from scratch in Verilog (a hardware description language) and sent it to a factory to be etched into silicon.

The CPU uses an **accumulator architecture**. This means there is one main register called the **accumulator (ACC)** that is involved in almost every operation. When you want to add two numbers, you load the first number into the accumulator, then add the second number to it -- the result stays in the accumulator. This is the simplest style of CPU to build, and it's how many early microprocessors (like the Intel 8080 and MOS 6502) worked.

---

## Architecture

Here's what's inside the chip and how the pieces connect:

```
                    +----------------------------------------------------+
                    |                    soc_top                          |
                    |                                                    |
  ui_in[7:0] ----->|   +-----------+       +-------+     +----------+   |
  (switches/       |   |  Program  | instr |       | r/w |  Data    |   |
   buttons)        |   |    ROM    |------>|  CPU  |<--->|   RAM    |   |
                   |   | (32 x 16) |       |  FSM  |     | (32 x 8) |   |
                   |   +-----------+       |       |     +----------+   |
                   |                       |       |                    |
  uo_out[7:0] <----|   +-----------+       |       |     +----------+   |
  (LEDs)           |   |   GPIO    |<----->|       |<--->|   ALU    |   |
                   |   +-----------+       |       |     | (8-bit)  |   |
                   |                       |       |     +----------+   |
  uio_out[0] <----|   (halt flag) <-------|       |                    |
                   |                       |       |     +----------+   |
  uio_out[1] <----|   +-----------+       |       |<--->|  Timer   |   |
  (serial out)     |   |  UART TX  |<------|       |     | Counter  |   |
                   |   +-----------+       +-------+     +----------+   |
                    +----------------------------------------------------+
```

### How the Blocks Work Together

When you release the reset pin, the CPU starts fetching instructions from the Program ROM starting at address 0. Each instruction tells the CPU what to do: load a number, do math, jump to a different instruction, send data out a pin, etc. The CPU reads one instruction at a time, figures out what it means, does the work, then moves on to the next instruction. This fetch-decode-execute cycle repeats until the CPU hits a `HLT` (halt) instruction.

Below is what each block does and why it exists.

### Program ROM -- "The Instruction Book"

**File:** `src/program_rom.v` | **Size:** 32 words x 16 bits

This is where the program lives. It's read-only memory (ROM) that is hardcoded into the chip at fabrication time. Each of the 32 memory locations holds one 16-bit instruction. The upper 8 bits are the **opcode** (what to do) and the lower 8 bits are the **operand** (what to do it with -- a number, an address, etc.).

You write programs by editing the initialization values in `program_rom.v` before synthesis. With 32 instruction slots, you can write small but complete programs including loops, subroutines, and I/O.

### CPU Control Unit (FSM) -- "The Brain"

**File:** `src/control.v` | **Instructions:** 33

This is the heart of the processor. It is a **Finite State Machine (FSM)** that steps through a cycle for each instruction:

1. **FETCH** -- Read the instruction from ROM at the current Program Counter (PC) address
2. **DECODE** -- Look at the opcode, set up the ALU, memory, or peripherals for the operation
3. **MEM_READ** -- *(only for some instructions)* Wait one cycle for data memory to produce its output
4. **EXECUTE** -- Latch the result into the accumulator, update flags, advance the PC

Most instructions take **3 clock cycles** (fetch-decode-execute). Instructions that need to read from RAM first (like `ADDA`, `POP`, `RET`) take **4 cycles** because of the extra memory read stage.

The control unit also manages:
- The **accumulator (ACC)** -- the main 8-bit working register
- The **program counter (PC)** -- which instruction to fetch next
- The **stack pointer (SP)** -- tracks the top of the hardware stack (for subroutines)
- The **zero flag (ZF)** and **carry flag (CF)** -- set by ALU operations, used for conditional branching

### ALU -- "The Calculator"

**File:** `src/alu.v` | **Operations:** 11

The Arithmetic Logic Unit does all the math and logic. It takes two 8-bit inputs (A and B), performs an operation, and produces an 8-bit result plus two status flags:

- **Zero flag** -- set to 1 if the result is exactly zero
- **Carry flag** -- set to 1 if the result overflowed past 255 (for addition) or underflowed below 0 (for subtraction)

The ALU is **purely combinational** -- it has no clock, no memory, no state. It's just a bunch of logic gates that instantly produce an output whenever the inputs change. The CPU control unit feeds it numbers and reads back the result.

Supported operations: pass-through, add, subtract, AND, OR, XOR, NOT, shift left, shift right, increment, decrement.

### Data RAM -- "The Scratchpad"

**File:** `src/regfile.v` | **Size:** 32 bytes x 8 bits

This is the read/write data memory. Programs use it to store variables, intermediate results, and anything they need to remember. It's also shared with the hardware stack -- the upper half (addresses 0x10-0x1F) is reserved for the stack, while the lower half (0x00-0x0F) is available for general use.

The RAM is **synchronous** -- reads and writes happen on the rising edge of the clock, which is why memory-read instructions need that extra MEM_READ cycle.

### Hardware Stack -- "The Return Address Notepad"

The stack is a region of RAM (addresses 0x10 through 0x1F) managed by a **5-bit stack pointer (SP)** that starts at 0x1F (the top) and grows downward. It enables two important capabilities:

- **PUSH/POP** -- Save the accumulator to the stack and restore it later. Useful for temporarily saving a value while you do other work.
- **CALL/RET** -- Call a subroutine (function). `CALL` saves the return address on the stack and jumps to the subroutine. `RET` pops that address and jumps back. This lets you write reusable pieces of code.

With 16 bytes of stack space, you can nest subroutine calls up to 16 levels deep (in practice you'll use some stack for PUSH/POP too, so the effective depth depends on your program).

### GPIO -- "The LED & Switch Interface"

**File:** `src/gpio.v`

GPIO (General-Purpose Input/Output) is how the CPU talks to the physical world. It has two 8-bit ports:

- **Output (`uo_out[7:0]`)** -- Connect LEDs here. When the program executes `OUT`, the accumulator value appears on these 8 pins. The value is **latched** -- it stays there until the next `OUT`.
- **Input (`ui_in[7:0]`)** -- Connect switches or buttons here. When the program executes `IN`, whatever logic levels are on these pins get copied into the accumulator.

### UART Transmitter -- "The Serial Port"

**File:** `src/uart_tx.v`

UART (Universal Asynchronous Receiver/Transmitter) is a standard serial communication protocol used by almost every microcontroller. This design includes a **transmit-only** UART that can send data one byte at a time over a single wire.

The format is **8-N-1**: 8 data bits, no parity, 1 stop bit. The protocol works like this:

```
Idle (high) ──┐    ┌──┬──┬──┬──┬──┬──┬──┬──┬──┐
              └────┤D0│D1│D2│D3│D4│D5│D6│D7│ST├── Idle (high)
              Start                           Stop
              bit                             bit
```

The baud rate (transmission speed) is programmable. The CPU sets a divisor value with the `UBRD` instruction:

```
baud_rate = clock_frequency / (16 x (divisor + 1))
```

At the default 5 MHz clock, a divisor of 25 gives roughly 12,000 baud, and a divisor of 32 gives roughly 9,600 baud.

Three instructions control the UART:
- `UBRD #divisor` -- Set the baud rate
- `UTXD` -- Send the byte currently in the accumulator
- `UTXS` -- Check if the transmitter is still busy (ACC becomes 1 if busy, 0 if done)

To send a byte, you typically set the baud rate once, load your data, call `UTXD`, then loop on `UTXS` until it reports not-busy.

### Timer/Counter -- "The Stopwatch"

**File:** `src/timer.v`

The timer is a free-running 8-bit counter that increments automatically based on the system clock. It has a **programmable prescaler** that controls how fast it counts:

```
count_frequency = clock_frequency / (prescaler + 1)
```

With prescaler = 0, the timer counts at the full clock speed (every cycle). With prescaler = 255, it counts roughly every 256 clock cycles. The count value wraps around from 255 back to 0.

Three instructions control the timer:
- `TSET #prescaler` -- Set the prescaler (controls counting speed)
- `TCLR` -- Reset the count to zero
- `TGET` -- Read the current count value into the accumulator

This is useful for creating time delays, measuring intervals, or generating periodic events in software.

---

## The Programmer's Model

This is the complete set of resources available to a programmer:

```
  +-----------+
  | ACC [7:0] |  Accumulator -- main working register, used by almost every instruction
  +-----------+
  | PC  [7:0] |  Program Counter -- address of the next instruction to fetch (0-31)
  +-----------+
  | SP  [4:0] |  Stack Pointer -- points to top of stack, starts at 0x1F, grows downward
  +-----------+
  | ZF        |  Zero Flag -- 1 if the last ALU result was zero
  +-----------+
  | CF        |  Carry Flag -- 1 if the last ALU result overflowed/underflowed
  +-----------+

  Memory Map:
  +-----------------+------------------+
  | Program ROM     | 0x00-0x1F        |  32 words x 16 bits (read-only instructions)
  +-----------------+------------------+
  | Data RAM        | 0x00-0x0F        |  16 bytes general-purpose storage
  |                 | 0x10-0x1F        |  16 bytes hardware stack (SP starts at 0x1F)
  +-----------------+------------------+
```

---

## Instruction Set Architecture (ISA)

The CPU understands 33 instructions. Each is encoded as a 16-bit word:

```
  15       8 7        0
  +--------+----------+
  | opcode | operand  |
  +--------+----------+
     what      with what
   to do     (number or address)
```

### Arithmetic Instructions

These perform math on the accumulator. All update the Zero and Carry flags.

| Hex | Mnemonic | What it does |
|-----|----------|-------------|
| `0x02` | `ADD imm` | Add a number to the accumulator: `ACC = ACC + imm` |
| `0x03` | `SUB imm` | Subtract a number from the accumulator: `ACC = ACC - imm` |
| `0x12` | `INC` | Add 1 to the accumulator: `ACC = ACC + 1` |
| `0x13` | `DEC` | Subtract 1 from the accumulator: `ACC = ACC - 1` |
| `0x14` | `ADDA addr` | Add a value from RAM to the accumulator: `ACC = ACC + mem[addr]` |
| `0x15` | `SUBA addr` | Subtract a value from RAM from the accumulator: `ACC = ACC - mem[addr]` |

### Logic Instructions

Bitwise logic operations on the accumulator.

| Hex | Mnemonic | What it does |
|-----|----------|-------------|
| `0x04` | `AND imm` | Bitwise AND: `ACC = ACC & imm` (keeps only bits that are 1 in both) |
| `0x05` | `OR imm` | Bitwise OR: `ACC = ACC \| imm` (sets bits that are 1 in either) |
| `0x06` | `XOR imm` | Bitwise XOR: `ACC = ACC ^ imm` (flips bits that differ) |
| `0x07` | `NOT` | Bitwise NOT: `ACC = ~ACC` (flips every bit) |

### Shift Instructions

Shift all bits in the accumulator left or right by one position. The bit that "falls off" the end goes into the Carry flag.

| Hex | Mnemonic | What it does |
|-----|----------|-------------|
| `0x10` | `SHL` | Shift left: each bit moves one position left, 0 fills the right, MSB goes to Carry |
| `0x11` | `SHR` | Shift right: each bit moves one position right, 0 fills the left, LSB goes to Carry |

### Load & Store Instructions

Move data between the accumulator, immediate values, and RAM.

| Hex | Mnemonic | What it does |
|-----|----------|-------------|
| `0x01` | `LDA imm` | Load an immediate (constant) value into the accumulator: `ACC = imm` |
| `0x08` | `STA addr` | Store the accumulator into RAM at the given address: `mem[addr] = ACC` |
| `0x09` | `LDM addr` | Load a value from RAM into the accumulator: `ACC = mem[addr]` |

### Branch Instructions

Change the flow of execution. Without branches, the CPU just runs instructions in order. Branches let you create loops (jump backward) and if/else logic (jump conditionally).

| Hex | Mnemonic | What it does |
|-----|----------|-------------|
| `0x0A` | `JMP addr` | Jump unconditionally: always go to the given address |
| `0x0B` | `JZ addr` | Jump if zero: go to address only if the Zero flag is set (last result was 0) |
| `0x0C` | `JNZ addr` | Jump if not zero: go to address only if the Zero flag is clear |
| `0x1A` | `JC addr` | Jump if carry: go to address only if the Carry flag is set (overflow occurred) |

### Stack Instructions

The stack is a last-in-first-out (LIFO) data structure used for temporary storage and subroutine calls. Think of it like a stack of plates -- you can only add to or remove from the top.

| Hex | Mnemonic | What it does |
|-----|----------|-------------|
| `0x16` | `PUSH` | Push: save ACC onto the stack (`mem[SP] = ACC`, then `SP = SP - 1`) |
| `0x17` | `POP` | Pop: restore ACC from the stack (`SP = SP + 1`, then `ACC = mem[SP]`) |
| `0x18` | `CALL addr` | Call subroutine: push the return address onto the stack, then jump to addr |
| `0x19` | `RET` | Return: pop the return address from the stack and jump back to it |

`CALL` and `RET` work together. When you `CALL 0x1C`, the CPU saves the address of the *next* instruction (so it knows where to come back) onto the stack, then jumps to address 0x1C. When that code runs `RET`, the CPU pops the saved address and jumps back to where it left off. This is how subroutines (functions) work.

### I/O Instructions

Read from switches/buttons or write to LEDs.

| Hex | Mnemonic | What it does |
|-----|----------|-------------|
| `0x0D` | `OUT` | Output: copy the accumulator to the GPIO output pins (LEDs) |
| `0x0E` | `IN` | Input: read the GPIO input pins (switches) into the accumulator |

### UART Instructions

Send serial data over a single wire.

| Hex | Mnemonic | What it does |
|-----|----------|-------------|
| `0x1B` | `UTXD` | Transmit: start sending the byte in ACC over the UART TX line |
| `0x1C` | `UTXS` | Status: read whether the UART is still busy (`ACC = 1` if busy, `0` if idle) |
| `0x1D` | `UBRD imm` | Baud rate: set the baud rate divisor. `baud = 5MHz / (16 * (imm + 1))` |

Common baud rate settings at 5 MHz clock:

| `UBRD` value | Approximate baud rate |
|-------------|-----------------------|
| 2 | 104,166 (close to 115,200) |
| 25 | 12,019 |
| 32 | 9,615 (close to 9,600) |

### Timer Instructions

Control the hardware timer/counter.

| Hex | Mnemonic | What it does |
|-----|----------|-------------|
| `0x1E` | `TSET imm` | Set prescaler: the timer increments every `(imm + 1)` clock cycles |
| `0x1F` | `TGET` | Get count: read the current timer count into the accumulator |
| `0x20` | `TCLR` | Clear: reset the timer count back to zero |

Timer speed at 5 MHz clock:

| `TSET` value | Timer counts per second |
|-------------|------------------------|
| 0 | 5,000,000 (every clock cycle) |
| 4 | 1,000,000 |
| 249 | 20,000 |
| 255 | ~19,531 |

### Control Instructions

| Hex | Mnemonic | What it does |
|-----|----------|-------------|
| `0x00` | `NOP` | No operation: does nothing, just advances to the next instruction |
| `0x0F` | `HLT` | Halt: stop the CPU. It stays stopped until the chip is reset. |

### Complete Opcode Quick Reference

```
Hex  Mnemonic       Hex  Mnemonic       Hex  Mnemonic       Hex  Mnemonic
---  --------       ---  --------       ---  --------       ---  --------
00   NOP            01   LDA  imm       02   ADD  imm       03   SUB  imm
04   AND  imm       05   OR   imm       06   XOR  imm       07   NOT
08   STA  addr      09   LDM  addr      0A   JMP  addr      0B   JZ   addr
0C   JNZ  addr      0D   OUT            0E   IN             0F   HLT
10   SHL            11   SHR            12   INC            13   DEC
14   ADDA addr      15   SUBA addr      16   PUSH           17   POP
18   CALL addr      19   RET            1A   JC   addr      1B   UTXD
1C   UTXS           1D   UBRD imm       1E   TSET imm       1F   TGET
20   TCLR
```

---

## Demo Program

The chip comes preloaded with a demonstration program that exercises all the major features. Here's what it does, step by step:

### Part 1: Counting (addresses 0x00-0x07)

The program counts from 1 to 5 and outputs each number on the GPIO pins (LEDs). It uses a loop: load 1, output it, increment, check if we've reached 6, if not loop back.

```asm
0x00: LDA  #1        ; Load the number 1 into the accumulator
0x01: STA  0x00      ; Store it in RAM address 0 (not strictly needed, just demonstrating STA)
0x02: OUT            ; Send accumulator value to the LEDs
0x03: INC            ; Add 1 to the accumulator (1->2->3->4->5->6)
0x04: SUB  #6        ; Subtract 6 -- if acc was 6, result is 0 (zero flag set)
0x05: JZ   0x08      ; If zero flag is set (we counted to 6), exit the loop
0x06: ADD  #6        ; Otherwise, undo the subtraction to restore the original value
0x07: JMP  0x02      ; Jump back to the OUT instruction and repeat
```

**LEDs show:** 1, 2, 3, 4, 5

### Part 2: Subroutine Call/Return (addresses 0x08-0x09)

Demonstrates `CALL` and `RET`. The main program calls a subroutine at address 28 that loads 5, increments it to 6, and returns. The main program then outputs the result.

```asm
0x08: CALL 0x1C      ; Call subroutine at address 28 (0x1C)
                      ;   - Pushes return address (0x09) onto the stack
                      ;   - Jumps to address 0x1C
0x09: OUT            ; After returning: output the result (6)
```

The subroutine:
```asm
0x1C: LDA  #5        ; Load 5
0x1D: INC            ; Increment to 6
0x1E: RET            ; Return to address 0x09 (popped from stack)
```

**LEDs show:** 6

### Part 3: UART Serial Output (addresses 0x0A-0x0E)

Sends the ASCII character 'H' (hex 0x48) over the UART serial port. First sets the baud rate, loads the character, starts the transmission, then loops checking the busy flag until the transmission is complete.

```asm
0x0A: UBRD #25       ; Set baud rate divisor to 25 (~12,000 baud at 5 MHz)
0x0B: LDA  #0x48     ; Load ASCII 'H' (0x48 = 72 decimal)
0x0C: UTXD           ; Start transmitting the byte
0x0D: UTXS           ; Read UART status: ACC = 1 if busy, 0 if done
0x0E: JNZ  0x0D      ; If still busy (ACC != 0), loop back and check again
```

**Serial output:** The character `H` is transmitted on the `uio_out[1]` pin.

### Part 4: Timer Demo (addresses 0x0F-0x14)

Configures the timer to count at full speed (prescaler = 0), clears it, waits a couple of instruction cycles, then reads the count. Since the timer runs continuously in hardware, the count will be a small non-zero number.

```asm
0x0F: TSET #0        ; Set prescaler to 0 (timer counts every clock cycle)
0x10: TCLR           ; Clear the timer counter back to 0
0x11: NOP            ; Do nothing -- just wait, letting the timer tick
0x12: NOP            ; Wait one more cycle
0x13: TGET           ; Read the timer count into the accumulator
0x14: OUT            ; Display the timer count on the LEDs
```

**LEDs show:** A small number (the timer count -- depends on exact cycle timing)

### Part 5: Final Output and Halt (addresses 0x15-0x17)

Loads the number 42, outputs it to the LEDs, and halts the CPU.

```asm
0x15: LDA  #42       ; Load the number 42 (the answer to everything)
0x16: OUT            ; Display 42 on the LEDs
0x17: HLT            ; Halt the CPU -- it stops here until reset
```

**LEDs show:** 42 (binary: 00101010)

### Complete GPIO Output Sequence

```
1 -> 2 -> 3 -> 4 -> 5 -> 6 -> (timer count) -> 42 -> (CPU halts)
```

---

## Pin Mapping

### Dedicated Inputs (`ui_in`)

These 8 pins are connected to the GPIO input port. Connect DIP switches, buttons, or other logic signals. The CPU reads them using the `IN` instruction.

| Pin | Signal |
|-----|--------|
| `ui_in[7:0]` | `gpio_in[7:0]` |

### Dedicated Outputs (`uo_out`)

These 8 pins are connected to the GPIO output port. Connect LEDs to see the CPU's output. The CPU writes to them using the `OUT` instruction. Values are latched -- they hold steady until the next `OUT`.

| Pin | Signal |
|-----|--------|
| `uo_out[7:0]` | `gpio_out[7:0]` |

### Bidirectional Pins (`uio`)

| Pin | Direction | Signal | Description |
|-----|-----------|--------|-------------|
| `uio[0]` | Output | `halted` | Goes HIGH when the CPU executes HLT |
| `uio[1]` | Output | `uart_tx` | UART serial data output (idle high, active low) |
| `uio[2-7]` | Input | -- | Unused |

Output enable: `uio_oe = 0x03` (only bits 0 and 1 are driven as outputs)

---

## How to Test

### On Real Hardware

1. **Reset the CPU:** Hold `rst_n` LOW for at least 5 clock cycles, then release it HIGH
2. **Enable the design:** Make sure `ena` is HIGH (TinyTapeout selects your design)
3. **Watch the LEDs:** Connect 8 LEDs to `uo_out[7:0]`. You'll see them count 1, 2, 3, 4, 5, then show 6, a small timer value, and finally 42
4. **Check the halt LED:** Connect an LED to `uio_out[0]`. It lights up when the CPU stops
5. **Read the serial output:** Connect a USB-to-UART adapter's RX pin to `uio_out[1]`. Set your terminal to match the baud rate. You'll receive the letter `H`
6. **Try the inputs:** Connect switches to `ui_in[7:0]`. If you modify the ROM program to use the `IN` instruction, the CPU can read your switch positions

### Running the Simulation

The project includes a full test suite using [cocotb](https://www.cocotb.org/) (a Python-based hardware verification framework) and [Icarus Verilog](http://iverilog.icarus.com/) (an open-source Verilog simulator). The 7 tests verify every major feature:

| Test | What it checks |
|------|---------------|
| `test_reset_state` | GPIO output is all zeros during reset |
| `test_uio_oe` | Bidirectional pin direction register reads `0x03` |
| `test_count_to_5` | The counting loop outputs `[1, 2, 3, 4, 5]` correctly |
| `test_call_ret` | CALL/RET subroutine produces the value `6` |
| `test_uart_tx_activity` | The UART TX line goes low (start bit) when sending |
| `test_timer_activity` | The timer demo runs and the full program reaches value 42 |
| `test_full_demo_halts` | The CPU halts with `uo_out=42` and halt flag asserted |

To run locally:

```bash
# Prerequisites: iverilog, Python <= 3.13, pip
cd test
python3 -m venv .venv
source .venv/bin/activate
pip install cocotb
make -B
```

Expected output:
```
** TESTS=7 PASS=7 FAIL=0 SKIP=0 **
```

---

## Writing Your Own Programs

To write a custom program, edit the ROM initialization in `src/program_rom.v`. Each `rom[n]` entry is a 16-bit value where the upper byte is the opcode and the lower byte is the operand:

```verilog
rom[address] = 16'hOO_DD;
//                  ^^ ^^
//                  |  |
//                  |  +-- operand (immediate value or address)
//                  +----- opcode (instruction code from the table above)
```

### Example: Alternating LED Pattern

```verilog
rom[0] = 16'h01_AA;  // LDA  #0xAA   ; Load 10101010 pattern
rom[1] = 16'h0D_00;  // OUT          ; Display it on LEDs
rom[2] = 16'h07_00;  // NOT          ; Flip all bits to 01010101
rom[3] = 16'h0D_00;  // OUT          ; Display that
rom[4] = 16'h07_00;  // NOT          ; Flip back to 10101010
rom[5] = 16'h0A_01;  // JMP  0x01    ; Loop forever
```

### Example: Add Two Numbers from RAM

```verilog
rom[0] = 16'h01_07;  // LDA  #7     ; Load 7 into accumulator
rom[1] = 16'h08_00;  // STA  0x00   ; Store it at RAM address 0
rom[2] = 16'h01_03;  // LDA  #3     ; Load 3 into accumulator
rom[3] = 16'h14_00;  // ADDA 0x00   ; Add RAM[0] (which is 7) to accumulator -> ACC = 10
rom[4] = 16'h0D_00;  // OUT         ; Display 10 on LEDs
rom[5] = 16'h0F_00;  // HLT         ; Stop
```

### Example: Send "Hi" Over UART

```verilog
rom[0]  = 16'h1D_19;  // UBRD #25    ; Set baud rate
rom[1]  = 16'h01_48;  // LDA  #0x48  ; 'H'
rom[2]  = 16'h1B_00;  // UTXD        ; Send it
rom[3]  = 16'h1C_00;  // UTXS        ; Check busy?
rom[4]  = 16'h0C_03;  // JNZ  0x03   ; Wait until done
rom[5]  = 16'h01_69;  // LDA  #0x69  ; 'i'
rom[6]  = 16'h1B_00;  // UTXD        ; Send it
rom[7]  = 16'h1C_00;  // UTXS        ; Check busy?
rom[8]  = 16'h0C_07;  // JNZ  0x07   ; Wait until done
rom[9]  = 16'h0F_00;  // HLT         ; Stop
```

---

## Design Specifications

| Parameter | Value |
|-----------|-------|
| Process node | SkyWater SKY130 (130nm) |
| Tile size | 1x2 (~167 x 216 um) |
| Standard cell utilization | 76.7% |
| Target clock frequency | 5 MHz |
| Total instructions | 33 |
| Instruction width | 16 bits (8-bit opcode + 8-bit operand) |
| Data width | 8 bits |
| Program ROM | 32 words x 16 bits (512 bits total) |
| Data RAM | 32 bytes x 8 bits (256 bits total) |
| Stack depth | Up to 16 entries (shares upper half of RAM) |
| GPIO | 8-bit input + 8-bit output |
| UART | Transmit only, 8-N-1, programmable baud rate |
| Timer | 8-bit counter with 8-bit programmable prescaler |
| Pipeline | 3/4-stage FSM (FETCH, DECODE, [MEM_READ], EXECUTE) |
| Reset | Active-low asynchronous reset |

---

## Source Files

```
ttsky-8bit-cpu-soc/
├── src/
│   ├── tt_um_fidel_makatia_digital_tapeout.v   # TinyTapeout pin wrapper
│   ├── soc_top.v                                # Top-level SoC interconnect
│   ├── control.v                                # CPU control FSM (33 instructions)
│   ├── alu.v                                    # 8-bit arithmetic logic unit
│   ├── program_rom.v                            # 32-word instruction ROM + demo program
│   ├── regfile.v                                # 32-byte data RAM / register file
│   ├── gpio.v                                   # General-purpose I/O
│   ├── uart_tx.v                                # UART serial transmitter
│   └── timer.v                                  # Timer/counter with prescaler
├── test/
│   ├── test.py                                  # cocotb test suite (7 tests)
│   ├── tb.v                                     # Verilog simulation testbench
│   └── Makefile                                 # Simulation build rules
├── docs/
│   └── info.md                                  # TinyTapeout documentation
├── info.yaml                                    # TinyTapeout project configuration
└── README.md
```

---

## License

Apache-2.0

## Author

Fidel Makatia
