`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    tb_fifo
// Author:	   Eric Qin

// Description:    Simple FIFO Testbench
//////////////////////////////////////////////////////////////////////////////////
module tb_fifo ();


  parameter FIFO_DEPTH = 32;
  parameter LOG2_FIFO_DEPTH = 5;
  parameter DATA_LINE_WIDTH = 40;
  parameter CONTROL_LINE_WIDTH = 0;

  reg clk, rd_en, wr_en;
  reg [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] data_in ;
  wire [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] data_out ;
  wire empty, full;
  integer i;

  initial begin
    $monitor ("%g wr:%h wr_data:%h rd:%h rd_data:%h", 
    $time, wr_en, data_in,  rd_en, data_out);
    clk = 0;
    rd_en = 0;
    wr_en = 0;
    data_in = 0;
    @ (negedge clk);
    wr_en = 1;
    // We are causing over flow
    for (i = 0 ; i < 70; i = i + 1) begin
      data_in  = i;
      @ (negedge clk);
    end
    wr_en  = 0;
    @ (negedge clk);
    rd_en = 1;
    // We are causing under flow 
    for (i = 0 ; i < 70; i = i + 1) begin
      @ (negedge clk);
    end
    rd_en = 0;
    #100 $finish;
  end  

  // Generate simulation clock
  always #1 clk = !clk;

  // instantiate fifo
  fifo strawfifo(
    .clk(clk),

    .i_read_packet_en(rd_en),
    .i_write_packet_en(wr_en),
    .i_write_packet(data_in),

    .o_read_packet(data_out),
    .o_empty_flag(empty),
    .o_full_flag(full)
  );   


  endmodule



