module p1 (
  output logic [6:0] HEX3, HEX2, HEX1, HEX0,
  output logic [9:0] LEDG,
  input logic  [2:0] BUTTON,
  input logic  CLOCK_50);

  logic done, go_l;
  logic [7:0] valueToinA, tbsum;

  tatb testbench (.ck(CLOCK_50), .done(done), .reset_l(BUTTON[2]), .Button0(BUTTON[0]), //INPUTS 
   .valueToinA(valueToinA), // OUTPUT: connect this to sumitup’s inA 
   .tbSum(tbsum), // INPUT: tb’s sum for display
   .go_l(go_l), //OUTPUT
   .L0(LEDG[0]),// OUTPUT: L0 indicating sums match
   .outResult(sumfinalOut)); //INPUT: your downstream thread’s
                             // output connected to tb 
  
  sumItUp adderSum(.ck(CLOCK_50), .reset_l(BUTTON2), .go_l(go_l), .inA(valueToinA),
                    .done(done), .sum(sum));

  downStream dsThread(.potVal(sum), .load(done), .clk(CLOCK_50), .rst_l(BUTTON2), .sum(sumfinalOut));

  sevenSegmentDisplay tb1Value(.valueToDisplay(tbSum[7:4]), .hexDisplay(HEX3));
  sevenSegmentDisplay tb2Value(.valueToDisplay(tbSum[3:0]), .hexDisplay(HEX2));
  sevenSegmentDisplay ds1Value(.valueToDisplay(sumfinalOut[7:4]), .hexDisplay(HEX1));
  sevenSegmentDisplay ds2Value(.valueToDisplay(sumfinalOut[3:0]), .hexDisplay(HEX0));
  
endmodule: p1


module sevenSegmentDisplay(
  input logic [3:0] valueToDisplay,
  output logic [6:0] hexDisplay);

  always_comb begin
    case (valueToDisplay)
      4'd0:  hexDisplay = 7'b0000001;
      4'd1:  hexDisplay = 7'b1001111;
      4'd2:  hexDisplay = 7'b0010010;
      4'd3:  hexDisplay = 7'b0000110;
      4'd4:  hexDisplay = 7'b1001100;      
      4'd5:  hexDisplay = 7'b0100100;
      4'd6:  hexDisplay = 7'b0100000;
      4'd7:  hexDisplay = 7'b0001111;
      4'd8:  hexDisplay = 7'b0000000;
      4'd9:  hexDisplay = 7'b0001100;
      4'd10: hexDisplay = 7'b0001000;
      4'd11: hexDisplay = 7'b1100000;
      4'd12: hexDisplay = 7'b0110001;
      4'd13: hexDisplay = 7'b1000010;
      4'd14: hexDisplay = 7'b0110000;
      4'd15: hexDisplay = 7'b0111000;
    endcase
  end

endmodule: sevenSegmentDisplay