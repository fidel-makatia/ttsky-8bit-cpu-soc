// ============================================================================
// Timer Module - 8-bit Free-Running Counter with Prescaler
// ============================================================================
// The prescaler divides the system clock. The main counter increments
// every (prescaler + 1) clock cycles. Both are software-controllable.
//
// Interface:
//   prescaler_we + prescaler_in -> set prescaler value (TSET instruction)
//   timer_clear                 -> reset count to 0    (TCLR instruction)
//   count                       -> read current count  (TGET instruction)
// ============================================================================

module timer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  prescaler_in,   // Prescaler value from CPU
    input  wire        prescaler_we,   // Write enable for prescaler
    input  wire        timer_clear,    // Clear/reset counter
    output reg  [7:0]  count           // Current timer count
);

    reg [7:0] prescaler;
    reg [7:0] prescale_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescaler    <= 8'h00;
            prescale_cnt <= 8'h00;
            count        <= 8'h00;
        end else begin
            if (prescaler_we)
                prescaler <= prescaler_in;

            if (timer_clear) begin
                count        <= 8'h00;
                prescale_cnt <= 8'h00;
            end else if (prescale_cnt == prescaler) begin
                prescale_cnt <= 8'h00;
                count        <= count + 8'd1;
            end else begin
                prescale_cnt <= prescale_cnt + 8'd1;
            end
        end
    end

endmodule
