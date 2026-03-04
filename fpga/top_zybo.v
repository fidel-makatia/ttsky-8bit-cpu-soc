// ============================================================================
// FPGA Top-Level Wrapper for Zybo Z7-010 (Comprehensive Test Mode)
// ============================================================================
// LED0-LED3 = gpio_out[3:0] showing test phase numbers 1-F
// BTN0      = Reset (press to restart test sequence)
// CPU clock = ~4 Hz (each test step visible for ~1 second)
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

    // ---- Clock divider: 125 MHz → ~4 Hz for visible test stepping ----
    // 125_000_000 / (2 * 15_625_000) = 4 Hz
    // Each instruction (3 cycles) takes ~0.75 seconds → clearly visible

    localparam CLK_DIV = 15_625_000;

    reg [23:0] clk_cnt = 24'd0;
    reg        clk_slow = 1'b0;

    always @(posedge sys_clk) begin
        if (clk_cnt == CLK_DIV - 1) begin
            clk_cnt  <= 24'd0;
            clk_slow <= ~clk_slow;
        end else begin
            clk_cnt <= clk_cnt + 24'd1;
        end
    end

    // ---- Power-on reset ----
    // Hold rst_n low for first 8 slow clock cycles after FPGA configuration.
    // This ensures all CPU registers are properly initialized via async reset.

    reg [3:0] por_cnt = 4'd0;
    wire      por_done = por_cnt[3];   // High after 8 slow clocks (~2 sec)

    always @(posedge clk_slow) begin
        if (!por_done)
            por_cnt <= por_cnt + 4'd1;
    end

    // ---- Reset debouncer ----
    // BTN0 is active-high. Sample with shift register clocked at slow clock.
    // Reset asserted (rst_n=0) when all 4 samples show button pressed.

    reg [3:0] btn_shift = 4'b0000;

    always @(posedge clk_slow)
        btn_shift <= {btn_shift[2:0], btn0};

    // rst_n low during power-on OR when button held
    wire rst_n = por_done & ~(&btn_shift);

    // ---- SoC instance ----

    wire [7:0] gpio_out;
    wire       uart_tx_out;
    wire       halted;

    soc_top u_soc (
        .clk         (clk_slow),
        .rst_n       (rst_n),
        .gpio_out    (gpio_out),
        .gpio_in     ({4'b0000, sw}),   // Upper 4 bits tied low
        .uart_tx_out (uart_tx_out),
        .halted      (halted)
    );

    // ---- Output mapping ----

    assign led        = gpio_out[3:0];  // All 4 LEDs show test phase number
    assign ja_upper   = gpio_out[7:4];  // PMOD JA pins 1-4
    assign ja_uart_tx = uart_tx_out;    // PMOD JA pin 7
    assign ja_halted  = halted;         // PMOD JA pin 8

endmodule
