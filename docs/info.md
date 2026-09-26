## How it works

This test design implements an 8-bit combinational adder.

The dedicated input bus `ui_in` provides operand A and the
bidirectional input bus `uio_in` provides operand B.

The lower eight bits of A + B are presented on `uo_out`.

The bidirectional pins are configured as inputs.

## How to test

Apply an 8-bit value to `ui_in` and another 8-bit value to `uio_in`.

The resulting sum appears on `uo_out`.

For example:

- A = 20
- B = 30
- Output = 50

## External hardware

None.
