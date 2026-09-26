## How it works

This project implements a 32-bit RISC-V arithmetic logic unit with four
clock-gated functional domains.

The four domains group arithmetic/comparison, logical, shift, and
miscellaneous operations. SKY130 integrated clock-gating cells suppress
clock activity in functional domains that are not required by the
currently selected ALU operation.

Tiny Tapeout provides an 8-bit dedicated input bus, so the 32-bit
operands are transferred into internal registers one byte at a time.

The Tiny Tapeout wrapper does not change the internal 32-bit ALU
datapath. It provides a byte-oriented interface around the original ALU.

The result is also read one byte at a time through the 8-bit output bus.

## How to test

The command field is carried on uio_in[2:0].

Command 000 loads one byte of operand A.

Command 001 loads one byte of operand B.

For operand loading, uio_in[4:3] selects the byte position:

00 selects bits 7:0.

01 selects bits 15:8.

10 selects bits 23:16.

11 selects bits 31:24.

Command 010 loads the ALU operation code from ui_in[3:0].

Command 011 selects which output byte is presented on uo_out.
uio_in[5:3] selects the output:

000 selects result bits 7:0.

001 selects result bits 15:8.

010 selects result bits 23:16.

011 selects result bits 31:24.

100 selects the ALU status flags.

The Cocotb testbench loads two 32-bit operands, performs an XOR
operation, reconstructs the 32-bit result from the four output bytes,
and compares the hardware result with the expected value.

The same testbench is used for the Tiny Tapeout RTL and gate-level tests.

## External hardware

None.
