`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    fifo
// Author:	   Eric Qin

// Description:    Simple Parameterizable FIFO implementation
// NOTE: Code has initialize statements - will work for FPGAs, but not ASIC
//////////////////////////////////////////////////////////////////////////////////
module fifo (
  clk,

  i_read_packet_en,
  i_write_packet_en,
  i_write_packet,

  o_read_packet,
  o_empty_flag,
  o_full_flag
);

  parameter FIFO_DEPTH = 32;
  parameter LOG2_FIFO_DEPTH = 5;
  parameter DATA_LINE_WIDTH = 40;
  parameter CONTROL_LINE_WIDTH = 0;

  //Inputs
  input clk;
  input i_read_packet_en;
  input i_write_packet_en;
  input [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] i_write_packet;

  //Outputs
  output reg [DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1:0] o_read_packet;
  output o_empty_flag;
  output o_full_flag;


  reg [(DATA_LINE_WIDTH+CONTROL_LINE_WIDTH-1):0] FIFO [0:(FIFO_DEPTH-1)];
  reg [FIFO_DEPTH-1:0] FIFOvalid = 'd0;

  reg [LOG2_FIFO_DEPTH-1:0] head_pointer = 'd0;
  reg [LOG2_FIFO_DEPTH-1:0] tail_pointer = 'd0;

  // write new entry to the tail of the FIFO
  always @ (posedge clk) begin
    // if write enable and there is an empty space....
    if ( (i_write_packet_en == 1'b1) && (FIFOvalid[tail_pointer] == 1'b0) ) begin
      FIFO[tail_pointer] = i_write_packet;
      FIFOvalid[tail_pointer] = 1'b1;

      // increment tail pointer in a circular buffer structure
      if (tail_pointer < (FIFO_DEPTH-1)) begin
        tail_pointer = tail_pointer + 1'b1;
      end else begin
        tail_pointer = 'd0;
      end

    end

    // read new entry from the head of the FIFO
    if ( (i_read_packet_en == 1'b1) && (FIFOvalid[head_pointer] == 1'b1) ) begin
      //if ( ((head_pointer + 1'b1)== tail_pointer) && (i_read_packet_en == 1'b1) && (i_write_packet_en == 1'b0)) begin // fix logic
        //o_read_packet = 'b0; // invalid packet
      //end else begin        
        o_read_packet = FIFO[head_pointer];
      //end

      FIFOvalid[head_pointer] = 1'b0;

      // increment head pointer in a circular buffer structure
      if (head_pointer < (FIFO_DEPTH-1)) begin
        head_pointer = head_pointer + 1'b1;
      end else begin
        head_pointer = 'd0;
      end

    end else begin
      o_read_packet = 'b0; // Invalid packet
    end

  end


  // Logic to determine if FIFO is empty or full
  assign o_empty_flag = !FIFOvalid[head_pointer];
  assign o_full_flag = FIFOvalid[tail_pointer];
  
endmodule


