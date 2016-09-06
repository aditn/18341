module downStream(
  input logic [7:0] potVal,
  input logic load, clk, rst_l,
  output logic [7:0] sum);

  always_ff @(posedge clk, negedge rst_l) 
    if (~reset_l) sum <= 0;
    else if (load) sum <=potVal;

endmodule downStream