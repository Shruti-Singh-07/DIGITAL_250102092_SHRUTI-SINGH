`timescale 1ns / 1ps

module command_receiver (
    input  wire       clk,
    input  wire       rst_n, 
    input  wire       in_bit,
    
    output reg        done,
    output reg        parity_err,
    output reg        frame_err,
    output reg  [7:0] result
);

    // 1. STATE ENCODINGS (Added CMD state)
    localparam IDLE   = 3'b000;
    localparam CMD    = 3'b001; // New state for the 2 command bits
    localparam DATA   = 3'b010;
    localparam PARITY = 3'b011;
    localparam STOP   = 3'b100;

     // 2. INTERNAL REGISTERS
    reg [2:0] current_state, next_state;
    
    reg [1:0] cmd_reg;        // Stores the 2 command bits
    reg [7:0] shift_reg;      // Stores the 8 data bits
    reg [7:0] reg_A, reg_B;   // Internal Memory Registers A and B
    
    reg [3:0] bit_count;      
    reg       parity_calc;          

    // BLOCK 1: STATE MEMORY 
      always @(posedge clk) begin
        if (~rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // BLOCK 2: NEXT STATE LOGIC
      always @(*) begin
        next_state = current_state; 
        case (current_state)
            IDLE:   if (in_bit == 1'b0) next_state = CMD;
            
            // Wait for 2 Command Bits (Count 0 and 1)
            CMD:    if (bit_count == 4'd1) next_state = DATA;
            
            // Wait for 8 Data Bits (Count 0 to 7)
            DATA:   if (bit_count == 4'd7) next_state = PARITY;
            
            PARITY: next_state = STOP;
            STOP:   next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

   // BLOCK 3: DATAPATH & EXECUTION LOGIC
      always @(posedge clk) begin
        if (~rst_n) begin
            bit_count   <= 4'd0;
            cmd_reg     <= 2'd0;
            shift_reg   <= 8'd0;
            reg_A       <= 8'd0;
            reg_B       <= 8'd0;
            parity_calc <= 1'b0;
            
            done        <= 1'b0;
            parity_err  <= 1'b0;
            frame_err   <= 1'b0;
            result      <= 8'd0;
        end else begin
            done       <= 1'b0;
            parity_err <= 1'b0;
            frame_err  <= 1'b0;
            result     <= 8'd0; 

            case (current_state)
                IDLE: begin
                    bit_count <= 4'd0;
                end

                CMD: begin
                    cmd_reg <= {cmd_reg[0], in_bit};
                    if (bit_count == 4'd1) bit_count <= 4'd0; // Reset counter for DATA 
                    else bit_count <= bit_count + 1'b1;
                end

                DATA: begin
                    shift_reg <= {shift_reg[6:0], in_bit};
                    if (bit_count == 4'd7) bit_count <= 4'd0; // Reset counter
                    else bit_count <= bit_count + 1'b1;
                end

                PARITY: begin
                    parity_calc <= in_bit;
                end

                STOP: begin
                    //Framing Error
                    if (in_bit == 1'b0) begin
                        frame_err <= 1'b1;   
                    end 
                    
                    //Parity Error (Checking the 8 Data Bits)
                    else if ((^shift_reg ^ parity_calc) == 1'b1) begin
                        parity_err <= 1'b1;  
                    end 
                    
                    //Perfect Packet EXECUTE COMMAND
                    else begin
                        done <= 1'b1;      
                        
                        case (cmd_reg)
                            2'b00: begin
                                reg_A  <= shift_reg;
                                result <= shift_reg;
                            end
                            2'b01: begin 
                                reg_B  <= shift_reg;
                                result <= shift_reg;
                            end
                            2'b10: begin 
                                result <= reg_A + reg_B;
                            end
                            2'b11: begin 
                                reg_A  <= 8'd0;
                                reg_B  <= 8'd0;
                                result <= 8'd0;
                            end
                        endcase
                    end
                end
            endcase
        end
    end

endmodule