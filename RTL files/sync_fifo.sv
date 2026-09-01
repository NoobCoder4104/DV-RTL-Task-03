// ============================================================================
// sync_fifo.sv - Synchronous FIFO Implementation
//
// First-In-First-Out queue operating in a single clock domain.
// Data written first is read first. Handles full, empty, and simultaneous
// read/write conditions.
//
// Architecture:
//   - Memory array (dual-port: simultaneous read and write)
//   - Write pointer (points to next write location)
//   - Read pointer (points to next read location)
//   - Count register (number of valid entries)
//   - Full/Empty flags derived from count
//
// Key Feature: Simultaneous read + write in same cycle is handled correctly
// (count does not change when both happen together).
//
// ============================================================================

module sync_fifo #(
    parameter WIDTH = 8,   // Data width in bits
    parameter DEPTH = 8    // Number of storage locations (MUST be power of 2)
) (
    // Clock and Reset
    input  logic clk,
    input  logic rst_n,
    
    // Write Interface
    input  logic wr_en,                      // Write enable
    input  logic [WIDTH-1:0] din,           // Data input
    
    // Read Interface
    input  logic rd_en,                      // Read enable
    output logic [WIDTH-1:0] dout,          // Data output
    
    // Status Flags
    output logic full,                       // FIFO is full (can't write)
    output logic empty                       // FIFO is empty (can't read)
);

    // ========================================================================
    // Local Parameters
    // ========================================================================
    // ADDR_WIDTH is log2(DEPTH). For DEPTH=8, ADDR_WIDTH=3.
    // This determines the size of the read and write pointers.
    localparam ADDR_WIDTH = $clog2(DEPTH);

    // ========================================================================
    // Internal Registers
    // ========================================================================
    // Memory array: each entry is WIDTH bits wide
    logic [WIDTH-1:0] mem [0:DEPTH-1];
    
    // Read pointer: points to next read location
    logic [ADDR_WIDTH-1:0] rd_ptr, next_rd_ptr;
    
    // Write pointer: points to next write location
    logic [ADDR_WIDTH-1:0] wr_ptr, next_wr_ptr;
    
    // Count: number of valid entries currently in FIFO
    // Range: 0 to DEPTH. Needs ADDR_WIDTH+1 bits to hold DEPTH.
    logic [ADDR_WIDTH:0] count, next_count;

    // ========================================================================
    // Sequential Logic (Always FF Block)
    // ========================================================================
    // Updates on clock edge:
    //   - Memory write (if wr_en and !full)
    //   - Read pointer (if rd_en and !empty)
    //   - Write pointer (if wr_en and !full)
    //   - Count (based on simultaneous read/write)
    //
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset: empty FIFO, pointers at 0, count is 0
            rd_ptr <= {ADDR_WIDTH{1'b0}};
            wr_ptr <= {ADDR_WIDTH{1'b0}};
            count  <= {ADDR_WIDTH+1{1'b0}};
        end else begin
            // Update pointers and count (calculated combinationally)
            rd_ptr <= next_rd_ptr;
            wr_ptr <= next_wr_ptr;
            count  <= next_count;
            
            // Write to memory (if write is enabled and FIFO not full)
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
            end
        end
    end

    // ========================================================================
    // Combinational Logic - Pointer and Count Updates
    // ========================================================================
    // These blocks compute next state based on current state and control inputs.
    //
    always_comb begin
        // Default: pointers stay the same
        next_rd_ptr = rd_ptr;
        next_wr_ptr = wr_ptr;
        next_count  = count;
        
        // Update based on read and write enables
        case ({wr_en && !full, rd_en && !empty})
            2'b00: begin
                // No operation: pointers and count unchanged
                next_rd_ptr = rd_ptr;
                next_wr_ptr = wr_ptr;
                next_count  = count;
            end
            
            2'b01: begin
                // Read only: rd_ptr advances, count decreases
                next_rd_ptr = (rd_ptr == DEPTH-1) ? {ADDR_WIDTH{1'b0}} : rd_ptr + 1;
                next_wr_ptr = wr_ptr;
                next_count  = count - 1;
            end
            
            2'b10: begin
                // Write only: wr_ptr advances, count increases
                next_rd_ptr = rd_ptr;
                next_wr_ptr = (wr_ptr == DEPTH-1) ? {ADDR_WIDTH{1'b0}} : wr_ptr + 1;
                next_count  = count + 1;
            end
            
            2'b11: begin
                // Simultaneous read and write: both pointers advance, count unchanged
                next_rd_ptr = (rd_ptr == DEPTH-1) ? {ADDR_WIDTH{1'b0}} : rd_ptr + 1;
                next_wr_ptr = (wr_ptr == DEPTH-1) ? {ADDR_WIDTH{1'b0}} : wr_ptr + 1;
                next_count  = count;  // Count doesn't change!
            end
        endcase
    end

    // ========================================================================
    // Combinational Logic - Output Data
    // ========================================================================
    // Read from memory at current read pointer
    //
    assign dout = mem[rd_ptr];

    // ========================================================================
    // Combinational Logic - Status Flags
    // ========================================================================
    // Full and Empty flags are derived from the count.
    //
    assign empty = (count == 0);          // No valid data to read
    assign full  = (count == DEPTH);      // No room to write more

endmodule

// ============================================================================
// END OF sync_fifo.sv
// ============================================================================
