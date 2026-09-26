`default_nettype none

module icg_cell (
    input  wire clk,
    input  wire en,
    input  wire te,
    output wire gclk
);

`ifdef COCOTB_SIM

    /*
     * Behavioral model for RTL simulation.
     *
     * The enable is captured only while clk is low.
     * It therefore remains stable throughout the high
     * phase of the clock.
     */

    reg en_latched;

    always @(clk or en or te) begin
        if (!clk)
            en_latched = en | te;
    end

    assign gclk = clk & en_latched;

`else

    /*
     * Physical implementation.
     *
     * Tiny Tapeout / LibreLane resolves this cell using
     * the SKY130 standard-cell library.
     */

    sky130_fd_sc_hd__sdlclkp_1 u_icg (
        .CLK  (clk),
        .GATE (en),
        .SCE  (te),
        .GCLK (gclk)
    );

`endif

endmodule

`default_nettype wire
