`include "alu_pkg.vh"

module adder_select_32 #(
    parameter ADDER_STYLE = `ADDER_BEHAVIORAL
) (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire        cin,
    output wire [31:0] sum,
    output wire        cout
);
    generate
        if (ADDER_STYLE == `ADDER_BRENT_KUNG) begin : g_bk
            adder_brent_kung_32 u_adder (
                .a(a), .b(b), .cin(cin), .sum(sum), .cout(cout)
            );
        end else if (ADDER_STYLE == `ADDER_HCLA) begin : g_hcla
            adder_hcla_32 u_adder (
                .a(a), .b(b), .cin(cin), .sum(sum), .cout(cout)
            );
        end else if (ADDER_STYLE == `ADDER_CARRY_SEL) begin : g_csla
            adder_carry_select_32 u_adder (
                .a(a), .b(b), .cin(cin), .sum(sum), .cout(cout)
            );
        end else begin : g_behavioral
            adder_behavioral_32 u_adder (
                .a(a), .b(b), .cin(cin), .sum(sum), .cout(cout)
            );
        end
    endgenerate
endmodule
