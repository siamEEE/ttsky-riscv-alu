## How it works

This project implements a 32-bit RISC-V arithmetic logic unit with
four clock-gated functional domains: arithmetic/compare, logic,
shift, and miscellaneous operations.

Because Tiny Tapeout provides an 8-bit dedicated input bus, operands
are transferred into 32-bit input registers one byte at a time.

The Tiny Tapeout wrapper does not modify the internal ALU datapath.
It only provides a byte-oriented transport interface around the
original 32-bit ALU core.

The ALU uses SKY130 integrated clock-gating cells to suppress clock
activity in functional domains that are not selected by the current
operation.

## How to test

Operand A and operand B are loaded one byte at a time through ui_in.

uio_in selects whether the byte is written to operand A, operand B,
the ALU opcode register, or the output selector.

After an operation is selected, the 32-bit result can be read one
byte at a time through uo_out.

The automated Cocotb testbench verifies ALU behavior both at RTL and
after gate-level implementation.

## External hardware

None.
