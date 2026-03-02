// ============================================================================
// GPIO Module - General Purpose Input/Output
// ============================================================================
// This module is STUDENT-MODIFIABLE.
// Students can add output processing, LED patterns, etc.
//
// Directly maps 8-bit input and output ports.
// gpio_out is directly accessible from the CPU via the OUT instruction.
// gpio_in is read by the CPU via the IN instruction.
// ============================================================================

module gpio (
    input  wire        clk,
    input  wire        rst_n,

    // CPU interface
    input  wire [7:0]  data_in,    // Data from CPU (accumulator)
    input  wire        write_en,   // Write enable from CPU (OUT instruction)
    output wire [7:0]  data_out,   // Data to CPU (IN instruction)

    // External pins
    output reg  [7:0]  gpio_pins_out,  // Output pins to outside world
    input  wire [7:0]  gpio_pins_in    // Input pins from outside world
);

    // Output register - latches data when CPU writes
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_pins_out <= 8'h00;
        end else if (write_en) begin
            gpio_pins_out <= data_in;
        end
    end

    // Input is directly passed through (no latching, synchronous read by CPU)
    assign data_out = gpio_pins_in;

endmodule
