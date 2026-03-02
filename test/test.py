# SPDX-FileCopyrightText: © 2024 Fidel Makatia
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


async def reset_cpu(dut):
    """Reset the CPU and release cleanly."""
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1


@cocotb.test()
async def test_reset_state(dut):
    """Verify output is zero during and immediately after reset."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 5)

    assert int(dut.uo_out.value) == 0, "GPIO output should be 0 during reset"


@cocotb.test()
async def test_uio_oe(dut):
    """Verify uio_oe is correctly configured (only bit 0 is output)."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_cpu(dut)
    await ClockCycles(dut.clk, 2)

    assert int(dut.uio_oe.value) == 0x01, f"Expected uio_oe=0x01, got {int(dut.uio_oe.value):#x}"


@cocotb.test()
async def test_count_to_5(dut):
    """Test the hardcoded demo program: count 1 to 5 on GPIO output, then halt.

    The ROM contains a program that:
      - Loads 1 into accumulator
      - Outputs accumulator to GPIO
      - Increments accumulator
      - Checks if value exceeds 5 (SUB 6, JZ halt, ADD 6 to restore)
      - Loops back to output
      - Halts after outputting 5

    Expected GPIO output sequence: 1, 2, 3, 4, 5
    """
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_cpu(dut)

    # Collect GPIO output values as the CPU runs
    gpio_values = []
    prev_value = 0

    # Run for enough cycles for the program to complete
    # The 8-bit CPU has a 3-cycle pipeline (FETCH, DECODE, EXECUTE)
    # The program loops 5 times with ~7 instructions per loop = ~105 cycles
    for _ in range(500):
        await RisingEdge(dut.clk)

        current_value = int(dut.uo_out.value)
        if current_value != prev_value and current_value != 0:
            gpio_values.append(current_value)
            prev_value = current_value

        # Check if CPU has halted
        halted = int(dut.uio_out.value) & 0x01
        if halted:
            break
    else:
        assert False, "CPU did not halt within 500 cycles"

    # Verify the halted signal
    assert (int(dut.uio_out.value) & 0x01) == 1, "Expected halted signal on uio_out[0]"

    # Verify the GPIO output sequence
    assert gpio_values == [1, 2, 3, 4, 5], f"Expected GPIO sequence [1,2,3,4,5], got {gpio_values}"


@cocotb.test()
async def test_final_output(dut):
    """Verify the final GPIO output value is 5 after the program completes."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_cpu(dut)

    # Wait for halt
    for _ in range(500):
        await RisingEdge(dut.clk)
        if int(dut.uio_out.value) & 0x01:
            break

    # The last value output before the final SUB was 5
    # After SUB 6 (acc becomes 0) and JZ to halt, gpio_out should still hold 5
    # because the OUT instruction latches into the GPIO register
    assert int(dut.uo_out.value) == 5, f"Expected final gpio_out=5, got {int(dut.uo_out.value)}"
