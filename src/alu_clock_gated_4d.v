module alu_clock_gated_4d (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        scan_en,
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  alu_op,

    output wire [31:0] result,
    output wire        flag_zero,
    output wire        flag_negative,
    output wire        flag_carry,
    output wire        flag_overflow
);

    wire [3:0] unit_en;

    wire gclk_arithcmp;
    wire gclk_logic;
    wire gclk_shift;
    wire gclk_misc;

    /*
     * Four gated clock domains.
     */
    icg_cell icg_ac (
        .clk(clk),
        .en(unit_en[0]),
        .te(scan_en),
        .gclk(gclk_arithcmp)
    );

    icg_cell icg_l (
        .clk(clk),
        .en(unit_en[1]),
        .te(scan_en),
        .gclk(gclk_logic)
    );

    icg_cell icg_s (
        .clk(clk),
        .en(unit_en[2]),
        .te(scan_en),
        .gclk(gclk_shift)
    );

    icg_cell icg_m (
        .clk(clk),
        .en(unit_en[3]),
        .te(scan_en),
        .gclk(gclk_misc)
    );

    alu_partitioned_datapath_4d u_datapath (
        .clk(clk),

        .clk_arithcmp(gclk_arithcmp),
        .clk_logic(gclk_logic),
        .clk_shift(gclk_shift),
        .clk_misc(gclk_misc),

        .rst_n(rst_n),

        .operand_a(operand_a),
        .operand_b(operand_b),
        .alu_op(alu_op),

        .unit_en(unit_en),

        .result(result),
        .flag_zero(flag_zero),
        .flag_negative(flag_negative),
        .flag_carry(flag_carry),
        .flag_overflow(flag_overflow)
    );

endmodule
