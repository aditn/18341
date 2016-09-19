module ChipInterface (
  input logic CLOCK_50,
  input logic [9:0] SW,
  input logic [2:0] BUTTON,
  output logic [6:0] HEX3_D, HEX2_D, HEX1_D, HEX0_D);

  logic ready;
  logic[15:0] answer, answer_out, display;
  logic[15:0] clock_cycle_count, clock_cycle_count_out;

  // Instantiate p2 module for matrix multiplication
  p2 p2Mod(.clock(CLOCK_50),
           .reset_l(BUTTON[0]),
           .final_sum(answer),
           .clock_cycle_count(clock_cycle_count),
           .done(ready));

  // Instantiate register to hold answer value for display
  register register_answer(.clock(CLOCK_50),
                           .enable(ready),
                           .reset_l(BUTTON[0]),
                           .d(answer),
                           .q(answer_out));

  // Instantiate register to hold clock counter for display
  register register_clock(.clock(CLOCK_50),
                          .enable(ready),
                          .reset_l(BUTTON[0]),
                          .d(clock_cycle_count),
                          .q(clock_cycle_count_out));

  // Choose to display answer or clock count
  assign display = (SW[1]) ? clock_cycle_count_out : answer_out;

  // Displays to 7-segment Display on FPGA
  sevenSegmentDisplay value4(.valueToDisplay(display[15:12]),
                             .hexDisplay(HEX3_D));
  sevenSegmentDisplay value3(.valueToDisplay(display[11:8]),
                            .hexDisplay(HEX2_D));
  sevenSegmentDisplay value2(.valueToDisplay(display[7:4]),
                             .hexDisplay(HEX1_D));
  sevenSegmentDisplay value1(.valueToDisplay(display[3:0]),
                             .hexDisplay(HEX0_D));
   

endmodule


module p2 (
  input clock, reset_l,
  output[15:0] final_sum, clock_cycle_count,
  output done);

  //logic[7:0] romABlocks, romBBlocks, sum_registers, registers,
  //           mult, adder_L1, adder_L2, adder_L3, adder_L4, adder_L5;

  logic[5:0] romB_addr;
  logic[11:0] romA_addr;

  logic[7:0] col_A[64], row_B[64], row_B_out[64];
  logic[15:0] col_A_out[64], mult_result[64], 
              addL1_result[32], addL2_result[16],
              addL3_result[8], addL4_result[4],
              addL5_result[2];

  logic[31:0] doneValA;
  logic[7:0]  doneValB;
  logic doneA, doneB;

  /*assign romABlocks = 13;
  assign romBBlocks = 4;
  assign sum_registers = 64;
  assign registers = 64;
  assign mult = 64;
  assign adder_L1 = 64;
  assign adder_L2 = 32;
  assign adder_L3 = 16;
  assign adder_L4 = 8;
  assign adder_L5 = 4;*/

  assign doneValA = 64*64-1;
  assign doneValB = 63;
  assign done = doneA;

  // Instantiate counter for keeping track of clock cycles
  counterPlain clock_counter(.clock(clock),
                             .reset_l(reset_l),
                             .enable(~done),
                             .q(clock_cycle_count));

  // Instantiate counter register for address to romA
  counter romA_addr_counter(.clock(clock),
                            .reset_l(reset_l),
                            .done(doneA),
                            .doneVal(doneValA),
                            .q(romA_addr));

  // Instantiate counter register for address to romB
  counter #(.WIDTH(6), .DONE_WIDTH(32))
         romB_addr_counter (.clock(clock),
                            .reset_l(reset_l),
                            .done(doneB),
                            .doneVal(doneValB),
                            .q(romB_addr));


  genvar i,j,k,l,m,n,q,r,s,t;
  generate
    // Instantiate 13 romA blocks (26 vals/clk cycle)
    for (i = 0; i < 12; i++) begin: romAblock
      romA romA_blocks(.address_a(romA_addr+2*i),
                       .address_b(romA_addr+2*i+1),
                       .clock(clock),
                       .q_a(col_A[i]),
                       .q_b(col_A[i+1]));
    end

    // Instantiate 4 romB blocks (8 vals/clk cycle)
    for (j = 0; j < 3; j++) begin: romBblock
      romB romB_blocks(.address_a(romB_addr+2*j),
                       .address_b(romBBlocks+2*j+1),
                       .clock(clock),
                       .q_a(row_B[j]),
                       .q_b(row_B[j+1]));
    end

    // Instantiate 64 sum_registers for matrix A
    for (k = 0; k < 63; k++) begin: sumRegs
      sum_register sum_register_A(.clock(clock),
                                  .enable(~doneA),
                                  .reset_l(reset_l),
                                  .d(col_A[k]),
                                  .q(col_A_out[k]));
    end

    // Instantiate 64 registers for matrix B
    for (l = 0; l < 63; l++) begin: regs
      register register_B(.clock(clock),
                          .enable(~doneB),
                          .reset_l(reset_l),
                          .d(row_B[l]),
                          .q(row_B_out[l]));
    end

    // Instantiate 64 multipliers
    for (m = 0; m < 63; m++) begin: mults
      multiplier multi(.dataa(col_A_out[m]),
                        .datab(row_B_out[m]),
                        .result(mult_result[m]));
    end

    // Instantiate first layer of adders after multipliers
    for (n = 0; n < 63; n=n+2) begin: aL1
      adder addL1(.a(mult_result[n]),
                  .b(mult_result[n+1]),
                  .sum(addL1_result[n/2]));
    end

    // Instantiate second layer of adders after multipliers
    for (q = 0; q < 31; q=q+2) begin: aL2
      adder addL2(.a(addL1_result[q]),
                  .b(addL1_result[q+1]),
                  .sum(addL2_result[q/2]));
    end

    // Instantiate third layer of adders after multipliers
    for (r = 0; r < 15; r=r+2) begin: aL3
      adder addL3(.a(addL2_result[r]),
                  .b(addL2_result[r+1]),
                  .sum(addL3_result[r/2]));
    end

    // Instantiate fourth layer of adders after multipliers
    for (s = 0; s < 7; s=s+2) begin: aL4
      adder addL4(.a(addL3_result[s]),
                  .b(addL3_result[s+1]),
                  .sum(addL4_result[s/2]));
    end

    // Instantiate fifth layer of adders after multipliers

    for (t = 0; t < 3; t=t+2) begin: aL5
      adder addL5(.a(addL4_result[t]),
                  .b(addL4_result[t+1]), 
                  .sum(addL5_result[t/2]));
    end

  endgenerate

  // Instantiate adder to calculate final sum
  adder addL6(.a(addL5_result[0]),
              .b(addL5_result[1]),
              .sum(final_sum));



endmodule


module counterPlain (
  input clock, reset_l, enable,
  output[15:0] q);

  always @(posedge clock or negedge reset_l)
    if (~reset_l)
      q <= 0;
    else if (enable)
      q <= q + 1;

endmodule


module counter (
  input clock, reset_l,
  input[DONE_WIDTH-1:0] doneVal,
  output done,
  output[WIDTH-1:0] q);

  parameter WIDTH = 12;
  parameter DONE_WIDTH = 32;

  always @(posedge clock or negedge reset_l)
    if (~reset_l) begin
      q <= 0;
      done = 0;
    end
    else begin
      q <= q + 1;
      done = 0;
      if (q == doneVal)
        done = 1;
    end

endmodule


module register (
  input clock, enable, reset_l,
  input[7:0] d,
  output[7:0] q);  

  always @(posedge clock or negedge reset_l)
    if (~reset_l)
      q <= 0;
    else if (enable)
      q <= d;

endmodule


module sum_register (
  input clock, enable, reset_l,
  input[15:0] d,
  output[15:0] q);  

  always @(posedge clock or negedge reset_l)
    if (~reset_l)
      q <= 0;
    else if (enable)
      q <= q + d;

endmodule


module adder (
  input[15:0] a,b,
  output[15:0] sum);

  assign sum = a + b;

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
