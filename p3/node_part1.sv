/*********************************************
 *  18-341 Fall 2016                         *
 *  Project 3                                *
 *  Network-on-Chip node                     *
 *********************************************/
// Adit Namdev


module node
 #(parameter NODEID = 0)
 (input  logic       clock, reset_b,
  input  pkt_t       pkt_in,           // data packet from the TB
  input  logic       pkt_in_avail,     // the above data is available
  output logic       cQ_full,          // the Q is full, send no more
  output pkt_t       pkt_out,          // data node received; sending to TB
  output logic       pkt_out_avail,    // signal to the TB
  input  logic       free_outbound,    // from router—it’s free
  output logic       put_outbound,     // to the router
  output logic [7:0] payload_outbound, // data to the router
  output logic       free_inbound,     // to router— you’re free
  input  logic       put_inbound,      // from the router
  input  logic [7:0] payload_inbound); // data from the router

  pkt_t inter_pkt;
  logic [7:0] byte1, byte2, byte3, byte0;
  logic [7:0] q[4]; // this is used to hold bytes 2-4 before sending
  logic [2:0] sendCounter;
  logic readFIFO, emptyFIFO, fullFIFO;

  assign byte0 = {inter_pkt.sourceID, inter_pkt.destID};
  assign byte1 = inter_pkt.data[23:16];
  assign byte2 = inter_pkt.data[15:8];
  assign byte3 = inter_pkt.data[7:0];

  // Set put_outbound first when free_outbound is set and
  // second while send subsequent bits. FIFO must not be
  // empty.
  assign put_outbound = ((free_outbound && (sendCounter==0) && (!emptyFIFO)) ||
                        ((0<sendCounter) && (sendCounter<4)));

  // Only read from FIFO when router requests
  // TODO: account for empty queue
  assign readFIFO = free_outbound;
  assign cQ_full = fullFIFO;


  always_ff @(posedge clock or negedge reset_b) begin: cntr
    if(~reset_b)
      sendCounter <= 0;
    else if(put_outbound)
      sendCounter <= sendCounter + 1;
    else
      sendCounter <= 0;
  end: cntr

  always_ff @(posedge clock or negedge reset_b) begin: dout
    if(~reset_b)
      payload_outbound <= 8'd0;
    else if(put_outbound) // While put_outbound signal is set, send bytes to router
      payload_outbound <= q[sendCounter];
  end: dout

  always_ff @(posedge clock or negedge reset_b) begin: strBytes
    if(~reset_b) begin
      q[1] <= 8'd0;
      q[1] <= 8'd0;
      q[2] <= 8'd0;
      q[3] <= 8'd0;
    end
    // Only read bytes once during packet sending
    else if(free_outbound && (sendCounter==0) && (!emptyFIFO)) begin 
      q[0] <= byte0;
      q[1] <= byte1;
      q[2] <= byte2;
      q[3] <= byte3;
    end
    else begin
      q[0] <= q[0];
      q[1] <= q[1];
      q[2] <= q[2];
      q[3] <= q[3];
    end
  end: strBytes


  fifo queue(.clock(clock),
             .reset_b(reset_b),
             .data_in(pkt_in),
             .we(pkt_in_avail),
             .re(readFIFO),
             .data_out(inter_pkt),
             .full(fullFIFO),
             .empty(emptyFIFO));




endmodule : node





/*  Create a fifo (First In First Out) with depth 4 using the given interface
 *  and constraints.
 *  -The fifo is initally empty.
 *  -Reads are combinational, so "data_out" is valid unless "empty" is asserted.
 *   Removal from the queue is processed on the clock edge.
 *  -Writes are processed on the clock edge.  
 *  -If the "we" happens to be asserted while the fifo is full, do NOT update
 *   the fifo.
 *  -Similarly, if the "re" is asserted while the fifo is empty, do NOT update
 *   the fifo. 
 */

module fifo
  #(parameter WIDTH = 32)
  (input  logic             clock, reset_b,
   input  logic [WIDTH-1:0] data_in,
   input  logic             we, re,
   output logic [WIDTH-1:0] data_out,
   output logic             full, empty);

  logic [WIDTH-1:0] Q[4];
  logic [1:0] rdPtr, wrPtr, counter;

  assign full = (counter == 2'd3);
  assign empty = (counter == 2'd0);

  always_ff @(posedge clock or negedge reset_b) begin: ctr
    if (~reset_b)
      counter <= 0;
    else if(re && !empty)
      counter <= counter - 2'd1;
    else if(we && !full)
      counter <= counter + 2'd1;
    else
      counter <= counter;
  end: ctr

  always_ff @(posedge clock or negedge reset_b) begin: rd_ptr
    if (~reset_b)
      rdPtr <= 2'd0;
    else if(re && !empty)
      rdPtr <= rdPtr + 2'd1;
    else
      rdPtr <= rdPtr;
  end: rd_ptr

  always_ff @(posedge clock or negedge reset_b) begin: wr_ptr
    if (~reset_b)
      wrPtr <= 2'd0;
    else if(we && !full)
      wrPtr <= wrPtr + 2'd1;
    else
      wrPtr <= wrPtr;
  end: wr_ptr

  always_ff @(posedge clock) begin: din
    if(we && !full)
      Q[wrPtr] <= data_in;
    else
      Q[wrPtr] <= Q[wrPtr];
  end: din

  always_ff @(posedge clock or negedge reset_b) begin: dout
    if(~reset_b)
      data_out <= 0;
    else // always have value at rdPtr on data_out line to meet timing req
      data_out <= Q[rdPtr];
  end: dout


endmodule : fifo
