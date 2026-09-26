`include "alu_pkg.vh"

module alu_partitioned_datapath_4d (
    input  wire        clk,

    input  wire        clk_arithcmp,
    input  wire        clk_logic,
    input  wire        clk_shift,
    input  wire        clk_misc,

    input  wire        rst_n,
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_op,

    output wire [3:0]  unit_en,

    output wire [31:0] result,
    output wire        flag_zero,
    output wire        flag_negative,
    output wire        flag_carry,
    output wire        flag_overflow
);

    wire [13:0] op_sel;
    wire [4:0]  unit_en_5;
    wire        valid_op_unused;

    reg  [3:0] unit_en_q;

    wire [31:0] arith_result;
    wire        arith_carry;
    wire        arith_overflow;

    reg [31:0] arithcmp_next;
    reg        arithcmp_carry_next;
    reg        arithcmp_overflow_next;

    reg [31:0] logic_next;
    reg [31:0] shift_next;
    reg [31:0] misc_next;

    wire [5:0] clz_count;

    reg [31:0] arithcmp_r;
    reg [31:0] logic_r;
    reg [31:0] shift_r;
    reg [31:0] misc_r;

    reg arithcmp_zero_r;
    reg logic_zero_r;
    reg shift_zero_r;
    reg misc_zero_r;

    reg arithcmp_negative_r;
    reg logic_negative_r;
    reg shift_negative_r;
    reg misc_negative_r;

    reg carry_r;
    reg overflow_r;

    wire [31:0] selected_result;
    wire        selected_zero;
    wire        selected_negative;
    wire        valid_q;

    /*
     * Reuse the existing exact-operation decoder.
     */
    alu_decode u_decode (
        .alu_op(alu_op),
        .op_sel(op_sel),
        .unit_en(unit_en_5),
        .valid_op(valid_op_unused)
    );

    /*
     * Merge the old arithmetic and comparison domains.
     *
     * unit_en[0] = ADD/SUB/SLT/SLTU
     * unit_en[1] = bitwise
     * unit_en[2] = shift
     * unit_en[3] = misc
     */
    assign unit_en[0] = unit_en_5[0] | unit_en_5[3];
    assign unit_en[1] = unit_en_5[1];
    assign unit_en[2] = unit_en_5[2];
    assign unit_en[3] = unit_en_5[4];

    /*
     * Register which domain captured the current operation.
     */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            unit_en_q <= 4'b0;
        else
            unit_en_q <= unit_en;
    end

    /*
     * Shared ADD/SUB datapath, unchanged.
     */
    alu_addsub #(
        .ADDER_STYLE(`ADDER_BEHAVIORAL)
    ) u_addsub (
        .a(operand_a),
        .b(operand_b),
        .sub(op_sel[`ALU_SUB]),
        .result(arith_result),
        .carry_flag(arith_carry),
        .overflow_flag(arith_overflow)
    );

    /*
     * Combined arithmetic + comparison domain.
     */
    always @(*) begin
        arithcmp_next          = 32'b0;
        arithcmp_carry_next    = 1'b0;
        arithcmp_overflow_next = 1'b0;

        case (alu_op)

            `ALU_ADD,
            `ALU_SUB: begin
                arithcmp_next          = arith_result;
                arithcmp_carry_next    = arith_carry;
                arithcmp_overflow_next = arith_overflow;
            end

            `ALU_SLT: begin
                arithcmp_next = {
                    31'b0,
                    $signed(operand_a) < $signed(operand_b)
                };
            end

            `ALU_SLTU: begin
                arithcmp_next = {
                    31'b0,
                    operand_a < operand_b
                };
            end

            default: begin
                arithcmp_next          = 32'b0;
                arithcmp_carry_next    = 1'b0;
                arithcmp_overflow_next = 1'b0;
            end
        endcase
    end

    /*
     * Bitwise domain.
     */
    always @(*) begin
        logic_next = 32'b0;

        case (alu_op)
            `ALU_AND:
                logic_next = operand_a & operand_b;

            `ALU_OR:
                logic_next = operand_a | operand_b;

            `ALU_XOR:
                logic_next = operand_a ^ operand_b;

            `ALU_NOR:
                logic_next = ~(operand_a | operand_b);

            `ALU_XNOR:
                logic_next = ~(operand_a ^ operand_b);

            default:
                logic_next = 32'b0;
        endcase
    end

    /*
     * Shift domain.
     */
    always @(*) begin
        shift_next = 32'b0;

        case (alu_op)
            `ALU_SLL:
                shift_next = operand_a << operand_b[4:0];

            `ALU_SRL:
                shift_next = operand_a >> operand_b[4:0];

            `ALU_SRA:
                shift_next =
                    $signed(operand_a) >>> operand_b[4:0];

            default:
                shift_next = 32'b0;
        endcase
    end

    /*
     * Miscellaneous domain.
     */
    clz32_tree u_clz (
        .data(operand_a),
        .count(clz_count)
    );

    always @(*) begin
        misc_next = 32'b0;

        case (alu_op)
            `ALU_PASS:
                misc_next = operand_a;

            `ALU_CLZ:
                misc_next = {26'b0, clz_count};

            default:
                misc_next = 32'b0;
        endcase
    end

    /*
     * Arithmetic + comparison register bank.
     */
    always @(posedge clk_arithcmp or negedge rst_n) begin
        if (!rst_n) begin
            arithcmp_r          <= 32'b0;
            arithcmp_zero_r     <= 1'b1;
            arithcmp_negative_r <= 1'b0;
            carry_r             <= 1'b0;
            overflow_r          <= 1'b0;
        end else begin
            arithcmp_r          <= arithcmp_next;
            arithcmp_zero_r     <= (arithcmp_next == 32'b0);
            arithcmp_negative_r <= arithcmp_next[31];
            carry_r             <= arithcmp_carry_next;
            overflow_r          <= arithcmp_overflow_next;
        end
    end

    /*
     * Bitwise register bank.
     */
    always @(posedge clk_logic or negedge rst_n) begin
        if (!rst_n) begin
            logic_r          <= 32'b0;
            logic_zero_r     <= 1'b1;
            logic_negative_r <= 1'b0;
        end else begin
            logic_r          <= logic_next;
            logic_zero_r     <= (logic_next == 32'b0);
            logic_negative_r <= logic_next[31];
        end
    end

    /*
     * Shift register bank.
     */
    always @(posedge clk_shift or negedge rst_n) begin
        if (!rst_n) begin
            shift_r          <= 32'b0;
            shift_zero_r     <= 1'b1;
            shift_negative_r <= 1'b0;
        end else begin
            shift_r          <= shift_next;
            shift_zero_r     <= (shift_next == 32'b0);
            shift_negative_r <= shift_next[31];
        end
    end

    /*
     * Misc register bank.
     */
    always @(posedge clk_misc or negedge rst_n) begin
        if (!rst_n) begin
            misc_r          <= 32'b0;
            misc_zero_r     <= 1'b1;
            misc_negative_r <= 1'b0;
        end else begin
            misc_r          <= misc_next;
            misc_zero_r     <= (misc_next == 32'b0);
            misc_negative_r <= misc_next[31];
        end
    end

    /*
     * Four-way registered-result selection.
     */
    assign selected_result =
        (arithcmp_r & {32{unit_en_q[0]}}) |
        (logic_r    & {32{unit_en_q[1]}}) |
        (shift_r    & {32{unit_en_q[2]}}) |
        (misc_r     & {32{unit_en_q[3]}});

    assign selected_zero =
        (arithcmp_zero_r & unit_en_q[0]) |
        (logic_zero_r    & unit_en_q[1]) |
        (shift_zero_r    & unit_en_q[2]) |
        (misc_zero_r     & unit_en_q[3]);

    assign selected_negative =
        (arithcmp_negative_r & unit_en_q[0]) |
        (logic_negative_r    & unit_en_q[1]) |
        (shift_negative_r    & unit_en_q[2]) |
        (misc_negative_r     & unit_en_q[3]);

    assign valid_q = |unit_en_q;

    assign result = selected_result;

    assign flag_zero =
        valid_q ? selected_zero : 1'b1;

    assign flag_negative =
        valid_q ? selected_negative : 1'b0;

    /*
     * Carry/overflow only have meaning for ADD/SUB.
     * For comparison operations they were registered as zero.
     */
    assign flag_carry =
        unit_en_q[0] ? carry_r : 1'b0;

    assign flag_overflow =
        unit_en_q[0] ? overflow_r : 1'b0;

endmodule
