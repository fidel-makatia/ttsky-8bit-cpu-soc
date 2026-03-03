# FPGA Testing on Zybo Z7-010

Test the 8-bit CPU SoC on a real FPGA before the silicon comes back.

## Board Setup

### What You Need

- Digilent Zybo Z7-010 board
- USB cable (micro-USB, for power + JTAG programming)
- Optional: USB-to-UART adapter (for reading UART serial output from PMOD JA)
- Optional: LEDs + resistors on a breadboard (for viewing gpio_out[7:4] on PMOD JA)

### Pin Connections

**On-board (no wiring needed):**

| Board Feature | CPU Signal | What You'll See |
|--------------|-----------|-----------------|
| LED0-LED3 | gpio_out[3:0] | Count 1→5, then 6, timer value, 42 |
| SW0-SW3 | gpio_in[3:0] | Read by the `IN` instruction |
| BTN0 | Reset | Press to reset the CPU |

**PMOD JA header (optional wiring):**

```
PMOD JA Pinout (top view, looking at the connector):
┌─────────────────────────────┐
│  GND  GND  3V3  3V3        │
│   6    5    12   11         │  ← power pins (no connect needed)
│                             │
│  JA4  JA3  JA2  JA1        │
│   4    3    2    1          │  ← gpio_out[7:4]
│                             │
│  JA8  JA7  JA6  JA5        │
│   10   9    8    7          │  ← halted, uart_tx, (unused), (unused)
└─────────────────────────────┘

Pin 1 (JA1) = gpio_out[4]
Pin 2 (JA2) = gpio_out[5]
Pin 3 (JA3) = gpio_out[6]
Pin 4 (JA4) = gpio_out[7]
Pin 7 (JA7) = UART TX output  ← connect USB-UART adapter RX here
Pin 8 (JA8) = Halted indicator ← connect an LED here (with resistor)
Pin 5,6     = GND              ← use for UART GND
Pin 11,12   = 3.3V
```

To read UART output: connect a USB-to-UART adapter's **RX** pin to PMOD JA pin 7, and **GND** to PMOD JA pin 5 or 6. Open a serial terminal at **12,000 baud** (8-N-1). You should see the character `H`.

---

## Building with Vivado in Docker

### Step 1: Get Vivado Docker Image

Xilinx doesn't provide an official Docker image, so you'll need to build one. The easiest approach:

1. Download [Vivado ML Edition (free)](https://www.xilinx.com/support/download.html) -- choose the Linux installer
2. Use a community Dockerfile or create a simple one:

```dockerfile
FROM ubuntu:22.04
# Copy in Vivado installer and run it
# (See Xilinx docs for silent install: xsetup --batch Install --agree XilinxEULA,3rdPartyEULA)
```

Alternatively, if you have access to a Linux machine (or a VM via UTM/Parallels), install Vivado there directly -- it's often simpler than Docker for FPGA tools.

### Step 2: Build the Bitstream

From inside the Vivado environment (Docker container, VM, or Linux machine):

```bash
cd fpga
vivado -mode batch -source build.tcl
```

This takes about 2-5 minutes and produces `fpga/build/top_zybo.bit`.

Check `fpga/build/utilization_route.rpt` for resource usage and `fpga/build/timing.rpt` to confirm timing is met.

### Step 3: Program the Board

Connect the Zybo Z7-010 via USB. Make sure the board is powered on (green LED near power switch).

```bash
vivado -mode batch -source program.tcl
```

Or open Vivado GUI → Hardware Manager → Auto Connect → Program Device → select `build/top_zybo.bit`.

**Note:** Programming via Docker requires USB passthrough to the container. This can be tricky on macOS. If you have issues, program from a Linux VM with USB passthrough instead, or use the Vivado GUI on a machine with direct USB access.

---

## What to Expect

Once programmed, the CPU starts running immediately:

1. **LEDs count:** LED0-LED3 flash through the binary values 1, 2, 3, 4, 5 (very fast at 5 MHz -- you'll see a brief flicker)
2. **Subroutine result:** LEDs show 6 (binary: 0110) briefly
3. **UART transmission:** Character 'H' sent on PMOD JA pin 7 (invisible unless you have a UART adapter connected)
4. **Timer value:** LEDs show a small number (the timer count)
5. **Final value:** LEDs show 42 (binary: 1010 on LED3,LED1 → LEDs 1 and 3 lit)
6. **Halt:** CPU stops. If you connected an LED to PMOD JA pin 8, it lights up.

**The counting happens very fast** at 5 MHz (each instruction takes 3-4 cycles = 600-800 ns). You'll mostly just see the final state: LEDs showing **42** (binary 00101010, so LED1 and LED3 on, LED0 and LED2 off).

Press **BTN0** to reset and watch it run again.

### Slowing Down the Demo

If you want to see the counting at human speed, you can reduce the clock frequency. Edit `top_zybo.v` and change the clock divider to produce a slower clock (e.g., 1 Hz):

```verilog
// Change from divide-by-25 (5 MHz) to divide-by-62500000 (1 Hz)
reg [25:0] clk_cnt = 0;
reg        clk_slow = 0;
always @(posedge sys_clk) begin
    if (clk_cnt == 26'd62_499_999) begin
        clk_cnt  <= 0;
        clk_slow <= ~clk_slow;
    end else
        clk_cnt <= clk_cnt + 1;
end
// Then use clk_slow instead of clk_5mhz for the SoC
```

At 1 Hz, each instruction takes ~3-4 seconds, so you can watch the LEDs count up slowly. Note that the UART won't work at this speed (the baud rate would be far too slow).

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| LEDs don't light up | Check power (green LED on board), check that JP5 jumper is set to USB |
| LEDs show wrong pattern | Press BTN0 to reset. Check that SW0-SW3 are in the down (off) position |
| UART not receiving | Check baud rate (12,000), check RX is on pin 7 not pin 1, check GND connected |
| Vivado can't find device | Make sure USB cable is connected, try `open_hw_target` manually in Vivado TCL console |
| Build fails with timing errors | Should not happen at 5 MHz. If it does, try `set_property STEPS.ROUTE.ARGS.DIRECTIVE MoreGlobalIterations [get_runs impl_1]` |
