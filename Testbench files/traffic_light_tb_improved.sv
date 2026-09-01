// ============================================================================
// IMPROVED 4-WAY TRAFFIC LIGHT TESTBENCH
// ============================================================================
// 
// This testbench includes:
// ✅ Safety assertions (mutual exclusion, valid colors)
// ✅ Sequence verification (correct order of states)
// ✅ Extended simulation (multiple full cycles)
// ✅ Cycle-by-cycle trace output
//
// ============================================================================

`timescale 1ns / 1ps

module traffic_light_4way_tb;

    // ========================================================================
    // Test Signals
    // ========================================================================
    logic clk;
    logic rst_n;
    
    // North-South direction
    logic ns_red;
    logic ns_yellow;
    logic ns_green;
    
    // East-West direction
    logic ew_red;
    logic ew_yellow;
    logic ew_green;

    // Instantiate Device Under Test (DUT)
    traffic_light_4way dut (
        .clk(clk),
        .rst_n(rst_n),
        .ns_red(ns_red),
        .ns_yellow(ns_yellow),
        .ns_green(ns_green),
        .ew_red(ew_red),
        .ew_yellow(ew_yellow),
        .ew_green(ew_green)
    );

    // ========================================================================
    // Clock Generation: 10ns period (100 MHz)
    // ========================================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;  // Toggle every 5ns = 10ns period
    end

    // ========================================================================
    // Test Stimulus + Monitoring
    // ========================================================================
    initial begin
        $display("\n%s", "="*70);
        $display("4-WAY TRAFFIC LIGHT CONTROLLER TEST");
        $display("%s\n", "="*70);
        
        $display("Parameters:");
        $display("  NS_GREEN_DUR  = %0d cycles", dut.NS_GREEN_DUR);
        $display("  NS_YELLOW_DUR = %0d cycles", dut.NS_YELLOW_DUR);
        $display("  EW_GREEN_DUR  = %0d cycles", dut.EW_GREEN_DUR);
        $display("  EW_YELLOW_DUR = %0d cycles", dut.EW_YELLOW_DUR);
        $display("  Full Cycle    = %0d cycles\n", 
                 dut.NS_GREEN_DUR + dut.NS_YELLOW_DUR + 
                 dut.EW_GREEN_DUR + dut.EW_YELLOW_DUR);

        // Apply Reset
        rst_n = 1'b0;
        #10;  // Hold reset for 1 cycle
        rst_n = 1'b1;
        #5;   // Wait for first clock edge after reset

        // Print header
        $display("%s", "-"*70);
        $display("Cycle | Time(ns) | State           | NS Color  | EW Color");
        $display("%s", "-"*70);

        // Run simulation for multiple full cycles
        // Total cycles = 4 full cycles + 1 extra = ~100 cycles
        repeat (100) begin
            @(posedge clk);
            print_cycle();
        end

        $display("%s", "-"*70);
        $display("TEST COMPLETE");
        $display("%s\n", "="*70);
        $finish;
    end

    // ========================================================================
    // SAFETY ASSERTIONS (Continuous)
    // ========================================================================
    // These check for violations on every clock edge
    
    always @(posedge clk) begin
        // Assertion 1: Mutual Exclusion
        // NS_GREEN and EW_GREEN should never both be 1
        if (ns_green && ew_green) begin
            $error("[CRASH] SAFETY VIOLATION: Both NS and EW are GREEN!");
            $display("  Time: %0t | NS: R=%b Y=%b G=%b | EW: R=%b Y=%b G=%b",
                     $time, ns_red, ns_yellow, ns_green,
                     ew_red, ew_yellow, ew_green);
            $finish;
        end
        
        // Assertion 2: Valid Color Combinations
        // Each direction must show exactly ONE color at a time
        if ((ns_red + ns_yellow + ns_green) != 1) begin
            $error("[ERROR] SAFETY VIOLATION: Invalid NS color combination!");
            $display("  NS: R=%b Y=%b G=%b (sum=%0d)",
                     ns_red, ns_yellow, ns_green,
                     ns_red + ns_yellow + ns_green);
            $finish;
        end
        
        if ((ew_red + ew_yellow + ew_green) != 1) begin
            $error("[ERROR] SAFETY VIOLATION: Invalid EW color combination!");
            $display("  EW: R=%b Y=%b G=%b (sum=%0d)",
                     ew_red, ew_yellow, ew_green,
                     ew_red + ew_yellow + ew_green);
            $finish;
        end
        
        // Assertion 3: No Green with Yellow
        // Each direction can't have both green and yellow lit
        if ((ns_green && ns_yellow) || (ew_green && ew_yellow)) begin
            $error("[ERROR] SAFETY VIOLATION: Green and Yellow lit simultaneously!");
            $finish;
        end
    end

    // ========================================================================
    // STATE SEQUENCE VERIFICATION
    // ========================================================================
    // Verify the state machine follows the correct sequence
    
    int cycle_count = 0;
    int full_cycle_length = dut.NS_GREEN_DUR + dut.NS_YELLOW_DUR + 
                            dut.EW_GREEN_DUR + dut.EW_YELLOW_DUR;
    
    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count++;
            verify_state_sequence();
        end
    end

    task verify_state_sequence();
        int position_in_cycle = (cycle_count - 1) % full_cycle_length;
        int range;
        
        // Calculate which state should be active
        range = dut.NS_GREEN_DUR;
        if (position_in_cycle < range) begin
            if (!ns_green) begin
                $warning("[WARN] Expected NS_GREEN at cycle %0d, position %0d",
                        cycle_count, position_in_cycle);
            end
        end
        
        range += dut.NS_YELLOW_DUR;
        if (position_in_cycle >= dut.NS_GREEN_DUR && 
            position_in_cycle < range) begin
            if (!ns_yellow) begin
                $warning("[WARN] Expected NS_YELLOW at cycle %0d, position %0d",
                        cycle_count, position_in_cycle);
            end
        end
        
        range += dut.EW_GREEN_DUR;
        if (position_in_cycle >= (dut.NS_GREEN_DUR + dut.NS_YELLOW_DUR) && 
            position_in_cycle < range) begin
            if (!ew_green) begin
                $warning("[WARN] Expected EW_GREEN at cycle %0d, position %0d",
                        cycle_count, position_in_cycle);
            end
        end
        
        if (position_in_cycle >= (dut.NS_GREEN_DUR + dut.NS_YELLOW_DUR + 
                                   dut.EW_GREEN_DUR)) begin
            if (!ew_yellow) begin
                $warning("[WARN] Expected EW_YELLOW at cycle %0d, position %0d",
                        cycle_count, position_in_cycle);
            end
        end
    endtask

    // ========================================================================
    // MONITORING / LOGGING
    // ========================================================================
    
    task print_cycle();
        string state_name;
        string ns_color, ew_color;
        
        // Determine state name
        if (ns_green && !ns_yellow)
            state_name = "NS_GREEN";
        else if (ns_yellow && !ns_green)
            state_name = "NS_YELLOW";
        else if (ew_green && !ew_yellow)
            state_name = "EW_GREEN";
        else if (ew_yellow && !ew_green)
            state_name = "EW_YELLOW";
        else if (ns_red && ew_red)
            state_name = "ALL_RED";
        else
            state_name = "UNKNOWN";
        
        // Determine NS color
        if (ns_green)
            ns_color = "GREEN ";
        else if (ns_yellow)
            ns_color = "YELLOW";
        else
            ns_color = "RED   ";
        
        // Determine EW color
        if (ew_green)
            ew_color = "GREEN ";
        else if (ew_yellow)
            ew_color = "YELLOW";
        else
            ew_color = "RED   ";
        
        $display("%5d | %8.0f | %-15s | %s | %s",
                 cycle_count,
                 $time,
                 state_name,
                 ns_color,
                 ew_color);
    endtask

    // ========================================================================
    // TIMEOUT PROTECTION
    // ========================================================================
    initial begin
        #2000;  // 2000ns timeout
        $display("\n[ERROR] Simulation timeout - test did not complete!");
        $finish;
    end

endmodule
