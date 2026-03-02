// ============================================================================
// Control Unit - CPU Finite State Machine
// ============================================================================
// Modified for TinyTapeout: ADDA/SUBA bug fix with MEM_READ state.
//
// 3/4-stage FSM: FETCH -> DECODE -> [MEM_READ] -> EXECUTE (-> FETCH ...)
// MEM_READ stage used only for ADDA/SUBA (memory-to-ALU instructions).
// Special state: HALT stops execution.
//
// Instruction Format (16-bit):
//   [15:8] = opcode
//   [7:0]  = operand (immediate value or address)
//
// Opcode Map:
//   8'h00 : NOP       - No operation
//   8'h01 : LDA imm   - Load immediate into accumulator
//   8'h02 : ADD imm   - Add immediate to accumulator
//   8'h03 : SUB imm   - Subtract immediate from accumulator
//   8'h04 : AND imm   - AND immediate with accumulator
//   8'h05 : OR  imm   - OR immediate with accumulator
//   8'h06 : XOR imm   - XOR immediate with accumulator
//   8'h07 : NOT       - Bitwise NOT of accumulator
//   8'h08 : STA addr  - Store accumulator to data memory[addr]
//   8'h09 : LDM addr  - Load data memory[addr] into accumulator
//   8'h0A : JMP addr  - Unconditional jump
//   8'h0B : JZ  addr  - Jump if zero flag set
//   8'h0C : JNZ addr  - Jump if zero flag clear
//   8'h0D : OUT       - Copy accumulator to GPIO output
//   8'h0E : IN        - Copy GPIO input to accumulator
//   8'h0F : HLT       - Halt execution
//   8'h10 : SHL       - Shift accumulator left
//   8'h11 : SHR       - Shift accumulator right
//   8'h12 : INC       - Increment accumulator
//   8'h13 : DEC       - Decrement accumulator
//   8'h14 : ADDA addr - Add memory[addr] to accumulator
//   8'h15 : SUBA addr - Subtract memory[addr] from accumulator
// ============================================================================

module control (
    input  wire        clk,
    input  wire        rst_n,

    // ROM interface
    output reg  [7:0]  pc,            // Program counter
    input  wire [15:0] instruction,   // Current instruction from ROM

    // ALU interface
    output reg  [7:0]  alu_a,
    output reg  [7:0]  alu_b,
    output reg  [3:0]  alu_op,
    input  wire [7:0]  alu_result,
    input  wire        alu_zero,
    input  wire        alu_carry,

    // Data memory interface
    output reg  [7:0]  mem_addr,
    output reg  [7:0]  mem_wdata,
    output reg         mem_we,
    input  wire [7:0]  mem_rdata,

    // GPIO interface
    output reg  [7:0]  gpio_out,
    output reg         gpio_out_en,
    input  wire [7:0]  gpio_in,

    // Status
    output wire        halted
);

    // ---- FSM States ----
    localparam STATE_FETCH    = 3'd0;
    localparam STATE_DECODE   = 3'd1;
    localparam STATE_MEM_READ = 3'd2;
    localparam STATE_EXECUTE  = 3'd3;
    localparam STATE_HALT     = 3'd4;

    reg [2:0] state, next_state;

    // ---- Instruction decode registers ----
    reg [7:0] opcode;
    reg [7:0] operand;

    // ---- Accumulator and flags ----
    reg [7:0] acc;
    reg       zero_flag;
    reg       carry_flag;

    assign halted = (state == STATE_HALT);

    // ---- State register ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= STATE_FETCH;
        else
            state <= next_state;
    end

    // ---- Main control logic ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc         <= 8'h00;
            acc        <= 8'h00;
            zero_flag  <= 1'b0;
            carry_flag <= 1'b0;
            opcode     <= 8'h00;
            operand    <= 8'h00;
            gpio_out   <= 8'h00;
            gpio_out_en <= 1'b0;
            mem_we     <= 1'b0;
            mem_addr   <= 8'h00;
            mem_wdata  <= 8'h00;
            alu_a      <= 8'h00;
            alu_b      <= 8'h00;
            alu_op     <= 4'h0;
        end else begin
            // Defaults
            mem_we     <= 1'b0;
            gpio_out_en <= 1'b0;

            case (state)
                // ================================================
                // FETCH: Latch instruction from ROM at current PC
                // ================================================
                STATE_FETCH: begin
                    opcode  <= instruction[15:8];
                    operand <= instruction[7:0];
                end

                // ================================================
                // DECODE: Set up ALU and memory signals
                // ================================================
                STATE_DECODE: begin
                    case (opcode)
                        8'h00: begin // NOP
                            alu_op <= 4'h0;
                            alu_a  <= acc;
                            alu_b  <= 8'h00;
                        end
                        8'h01: begin // LDA imm
                            alu_op <= 4'h0;
                            alu_a  <= operand;
                            alu_b  <= 8'h00;
                        end
                        8'h02: begin // ADD imm
                            alu_op <= 4'h1;
                            alu_a  <= acc;
                            alu_b  <= operand;
                        end
                        8'h03: begin // SUB imm
                            alu_op <= 4'h2;
                            alu_a  <= acc;
                            alu_b  <= operand;
                        end
                        8'h04: begin // AND imm
                            alu_op <= 4'h3;
                            alu_a  <= acc;
                            alu_b  <= operand;
                        end
                        8'h05: begin // OR imm
                            alu_op <= 4'h4;
                            alu_a  <= acc;
                            alu_b  <= operand;
                        end
                        8'h06: begin // XOR imm
                            alu_op <= 4'h5;
                            alu_a  <= acc;
                            alu_b  <= operand;
                        end
                        8'h07: begin // NOT
                            alu_op <= 4'h6;
                            alu_a  <= acc;
                            alu_b  <= 8'h00;
                        end
                        8'h08: begin // STA addr
                            mem_addr  <= operand;
                            mem_wdata <= acc;
                            mem_we    <= 1'b1;
                        end
                        8'h09: begin // LDM addr
                            mem_addr <= operand;
                        end
                        8'h0D: begin // OUT
                            gpio_out    <= acc;
                            gpio_out_en <= 1'b1;
                        end
                        8'h0E: begin // IN
                            alu_op <= 4'h0;
                            alu_a  <= gpio_in;
                            alu_b  <= 8'h00;
                        end
                        8'h10: begin // SHL
                            alu_op <= 4'h7;
                            alu_a  <= acc;
                            alu_b  <= 8'h00;
                        end
                        8'h11: begin // SHR
                            alu_op <= 4'h8;
                            alu_a  <= acc;
                            alu_b  <= 8'h00;
                        end
                        8'h12: begin // INC
                            alu_op <= 4'h9;
                            alu_a  <= acc;
                            alu_b  <= 8'h00;
                        end
                        8'h13: begin // DEC
                            alu_op <= 4'hA;
                            alu_a  <= acc;
                            alu_b  <= 8'h00;
                        end
                        8'h14: begin // ADDA addr
                            mem_addr <= operand;
                            alu_op   <= 4'h1;
                            alu_a    <= acc;
                        end
                        8'h15: begin // SUBA addr
                            mem_addr <= operand;
                            alu_op   <= 4'h2;
                            alu_a    <= acc;
                        end
                        default: begin
                            alu_op <= 4'h0;
                            alu_a  <= acc;
                            alu_b  <= 8'h00;
                        end
                    endcase
                end

                // ================================================
                // MEM_READ: Latch memory data for ADDA/SUBA
                // ================================================
                STATE_MEM_READ: begin
                    alu_b <= mem_rdata;
                end

                // ================================================
                // EXECUTE: Latch results, update PC
                // ================================================
                STATE_EXECUTE: begin
                    case (opcode)
                        8'h00: begin // NOP
                            pc <= pc + 8'd1;
                        end
                        8'h01: begin // LDA imm
                            acc <= alu_result;
                            zero_flag  <= alu_zero;
                            carry_flag <= alu_carry;
                            pc <= pc + 8'd1;
                        end
                        8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07: begin
                            // ADD/SUB/AND/OR/XOR/NOT
                            acc <= alu_result;
                            zero_flag  <= alu_zero;
                            carry_flag <= alu_carry;
                            pc <= pc + 8'd1;
                        end
                        8'h08: begin // STA
                            pc <= pc + 8'd1;
                        end
                        8'h09: begin // LDM
                            acc <= mem_rdata;
                            zero_flag <= (mem_rdata == 8'h00);
                            pc <= pc + 8'd1;
                        end
                        8'h0A: begin // JMP
                            pc <= operand;
                        end
                        8'h0B: begin // JZ
                            if (zero_flag)
                                pc <= operand;
                            else
                                pc <= pc + 8'd1;
                        end
                        8'h0C: begin // JNZ
                            if (!zero_flag)
                                pc <= operand;
                            else
                                pc <= pc + 8'd1;
                        end
                        8'h0D: begin // OUT
                            pc <= pc + 8'd1;
                        end
                        8'h0E: begin // IN
                            acc <= alu_result;
                            zero_flag  <= alu_zero;
                            carry_flag <= alu_carry;
                            pc <= pc + 8'd1;
                        end
                        8'h0F: begin // HLT - PC stays
                            // Do nothing, state machine handles HALT
                        end
                        8'h10, 8'h11, 8'h12, 8'h13: begin
                            // SHL/SHR/INC/DEC
                            acc <= alu_result;
                            zero_flag  <= alu_zero;
                            carry_flag <= alu_carry;
                            pc <= pc + 8'd1;
                        end
                        8'h14: begin // ADDA addr
                            acc <= alu_result;
                            zero_flag  <= alu_zero;
                            carry_flag <= alu_carry;
                            pc <= pc + 8'd1;
                        end
                        8'h15: begin // SUBA addr
                            acc <= alu_result;
                            zero_flag  <= alu_zero;
                            carry_flag <= alu_carry;
                            pc <= pc + 8'd1;
                        end
                        default: begin
                            pc <= pc + 8'd1;
                        end
                    endcase
                end

                STATE_HALT: begin
                    // Do nothing
                end
            endcase
        end
    end

    // ---- Next state logic ----
    always @(*) begin
        case (state)
            STATE_FETCH:   next_state = STATE_DECODE;
            STATE_DECODE: begin
                if (opcode == 8'h14 || opcode == 8'h15)
                    next_state = STATE_MEM_READ;
                else
                    next_state = STATE_EXECUTE;
            end
            STATE_MEM_READ: next_state = STATE_EXECUTE;
            STATE_EXECUTE: begin
                if (opcode == 8'h0F)
                    next_state = STATE_HALT;
                else
                    next_state = STATE_FETCH;
            end
            STATE_HALT:    next_state = STATE_HALT;
            default:       next_state = STATE_FETCH;
        endcase
    end

endmodule
