import cocotb

from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


# ------------------------------------------------------------
# Tiny Tapeout wrapper commands
# ------------------------------------------------------------

CMD_LOAD_A  = 0b000
CMD_LOAD_B  = 0b001
CMD_LOAD_OP = 0b010
CMD_SET_OUT = 0b011


# ------------------------------------------------------------
# ALU operation
# ------------------------------------------------------------

ALU_XOR = 0b0100


async def command(
    dut,
    cmd,
    data=0,
    index=0,
    outsel=0
):
    """
    Execute one Tiny Tapeout wrapper command.
    """

    dut.ui_in.value = data

    control = cmd

    if cmd in (CMD_LOAD_A, CMD_LOAD_B):

        control |= (index & 0x3) << 3

    elif cmd == CMD_SET_OUT:

        control |= (outsel & 0x7) << 3

    dut.uio_in.value = control

    await ClockCycles(dut.clk, 1)


async def load_operand(
    dut,
    command_code,
    value
):
    """
    Load a 32-bit operand one byte at a time.
    """

    for byte_index in range(4):

        byte_value = (
            value >> (8 * byte_index)
        ) & 0xFF

        await command(
            dut,
            command_code,
            data=byte_value,
            index=byte_index
        )


async def read_result(dut):
    """
    Read four 8-bit output slices and reconstruct
    the complete 32-bit ALU result.
    """

    value = 0

    for byte_index in range(4):

        await command(
            dut,
            CMD_SET_OUT,
            outsel=byte_index
        )

        # Allow combinational propagation.
        await Timer(2, unit="ns")

        byte_value = int(dut.uo_out.value)

        value |= (
            byte_value
            << (8 * byte_index)
        )

    return value


@cocotb.test()
async def test_xor(dut):

    dut._log.info(
        "Starting 32-bit RISC-V ALU Tiny Tapeout test"
    )


    # Match the initial Tiny Tapeout physical constraint:
    # 20 ns = 50 MHz.
    clock = Clock(
        dut.clk,
        20,
        unit="ns"
    )

    cocotb.start_soon(
        clock.start()
    )


    # --------------------------------------------------------
    # Initial state
    # --------------------------------------------------------

    dut.ena.value = 1

    dut.ui_in.value = 0
    dut.uio_in.value = 0


    # --------------------------------------------------------
    # Reset
    # --------------------------------------------------------

    dut.rst_n.value = 0

    await ClockCycles(
        dut.clk,
        5
    )

    dut.rst_n.value = 1

    await ClockCycles(
        dut.clk,
        2
    )


    # --------------------------------------------------------
    # Test operands
    # --------------------------------------------------------

    operand_a = 0x12345678
    operand_b = 0x0F0F00FF


    # --------------------------------------------------------
    # Load A
    # --------------------------------------------------------

    await load_operand(
        dut,
        CMD_LOAD_A,
        operand_a
    )


    # --------------------------------------------------------
    # Load B
    # --------------------------------------------------------

    await load_operand(
        dut,
        CMD_LOAD_B,
        operand_b
    )


    # --------------------------------------------------------
    # Select XOR
    # --------------------------------------------------------

    await command(
        dut,
        CMD_LOAD_OP,
        data=ALU_XOR
    )


    # The four-domain ALU contains registered result banks
    # behind integrated clock-gating cells.
    #
    # Give the selected domain enough subsequent clock edges
    # to capture the requested operation.

    await ClockCycles(
        dut.clk,
        3
    )


    # --------------------------------------------------------
    # Read result
    # --------------------------------------------------------

    result = await read_result(
        dut
    )


    expected = (
        operand_a ^ operand_b
    ) & 0xFFFFFFFF


    dut._log.info(
        f"A        = 0x{operand_a:08X}"
    )

    dut._log.info(
        f"B        = 0x{operand_b:08X}"
    )

    dut._log.info(
        f"result   = 0x{result:08X}"
    )

    dut._log.info(
        f"expected = 0x{expected:08X}"
    )


    assert result == expected, (
        f"XOR mismatch: "
        f"got 0x{result:08X}, "
        f"expected 0x{expected:08X}"
    )
