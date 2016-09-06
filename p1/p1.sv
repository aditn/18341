module p1 (
  output logic [6:0] HEX3_D, HEX2_D, HEX1_D, HEX0_D,
  output logic [9:0] LEDG,
  input logic  [2:0] BUTTON,
  input logic  CLOCK_50);

  logic done, go_l;
  logic [7:0] valueToinA, tbsum, sumfinalOut, sum;

  tatb testbench (.ck(CLOCK_50), .done(done), .reset_l(BUTTON[2]), .Button0(BUTTON[0]), //INPUTS 
   .valueToinA(valueToinA), // OUTPUT: connect this to sumitup’s inA 
   .tbSum(tbsum), // INPUT: tb’s sum for display
   .go_l(go_l), //OUTPUT
   .L0(LEDG[0]),// OUTPUT: L0 indicating sums match
   .outResult(sumfinalOut)); //INPUT: your downstream thread’s
                             // output connected to tb 
  
  sumItUp adderSum(.ck(CLOCK_50), .reset_l(BUTTON[2]), .go_l(go_l), .inA(valueToinA),
                    .done(done), .sum(sum));

  downStream dsThread(.potVal(sum), .load(done), .clk(CLOCK_50), .rst_l(BUTTON[2]), .sum(sumfinalOut));

  sevenSegmentDisplay tb1Value(.valueToDisplay(tbsum[7:4]), .hexDisplay(HEX3_D));
  sevenSegmentDisplay tb2Value(.valueToDisplay(tbsum[3:0]), .hexDisplay(HEX2_D));
  sevenSegmentDisplay ds1Value(.valueToDisplay(sumfinalOut[7:4]), .hexDisplay(HEX1_D));
  sevenSegmentDisplay ds2Value(.valueToDisplay(sumfinalOut[3:0]), .hexDisplay(HEX0_D));
  
endmodule: p1


module sevenSegmentDisplay(
  input logic [3:0] valueToDisplay,
  output logic [6:0] hexDisplay);

  always_comb begin
    unique case (valueToDisplay)
      4'd0:  hexDisplay = 7'b1000000;
      4'd1:  hexDisplay = 7'b1111001;
      4'd2:  hexDisplay = 7'b0100100;
      4'd3:  hexDisplay = 7'b0110000;
      4'd4:  hexDisplay = 7'b0011001;      
      4'd5:  hexDisplay = 7'b0010010;
      4'd6:  hexDisplay = 7'b0000010;
      4'd7:  hexDisplay = 7'b1111000;
      4'd8:  hexDisplay = 7'b0000000;
      4'd9:  hexDisplay = 7'b0011000;
      4'd10: hexDisplay = 7'b0001000;
      4'd11: hexDisplay = 7'b0000011;
      4'd12: hexDisplay = 7'b1000110;
      4'd13: hexDisplay = 7'b0100001;
      4'd14: hexDisplay = 7'b0000110;
      4'd15: hexDisplay = 7'b0001110;
		default: hexDisplay = 7'b1000000;
    endcase
  end

endmodule: sevenSegmentDisplay