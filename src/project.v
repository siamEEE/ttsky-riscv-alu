/*
 * Tiny Tapeout wrapper for the 32-bit clock-gated RV32I ALU
 *
 * ui_in[7:0]   : byte data input
 *
 * uio_in[2:0]  : command
 * uio_in[4:3]  : byte index for A/B
 * uio_in[5:3]  : output selector for SET_OUT
 *
 * Commands:
 *   000 = load byte of operand A
 *   001 = load byte of operand B
 *   010 = load ALU opcode from ui_in[3:0]
 *   011 = set output selector from uio_in[5:3]
 *
 * Output selector:
 *   000 = result[7:0]
 *   001 = result[15:8]
 *   010 = result[23:16]
 *   011 = result[31:24]
 *   100 = flags
 */

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

    localparam CMD_LOAD_A  = 3'b000;
    localparam CMD_LOAD_B  = 3'b001;
    localparam CMD_LOAD_OP = 3'b010;
    localparam CMD_SET_OUT = 3'b011;

    reg [31:0] operand_a_reg;
    reg [31:0] operand_b_reg;
    reg [3:0]  alu_op_reg;
    reg [2:0]  output_sel;

    wire [31:0] alu_result;

    wire flag_zero;
    wire flag_negative;
    wire flag_carry;
    wire flag_overflow;

    /*
     * Tiny Tapeout interface registers.
     *
     * byte index:
     *   00 -> [7:0]
     *   01 -> [15:8]
     *   10 -> [23:16]
     *   11 -> [31:24]
     */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            operand_a_reg <= 32'b0;
            operand_b_reg <= 32'b0;
            alu_op_reg    <= 4'b0;
            output_sel    <= 3'b0;
        end
        else begin

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
                    alu_op_reg <= ui_in[3:0];
                end

                CMD_SET_OUT: begin
                    output_sel <= uio_in[5:3];
                end

                default: begin
                    // Hold state.
                end

            endcase
        end
    end


    /*
     * Original ALU core.
     *
     * scan_en remains disabled during normal Tiny Tapeout operation.
     */
    alu_clock_gated_4d u_alu (
        .clk           (clk),
        .rst_n         (rst_n),
        .scan_en       (1'b0),

        .operand_a     (operand_a_reg),
        .operand_b     (operand_b_reg),
        .alu_op        (alu_op_reg),

        .result        (alu_result),
        .flag_zero     (flag_zero),
        .flag_negative (flag_negative),
        .flag_carry    (flag_carry),
        .flag_overflow (flag_overflow)
    );


    /*
     * Byte-wise output multiplexer.
     */
    always @(*) begin
        case (output_sel)

            3'b000:
                uo_out = alu_result[7:0];

            3'b001:
                uo_out = alu_result[15:8];

            3'b010:
                uo_out = alu_result[23:16];

            3'b011:
                uo_out = alu_result[31:24];

            3'b100:
                uo_out = {
                    4'b0000,
                    flag_overflow,
                    flag_carry,
                    flag_negative,
                    flag_zero
                };

            default:
                uo_out = 8'b0;

        endcase
    end


    /*
     * uio pins are inputs only for this interface.
     */
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    /*
     * ena is supplied by Tiny Tapeout but is not required by the core.
     */
    wire _unused = &{ena, uio_in[7:6], 1'b0};

endmodule

`default_nettype wire
