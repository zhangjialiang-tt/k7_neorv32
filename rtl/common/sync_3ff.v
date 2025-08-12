// -----------------------------------------------------------------------------
// Module: sync_3ff
// Description: Generic three-flip-flop synchroniser for single-bit control
//              signals crossing an asynchronous clock domain.  The extra
//              register stage improves MTBF compared with a two-stage scheme.
//              Parameterisable reset value so this can be used for either
//              active-high or active-low signals.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module sync_3ff #(
    parameter RESET_VALUE = 1'b0  // value after reset (normally 0)
) (
    input  wire clk,   // destination clock domain
    input  wire rst_n, // active-low asynchronous reset for destination domain
    input  wire din,   // asynchronous input signal
    output wire dout   // synchronised output signal (1-clk latency)
);

    // ---------------------------------------------------------------------
    // Three-stage flip-flop chain
    // ---------------------------------------------------------------------
    reg sync_ff1;
    reg sync_ff2;
    reg sync_ff3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= RESET_VALUE;
            sync_ff2 <= RESET_VALUE;
            sync_ff3 <= RESET_VALUE;
        end else begin
            sync_ff1 <= din;
            sync_ff2 <= sync_ff1;
            sync_ff3 <= sync_ff2;
        end
    end

    assign dout = sync_ff3;

endmodule
