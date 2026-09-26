import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


CMD_LOAD_A  = 0b000
CMD_LOAD_B  = 0b001
CMD_LOAD_OP = 0b010
CMD_SET_OUT = 0b011

ALU_XOR = 0b0100


async def command(dut, cmd, data=0, index=0, outsel=0):
    dut.ui_in.value = data

    control = cmd

    if cmd in (CMD_LOAD_A, CMD_LOAD_B):
        control |= (index & 0x3) << 3

    if cmd == CMD_SET_OUT:
        control |= (outsel & 0x7) << 3

    dut.uio_in.value = control

    await ClockCycles(dut.clk, 1)


async def load_operand(dut, cmd, value):
    for byte_index in range(4):
        byte_value = (value >> (8 * byte_index)) & 0xFF

        await command(
            dut,
            cmd,
            data=byte_value,
            index=byte_index
        )


async def read_result(dut):

    value = 0

    for byte_index in range(4):

        await command(
            dut,
            CMD_SET_OUT,
            outsel=byte_index
        )

        await ClockCycles(dut.clk, 1)

        byte_value = int(dut.uo_out.value)

        value |= byte_value << (8 * byte_index)

    return value


@cocotb.test()
async def test_xor(dut):

    dut._log.info("Starting RV32I ALU Tiny Tapeout wrapper test")

    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)

    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    a = 0x12345678
    b = 0x0F0F00FF

    await load_operand(dut, CMD_LOAD_A, a)
    await load_operand(dut, CMD_LOAD_B, b)

    # Load XOR opcode.
    await command(
        dut,
        CMD_LOAD_OP,
        data=ALU_XOR
    )

    # Loading the opcode occurs on a clock edge.
    # Give the gated ALU domain subsequent clock edges to update.
    await ClockCycles(dut.clk, 3)

    result = await read_result(dut)

    expected = (a ^ b) & 0xFFFFFFFF

    dut._log.info(
        f"A        = 0x{a:08X}"
    )

    dut._log.info(
        f"B        = 0x{b:08X}"
    )

    dut._log.info(
        f"result   = 0x{result:08X}"
    )

    dut._log.info(
        f"expected = 0x{expected:08X}"
    )

    assert result == expected
