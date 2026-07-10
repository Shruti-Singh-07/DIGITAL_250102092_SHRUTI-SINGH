`timescale 1ns / 1ps

module tb_sequence_101;

    // 1. Inputs to the module are defined as 'reg' because we control them
    reg clk;
    reg rst_n;
    reg in_bit;

    // 2. Outputs from the module are defined as 'wire'
    wire out_bit;

    // 3. Instantiate the Unit Under Test (UUT)
    // This physically drops your Mealy machine into the testbench lab
    sequence_101_mealy uut (
        .clk(clk),
        .rst_n(rst_n),
        .in_bit(in_bit),
        .out_bit(out_bit)
    );

    // 4. Generate the Master Clock
    // This flips the clock signal every 5 nanoseconds (10ns total period)
    always #5 clk = ~clk;

    // 5. The Test Sequence (The Stimulus)
    initial begin
        // Initialize Inputs to zero
        clk = 0;
        rst_n = 0;
        in_bit = 0;

        // Wait 20 ns, then release the reset button
        #20;
        rst_n = 1;
        
        // Feed the overlapping sequence "1 0 1 0 1"
        // We wait 10ns between each bit to match the clock period
        #10 in_bit = 1; // State: Got 1
        #10 in_bit = 0; // State: Got 10
        #10 in_bit = 1; // State: Got 101 -> out_bit SHOULD SPIKE TO 1 HERE!
        #10 in_bit = 0; // State: Got 10
        #10 in_bit = 1; // State: Got 101 -> out_bit SHOULD SPIKE TO 1 HERE!
        
        // Feed some garbage to make sure it resets properly
        #10 in_bit = 0;
        #10 in_bit = 0;
        #10 in_bit = 1;
        #10 in_bit = 1;

        // End the simulation
        #20 $finish; 
    end

endmodule
