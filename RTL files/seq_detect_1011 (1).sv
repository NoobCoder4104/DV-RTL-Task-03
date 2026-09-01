// =============================================================================
// seq_detect_1011.sv
//
// 1011 Sequence Detector - Moore FSM with 4 States
//
// This FSM detects the pattern "1011" in a serial input stream.
// When the pattern is detected, the output "detected" goes HIGH.
//
// State Encoding (4 states only):
//   IDLE = 2'b00   --> no progress toward pattern
//   S1   = 2'b01   --> saw a '1'
//   S10  = 2'b10   --> saw '10'
//   S101 = 2'b11   --> saw '101' (next '1' completes the pattern)
//
// =============================================================================

module seq_detect_1011 (
    input  logic clk,       // system clock
    input  logic rst_n,     // active-low asynchronous reset
    input  logic din,       // serial input data
    output logic detected   // goes HIGH when "1011" is detected
);

    // ------------------------------------------------------------------
    // State Encoding using parameters
    // ------------------------------------------------------------------
    parameter [1:0] IDLE  = 2'b00;   
    parameter [1:0] S1    = 2'b01;   
    parameter [1:0] S10   = 2'b10;   
    parameter [1:0] S101  = 2'b11;   

    // State registers
    reg [1:0] state, next_state;

    // ------------------------------------------------------------------
    // Block 1: Sequential - State Register with Async Reset
    // ------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ------------------------------------------------------------------
    // Block 2: Combinational - Next State Logic
    // ------------------------------------------------------------------
    always @(*) begin
        case (state)
            IDLE: begin
                if (din == 1)
                    next_state = S1;
                else
                    next_state = IDLE;
            end
            
            S1: begin
                if (din == 1)
                    next_state = S1;      // Another '1', stay at S1
                else
                    next_state = S10;     // '0' after '1' is '10'
            end
            
            S10: begin
                if (din == 1)
                    next_state = S101;    // '1' after '10' is '101'
                else
                    next_state = IDLE;    // '0' after '10', start over
            end
            
            S101: begin
                if (din == 1)
                    next_state = S1;      // Pattern complete! Overlap: last '1' starts new
                else
                    next_state = S10;     // '0' after '101' 
            end
            
            default:
                next_state = IDLE;
        endcase
    end

    // ------------------------------------------------------------------
    // Output Logic: Pulse detected when we complete the pattern
    // Pulse occurs when: state is S101 AND din is 1
    // ------------------------------------------------------------------
    always @(*) begin
        if (state == S101 && din == 1)
            detected = 1;
        else
            detected = 0;
    end

endmodule
