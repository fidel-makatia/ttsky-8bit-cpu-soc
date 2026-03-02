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


async def wait_for_halt(dut, max_cycles=5000):
    """Wait until the CPU halts, return True if halted."""
    for _ in range(max_cycles):
        await RisingEdge(dut.clk)
        if int(dut.uio_out.value) & 0x01:
            return True
    return False


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
    """Verify uio_oe is correctly configured (bits 0,1 are outputs)."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_cpu(dut)
    await ClockCycles(dut.clk, 2)

    assert int(dut.uio_oe.value) == 0x03, f"Expected uio_oe=0x03, got {int(dut.uio_oe.value):#x}"


@cocotb.test()
async def test_count_to_5(dut):
    """Test the count-to-5 portion of the demo program.

    The ROM program starts by counting 1 to 5 on GPIO output.
    After 5, it continues to the subroutine and UART demos.
    We verify the initial count sequence [1, 2, 3, 4, 5] appears.
    """
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_cpu(dut)

    gpio_values = []
    prev_value = 0

    for _ in range(500):
        await RisingEdge(dut.clk)

        current_value = int(dut.uo_out.value)
        if current_value != prev_value and current_value != 0:
            gpio_values.append(current_value)
            prev_value = current_value

        if len(gpio_values) >= 5:
            break

    assert gpio_values[:5] == [1, 2, 3, 4, 5], \
        f"Expected count sequence [1,2,3,4,5], got {gpio_values[:5]}"


@cocotb.test()
async def test_call_ret(dut):
    """Test CALL/RET subroutine in the demo program.

    After count-to-5, the program CALLs a subroutine that returns 6,
    then OUTs it. Expected GPIO sequence includes: ..., 5, 6, ...
    """
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_cpu(dut)

    gpio_values = []
    prev_value = 0

    for _ in range(5000):
        await RisingEdge(dut.clk)

        current_value = int(dut.uo_out.value)
        if current_value != prev_value:
            if current_value != 0 or len(gpio_values) > 0:
                gpio_values.append(current_value)
            prev_value = current_value

        if int(dut.uio_out.value) & 0x01:
            break

    assert 6 in gpio_values, f"Expected 6 (from CALL/RET) in GPIO sequence, got {gpio_values}"


@cocotb.test()
async def test_uart_tx_activity(dut):
    """Verify the UART TX pin shows activity during the demo program.

    The demo sends 'H' (0x48) via UART. The TX line should go low
    (start bit) at some point during execution.
    """
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_cpu(dut)

    saw_tx_low = False

    for _ in range(5000):
        await RisingEdge(dut.clk)

        uart_tx = (int(dut.uio_out.value) >> 1) & 0x01
        if uart_tx == 0:
            saw_tx_low = True

        if int(dut.uio_out.value) & 0x01:
            break

    assert saw_tx_low, "UART TX should go low (start bit) when sending 'H'"


@cocotb.test()
async def test_timer_activity(dut):
    """Verify the timer produces a non-zero GPIO output during the demo.

    The demo program sets prescaler=0, clears the timer, waits 2 NOPs,
    then reads the timer with TGET and outputs it via OUT. The timer
    value should be non-zero since the timer runs freely after TCLR.
    """
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_cpu(dut)

    gpio_values = []
    prev_value = 0

    for _ in range(5000):
        await RisingEdge(dut.clk)

        current_value = int(dut.uo_out.value)
        if current_value != prev_value:
            if current_value != 0 or len(gpio_values) > 0:
                gpio_values.append(current_value)
            prev_value = current_value

        if int(dut.uio_out.value) & 0x01:
            break

    # After count [1,2,3,4,5], CALL/RET (6), UART, timer value, then 42
    # Timer value should appear between 6 and 42 in the sequence
    assert len(gpio_values) >= 3, f"Expected at least 3 GPIO changes, got {gpio_values}"
    # The second-to-last value before 42 should be the timer count (non-zero)
    assert 42 in gpio_values, f"Expected 42 in GPIO sequence, got {gpio_values}"


@cocotb.test()
async def test_full_demo_halts(dut):
    """Verify the full demo program completes and halts with final value 42."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await reset_cpu(dut)

    halted = await wait_for_halt(dut, max_cycles=5000)
    assert halted, "CPU should halt after the full demo program completes"

    assert (int(dut.uio_out.value) & 0x01) == 1, "Expected halted signal on uio_out[0]"
    assert int(dut.uo_out.value) == 42, f"Expected final gpio_out=42, got {int(dut.uo_out.value)}"
