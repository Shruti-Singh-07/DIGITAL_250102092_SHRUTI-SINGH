`timescale 1ns / 1ps

module tb_sequence_101_moore;

    // 1. Inputs (reg because we control them in the test)
    reg clk;
    reg rst_n;
    reg in_bit;

    // 2. Outputs (wire because the module drives them)
    wire out_bit;

    // 3. Instantiate the Unit Under Test (UUT)
    // IMPORTANT: Make sure your main Moore module is named exactly this!
    sequence_101_moore uut (
        .clk(clk),
        .rst_n(rst_n),
        .in_bit(in_bit),
        .out_bit(out_bit)
    );

    // 4. Generate the Master Clock (10ns period)
    always #5 clk = ~clk;

    // 5. The Test Sequence
    initial begin
        // Initialize Inputs to zero
        clk = 0;
        rst_n = 0;
        in_bit = 0;

        // Hold reset for 20 ns
        #20;
        rst_n = 1;
        
        // Feed the overlapping sequence "1 0 1 0 1"
        // We wait 10ns between each bit to sync with the clock
        #10 in_bit = 1; 
        #10 in_bit = 0; 
        
        // 1st Sequence Complete!
        #10 in_bit = 1; 
        
        #10 in_bit = 0; 
        
        // 2nd Sequence Complete! (Overlapping)
        #10 in_bit = 1; 
        
        // Feed some garbage to ensure it clears out properly
        #10 in_bit = 0;
        #10 in_bit = 0;

        // End the simulation
        #20 $finish; 
    end

endmodule
