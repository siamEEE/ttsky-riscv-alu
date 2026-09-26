`include "alu_pkg.vh"

module alu_addsub #(
    parameter ADDER_STYLE = `ADDER_BEHAVIORAL
) (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire        sub,
    output wire [31:0] result,
    output wire        carry_flag,
    output wire        overflow_flag
);
    wire [31:0] b_effective;
    wire        adder_cout;

    assign b_effective = b ^ {32{sub}};

    adder_select_32 #(.ADDER_STYLE(ADDER_STYLE)) u_adder (
        .a(a),
        .b(b_effective),
        .cin(sub),
        .sum(result),
        .cout(adder_cout)
    );

    // ADD: carry_flag is carry-out.
    // SUB: carry_flag is borrow, so invert the no-borrow carry-out.
    assign carry_flag = sub ? ~adder_cout : adder_cout;

    assign overflow_flag = sub ?
        ((a[31] ^ b[31]) & (result[31] ^ a[31])) :
        (~(a[31] ^ b[31]) & (result[31] ^ a[31]));
endmodule
