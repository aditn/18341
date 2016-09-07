////////////
// p1: Top module that wires together testbench, sumItUp, and
// downStream. Also uses buttons, LEDs, Clock and Seven-Segment
// Display on FPGA.
//
// INPUTS:
//      BUTTON: BUTTON2 and BUTTON0 are used for reset and starting the
//              testbench respectively.
//    CLOCK_50: 50 MHz clock
// OUTPUTS:
//      HEXn_D: denotes which Seven-segment display to write to (active low)
//        LEDG: denotes which LEDG to enable
////////////

module p1 (
  output logic [6:0] HEX3_D, HEX2_D, HEX1_D, HEX0_D,
  output logic [9:0] LEDG,
  input logic  [2:0] BUTTON,
  input logic  CLOCK_50);

  logic done, go_l;
  logic [7:0] valueToinA, tbsum, sumfinalOut, sum;

  //////////////////////
  // tatb: testbench that sends values to sumItUp and checks if the
  //       sum is correct
  //INPUTS:
  //        ck: clock
  //      done: reports when testbench finishes sending numbers
  //   reset_l: active low reset bit
  //   Button0: test bench sends values while BUTTON0 is held
  //     tbSum: testbench summation value to check against sumItUp's value.
  //            Displayed on HEX3,2.
  // outResult: wire downstream thread's output value here to set LEDG[0]
  //            when values are equal.
  //
  //OUTPUTS:
  //valueToinA: values sent from testbench to sumItUp's inA
  //      go_l: tells when testbench will start sending values
  //        L0: boolean that is set when testbench sum and downstream thread's
  //            output value are equal.
  //////////////////////

  // Testbench that sends values to sumItUp and determines if the
  // final sum is correct/
  tatb testbench (
    .ck(CLOCK_50),
    .done(done),
    .reset_l(BUTTON[2]),
    .Button0(BUTTON[0]), 
    .valueToinA(valueToinA),
    .tbSum(tbsum),
    .go_l(go_l),
    .L0(LEDG[0]),
    .outResult(sumfinalOut)); 

  // Receives values from testbench and outputs sum to downStream thread
  sumItUp adderSum(
    .ck(CLOCK_50),
    .reset_l(BUTTON[2]),
    .go_l(go_l),
    .inA(valueToinA),
    .done(done),
    .sum(sum));

  // DownStream thread to hold value that is printed to 7-segment display
  downStream dsThread(
    .potVal(sum),
    .load(done),
    .clk(CLOCK_50),
    .rst_l(BUTTON[2]),
    .sum(sumfinalOut));

  // Displays to 7-segment Display on FPGA
  sevenSegmentDisplay tb1Value(.valueToDisplay(tbsum[7:4]), .hexDisplay(HEX3_D));
  sevenSegmentDisplay tb2Value(.valueToDisplay(tbsum[3:0]), .hexDisplay(HEX2_D));
  sevenSegmentDisplay ds1Value(.valueToDisplay(sumfinalOut[7:4]), .hexDisplay(HEX1_D));
  sevenSegmentDisplay ds2Value(.valueToDisplay(sumfinalOut[3:0]), .hexDisplay(HEX0_D));
  
endmodule: p1

////////////
// downStream: holds value of sum to display on FPGA
//
// INPUTS:
//            potVal: potential value to be displayed
//              load: determines whether to set the output to potVal
//               clk: clock
//             rst_l: reset active low
//OUTPUTS:
//               sum: final sum value
////////////
module downStream(
  input logic [7:0] potVal,
  input logic load, clk, rst_l,
  output logic [7:0] sum);

  always_ff @(posedge clk, negedge rst_l) 
    if (~rst_l) sum <= 0;
    else if (load) sum <= potVal;

endmodule


////////////
// sevenSegmentDisplay: Combinational Logic to display seven segment
//                      representation of hexadecimal values.
//
// INPUTS:
//    valueToDisplay: 4-bit value to display
//OUTPUTS:
//        hexDisplay: 7-segment driver that is we write to to display value.
////////////
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
