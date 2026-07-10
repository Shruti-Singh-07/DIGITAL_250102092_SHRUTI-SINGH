module sequence_101_moore(
 input clk,
 input rst_n,
 input in_bit,
 output out_bit
 );
 
 reg Q1 , Q0;
 wire D1 , D0;
 

 assign D1 = (Q0 & ~in_bit) | (Q1 & ~Q0 & in_bit);
 assign D0 = in_bit;
 assign out_bit = (Q1&Q0);
 
 always@(posedge clk) begin
 if(~rst_n)begin
 Q1 <= 1'b0;
 Q0 <= 1'b0;
 end
 else begin
 Q1 <= D1;
 Q0 <= D0;
 end
end
  
endmodule
