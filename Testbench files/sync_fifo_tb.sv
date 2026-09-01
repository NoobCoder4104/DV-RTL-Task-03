// ============================================================================
// sync_fifo_tb.sv - Comprehensive Smoke Test for Synchronous FIFO
//
// Test Sequence:
//   1. Reset and verify FIFO is empty
//   2. Fill FIFO to capacity (write 8 entries: 0x00 to 0x07)
//   3. Verify full flag is asserted
//   4. Attempt one extra write (should be blocked)
//   5. Read all 8 entries and verify data comes out in order
//   6. Verify empty flag is asserted
//   7. Attempt one extra read (should be blocked / stale data)
//   8. Simultaneous read/write test (count should not change)
//
// Monitoring:
//   - Print each cycle: wr_en, rd_en, din, dout, count, full, empty
//   - Verify: no data loss, correct order, flags behave correctly
//
// ============================================================================

`timescale 1ns / 1ps

module sync_fifo_tb;

    // ========================================================================
    // Test Parameters
    // ========================================================================
    localparam WIDTH = 8;
    localparam DEPTH = 8;

    // ========================================================================
    // Test Signals
    // ========================================================================
    logic clk;
    logic rst_n;
    logic wr_en;
    logic rd_en;
    logic [WIDTH-1:0] din;
    logic [WIDTH-1:0] dout;
    logic full;
    logic empty;

    // ========================================================================
    // Instantiate Device Under Test (DUT)
    // ========================================================================
    sync_fifo #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty)
    );

    // ========================================================================
    // Clock Generation: 10ns period
    // ========================================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ========================================================================
    // Main Test Stimulus
    // ========================================================================
    int cycle_count = 0;
    int error_count = 0;

    initial begin
        $display("\n%s", "="*80);
        $display("SYNCHRONOUS FIFO SMOKE TEST");
        $display("%s\n", "="*80);
        
        $display("Parameters: WIDTH=%0d, DEPTH=%0d\n", WIDTH, DEPTH);

        // PHASE 1: Reset
        $display("PHASE 1: RESET");
        $display("%s", "-"*80);
        phase_reset();
        
        // PHASE 2: Fill FIFO
        $display("\nPHASE 2: FILL FIFO TO CAPACITY");
        $display("%s", "-"*80);
        phase_fill();
        
        // PHASE 3: Attempt write when full
        $display("\nPHASE 3: ATTEMPT WRITE WHEN FULL");
        $display("%s", "-"*80);
        phase_write_when_full();
        
        // PHASE 4: Drain FIFO
        $display("\nPHASE 4: DRAIN FIFO");
        $display("%s", "-"*80);
        phase_drain();
        
        // PHASE 5: Attempt read when empty
        $display("\nPHASE 5: ATTEMPT READ WHEN EMPTY");
        $display("%s", "-"*80);
        phase_read_when_empty();
        
        // PHASE 6: Simultaneous read/write
        $display("\nPHASE 6: SIMULTANEOUS READ/WRITE TEST");
        $display("%s", "-"*80);
        phase_simultaneous();
        
        // FINAL REPORT
        $display("\n%s", "="*80);
        $display("TEST SUMMARY");
        $display("Total Errors: %0d", error_count);
        if (error_count == 0)
            $display("✓ ALL TESTS PASSED");
        else
            $display("✗ TESTS FAILED");
        $display("%s\n", "="*80);
        
        $finish;
    end

    // ========================================================================
    // PHASE 1: RESET
    // ========================================================================
    task phase_reset();
        rst_n = 1'b0;
        wr_en = 1'b0;
        rd_en = 1'b0;
        din = 8'h00;
        
        #10;  // Hold reset for 1 cycle
        rst_n = 1'b1;
        #5;   // Wait for first clock
        
        print_header();
        
        #10;  // One cycle after reset
        print_state("RESET complete");
        
        // Verify: FIFO should be empty after reset
        if (empty && !full && dut.count == 0) begin
            $display("✓ FIFO correctly empty after reset");
        end else begin
            $error("✗ FIFO state incorrect after reset: empty=%b, full=%b, count=%0d",
                   empty, full, dut.count);
            error_count++;
        end
    endtask

    // ========================================================================
    // PHASE 2: FILL FIFO TO CAPACITY
    // ========================================================================
    task phase_fill();
        print_header();
        
        for (int i = 0; i < DEPTH; i++) begin
            din = 8'(i);        // Write value 0x00, 0x01, ..., 0x07
            wr_en = 1'b1;
            rd_en = 1'b0;
            
            #10;  // One cycle
            print_state($sformatf("Write 0x%02h", i));
            
            // Verify data was written
            if (i < DEPTH - 1) begin
                if (full) begin
                    $error("✗ FIFO marked full too early at index %0d", i);
                    error_count++;
                end
            end
        end
        
        // After 8 writes, should be full
        if (full && !empty && dut.count == DEPTH) begin
            $display("✓ FIFO correctly full after %0d writes", DEPTH);
        end else begin
            $error("✗ FIFO not in expected full state: full=%b, count=%0d",
                   full, dut.count);
            error_count++;
        end
    endtask

    // ========================================================================
    // PHASE 3: ATTEMPT WRITE WHEN FULL
    // ========================================================================
    task phase_write_when_full();
        print_header();
        
        // Try to write when full (should be blocked)
        din = 8'hFF;
        wr_en = 1'b1;
        rd_en = 1'b0;
        
        logic [WIDTH-1:0] count_before = dut.count;
        
        #10;
        print_state("Attempt write when full");
        
        // Verify: data was NOT written, count unchanged
        if (dut.count == count_before) begin
            $display("✓ Write correctly blocked when FIFO full");
        end else begin
            $error("✗ Write not blocked: count changed from %0d to %0d",
                   count_before, dut.count);
            error_count++;
        end
    endtask

    // ========================================================================
    // PHASE 4: DRAIN FIFO
    // ========================================================================
    task phase_drain();
        print_header();
        
        wr_en = 1'b0;
        din = 8'h00;
        
        for (int i = 0; i < DEPTH; i++) begin
            rd_en = 1'b1;
            
            #10;
            print_state($sformatf("Read position %0d", i));
            
            // Verify: correct data comes out
            if (dout == 8'(i)) begin
                $display("  ✓ Correct data read: 0x%02h", dout);
            end else begin
                $error("  ✗ Wrong data read: expected 0x%02h, got 0x%02h",
                       8'(i), dout);
                error_count++;
            end
        end
        
        // After 8 reads, should be empty
        if (empty && !full && dut.count == 0) begin
            $display("✓ FIFO correctly empty after draining");
        end else begin
            $error("✗ FIFO not empty: empty=%b, count=%0d", empty, dut.count);
            error_count++;
        end
    endtask

    // ========================================================================
    // PHASE 5: ATTEMPT READ WHEN EMPTY
    // ========================================================================
    task phase_read_when_empty();
        print_header();
        
        rd_en = 1'b1;
        wr_en = 1'b0;
        
        logic [WIDTH-1:0] count_before = dut.count;
        
        #10;
        print_state("Attempt read when empty");
        
        // Verify: read was not processed, count unchanged
        if (dut.count == count_before) begin
            $display("✓ Read correctly blocked when FIFO empty");
        end else begin
            $error("✗ Read not blocked: count changed from %0d to %0d",
                   count_before, dut.count);
            error_count++;
        end
    endtask

    // ========================================================================
    // PHASE 6: SIMULTANEOUS READ/WRITE
    // ========================================================================
    task phase_simultaneous();
        print_header();
        
        // Fill FIFO with a few entries
        for (int i = 0; i < 4; i++) begin
            din = 8'(i);
            wr_en = 1'b1;
            rd_en = 1'b0;
            #10;
        end
        
        $display("Setup: Filled with 4 entries (count=%0d)\n", dut.count);
        
        // Now do simultaneous read and write for 3 cycles
        // Count should remain at 4 throughout
        for (int i = 0; i < 3; i++) begin
            din = 8'(10 + i);   // Write 0x0A, 0x0B, 0x0C
            wr_en = 1'b1;
            rd_en = 1'b1;       // And read simultaneously
            
            logic [WIDTH-1:0] count_before = dut.count;
            
            #10;
            print_state($sformatf("Sim R/W cycle %0d", i));
            
            // Verify: count didn't change
            if (dut.count == count_before) begin
                $display("  ✓ Count stable during R/W: %0d", dut.count);
            end else begin
                $error("  ✗ Count changed during R/W: %0d → %0d",
                       count_before, dut.count);
                error_count++;
            end
        end
        
        if (dut.count == 4) begin
            $display("✓ Simultaneous read/write test passed");
        end
    endtask

    // ========================================================================
    // Utility Tasks
    // ========================================================================
    
    task print_header();
        $display("Cycle | WR | RD | Din    | Dout   | Count | Full | Empty");
        $display("%s", "-"*80);
    endtask

    task print_state(string label);
        cycle_count++;
        $display("%5d | %b  | %b  | 0x%02h | 0x%02h | %5d | %b    | %b     %s",
                 cycle_count, wr_en, rd_en, din, dout, dut.count, full, empty,
                 label != "" ? $sformatf("// %s", label) : "");
    endtask

    // ========================================================================
    // Timeout Protection
    // ========================================================================
    initial begin
        #10000;  // 10 microseconds
        $error("TEST TIMEOUT - simulation did not complete");
        $finish;
    end

endmodule

// ============================================================================
// END OF sync_fifo_tb.sv
// ============================================================================
