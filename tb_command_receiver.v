`timescale 1ns / 1ps

module tb_command_receiver;

    reg clk, rst_n, in_bit;
    wire done, parity_err, frame_err;
    wire [7:0] result;

    command_receiver uut (
        .clk(clk),
        .rst_n(rst_n),
        .in_bit(in_bit),
        .done(done),
        .parity_err(parity_err),
        .frame_err(frame_err),
        .result(result)
    );

    always #5 clk = ~clk;

    // Helper task to send the new 13-bit frame
    task send_command;
        input [1:0] cmd;
        input [7:0] data;
        input p_bit;
        input s_bit;
        integer i;
        begin
            in_bit = 0; #10; // Start Bit (0)
            
            // 2 Command Bits
            in_bit = cmd[1]; #10;
            in_bit = cmd[0]; #10;

            // 8 Data Bits
            for (i=7; i>=0; i=i-1) begin
                in_bit = data[i]; #10;
            end
            
            in_bit = p_bit; #10; // Parity Bit
            in_bit = s_bit; #10; // Stop Bit
            
            in_bit = 1; #40;     // Idle line
        end
    endtask

    initial begin
        clk = 0; rst_n = 0; in_bit = 1;
        #20; rst_n = 1; #10;

       
        // TEST 1: LOAD_A with Data '10' (Hex 0A)
        // Parity for 00001010 (two 1s) is 0. 
        // Expect result = 0A
        
        send_command(2'b00, 8'h0A, 1'b0, 1'b1);

       
        // TEST 2: LOAD_B with Data '5' (Hex 05)
        // Parity for 00000101 (two 1s) is 0. 
        // Expect result = 05
        
        send_command(2'b01, 8'h05, 1'b0, 1'b1);

       
        // TEST 3: ADD (A + B) -> 10 + 5 = 15 (Hex 0F)
        // Data payload doesn't matter, we'll send 0.
        // Expect result = 0F
        
        send_command(2'b10, 8'h00, 1'b0, 1'b1);

        // TEST 4: ERROR TEST - Corrupt Parity on a LOAD_A
        // We try to load A with FF, but force bad parity (1 instead of 0).
        // Expect parity_err to spike, result to be 00, and A remains untouched.
        
        send_command(2'b00, 8'hFF, 1'b1, 1'b1);

        // TEST 5: Verify ADD again. (Proves A was protected from Test 4!)
        // Expect result = 0F (Still 10 + 5)
    
        send_command(2'b10, 8'h00, 1'b0, 1'b1);

        
        // TEST 6: CLEAR 
        // Expect result = 00
        
        send_command(2'b11, 8'h00, 1'b0, 1'b1);

        #50; $finish;
    end
endmodule