// ============================================================================
// TinyTapeout Wrapper - 8-bit Accumulator CPU SoC
// ============================================================================
// Wraps the soc_top module for TinyTapeout submission.
//
// Pin Mapping:
//   ui_in[7:0]   -> gpio_in[7:0]   (dedicated inputs)
//   uo_out[7:0]  -> gpio_out[7:0]  (dedicated outputs)
//   uio_out[0]   -> halted         (CPU halt status)
//   uio_oe       -> 8'h01          (bit 0 output, rest inputs)
// ============================================================================

module tt_um_fidel_makatia_digital_tapeout (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       ena,
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe
);

    wire       halted;
    wire [7:0] gpio_out_internal;

    soc_top u_soc (
        .clk      (clk),
        .rst_n    (rst_n & ena),
        .gpio_out (gpio_out_internal),
        .gpio_in  (ui_in),
        .halted   (halted)
    );

    assign uo_out  = gpio_out_internal;
    assign uio_out = {7'b0, halted};
    assign uio_oe  = 8'h01;

endmodule
