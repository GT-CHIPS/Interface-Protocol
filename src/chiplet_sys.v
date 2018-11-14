`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    chiplet_sys
// Author:	   Eric Qin

// Description:    chiplet_sys with a strawman protocol
//////////////////////////////////////////////////////////////////////////////////
module chiplet_sys (
  clk,

  i_master_tx_packetstream, // input to master tx fsm
  i_master_tx_packetstream_valid,
  o_master_tx_fsm_ready, 

  i_slave_tx_packetstream, // input to slave tx fsm
  i_slave_tx_packetstream_wen,
  o_slave_tx_fsm_ready,

  i_slave_rx_ready,
  i_master_rx_ready,

  o_slave_rx_data,
  o_slave_rx_data_valid, 
  o_slave_rx_addr, 
  o_slave_rx_addr_valid, 
  o_slave_rx_cmd,
  o_slave_rx_cmd_valid,
  o_slave_rx_feature0,
  o_slave_rx_feature0_valid,
  o_slave_rx_feature1,
  o_slave_rx_feature1_valid,
  o_slave_rx_length,
  o_slave_rx_length_valid,

  o_master_rx_data, // for writes
  o_master_rx_data_valid, // for writes
  o_master_rx_addr, // for reads and writes
  o_master_rx_addr_valid, // for reads and writes
  o_master_rx_cmd,
  o_master_rx_cmd_valid,
  o_master_rx_feature0,
  o_master_rx_feature0_valid,
  o_master_rx_feature1,
  o_master_rx_feature1_valid,
  o_master_rx_length,
  o_master_rx_length_valid

);

  parameter FIFO_DEPTH = 32;
  parameter LOG2_FIFO_DEPTH = 5;
  parameter DATA_LINE_WIDTH = 40;
  parameter CONTROL_LINE_WIDTH = 0;
  parameter WORD_SIZE = 32;

  input clk;

  input [1075:0] i_master_tx_packetstream; // data bus from chiplet
  input i_master_tx_packetstream_valid;
  output o_master_tx_fsm_ready;

  input [1075:0] i_slave_tx_packetstream; // data bus from chiplet
  input i_slave_tx_packetstream_wen;
  output o_slave_tx_fsm_ready;

  input i_slave_rx_ready, i_master_rx_ready;

  output [31:0] o_slave_rx_data, o_master_rx_data;
  output o_slave_rx_data_valid, o_master_rx_data_valid;

  output [31:0] o_slave_rx_addr, o_master_rx_addr;
  output o_slave_rx_addr_valid, o_master_rx_addr_valid;

  output [2:0] o_slave_rx_cmd, o_master_rx_cmd;
  output o_slave_rx_cmd_valid, o_master_rx_cmd_valid;

  output [5:0] o_slave_rx_feature0, o_master_rx_feature0;
  output o_slave_rx_feature0_valid, o_master_rx_feature0_valid;

  output [5:0] o_slave_rx_feature1, o_master_rx_feature1;
  output o_slave_rx_feature1_valid, o_master_rx_feature1_valid;

  output [2:0] o_slave_rx_length, o_master_rx_length;
  output o_slave_rx_length_valid, o_master_rx_length_valid;


  wire [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] w_sc_rreq_outbits, w_mc_rreq_outbits;// out of fifo into FSM
  wire w_slave_rx_ren, w_master_rx_ren;

  wire [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] w_master_tx_packetstream; // tx packet stream out of FSM 

  wire [DATA_LINE_WIDTH-1:0] w_m_tx_fsm_packet, w_s_tx_fsm_packet;
  wire w_m_tx_fsm_packet_valid, w_s_tx_fsm_packet_valid;

  wire [LOG2_FIFO_DEPTH:0] credits_m2s = FIFO_DEPTH;
  wire [LOG2_FIFO_DEPTH:0] credits_s2m = FIFO_DEPTH;

  wire w_mc_sreq_fifo_empty, w_mc_sreq_fifo_full;
  wire w_sc_sresp_fifo_empty, w_sc_sresp_fifo_full;

  // FIFO interface connection between master and slave chiplet
  fifos_interface fifo_interface (
    .clk(clk),

    // master core send information to interface (Send Request)
    .i_mc_sreq_inbits(w_m_tx_fsm_packet),
    .i_mc_sreq_wen(w_m_tx_fsm_packet_valid),
    .o_mc_sreq_fifo_empty(w_mc_sreq_fifo_empty),
    .o_mc_sreq_fifo_full(w_mc_sreq_fifo_full),
  
    // slave core recieve information from interface (Recieve Request)
    .i_sc_rreq_ren(w_slave_rx_ren), // output of slave rx fsm
    .o_sc_rreq_outbits(w_sc_rreq_outbits),

    // slave core recieve information from interface (Send Response)
    .i_sc_sresp_inbits(w_s_tx_fsm_packet),
    .i_sc_sresp_wen(w_s_tx_fsm_packet_valid),
    .o_sc_sresp_fifo_empty(w_sc_sresp_fifo_empty),
    .o_sc_sresp_fifo_full(w_sc_sresp_fifo_full),

    // master core recieve information to interface (Recieve Response)
    .i_mc_rresp_ren(w_master_rx_ren),
    .o_mc_rresp_outbits(w_mc_rreq_outbits),

    // credits signal for FSM (TODO depending on flow control)
    .o_credits_m2s(credits_m2s),
    .o_credits_s2m(credits_s2m)
  );

  // Slave RX FSM

  strawman_rx_fsm strawman_s_rx_fsm(
    .clk(clk),
    .i_flit(w_sc_rreq_outbits),
    .i_slave_rx_ready(i_slave_rx_ready),

    .o_slave_rx_ren(w_slave_rx_ren),
    .o_address_valid(o_slave_rx_addr_valid),
    .o_data_valid(o_slave_rx_data_valid),
    .o_data(o_slave_rx_data),
    .o_address(o_slave_rx_addr),

    .o_cmd(o_slave_rx_cmd),
    .o_cmd_valid(o_slave_rx_cmd_valid),

    .o_feature0(o_slave_rx_feature0),
    .o_feature0_valid(o_slave_rx_feature0_valid),

    .o_feature1(o_slave_rx_feature1),
    .o_feature1_valid(o_slave_rx_feature1_valid),

    .o_length(o_slave_rx_length),
    .o_length_valid(o_slave_rx_length_valid)
  );

  // Master RX FSM

  strawman_rx_fsm strawman_m_rx_fsm(
    .clk(clk),
    .i_flit(w_mc_rreq_outbits),
    .i_slave_rx_ready(i_master_rx_ready),

    .o_slave_rx_ren(w_master_rx_ren),
    .o_address_valid(o_master_rx_addr_valid),
    .o_data_valid(o_master_rx_data_valid),
    .o_data(o_master_rx_data),
    .o_address(o_master_rx_addr),

    .o_cmd(o_master_rx_cmd),
    .o_cmd_valid(o_master_rx_cmd_valid),

    .o_feature0(o_master_rx_feature0),
    .o_feature0_valid(o_master_rx_feature0_valid),

    .o_feature1(o_master_rx_feature0),
    .o_feature1_valid(o_master_rx_feature1_valid),

    .o_length(o_master_rx_length),
    .o_length_valid(o_master_rx_length_valid)
  );


  // Master TX FSM

  strawman_tx_fsm strawman_m_tx_fsm(
    .clk(clk),
    .o_flit(w_m_tx_fsm_packet),
    .o_flit_valid(w_m_tx_fsm_packet_valid),
    .o_ready(o_master_tx_fsm_ready),
    .i_protocol_bus(i_master_tx_packetstream),
    .i_valid(i_master_tx_packetstream_valid)
  );

  // Slave TX FSM
  strawman_tx_fsm strawman_s_tx_fsm(
    .clk(clk),
    .o_flit(w_s_tx_fsm_packet),
    .o_flit_valid(w_s_tx_fsm_packet_valid),
    .o_ready(o_slave_tx_fsm_ready),
    .i_protocol_bus(i_slave_tx_packetstream),
    .i_valid(i_slave_tx_packetstream_valid)
  );



endmodule


