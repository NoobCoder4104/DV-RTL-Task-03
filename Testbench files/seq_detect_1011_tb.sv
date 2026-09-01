// =============================================================================
// seq_detect_1011_tb.sv
//
// Simple Testbench for 1011 Sequence Detector
//
// Test Sequence: 1 1 0 1 0 1 1
// Expected: detected should go HIGH during cycle 7 (when last '1' is input)
//
// =============================================================================

`timescale 1ns/1ps

module seq_detect_1011_tb;

    // Declare signals
    reg clk;
    reg rst_n;
    reg din;
    wire detected;

    // Instantiate the DUT (Device Under Test)
    seq_detect_1011 dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .din      (din),
        .detected (detected)
    );

    // ------------------------------------------------------------------
    // Clock Generation: 10 ns period (100 MHz)
    // ------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------------
    // Main Test Stimulus
    // ------------------------------------------------------------------
    initial begin
        $display("=========================================");
        $display(" Cycle | din | state | detected");
        $display("=========================================");

        // Apply reset
        rst_n = 0;
        din = 0;
        #10;
        #10;
        rst_n = 1;
        #10;

        // Test sequence: 1 1 0 1 0 1 1
        test_bit(1'b1, 1);  // Cycle 1
        test_bit(1'b1, 2);  // Cycle 2
        test_bit(1'b0, 3);  // Cycle 3
        test_bit(1'b1, 4);  // Cycle 4
        test_bit(1'b0, 5);  // Cycle 5
        test_bit(1'b1, 6);  // Cycle 6
        test_bit(1'b1, 7);  // Cycle 7 -- detected should go HIGH!
        
        // Extra cycle to see overlap
        test_bit(1'b0, 8);  // Cycle 8

        $display("=========================================");
        $display("Test Complete!");
        $finish;
    end

    // ------------------------------------------------------------------
    // Helper task to apply one bit and display results
    // ------------------------------------------------------------------
    task test_bit(input bit value, input int cycle);
        din = value;
        #10;  // Wait one clock
        $display("   %d   |  %b  | %b     | %b",
                 cycle, din, dut.state, detected);
    endtask

    // ------------------------------------------------------------------
    // Safety timeout
    // ------------------------------------------------------------------
    initial begin
        #2000;
        $display("ERROR: Test timeout!");
        $finish;
    end

endmodule
