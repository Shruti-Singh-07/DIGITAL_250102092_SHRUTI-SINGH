`timescale 1ns / 1ps

module tb_frame_receiver;

    // Inputs
    reg clk;
    reg rst_n;
    reg in_bit;

    // Outputs
    wire done;
    wire parity_err;
    wire frame_err;
    wire [7:0] data_out;

    // Instantiate the Unit Under Test (UUT)
    frame_receiver uut (
        .clk(clk),
        .rst_n(rst_n),
        .in_bit(in_bit),
        .done(done),
        .parity_err(parity_err),
        .frame_err(frame_err),
        .data_out(data_out)
    );

    // Generate 10ns Clock
    always #5 clk = ~clk;

    // Helper task to easily send a 11-bit packet frame
    task send_packet;
        input [7:0] data;
        input p_bit;
        input s_bit;
        integer i;
        begin
            in_bit = 0; #10; // Send Start Bit (0)
            
            // Send 8 Data Bits
            for (i=7; i>=0; i=i-1) begin
                in_bit = data[i]; #10;
            end
            
            in_bit = p_bit; #10; // Send Parity Bit
            in_bit = s_bit; #10; // Send Stop Bit
            
            in_bit = 1; #30;     // Return to Idle (1) before next packet
        end
    endtask

    initial begin
        // 1. Initialize Inputs
        clk = 0;
        rst_n = 0;
        in_bit = 1; // Idle state is 1

        // 2. Reset the system
        #20;
        rst_n = 1;
        #10;

        // TEST 1: PERFECT PACKET
        // Data: 8'b10101011 (Five 1s). 
        // Even Parity needs total 1s to be even, so Parity bit = 1.
        // Stop bit = 1.
        // EXPECT: 'done' spikes to 1, 'data_out' shows 10101011 (Hex: AB)
          send_packet(8'b10101011, 1'b1, 1'b1);

       
        // TEST 2: PARITY ERROR
        // Data: 8'b11001100 (Four 1s). 
        // We force Parity bit = 1 (Making total 1s odd -> ERROR!)
        // Stop bit = 1.
        // EXPECT: 'parity_err' spikes to 1, 'data_out' is forced to 00
        send_packet(8'b11001100, 1'b1, 1'b1);

       
        // TEST 3: FRAMING ERROR
        // Data: 8'b11110000. Parity = 0 (valid). 
        // We force Stop bit = 0 (ERROR!)
        // EXPECT: 'frame_err' spikes to 1, 'data_out' is forced to 00
        send_packet(8'b11110000, 1'b0, 1'b0);

        // Finish Simulation
        #50;
        $finish;
    end

endmodule
