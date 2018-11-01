`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    fifos_interface
// Author:	   Eric Qin

// Description:    Fifo system (One master and one slave interface)
//			(STRAWMAN-inspired interface design)
//////////////////////////////////////////////////////////////////////////////////
module fifos_interface (
  clk,

  // master core send information to interface (Send Request)
  i_mc_sreq_inbits,
  i_mc_sreq_wen,
  o_mc_sreq_fifo_empty,
  o_mc_sreq_fifo_full,
  
  // slave core recieve information from interface (Recieve Request)
  i_sc_rreq_ren,
  o_sc_rreq_outbits,

  // slave core recieve information from interface (Send Response)
  i_sc_sresp_inbits,
  i_sc_sresp_wen,
  o_sc_sresp_fifo_empty,
  o_sc_sresp_fifo_full,


  // master core recieve information to interface (Recieve Response)
  i_mc_rresp_ren,
  o_mc_rresp_outbits,

  // credits
  o_credits_m2s,
  o_credits_s2m

);

  parameter FIFO_DEPTH = 32;
  parameter LOG2_FIFO_DEPTH = 5;
  parameter DATA_LINE_WIDTH = 40;
  parameter CONTROL_LINE_WIDTH = 0;

  input clk;

  // ------------------------------------------------------------
  // master core send information to interface (Send Request)
  // ------------------------------------------------------------
  input [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] i_mc_sreq_inbits; // master core and send request FIFO connection
  input i_mc_sreq_wen; // master core and send request FIFO connection
  output o_mc_sreq_fifo_empty; // master core and send request FIFO connection
  output o_mc_sreq_fifo_full; // master core and send request FIFO connection

  wire [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] w_req_bus; // bus connection between send request FIFO and recieve request FIFO

  // slave core recieve information from interface (Recieve Request)
  input i_sc_rreq_ren;
  output [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] o_sc_rreq_outbits;
  wire w_sc_rreq_fifo_empty;
  wire w_sc_rreq_fifo_full, w_sc_rreq_fifo_full_aib;

  // slave core recieve information from interface (Send Response)
  input [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] i_sc_sresp_inbits;
  input i_sc_sresp_wen;
  output o_sc_sresp_fifo_empty;
  output o_sc_sresp_fifo_full;

  wire [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] w_resp_bus; // bus connection between send request FIFO and recieve request FIFO

  // master core recieve information to interface (Recieve Response)
  input i_mc_rresp_ren;
  output [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] o_mc_rresp_outbits;
  wire w_mc_rresp_fifo_empty;
  wire w_mc_rresp_fifo_full, w_mc_rresp_fifo_full_aib;

  /// credit system nets
  output wire [LOG2_FIFO_DEPTH:0] o_credits_m2s;
  output wire [LOG2_FIFO_DEPTH:0] o_credits_s2m;

  reg [LOG2_FIFO_DEPTH:0] credits_m2s = FIFO_DEPTH;
  reg [LOG2_FIFO_DEPTH:0] credits_s2m = FIFO_DEPTH;

  wire [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] w_req_bus_aib, w_resp_bus_aib;

  // Master core sends information from interface (Send Request) FIFOs
  fifo M_fifo_sreq (
    .clk(clk),

    .i_read_packet_en(!w_sc_rreq_fifo_full_aib),
    .i_write_packet_en(i_mc_sreq_wen),
    .i_write_packet(i_mc_sreq_inbits),

    .o_read_packet(w_req_bus),
    .o_empty_flag(o_mc_data_sr_empty),
    .o_full_flag(o_mc_data_sr_full)
  );

  // slave core recieves information from interface (Recieve Request) FIFOs
  fifo S_fifo_rreq (
    .clk(clk),

    .i_read_packet_en(i_sc_rreq_ren),
    .i_write_packet_en(!w_sc_rreq_fifo_full),
    .i_write_packet(w_req_bus_aib),

    .o_read_packet(o_sc_rreq_outbits),
    .o_empty_flag(w_sc_rreq_fifo_empty),
    .o_full_flag(w_sc_rreq_fifo_full)
  );


  // slave core sends information from interface (Send Response) FIFOs
  fifo S_fifo_sresp (
    .clk(clk),

    .i_read_packet_en(!w_mc_rresp_fifo_full_aib),
    .i_write_packet_en(i_sc_sresp_wen),
    .i_write_packet(i_sc_sresp_inbits),

    .o_read_packet(w_resp_bus),
    .o_empty_flag(o_sc_sresp_fifo_empty),
    .o_full_flag(o_sc_sresp_fifo_full)
  );

  // master core recievs information to interface (Recieve Response) FIFOs
  fifo M_fifo_rresp (
    .clk(clk),

    .i_read_packet_en(i_mc_rresp_ren),
    .i_write_packet_en(!w_mc_rresp_fifo_full),
    .i_write_packet(w_resp_bus_aib),

    .o_read_packet(o_mc_rresp_outbits),
    .o_empty_flag(w_mc_rresp_fifo_empty),
    .o_full_flag(w_mc_rresp_fifo_full)
  );

  // Credit-based counter system... For detecting credits - a custom FSM must be built
  // for wormhole / full packet installation.....

  // NEED TO VERIFY
  always @ (posedge clk) begin
    if ((i_sc_rreq_ren) && (!w_sc_rreq_fifo_full)) begin
      credits_m2s <= credits_m2s;
    end else if ((i_sc_rreq_ren) && (credits_m2s < FIFO_DEPTH)) begin // fsm reads from fifo
      credits_m2s <= credits_m2s + 1'b1;
    end else if ((!w_sc_rreq_fifo_full) && (credits_m2s < FIFO_DEPTH)) begin // writes to fifo
      credits_m2s <= credits_m2s - 1'b1;
    end

    if ((i_mc_rresp_ren) && (!w_mc_rresp_fifo_full)) begin
      credits_s2m <= credits_s2m;
    end else if ((i_mc_rresp_ren) && (credits_m2s < FIFO_DEPTH)) begin // fsm reads from fifo
      credits_s2m <= credits_s2m + 1'b1;
    end else if ((!w_mc_rresp_fifo_full) && (credits_m2s < FIFO_DEPTH)) begin // writes to fifo
      credits_s2m <= credits_s2m - 1'b1;
    end

  end 
  
  assign o_credits_s2m = credits_s2m;
  assign o_credits_m2s = credits_m2s;

  // AIB interface removed...

endmodule


