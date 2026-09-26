/*
 * SKY130 integrated clock-gating wrapper.
 *
 * RTL simulation:
 *   use a latch-based behavioral ICG model.
 *
 * Synthesis / physical design:
 *   instantiate the real SKY130 ICG cell.
 */

(* blackbox *)
module sky130_fd_sc_hd__sdlclkp_1 (
    input  wire CLK,
    input  wire GATE,
    input  wire SCE,
    output wire GCLK
);
endmodule


module icg_cell (
    input  wire clk,
    input  wire en,
    input  wire te,
    output wire gclk
);

`ifdef COCOTB_SIM

    /*
     * Functional model of an integrated clock-gating cell.
     *
     * The enable is captured while the clock is LOW and held
     * stable while the clock is HIGH. This avoids runt pulses.
     */
    reg en_latched;

    always @(clk or en or te) begin
        if (!clk)
            en_latched = en | te;
    end

    assign gclk = clk & en_latched;

`else

    /*
     * Real SKY130 implementation used by synthesis / PnR.
     */
    sky130_fd_sc_hd__sdlclkp_1 u_icg (
        .CLK  (clk),
        .GATE (en),
        .SCE  (te),
        .GCLK (gclk)
    );

`endif

endmodule
