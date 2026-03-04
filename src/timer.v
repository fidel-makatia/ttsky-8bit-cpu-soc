// ============================================================================
// Timer/Counter - 8-bit Free-Running Timer with Prescaler
// ============================================================================
// Counter increments every (prescaler+1) clock cycles.
// Software-readable via TGET, clearable via TCLR, prescaler set via TSET.
// ============================================================================

module timer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  prescaler_in,
    input  wire        prescaler_we,
    input  wire        timer_clear,
    output reg  [7:0]  count
);

    reg [7:0] prescaler;
    reg [7:0] prescale_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescaler      <= 8'h00;
            prescale_count <= 8'h00;
            count          <= 8'h00;
        end else begin
            if (prescaler_we) begin
                prescaler      <= prescaler_in;
                prescale_count <= 8'h00;
            end

            if (timer_clear) begin
                count          <= 8'h00;
                prescale_count <= 8'h00;
            end else if (prescale_count >= prescaler) begin
                prescale_count <= 8'h00;
                count          <= count + 8'h01;
            end else begin
                prescale_count <= prescale_count + 8'h01;
            end
        end
    end

endmodule
