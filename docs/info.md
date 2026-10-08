## How it works

This project implements a simple 32-bit arithmetic and logic unit with a 3-bit opcode.

The eight operations are:

| Opcode | Operation |
| --- | --- |
| 000 | A + B |
| 001 | A - B |
| 010 | A + 1 |
| 011 | A - 1 |
| 100 | A AND B |
| 101 | A OR B |
| 110 | A XOR B |
| 111 | NOT A |

The ALU core is combinational. The Tiny Tapeout wrapper contains two 32-bit operand registers and a 3-bit opcode register.

Tiny Tapeout provides an 8-bit dedicated input bus, so each 32-bit operand is loaded in four 8-bit transfers. The 32-bit result is read back in four 8-bit slices.

There is no UART, clock gating, operand isolation, custom adder, or processor core in the ASIC.

## How to test

The command is carried on `uio_in[2:0]`:

- `000`: load one byte of operand A
- `001`: load one byte of operand B
- `010`: load the ALU opcode from `ui_in[2:0]`
- `011`: select one result byte for `uo_out`

For operand loading and result selection, `uio_in[4:3]` chooses the byte:

- `00`: bits 7:0
- `01`: bits 15:8
- `10`: bits 23:16
- `11`: bits 31:24

The Cocotb testbench checks every opcode with directed edge cases and randomized 32-bit operands. It also checks that deasserting `ena` prevents interface state from being modified.

The same testbench is used for RTL and gate-level simulation.

## External hardware

None is required for simulation. The fabricated design can be exercised through the Tiny Tapeout development board by driving the input and bidirectional pins and reading `uo_out`.
