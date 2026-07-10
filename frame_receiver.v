`timescale 1ns / 1ps

module frame_receiver (
    input  wire       clk,
    input  wire       rst_n, 
    input  wire       in_bit,
    
    output reg        done,
    output reg        parity_err,
    output reg        frame_err,
    output reg  [7:0] data_out
);

    // STATE ENCODINGS
    localparam IDLE   = 2'b00;
    localparam DATA   = 2'b01;
    localparam PARITY = 2'b10;
    localparam STOP   = 2'b11;

   // INTERNAL REGISTERS 
    reg [1:0] current_state;
    reg [1:0] next_state;
    
    reg [3:0] bit_count;      
    reg [7:0] shift_reg;      
    reg       parity_calc;          

    // BLOCK 1: STATE MEMORY (The Clock)
      always @(posedge clk) begin
        if (~rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // BLOCK 2: NEXT STATE LOGIC (The Brain)
     always @(*) begin
        // Default assignment to prevent latches
        next_state = current_state; 

        case (current_state)
            IDLE: begin
                if (in_bit == 1'b0) begin
                    next_state = DATA;
                end
            end

            DATA: begin
                if (bit_count == 4'd7) begin
                    next_state = PARITY;
                end
            end

            PARITY: begin
                next_state = STOP;
            end

            STOP: begin
                next_state = IDLE;
            end
        endcase
    end

    // BLOCK 3: DATAPATH & OUTPUT LOGIC (The Muscle)
      always @(posedge clk) begin
        if (~rst_n) begin
            // Hardware Reset
            bit_count   <= 4'd0;
            shift_reg   <= 8'd0;
            parity_calc <= 1'b0;
            done        <= 1'b0;
            parity_err  <= 1'b0;
            frame_err   <= 1'b0;
            data_out    <= 8'd0;
        end else begin
            done       <= 1'b0;
            parity_err <= 1'b0;
            frame_err  <= 1'b0;

            // Physical actions based on current state
            case (current_state)
                IDLE: begin
                    bit_count <= 4'd0; // Reset counter for next packet
                end

                DATA: begin
                    shift_reg <= {shift_reg[6:0], in_bit}; // Shift and catch
                    bit_count <= bit_count + 1'b1;         // Count the bit
                end

                PARITY: begin
                    parity_calc <= in_bit; // Catch the parity bit
                end

                STOP: begin
                    //Framing Error
                    if (in_bit == 1'b0) begin
                        frame_err <= 1'b1;   
                        data_out  <= 8'd0;   
                    end 
                    //Parity Error
                    else if ((^shift_reg ^ parity_calc) == 1'b1) begin
                        parity_err <= 1'b1;  
                        data_out   <= 8'd0;  
                    end 
                    //Perfect Packet
                    else begin
                        done     <= 1'b1;      
                        data_out <= shift_reg; 
                    end
                end
            endcase
        end
    end

endmodule