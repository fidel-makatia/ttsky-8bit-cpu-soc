// ============================================================================
// SoC Top-Level - 8-bit Accumulator Microcontroller
// ============================================================================
// Top-level SoC module for TinyTapeout integration.
//
// Integrates: CPU Control, ALU, Register File, Program ROM, GPIO
//
// External Ports:
//   clk         - System clock (target: <= 5 MHz for SKY130)
//   rst_n       - Active-low synchronous reset
//   gpio_out    - 8-bit output port
//   gpio_in     - 8-bit input port
//   halted      - CPU halt status indicator
// ============================================================================

module soc_top (
    input  wire        clk,
    input  wire        rst_n,
    output wire [7:0]  gpio_out,
    input  wire [7:0]  gpio_in,
    output wire        halted
);

    // ---- Internal wires ----

    // Program ROM
    wire [7:0]  pc;
    wire [15:0] instruction;

    // ALU
    wire [7:0]  alu_a;
    wire [7:0]  alu_b;
    wire [3:0]  alu_op;
    wire [7:0]  alu_result;
    wire        alu_zero;
    wire        alu_carry;

    // Data Memory
    wire [7:0]  mem_addr;
    wire [7:0]  mem_wdata;
    wire        mem_we;
    wire [7:0]  mem_rdata;

    // GPIO internal
    wire [7:0]  gpio_data_to_cpu;
    wire [7:0]  gpio_data_from_cpu;
    wire        gpio_write_en;

    // ---- Program ROM ----
    program_rom u_rom (
        .addr   (pc),
        .data   (instruction)
    );

    // ---- Control Unit (CPU FSM) ----
    control u_ctrl (
        .clk         (clk),
        .rst_n       (rst_n),
        .pc          (pc),
        .instruction (instruction),
        .alu_a       (alu_a),
        .alu_b       (alu_b),
        .alu_op      (alu_op),
        .alu_result  (alu_result),
        .alu_zero    (alu_zero),
        .alu_carry   (alu_carry),
        .mem_addr    (mem_addr),
        .mem_wdata   (mem_wdata),
        .mem_we      (mem_we),
        .mem_rdata   (mem_rdata),
        .gpio_out    (gpio_data_from_cpu),
        .gpio_out_en (gpio_write_en),
        .gpio_in     (gpio_data_to_cpu),
        .halted      (halted)
    );

    // ---- ALU ----
    alu u_alu (
        .a          (alu_a),
        .b          (alu_b),
        .alu_op     (alu_op),
        .result     (alu_result),
        .zero_flag  (alu_zero),
        .carry_flag (alu_carry)
    );

    // ---- Data Memory (Register File) ----
    regfile u_regfile (
        .clk    (clk),
        .rst_n  (rst_n),
        .we     (mem_we),
        .addr   (mem_addr),
        .wdata  (mem_wdata),
        .rdata  (mem_rdata)
    );

    // ---- GPIO ----
    gpio u_gpio (
        .clk           (clk),
        .rst_n         (rst_n),
        .data_in       (gpio_data_from_cpu),
        .write_en      (gpio_write_en),
        .data_out      (gpio_data_to_cpu),
        .gpio_pins_out (gpio_out),
        .gpio_pins_in  (gpio_in)
    );

endmodule
