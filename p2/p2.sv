module p2 (
  input logic CLOCK_50,
  input logic [9:0] SW,
  input logic [2:0] BUTTON,
  output logic [6:0] HEX3_D, HEX2_D, HEX1_D, HEX0_D);

  logic ready;
  logic[15:0] answer, answer_out, display;
  logic[15:0] clock_cycle_count, clock_cycle_count_out;

  // Instantiate p2 module for matrix multiplication
  main mainMod(.clock(CLOCK_50),
           .reset_l(BUTTON[0]),
           .final_sum_out(answer),
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
  assign display = (SW[0]) ? clock_cycle_count_out : answer_out;

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


module main(
  input clock, reset_l,
  output[15:0] final_sum_out, clock_cycle_count,
  output done);

  logic doneIgnore;
  logic[5:0] doneValueIgnore;

  logic[5:0] romB_addr_index;
  logic[12:0] romA_addr_index;

  logic[15:0][7:0] col_A_read, col_A_read_out,
                   row_B_read, row_B_read_out;
  logic[15:0][15:0] mult_result;
  logic[7:0][15:0] addL1_out;
  logic[3:0][15:0] addL2_out;
  logic[1:0][15:0] addL3_out;

  logic[15:0] final_sum_in;

  assign done = (romA_addr_index >= 4096) ? 1'd1 : 1'd0;

  counter #(.WIDTH(13),.INCREMENT(16))
          romA_address(.clock(clock),
                       .reset_l(reset_l),
                       .enable(1),
                       .q(romA_addr_index));
  
  counter #(.WIDTH(6),.INCREMENT(16))
          romB_address(.clock(clock),
                       .reset_l(reset_l),
                       .enable(1),
                       .q(romB_addr_index));

  genvar a,b,c,d,e,f,g,h;

  generate
    // Instantiate 8 romA blocks
    for (a = 0; a < 16; a = a + 2) begin: romAInst
      romA rom_A_blocks(.address_a(a + romA_addr_index),
                        .address_b(a + romA_addr_index + 1),
                        .clock(clock),
                        .q_a(col_A_read[a]),
                        .q_b(col_A_read[a+1]));
    end: romAInst

    // Instantiate 8 romB blocks
    for (b = 0; b < 16; b = b + 2) begin: romBInst
      romB rom_B_blocks(.address_a(b + romB_addr_index),
                        .address_b(b+1 + romB_addr_index),
                        .clock(clock),
                        .q_a(row_B_read[b]),
                        .q_b(row_B_read[b + 1]));
    end: romBInst

    // Instantiate 16 registers to hold matrix A values
    for (g = 0; g < 16; g++) begin: regForA
      register regA(.clock(clock),
                    .enable(1),
                    .reset_l(reset_l),
                    .d(col_A_read[g]),
                    .q(col_A_read_out[g]));
    end: regForA

    // Instantiate 16 registers to hold matrix B values
    for (h = 0; h < 16; h++) begin: regForB
      register regB(.clock(clock),
                    .enable(1),
                    .reset_l(reset_l),
                    .d(row_B_read[h]),
                    .q(row_B_read_out[h]));
    end: regForB

    // Instantiate 16 multipliers
    for (c = 0; c < 16; c++) begin: multInst
      multiplier multi(.dataa(col_A_read_out[c + romA_addr_index]),
                       .datab(row_B_read_out[c + romB_addr_index]),
                       .result(mult_result[c]));
    end: multInst

    // Instantiate 8 adders for first layer
    for (d = 0; d < 8; d++) begin: adderL1 
      adder addL1(.a(mult_result[d]),
                  .b(mult_result[d+8]),
                  .sum(addL1_out[d]));
    end: adderL1

    // Instantiate 4 adders for second layer
    for (e = 0; e < 4; e++) begin: adderL2 
      adder addL2(.a(addL1_out[e]),
                  .b(addL1_out[e+4]),
                  .sum(addL2_out[e]));
    end: adderL2
    
    // Instantiate 2 adders for 3rd layer
    for (f = 0; f < 2; f++) begin: adderL3 
      adder addL3(.a(addL2_out[f]),
                  .b(addL2_out[f+2]),
                  .sum(addL3_out[f]));
    end: adderL3

  endgenerate

  // Instantiate final adder
  adder addL4(.a(addL3_out[0]),
              .b(addL3_out[1]),
              .sum(final_sum_in));

  // Instantiate sum_register for final sum
  sum_register regFinal(.clock(clock),
                    .enable(~done),
                    .reset_l(reset_l),
                    .d(final_sum_in),
                    .q(final_sum_out));

  // Instantiate counter to keep track of clock cycles
  counter clock_cycle_counter(.clock(clock),
                              .reset_l(reset_l),
                              .enable(1),
                              .q(clock_cycle_count));

endmodule


module counter (
  input clock, reset_l, enable,
  output[WIDTH-1:0] q);

  parameter WIDTH = 12;
  parameter INCREMENT = 1;

  always @(posedge clock or negedge reset_l)
    if (~reset_l)
      q <= 0;
    else if (enable)
      q <= q + INCREMENT;

endmodule


module register (
  input clock, enable, reset_l,
  input[WIDTH-1:0] d,
  output[WIDTH-1:0] q);

  parameter WIDTH = 8;  

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
    else
      q <= q;

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
