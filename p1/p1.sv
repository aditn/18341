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
  
endmodule