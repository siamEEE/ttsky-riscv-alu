`default_nettype none

module tt_um_siameee_riscv_alu (
    input  wire [7:0] ui_in,
    output reg  [7:0] uo_out,

    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,

    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Tiny Tapeout command encoding:
    // 000 = load one byte of operand A
    // 001 = load one byte of operand B
    // 010 = load 3-bit ALU opcode from ui_in[2:0]
    // 011 = select one result byte for uo_out

    localparam CMD_LOAD_A  = 3'b000;
    localparam CMD_LOAD_B  = 3'b001;
    localparam CMD_LOAD_OP = 3'b010;
    localparam CMD_SET_OUT = 3'b011;

    reg [31:0] operand_a_reg;
    reg [31:0] operand_b_reg;
    reg [2:0]  opcode_reg;
    reg [1:0]  output_sel;

    wire [31:0] alu_result;

    // uio_in[4:3] selects one of four bytes.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            operand_a_reg <= 32'b0;
            operand_b_reg <= 32'b0;
            opcode_reg    <= 3'b000;
            output_sel    <= 2'b00;
        end else if (ena) begin
            case (uio_in[2:0])
                CMD_LOAD_A: begin
                    case (uio_in[4:3])
                        2'b00: operand_a_reg[7:0]   <= ui_in;
                        2'b01: operand_a_reg[15:8]  <= ui_in;
                        2'b10: operand_a_reg[23:16] <= ui_in;
                        2'b11: operand_a_reg[31:24] <= ui_in;
                    endcase
                end

                CMD_LOAD_B: begin
                    case (uio_in[4:3])
                        2'b00: operand_b_reg[7:0]   <= ui_in;
                        2'b01: operand_b_reg[15:8]  <= ui_in;
                        2'b10: operand_b_reg[23:16] <= ui_in;
                        2'b11: operand_b_reg[31:24] <= ui_in;
                    endcase
                end

                CMD_LOAD_OP: begin
                    opcode_reg <= ui_in[2:0];
                end

                CMD_SET_OUT: begin
                    output_sel <= uio_in[4:3];
                end

                default: begin
                    // Hold state.
                end
            endcase
        end
    end

    alu_core u_alu (
        .a      (operand_a_reg),
        .b      (operand_b_reg),
        .opcode (opcode_reg),
        .result (alu_result)
    );

    always @(*) begin
        case (output_sel)
            2'b00: uo_out = alu_result[7:0];
            2'b01: uo_out = alu_result[15:8];
            2'b10: uo_out = alu_result[23:16];
            2'b11: uo_out = alu_result[31:24];
        endcase
    end

    // Bidirectional pins are inputs only in this design.
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // uio_in[7:5] are intentionally unused.
    wire _unused = &{uio_in[7:5], 1'b0};

endmodule

`default_nettype wire
