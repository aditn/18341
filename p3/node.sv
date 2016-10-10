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
  logic [7:0] q[4], r[4]; // this is used to hold bytes 2-4 before sending
  logic [2:0] sendCounter, receiveCounter;
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
  assign payload_outbound = ((free_outbound && (sendCounter==0) && (!emptyFIFO))) ? byte0 :q[sendCounter];
  // Only read from FIFO when router requests
  assign readFIFO = (free_outbound && (sendCounter==0) && (!emptyFIFO));
  assign cQ_full = fullFIFO;

  // Node can receive from router after done receiving previously
  assign free_inbound = !((0<receiveCounter) && (receiveCounter<4));
  assign pkt_out_avail = (receiveCounter == 3'd4);
  assign pkt_out.sourceID = r[0][7:4];
  assign pkt_out.destID = r[0][3:0];
  assign pkt_out.data = {r[1],r[2],r[3]};

  // Increments counter when sending bytes to router
  always_ff @(posedge clock or negedge reset_b) begin: sendCntr
    if(~reset_b)
      sendCounter <= 0;
    else if(put_outbound)
      sendCounter <= sendCounter + 3'd1;
    else
      sendCounter <= 0;
  end: sendCntr

  always_ff @(posedge clock or negedge reset_b) begin: storeBytesNodetoRtr
    if(~reset_b) begin
      q[0] <= 8'd0;
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
    else if(!put_outbound) begin
      q[0] <= 8'd0;
      q[1] <= 8'd0;
      q[2] <= 8'd0;
      q[3] <= 8'd0;
    end
    else begin
      q[0] <= q[0];
      q[1] <= q[1];
      q[2] <= q[2];
      q[3] <= q[3];
    end
  end: storeBytesNodetoRtr


  always_ff @(posedge clock or negedge reset_b) begin: rtrToTBStore
    if (~reset_b) begin
      r[0] <= 8'dx;
      r[1] <= 8'dx;
      r[2] <= 8'dx;
      r[3] <= 8'dx;
      receiveCounter <= 3'd0;
    end
    else begin
      if(pkt_out_avail) begin
        receiveCounter <= 3'd0;
      end
      if(put_inbound) begin // When you receive byte from router start storing
        r[receiveCounter] <= payload_inbound;
        receiveCounter <= receiveCounter + 3'd1;
      end
      else if(receiveCounter == 3'd4) begin
        // After receiving all bytes, set to x to avoid resending value
        r[0] <= 8'dx;
        r[1] <= 8'dx;
        r[2] <= 8'dx;
        r[3] <= 8'dx;
      end
      else begin
        receiveCounter <= receiveCounter;
      end
    end
  end: rtrToTBStore


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

  logic [WIDTH-1:0] Q[8];
  logic [2:0] rdPtr, wrPtr, counter;
  //logic rdPtrReset, wrPtrReset;

  assign full = (counter == 3'd5);
  assign empty = (counter == 3'd0);
  //assign rdPtrReset = (rdPtr == 3'd4);
  //assign wrPtrReset = (wrPtr == 3'd4);
  assign data_out = Q[rdPtr];

  always_ff @(posedge clock or negedge reset_b) begin: ctr
    if (~reset_b)
      counter <= 0;
    else if(re && !empty) begin
      counter <= counter - 3'd1;
    end
    else if(we && !full) begin
      counter <= counter + 3'd1;
    end
    else
      counter <= counter;
  end: ctr

  always_ff @(posedge clock or negedge reset_b) begin: rd_ptr
    if (~reset_b)
      rdPtr <= 3'd0;
    else if(re && !empty)
      rdPtr <= rdPtr + 3'd1;
    //else if(rdPtrReset)
      //rdPtr <= 3'd0;
    else
      rdPtr <= rdPtr;
  end: rd_ptr

  always_ff @(posedge clock or negedge reset_b) begin: wr_ptr
    if (~reset_b)
      wrPtr <= 3'd0;
    else if(we && !full)
      wrPtr <= wrPtr + 3'd1;
    //else if(wrPtrReset)
      //wrPtr <= 3'd0;
    else
      wrPtr <= wrPtr;
  end: wr_ptr

  always_ff @(posedge clock) begin: din
    if(we && !full)
      Q[wrPtr] <= data_in;
    else
      Q[wrPtr] <= Q[wrPtr];
  end: din

  /*always_ff @(posedge clock or negedge reset_b) begin: dout
    if(~reset_b)
      data_out <= 32'd0;
    else begin// always have value at rdPtr on data_out line to meet timing req
      data_out <= Q[rdPtr];
    end
  end: dout*/


endmodule : fifo
