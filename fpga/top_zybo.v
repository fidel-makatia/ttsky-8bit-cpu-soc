// ============================================================================
// FPGA Top-Level Wrapper for Zybo Z7-010
// ============================================================================
// Maps the 8-bit CPU SoC onto the Zybo Z7-010 board:
//
//   125 MHz on-board clock → 5 MHz divided clock for SoC
//   BTN0                   → Reset (debounced, active-high → active-low)
//   LED0-LED3              → gpio_out[3:0]
//   SW0-SW3                → gpio_in[3:0]
//   PMOD JA[3:0]           → gpio_out[7:4]
//   PMOD JA pin 7          → UART TX
//   PMOD JA pin 8          → Halted indicator
// ============================================================================

module top_zybo (
    // 125 MHz system clock
    input  wire       sys_clk,

    // Push button (active-high, directly active on press)
    input  wire       btn0,

    // On-board LEDs
    output wire [3:0] led,

    // On-board slide switches
    input  wire [3:0] sw,

    // PMOD JA header
    output wire [3:0] ja_upper,   // gpio_out[7:4]
    output wire       ja_uart_tx, // UART TX
    output wire       ja_halted   // Halt indicator
);

    // ---- Clock divider: 125 MHz → 5 MHz ----
    // Divide by 25: count 0-24, output high for 13 cycles, low for 12
    // Frequency = 125 MHz / 25 = 5 MHz (52% duty cycle)

    reg [4:0] clk_cnt = 5'd0;
    reg       clk_5mhz = 1'b0;

    always @(posedge sys_clk) begin
        if (clk_cnt == 5'd24)
            clk_cnt <= 5'd0;
        else
            clk_cnt <= clk_cnt + 5'd1;

        clk_5mhz <= (clk_cnt < 5'd13);
    end

    // ---- Reset debouncer ----
    // BTN0 is active-high and noisy. Sample it with a shift register
    // clocked at 5 MHz. Reset is asserted (rst_n=0) when all 4 samples
    // show the button pressed.

    reg [3:0] btn_shift = 4'b0000;

    always @(posedge clk_5mhz)
        btn_shift <= {btn_shift[2:0], btn0};

    wire rst_n = ~(&btn_shift);  // Active-low: 0 when all 4 samples are 1

    // ---- SoC instance ----

    wire [7:0] gpio_out;
    wire       uart_tx_out;
    wire       halted;

    soc_top u_soc (
        .clk         (clk_5mhz),
        .rst_n       (rst_n),
        .gpio_out    (gpio_out),
        .gpio_in     ({4'b0000, sw}),   // Upper 4 bits tied low
        .uart_tx_out (uart_tx_out),
        .halted      (halted)
    );

    // ---- Output mapping ----

    assign led       = gpio_out[3:0];  // On-board LEDs
    assign ja_upper  = gpio_out[7:4];  // PMOD JA pins 1-4
    assign ja_uart_tx = uart_tx_out;   // PMOD JA pin 7
    assign ja_halted  = halted;        // PMOD JA pin 8

endmodule
