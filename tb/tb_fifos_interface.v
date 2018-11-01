`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    tb_fifos_interface
// Author:	   Eric Qin

// Description:    Two FIFO Interface Testbench / STRAWMAN Implementation
//////////////////////////////////////////////////////////////////////////////////
module tb_fifos_interface ();


  parameter FIFO_DEPTH = 32;
  parameter LOG2_FIFO_DEPTH = 5;
  parameter DATA_LINE_WIDTH = 40;
  parameter CONTROL_LINE_WIDTH = 0;

  reg clk = 0;

  reg i_mc_sreq_wen = 0;
  wire o_mc_sreq_fifo_empty = 0, o_mc_sreq_fifo_full = 0;
  reg [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] i_mc_sreq_inbits;

  reg i_sc_rreq_ren = 0;
  wire [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] o_sc_rreq_outbits;

  reg i_sc_sresp_wen = 0;
  wire o_sc_sresp_fifo_empty = 0, o_sc_sresp_fifo_full = 0;
  reg [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] i_sc_sresp_inbits;

  reg i_mc_rresp_ren = 0;
  wire [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] o_mc_rresp_outbits;


  integer i;

  initial begin

    $monitor ("%g i_mc_sreq_wen:%h o_mc_sreq_fifo_empty:%h o_mc_sreq_fifo_full:%h i_mc_sreq_inbits:%h", 
    $time, i_mc_sreq_wen, o_mc_sreq_fifo_empty, o_mc_sreq_fifo_full, i_mc_sreq_inbits);
    $monitor ("%g i_sc_rreq_ren:%h o_sc_rreq_outbits:%h", 
    $time, i_sc_rreq_ren, o_sc_rreq_outbits);
    $monitor ("%g i_sc_sresp_wen:%h o_sc_sresp_fifo_empty:%h o_sc_sresp_fifo_full:%h i_sc_sresp_inbits:%h", 
    $time, i_sc_sresp_wen, o_sc_sresp_fifo_empty, o_sc_sresp_fifo_full, i_sc_sresp_inbits);
    $monitor ("%g i_mc_rresp_ren:%h o_mc_rresp_outbits:%h", 
    $time, i_mc_rresp_ren, o_mc_rresp_outbits);

    clk = 0;

    @ (negedge clk);
    i_mc_sreq_wen = 1;
    // We are causing over flow in master send request fifo
    for (i = 0 ; i < 70; i = i + 1) begin
      i_mc_sreq_inbits  = i;
      @ (negedge clk);
    end
    i_mc_sreq_wen  = 0;
    @ (negedge clk);
    i_sc_rreq_ren = 1;
    // We are causing over flow in slave recieve request fifo
    for (i = 0 ; i < 70; i = i + 1) begin
      @ (negedge clk);
    end
    i_sc_rreq_ren = 0;

    @ (negedge clk);
    i_sc_sresp_wen = 1;
    // We are causing over flow in slave send response fifo
    for (i = 70 ; i < 140; i = i + 1) begin
      i_sc_sresp_inbits  = i;
      @ (negedge clk);
    end
    i_sc_sresp_wen = 0;
    @ (negedge clk);
    i_mc_rresp_ren = 1;
    // We are causing over flow in slave recieve request fifo
    for (i = 70 ; i < 140; i = i + 1) begin
      @ (negedge clk);
    end
    i_mc_rresp_ren = 0;

    #100 $finish;
  end  

  // Generate simulation clock
  always #1 clk = !clk;

  // instantiate fifo system
  fifos_interface strawfifo(
    .clk(clk),

    .i_mc_sreq_inbits(i_mc_sreq_inbits),
    .i_mc_sreq_wen(i_mc_sreq_wen),
    .o_mc_sreq_fifo_empty(o_mc_sreq_fifo_empty),
    .o_mc_sreq_fifo_full(o_mc_sreq_fifo_full),
  
    .i_sc_rreq_ren(i_sc_rreq_ren),
    .o_sc_rreq_outbits(o_sc_rreq_outbits),

    .i_sc_sresp_inbits(i_sc_sresp_inbits),
    .i_sc_sresp_wen(i_sc_sresp_wen),
    .o_sc_sresp_fifo_empty(o_sc_sresp_fifo_empty),
    .o_sc_sresp_fifo_full(o_sc_sresp_fifo_full),

    .i_mc_rresp_ren(i_mc_rresp_ren),
    .o_mc_rresp_outbits(o_mc_rresp_outbits)

  );   


  endmodule



