// ============================================================================
// SoC Top-Level - 8-bit Accumulator Microcontroller
// ============================================================================
// Top-level SoC module for TinyTapeout integration.
//
// Integrates: CPU Control, ALU, Register File, Program ROM, GPIO,
//             Hardware Multiplier, Timer, UART TX
//
// External Ports:
//   clk         - System clock (target: <= 5 MHz for SKY130)
//   rst_n       - Active-low synchronous reset
//   gpio_out    - 8-bit output port
//   gpio_in     - 8-bit input port
//   uart_tx_out - UART serial transmit output
//   halted      - CPU halt status indicator
// ============================================================================

module soc_top (
    input  wire        clk,
    input  wire        rst_n,
    output wire [7:0]  gpio_out,
    input  wire [7:0]  gpio_in,
    output wire        uart_tx_out,
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

    // Multiplier
    wire [7:0]  mul_a;
    wire [7:0]  mul_b;
    wire [15:0] mul_product;

    // Timer
    wire [7:0]  timer_prescaler;
    wire        timer_prescaler_we;
    wire        timer_clear;
    wire [7:0]  timer_count;

    // UART TX
    wire [7:0]  uart_data;
    wire        uart_data_we;
    wire [7:0]  uart_baud_div;
    wire        uart_baud_div_we;
    wire        uart_busy;

    // ---- Program ROM ----
    program_rom u_rom (
        .addr   (pc),
        .data   (instruction)
    );

    // ---- Control Unit (CPU FSM) ----
    control u_ctrl (
        .clk              (clk),
        .rst_n            (rst_n),
        .pc               (pc),
        .instruction      (instruction),
        .alu_a            (alu_a),
        .alu_b            (alu_b),
        .alu_op           (alu_op),
        .alu_result       (alu_result),
        .alu_zero         (alu_zero),
        .alu_carry        (alu_carry),
        .mem_addr         (mem_addr),
        .mem_wdata        (mem_wdata),
        .mem_we           (mem_we),
        .mem_rdata        (mem_rdata),
        .gpio_out         (gpio_data_from_cpu),
        .gpio_out_en      (gpio_write_en),
        .gpio_in          (gpio_data_to_cpu),
        .mul_a            (mul_a),
        .mul_b            (mul_b),
        .mul_product      (mul_product),
        .timer_prescaler  (timer_prescaler),
        .timer_prescaler_we (timer_prescaler_we),
        .timer_clear      (timer_clear),
        .timer_count      (timer_count),
        .uart_data        (uart_data),
        .uart_data_we     (uart_data_we),
        .uart_baud_div    (uart_baud_div),
        .uart_baud_div_we (uart_baud_div_we),
        .uart_busy        (uart_busy),
        .halted           (halted)
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

    // ---- Hardware Multiplier ----
    multiplier u_mul (
        .a       (mul_a),
        .b       (mul_b),
        .product (mul_product)
    );

    // ---- Timer ----
    timer u_timer (
        .clk           (clk),
        .rst_n         (rst_n),
        .prescaler_in  (timer_prescaler),
        .prescaler_we  (timer_prescaler_we),
        .timer_clear   (timer_clear),
        .count         (timer_count)
    );

    // ---- UART Transmitter ----
    uart_tx u_uart (
        .clk          (clk),
        .rst_n        (rst_n),
        .data_in      (uart_data),
        .data_we      (uart_data_we),
        .baud_div_in  (uart_baud_div),
        .baud_div_we  (uart_baud_div_we),
        .tx           (uart_tx_out),
        .busy         (uart_busy)
    );

endmodule
