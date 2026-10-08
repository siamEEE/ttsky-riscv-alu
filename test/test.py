import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

CMD_LOAD_A  = 0b000
CMD_LOAD_B  = 0b001
CMD_LOAD_OP = 0b010
CMD_SET_OUT = 0b011

MASK32 = 0xFFFFFFFF

OPS = {
    0b000: lambda a, b: (a + b) & MASK32,
    0b001: lambda a, b: (a - b) & MASK32,
    0b010: lambda a, b: (a + 1) & MASK32,
    0b011: lambda a, b: (a - 1) & MASK32,
    0b100: lambda a, b: a & b,
    0b101: lambda a, b: a | b,
    0b110: lambda a, b: a ^ b,
    0b111: lambda a, b: (~a) & MASK32,
}


async def command(dut, cmd, data=0, index=0):
    dut.ui_in.value = data & 0xFF
    dut.uio_in.value = (cmd & 0x7) | ((index & 0x3) << 3)
    await ClockCycles(dut.clk, 1)


async def load_operand(dut, cmd, value):
    for index in range(4):
        await command(dut, cmd, (value >> (8 * index)) & 0xFF, index)


async def set_opcode(dut, opcode):
    await command(dut, CMD_LOAD_OP, opcode & 0x7)


async def read_result(dut):
    value = 0
    for index in range(4):
        await command(dut, CMD_SET_OUT, index=index)
        await Timer(1, unit="ns")
        value |= int(dut.uo_out.value) << (8 * index)
    return value & MASK32


async def run_case(dut, a, b, opcode):
    await load_operand(dut, CMD_LOAD_A, a)
    await load_operand(dut, CMD_LOAD_B, b)
    await set_opcode(dut, opcode)
    result = await read_result(dut)
    expected = OPS[opcode](a, b) & MASK32
    assert result == expected, (
        f"opcode={opcode:03b} A=0x{a:08X} B=0x{b:08X} "
        f"got=0x{result:08X} expected=0x{expected:08X}"
    )


@cocotb.test()
async def test_all_operations(dut):
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    directed = [
        (0x00000000, 0x00000000),
        (0x00000001, 0x00000001),
        (0xFFFFFFFF, 0x00000001),
        (0x80000000, 0x7FFFFFFF),
        (0x12345678, 0x0F0F00FF),
        (0xAAAAAAAA, 0x55555555),
    ]

    for opcode in range(8):
        for a, b in directed:
            await run_case(dut, a, b, opcode)

    random.seed(26)
    for _ in range(64):
        a = random.getrandbits(32)
        b = random.getrandbits(32)
        opcode = random.randrange(8)
        await run_case(dut, a, b, opcode)


@cocotb.test()
async def test_enable_holds_state(dut):
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 1
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    await load_operand(dut, CMD_LOAD_A, 0x12345678)
    await load_operand(dut, CMD_LOAD_B, 0x01020304)
    await set_opcode(dut, 0b000)
    before = await read_result(dut)

    dut.ena.value = 0
    await load_operand(dut, CMD_LOAD_A, 0xFFFFFFFF)
    await load_operand(dut, CMD_LOAD_B, 0xFFFFFFFF)
    await set_opcode(dut, 0b111)

    dut.ena.value = 1
    after = await read_result(dut)

    assert before == 0x1336597C
    assert after == before
