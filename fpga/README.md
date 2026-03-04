# FPGA Workshop: 8-bit CPU SoC on Zybo Z7-010

Test and demo the TTSky 8-bit CPU SoC on a real FPGA — no Vivado required.

The CPU runs at **4 Hz** so you can watch each instruction execute in real time on the LEDs. A 15-phase test program exercises all 33 CPU instructions, with LEDs counting from 0001 to 1111 as each test passes.

---

## Table of Contents

1. [Hardware Requirements](#hardware-requirements)
2. [Pin Map](#pin-map)
3. [Quick Start (Pre-built Bitstream)](#quick-start-pre-built-bitstream)
4. [Building the Bitstream](#building-the-bitstream)
5. [Programming the FPGA](#programming-the-fpga)
6. [What to Expect (Demo Script)](#what-to-expect-demo-script)
7. [CPU Instruction Set Reference](#cpu-instruction-set-reference)
8. [Writing Your Own Programs](#writing-your-own-programs)
9. [Troubleshooting](#troubleshooting)

---

## Hardware Requirements

| Item | Required? | Notes |
|------|-----------|-------|
| Digilent Zybo Z7-010 | Yes | xc7z010clg400-1 (Z7-020 also works) |
| Micro-USB cable | Yes | Powers the board + JTAG programming |
| USB-to-UART adapter | Optional | To see UART output from PMOD JA pin 7 |
| Breadboard + LEDs | Optional | To view gpio_out[7:4] on PMOD JA pins 1-4 |

**Software (choose one):**
- **Option A (recommended):** Docker + openFPGALoader (fully open-source, ~500 MB)
- **Option B:** Xilinx Vivado ML Edition (free but ~50 GB download)

---

## Pin Map

### On-board (no wiring needed)

| Board Feature | CPU Signal | Function |
|---------------|------------|----------|
| LED0 | gpio_out[0] | Test phase bit 0 |
| LED1 | gpio_out[1] | Test phase bit 1 |
| LED2 | gpio_out[2] | Test phase bit 2 |
| LED3 | gpio_out[3] | Test phase bit 3 |
| SW0-SW3 | gpio_in[3:0] | Read by the `IN` instruction |
| BTN0 | Reset | Press to restart the CPU |

### PMOD JA header (optional wiring)

```
PMOD JA Pinout (top view, looking at the connector):
┌─────────────────────────────────────┐
│  GND  GND  3V3  3V3                │
│   6    5    12   11                 │  ← power pins
│                                     │
│  JA4  JA3  JA2  JA1                │
│   4    3    2    1                  │  ← gpio_out[7:4]
│                                     │
│  JA8  JA7  JA6  JA5                │
│   10   9    8    7                  │  ← halted, uart_tx
└─────────────────────────────────────┘

Pin 1 (JA1) = gpio_out[4]
Pin 2 (JA2) = gpio_out[5]
Pin 3 (JA3) = gpio_out[6]
Pin 4 (JA4) = gpio_out[7]
Pin 7 (JA7) = UART TX     ← connect USB-UART adapter RX here
Pin 8 (JA8) = Halted flag  ← connect LED + 330Ω resistor
Pin 5,6     = GND          ← use for UART GND
```

**UART setup:** Connect USB-UART adapter RX to JA pin 7, GND to JA pin 5. Open serial terminal at **12,000 baud** (8-N-1). You'll see the character `H` sent during Test F.

---

## Quick Start (Pre-built Bitstream)

If someone already built the bitstream for you:

1. Connect the Zybo Z7-010 via USB
2. Set JP5 jumper to "USB" (powers board from USB)
3. Flip the power switch ON (green LED lights up)
4. Program:
   ```bash
   # Install openFPGALoader (see "Programming the FPGA" section below)
   openFPGALoader -b zybo_z7_10 fpga/build/top_zybo.bit
   ```
5. Watch LEDs count from 0001 to 1111
6. Press BTN0 to reset and re-run

---

## Building the Bitstream

### Option A: Open-Source Tools (Recommended)

Uses the **openXC7** toolchain (yosys + nextpnr-xilinx + prjxray) inside Docker. No Xilinx tools needed.

#### Prerequisites

Install Docker:
- **Windows:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) (enable WSL2 backend)
- **macOS:** [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- **Linux:** `sudo apt install docker.io && sudo usermod -aG docker $USER`

#### Build

```bash
# Clone the repo (if you haven't already)
git clone https://github.com/fidel-makatia/ttsky-8bit-cpu-soc.git
cd ttsky-8bit-cpu-soc

# Build (first run takes ~5-10 min to generate chipdb, subsequent builds ~1-2 min)
docker run --rm \
    -v "$(pwd)":/project \
    -v openxc7-chipdb:/chipdb \
    regymm/openxc7 \
    bash /project/fpga/build_openxc7.sh
```

The named volume `openxc7-chipdb` caches the chip database between builds. Output: `fpga/build/top_zybo.bit`

**Windows (PowerShell):**
```powershell
docker run --rm `
    -v "${PWD}:/project" `
    -v openxc7-chipdb:/chipdb `
    regymm/openxc7 `
    bash /project/fpga/build_openxc7.sh
```

**Windows (Git Bash / MSYS2):**
```bash
MSYS_NO_PATHCONV=1 docker run --rm \
    -v "$(pwd)":/project \
    -v openxc7-chipdb:/chipdb \
    regymm/openxc7 \
    bash /project/fpga/build_openxc7.sh
```

### Option B: Vivado

If you have Vivado installed:

```bash
cd fpga
vivado -mode batch -source build.tcl
```

Output: `fpga/build/top_zybo.bit` (~2-5 minutes)

---

## Programming the FPGA

### openFPGALoader (Recommended — No Vivado)

[openFPGALoader](https://github.com/trabucayre/openFPGALoader) is a universal open-source FPGA programmer supporting 40+ boards including the Zybo.

#### Installation

**Windows (MSYS2):**
```bash
# Install MSYS2 from https://www.msys2.org/ if you don't have it
# Open "MSYS2 UCRT64" terminal, then:
pacman -S mingw-w64-ucrt-x86_64-openFPGALoader
```

**macOS:**
```bash
brew install openfpgaloader
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt install openfpgaloader
```

**Linux (Fedora):**
```bash
sudo dnf install openFPGALoader
```

**From source (any platform):**
```bash
git clone https://github.com/trabucayre/openFPGALoader.git
cd openFPGALoader
mkdir build && cd build
cmake ..
make -j$(nproc)
sudo make install
```

#### USB Driver Setup (Windows Only)

On Windows, you may need to install the **WinUSB** or **libusbK** driver for the JTAG interface:

1. Download [Zadig](https://zadig.akeo.ie/)
2. Connect the Zybo and power it on
3. In Zadig: Options → List All Devices
4. Select "Digilent USB Device (Interface 0)"
5. Set driver to "WinUSB" and click "Replace Driver"

#### Programming

```bash
# Using the helper script:
cd fpga
./program.sh

# Or directly:
openFPGALoader -b zybo_z7_10 fpga/build/top_zybo.bit
```

This programs the FPGA's SRAM (volatile — lost on power cycle). The CPU starts running immediately.

### Vivado (Alternative)

```bash
cd fpga
vivado -mode batch -source program.tcl
```

Or use Vivado GUI: Hardware Manager → Auto Connect → Program Device → select `build/top_zybo.bit`.

---

## What to Expect (Demo Script)

After programming, the CPU starts running the 15-phase test at **4 Hz** (~0.75 seconds per instruction, ~2-3 seconds per test phase). Watch the 4 LEDs:

| Phase | LEDs (3210) | Binary | What's Being Tested |
|-------|-------------|--------|---------------------|
| 1 | `○○○●` | 0001 | LDA, OUT — Load immediate and output |
| 2 | `○○●○` | 0010 | ADD, SUB — Arithmetic operations |
| 3 | `○○●●` | 0011 | AND, XOR — Logic operations |
| 4 | `○●○○` | 0100 | NOT — Bitwise inversion |
| 5 | `○●○●` | 0101 | SHR — Shift right |
| 6 | `○●●○` | 0110 | INC — Increment |
| 7 | `○●●●` | 0111 | STA, LDM — Memory store/load |
| 8 | `●○○○` | 1000 | JMP, JZ, JNZ — Conditional branches |
| 9 | `●○○●` | 1001 | OR — Bitwise OR |
| A | `●○●○` | 1010 | DEC — Decrement |
| B | `●○●●` | 1011 | ADD, INC combined |
| C | `●●○○` | 1100 | JC — Carry flag jump |
| D | `●●○●` | 1101 | ADDA, SUBA — Memory arithmetic |
| E | `●●●○` | 1110 | PUSH, POP, CALL, RET — Stack ops |
| F | `●●●●` | 1111 | UART TX, Timer — Peripherals |
| **Done** | `●●●●` | 1111 | All tests passed! CPU halts. |

`●` = LED ON, `○` = LED OFF

**Total runtime:** ~45 seconds from reset to halt.

**If a test fails**, the LEDs will stop incrementing at the failing phase. For example, if LEDs are stuck at `●●○○` (1100), test D (ADDA/SUBA) failed.

Press **BTN0** to reset and re-run the test sequence.

### Quick Demo Talking Points

1. "This is an 8-bit CPU I designed — it has 33 instructions, a UART, timer, and GPIO"
2. "It's running at 4 Hz so we can see each instruction execute"
3. "Watch the LEDs count up as each test phase passes"
4. "The same RTL goes through OpenLane to produce a real chip layout for TinyTapeout"
5. "The entire toolchain is open-source — no commercial tools needed"

---

## CPU Instruction Set Reference

33 instructions, 16-bit encoding: `{opcode[7:0], operand[7:0]}`

### Data Movement
| Opcode | Mnemonic | Description |
|--------|----------|-------------|
| 0x01 | LDA imm | Load immediate into accumulator |
| 0x08 | STA addr | Store accumulator to memory[addr] |
| 0x09 | LDM addr | Load memory[addr] into accumulator |
| 0x0D | OUT | Copy accumulator to GPIO output |
| 0x0E | IN | Copy GPIO input to accumulator |

### Arithmetic
| Opcode | Mnemonic | Description |
|--------|----------|-------------|
| 0x02 | ADD imm | Add immediate to accumulator |
| 0x03 | SUB imm | Subtract immediate from accumulator |
| 0x12 | INC | Increment accumulator |
| 0x13 | DEC | Decrement accumulator |
| 0x14 | ADDA addr | Add memory[addr] to accumulator |
| 0x15 | SUBA addr | Subtract memory[addr] from accumulator |

### Logic
| Opcode | Mnemonic | Description |
|--------|----------|-------------|
| 0x04 | AND imm | AND immediate with accumulator |
| 0x05 | OR imm | OR immediate with accumulator |
| 0x06 | XOR imm | XOR immediate with accumulator |
| 0x07 | NOT | Bitwise NOT of accumulator |
| 0x10 | SHL | Shift accumulator left (carry = MSB) |
| 0x11 | SHR | Shift accumulator right (carry = LSB) |

### Control Flow
| Opcode | Mnemonic | Description |
|--------|----------|-------------|
| 0x00 | NOP | No operation |
| 0x0A | JMP addr | Unconditional jump |
| 0x0B | JZ addr | Jump if zero flag set |
| 0x0C | JNZ addr | Jump if zero flag clear |
| 0x1A | JC addr | Jump if carry flag set |
| 0x0F | HLT | Halt execution |

### Stack
| Opcode | Mnemonic | Description |
|--------|----------|-------------|
| 0x16 | PUSH | Push accumulator onto stack |
| 0x17 | POP | Pop stack top into accumulator |
| 0x18 | CALL addr | Push return address, jump to addr |
| 0x19 | RET | Pop return address, jump there |

### Peripherals
| Opcode | Mnemonic | Description |
|--------|----------|-------------|
| 0x1B | UTXD | Send accumulator via UART TX |
| 0x1C | UTXS | Read UART TX busy status into accumulator |
| 0x1D | UBRD imm | Set UART baud rate divisor |
| 0x1E | TSET imm | Set timer prescaler |
| 0x1F | TGET | Read timer count into accumulator |
| 0x20 | TCLR | Clear timer count |

---

## Writing Your Own Programs

Edit `fpga/program_rom_fpga.v` to write your own programs. The ROM holds 128 instructions (addresses 0x00-0x7F).

### Example: Blink LEDs

```verilog
rom[0] = 16'h01_0F;  // LDA  #0x0F    ; all LEDs on
rom[1] = 16'h0D_00;  // OUT           ; display on LEDs
rom[2] = 16'h01_00;  // LDA  #0x00    ; all LEDs off
rom[3] = 16'h0D_00;  // OUT           ; display on LEDs
rom[4] = 16'h0A_00;  // JMP  0x00     ; loop forever
```

At 4 Hz, each LED state lasts ~2.25 seconds (3 instructions x 0.75s each).

### Example: Read switches, display on LEDs

```verilog
rom[0] = 16'h0E_00;  // IN            ; read switch positions
rom[1] = 16'h0D_00;  // OUT           ; show on LEDs
rom[2] = 16'h0A_00;  // JMP  0x00     ; loop forever
```

### Example: Count up forever

```verilog
rom[0] = 16'h01_00;  // LDA  #0       ; start at 0
rom[1] = 16'h0D_00;  // OUT           ; show on LEDs
rom[2] = 16'h12_00;  // INC           ; acc++
rom[3] = 16'h0A_01;  // JMP  0x01     ; loop (skip LDA)
```

### Example: Send "Hi" over UART

```verilog
rom[0]  = 16'h1D_19;  // UBRD #25      ; set baud divider (~12000 baud at 4 Hz*)
rom[1]  = 16'h01_48;  // LDA  #0x48    ; 'H'
rom[2]  = 16'h1B_00;  // UTXD          ; send
rom[3]  = 16'h1C_00;  // UTXS          ; check busy
rom[4]  = 16'h0C_03;  // JNZ  3        ; wait until done
rom[5]  = 16'h01_69;  // LDA  #0x69    ; 'i'
rom[6]  = 16'h1B_00;  // UTXD          ; send
rom[7]  = 16'h1C_00;  // UTXS          ; check busy
rom[8]  = 16'h0C_07;  // JNZ  7        ; wait until done
rom[9]  = 16'h0F_00;  // HLT           ; done
// *Note: UART baud rate is relative to CPU clock. At 4 Hz this is extremely slow.
// For practical UART, change CLK_DIV in top_zybo.v to get a faster clock.
```

After editing, rebuild and reprogram:
```bash
# Rebuild
docker run --rm -v "$(pwd)":/project -v openxc7-chipdb:/chipdb \
    regymm/openxc7 bash /project/fpga/build_openxc7.sh

# Reprogram
openFPGALoader -b zybo_z7_10 fpga/build/top_zybo.bit
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| LEDs don't light up | Check power: green LED near power switch should be on. Set JP5 to "USB". |
| LEDs show wrong pattern | Press BTN0 to reset. Make sure SW0-SW3 are all DOWN (off). |
| LEDs stuck at one phase | That test failed. Check the test table above to identify which instruction is broken. |
| openFPGALoader: "No cable found" | Check USB connection. On Windows, install WinUSB driver via Zadig (see above). |
| openFPGALoader: "JTAG init failed" | Another tool (Vivado hw_server) may be holding the JTAG. Kill `hw_server` processes. |
| Docker build fails | Make sure Docker is running. On Windows, check WSL2 is enabled. Try `docker pull regymm/openxc7` first. |
| Docker volume mount error (Windows) | Use PowerShell syntax with backticks, or set `MSYS_NO_PATHCONV=1` in Git Bash. |
| UART not receiving | Check baud rate (12,000 baud), check RX on JA pin 7, GND on JA pin 5/6. Note: UART is very slow at 4 Hz clock. |
| Build timing errors | Should not happen — CPU runs at 4 Hz internally. If it does, it's a sys_clk domain issue. |

### Getting Help

- Open an issue: https://github.com/fidel-makatia/ttsky-8bit-cpu-soc/issues
- Check the [openFPGALoader docs](https://trabucayre.github.io/openFPGALoader/)
- Check the [openXC7 Docker image](https://hub.docker.com/r/regymm/openxc7)

---

## Project Structure

```
fpga/
├── README.md              ← You are here
├── top_zybo.v             ← FPGA top-level wrapper (4 Hz clock, POR, reset)
├── program_rom_fpga.v     ← 128-entry test ROM (15-phase comprehensive test)
├── zybo_z7010.xdc         ← Vivado pin constraints
├── zybo_openxc7.xdc       ← openXC7 pin constraints
├── build.tcl              ← Vivado build script
├── build_openxc7.sh       ← Open-source build script (Docker)
├── program.tcl            ← Vivado programming script
├── program.sh             ← openFPGALoader programming script
└── build/                 ← Build output (top_zybo.bit)

src/
├── soc_top.v              ← SoC top-level (CPU + peripherals)
├── control.v              ← CPU control unit (33-instruction FSM)
├── alu.v                  ← 8-bit ALU (11 operations)
├── regfile.v              ← 32-byte data memory
├── program_rom.v          ← ASIC demo ROM (32-entry, for tapeout)
├── gpio.v                 ← GPIO with input synchronizer
├── uart_tx.v              ← UART transmitter (8-N-1)
└── timer.v                ← 8-bit timer with prescaler
```
