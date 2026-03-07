# Run the 8-bit CPU on a Zybo Z7-010 FPGA

A 15-phase test runs all 33 CPU instructions. LEDs count from 0001 to 1111 as each test passes (~45 seconds total). CPU runs at 4 Hz so you can watch every instruction execute.

## You Need

- Zybo Z7-010 board + micro-USB cable
- Vivado installed (any version, free ML Edition works)

## Step 1: Set Up Vivado in Your Terminal

**Windows (CMD):**
```
call C:\Xilinx\Vivado\2024.2\settings64.bat
```

**Windows (PowerShell):**
```
C:\Xilinx\Vivado\2024.2\settings64.ps1
```

**Linux / macOS:**
```
source /tools/Xilinx/Vivado/2024.2/settings64.sh
```

> Replace the path with wherever Vivado is installed on your machine.
> After this, `vivado` should work in your terminal. Test with: `vivado -version`

## Step 2: Clone and Build (~2 min)

```
git clone https://github.com/fidel-makatia/ttsky-8bit-cpu-soc.git
cd ttsky-8bit-cpu-soc
vivado -mode batch -source fpga/build.tcl
```

This produces `fpga/build/top_zybo.bit`.

## Step 3: Connect and Program

1. Connect the Zybo to your laptop via USB
2. Set the JP5 jumper to **USB**
3. Flip the power switch **ON** (green LED lights up)

```
vivado -mode batch -source fpga/program.tcl
```

Done. The CPU starts running immediately.

## What You'll See

LEDs count up in binary as each test phase passes:

| LEDs | Test | What's Tested |
|------|------|---------------|
| `0001` | 1 | LDA, OUT |
| `0010` | 2 | ADD, SUB |
| `0011` | 3 | AND, XOR |
| `0100` | 4 | NOT |
| `0101` | 5 | SHR (shift right) |
| `0110` | 6 | INC |
| `0111` | 7 | STA, LDM (memory) |
| `1000` | 8 | JMP, JZ, JNZ (branches) |
| `1001` | 9 | OR |
| `1010` | A | DEC |
| `1011` | B | ADD + INC |
| `1100` | C | JC (carry flag) |
| `1101` | D | ADDA, SUBA (memory math) |
| `1110` | E | PUSH, POP, CALL, RET (stack) |
| `1111` | F | UART TX, Timer |

All 4 LEDs ON = **all 15 tests passed**. Press **BTN0** to restart.

If LEDs get stuck, that test failed.

## Try Other Programs

There are ready-made programs in `fpga/programs/`:

```
copy fpga\programs\guess_game.v fpga\program_rom_fpga.v
vivado -mode batch -source fpga/build.tcl
vivado -mode batch -source fpga/program.tcl
```

| Program | What It Does |
|---------|-------------|
| `guess_game.v` | Number guessing game — use switches to guess, LEDs give hints |
| `fibonacci.v` | Fibonacci sequence on LEDs |

To go back to the test: `git checkout fpga/program_rom_fpga.v`

## Write Your Own Program

Edit `fpga/program_rom_fpga.v`. Each line is one instruction: `rom[addr] = {opcode, operand}`

**Blink LEDs:**
```verilog
rom[0] = 16'h01_0F;  // LDA  #0x0F   ; all LEDs on
rom[1] = 16'h0D_00;  // OUT
rom[2] = 16'h01_00;  // LDA  #0x00   ; all LEDs off
rom[3] = 16'h0D_00;  // OUT
rom[4] = 16'h0A_00;  // JMP  0       ; loop
```

**Read switches → LEDs:**
```verilog
rom[0] = 16'h0E_00;  // IN           ; read switches
rom[1] = 16'h0D_00;  // OUT          ; show on LEDs
rom[2] = 16'h0A_00;  // JMP  0       ; loop
```

**Count up:**
```verilog
rom[0] = 16'h01_00;  // LDA  #0      ; start at 0
rom[1] = 16'h0D_00;  // OUT          ; show on LEDs
rom[2] = 16'h12_00;  // INC          ; +1
rom[3] = 16'h0A_01;  // JMP  1       ; loop
```

Then rebuild and reprogram (same two `vivado` commands).

## Pin Map

| Board | Signal | Notes |
|-------|--------|-------|
| LED0-3 | gpio_out[3:0] | Shows test phase / program output |
| SW0-3 | gpio_in[3:0] | Read by `IN` instruction |
| BTN0 | Reset | Restarts the CPU |
| PMOD JA pin 7 | UART TX | Optional: connect USB-UART adapter (12000 baud) |
| PMOD JA pin 8 | Halted | Goes high when CPU halts |

## Instruction Set (33 instructions)

| Opcode | Name | What It Does |
|--------|------|-------------|
| `01` | LDA # | Load number into accumulator |
| `02` | ADD # | Add number to accumulator |
| `03` | SUB # | Subtract number from accumulator |
| `04` | AND # | Bitwise AND |
| `05` | OR # | Bitwise OR |
| `06` | XOR # | Bitwise XOR |
| `07` | NOT | Flip all bits |
| `08` | STA addr | Store accumulator to memory |
| `09` | LDM addr | Load memory into accumulator |
| `0A` | JMP addr | Jump to address |
| `0B` | JZ addr | Jump if zero |
| `0C` | JNZ addr | Jump if not zero |
| `0D` | OUT | Send accumulator to LEDs |
| `0E` | IN | Read switches into accumulator |
| `0F` | HLT | Stop the CPU |
| `10` | SHL | Shift left |
| `11` | SHR | Shift right |
| `12` | INC | Add 1 |
| `13` | DEC | Subtract 1 |
| `14` | ADDA addr | Add memory value to accumulator |
| `15` | SUBA addr | Subtract memory value from accumulator |
| `16` | PUSH | Push accumulator to stack |
| `17` | POP | Pop stack to accumulator |
| `18` | CALL addr | Call subroutine |
| `19` | RET | Return from subroutine |
| `1A` | JC addr | Jump if carry |
| `1B` | UTXD | Send accumulator over UART |
| `1C` | UTXS | Read UART busy status |
| `1D` | UBRD # | Set UART baud rate |
| `1E` | TSET # | Set timer speed |
| `1F` | TGET | Read timer into accumulator |
| `20` | TCLR | Reset timer to 0 |

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `vivado` not found | Run Vivado's `settings64` script first (see Step 1) |
| "No board found" | Check USB cable, board power, close other Vivado instances |
| LEDs don't light up | Check JP5 is set to USB, power switch is ON |
| LEDs stuck at one value | That test failed — press BTN0 to retry |
| Build fails | Make sure you're in the repo root directory |
