`include "alu_pkg.vh"

module alu_decode (
    input  wire [3:0]  alu_op,
    output reg  [13:0] op_sel,
    output wire [4:0]  unit_en,
    output wire        valid_op
);
    always @(*) begin
        op_sel = 14'b0;
        case (alu_op)
            `ALU_ADD:  op_sel[`ALU_ADD]  = 1'b1;
            `ALU_SUB:  op_sel[`ALU_SUB]  = 1'b1;
            `ALU_AND:  op_sel[`ALU_AND]  = 1'b1;
            `ALU_OR:   op_sel[`ALU_OR]   = 1'b1;
            `ALU_XOR:  op_sel[`ALU_XOR]  = 1'b1;
            `ALU_SLT:  op_sel[`ALU_SLT]  = 1'b1;
            `ALU_SLL:  op_sel[`ALU_SLL]  = 1'b1;
            `ALU_SRL:  op_sel[`ALU_SRL]  = 1'b1;
            `ALU_SRA:  op_sel[`ALU_SRA]  = 1'b1;
            `ALU_SLTU: op_sel[`ALU_SLTU] = 1'b1;
            `ALU_NOR:  op_sel[`ALU_NOR]  = 1'b1;
            `ALU_XNOR: op_sel[`ALU_XNOR] = 1'b1;
            `ALU_PASS: op_sel[`ALU_PASS] = 1'b1;
            `ALU_CLZ:  op_sel[`ALU_CLZ]  = 1'b1;
            default:   op_sel = 14'b0;
        endcase
    end

    assign unit_en[0] = op_sel[`ALU_ADD] | op_sel[`ALU_SUB];
    assign unit_en[1] = op_sel[`ALU_AND] | op_sel[`ALU_OR] |
                        op_sel[`ALU_XOR] | op_sel[`ALU_NOR] |
                        op_sel[`ALU_XNOR];
    assign unit_en[2] = op_sel[`ALU_SLL] | op_sel[`ALU_SRL] |
                        op_sel[`ALU_SRA];
    assign unit_en[3] = op_sel[`ALU_SLT] | op_sel[`ALU_SLTU];
    assign unit_en[4] = op_sel[`ALU_PASS] | op_sel[`ALU_CLZ];
    assign valid_op   = |op_sel;
endmodule
