// ============================================================================
// UART Transmitter - 8-N-1 Serial Output
// ============================================================================
// Sends 8 data bits with no parity and 1 stop bit.
// Baud rate = clk / (16 * (baud_div + 1))
//
// At 5 MHz clock:
//   baud_div = 25  -> ~12,019 baud (~9600 with 25% error, use 32 for 9615)
//   baud_div = 2   -> ~104,166 baud (~115200 approximation)
//
// Interface:
//   data_we + data_in  -> load TX data and start sending (UTXD instruction)
//   baud_div_we + baud_div_in -> set baud rate divisor   (UBRD instruction)
//   tx                 -> serial output pin
//   busy               -> 1 while transmitting           (UTXS reads this)
// ============================================================================

module uart_tx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,       // TX data from CPU
    input  wire        data_we,       // Start transmission
    input  wire [7:0]  baud_div_in,   // Baud rate divisor
    input  wire        baud_div_we,   // Write enable for baud divisor
    output reg         tx,            // Serial output (active low start bit)
    output wire        busy           // Transmitter busy flag
);

    // Baud rate generator
    reg [7:0]  baud_div;
    reg [7:0]  baud_cnt;     // Counts to baud_div
    reg [3:0]  oversample;   // 16x oversampling counter

    // Shift register and state
    reg [9:0]  shift_reg;    // {stop, data[7:0], start}
    reg [3:0]  bit_cnt;      // Bits remaining to send (0 = idle)

    assign busy = (bit_cnt != 4'd0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_div   <= 8'd0;
            baud_cnt   <= 8'd0;
            oversample <= 4'd0;
            shift_reg  <= 10'h3FF;
            bit_cnt    <= 4'd0;
            tx         <= 1'b1;  // Idle high
        end else begin
            // Baud divisor register
            if (baud_div_we)
                baud_div <= baud_div_in;

            // Load new data
            if (data_we && !busy) begin
                shift_reg  <= {1'b1, data_in, 1'b0};  // {stop, data, start}
                bit_cnt    <= 4'd10;
                baud_cnt   <= 8'd0;
                oversample <= 4'd0;
                tx         <= 1'b0;  // Start bit immediately
            end else if (busy) begin
                // Baud rate counter
                if (baud_cnt == baud_div) begin
                    baud_cnt <= 8'd0;
                    if (oversample == 4'd15) begin
                        oversample <= 4'd0;
                        // Shift out next bit
                        shift_reg <= {1'b1, shift_reg[9:1]};
                        bit_cnt   <= bit_cnt - 4'd1;
                        tx        <= shift_reg[1];  // Next bit to output
                    end else begin
                        oversample <= oversample + 4'd1;
                    end
                end else begin
                    baud_cnt <= baud_cnt + 8'd1;
                end
            end else begin
                tx <= 1'b1;  // Idle high
            end
        end
    end

endmodule
