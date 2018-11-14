`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    strawman_s_rx_fsm
// Author:	   Eric Qin

// Description:    State Machine of Strawman FSM
    

//////////////////////////////////////////////////////////////////////////////////
module strawman_tx_fsm (
  clk,
  o_flit,
  o_flit_valid,

  o_ready, // fsm ready for new bus input

  i_protocol_bus,
  i_valid

);

  parameter FIFO_DEPTH = 32;
  parameter LOG2_FIFO_DEPTH = 5;
  parameter DATA_LINE_WIDTH = 40;
  parameter CONTROL_LINE_WIDTH = 0;
  parameter WORD_SIZE = 32;

  parameter LOG2_NUM_STATES = 4;

  parameter [LOG2_NUM_STATES-1:0] 
	IDLE  = 4'b0000,
	WRITE_REQ_HEADER = 4'b0001,
	WRITE_REQ_EX_HEADER = 4'b0010,
	WRITE_REQ_BODY = 4'b0011,
	READ_REQ_HEADER = 4'b0100,
	READ_REQ_EX_HEADER = 4'b0101,
	READ_REQ_EX_BODY = 4'b0110,
	READ_RESP_HEADER = 4'b0111,
	READ_RESP_EX_HEADER = 4'b1000,
	READ_RESP_BODY = 4'b1001;

  input clk;
  output reg [DATA_LINE_WIDTH-1:0] o_flit;
  output reg o_flit_valid;

  output reg o_ready;

  input [1075:0] i_protocol_bus;
  input i_valid;

  wire w_mode;
  wire w_valid;
  wire [2:0] w_cmd;
  wire [2:0] w_length;
  wire [31:0] w_address;
  wire [1023:0] w_data;
  wire [5:0] w_feature0;
  wire [5:0] w_feature1;

  assign w_mode = i_protocol_bus[0];
  assign w_valid = i_protocol_bus[1];
  assign w_cmd = i_protocol_bus[4:2];
  assign w_length = i_protocol_bus[7:5];
  assign w_address = i_protocol_bus[39:8];
  assign w_data = i_protocol_bus[1063:40];
  assign w_feature0 = i_protocol_bus[1069:1064];
  assign w_feature1 = i_protocol_bus[1075:1070];


  reg [LOG2_NUM_STATES-1:0] current_state = 'b0; // start at IDLE
  reg [LOG2_NUM_STATES-1:0] next_state = 'b0; // start at IDLE

  // TODO: Implement a counter system
  // counter variable
  reg [6:0] counter = 'b0;
  reg [5:0] cycles2hflit = 'b0;

  reg is_header_flit;

  reg toggle_fsm = 1'b0;

  wire [2:0] length2;

  assign length2 = w_length; // FIXME


  always @ (cycles2hflit) begin
    if (cycles2hflit == 'b0) begin
      is_header_flit = 1'b1;
    end else begin
      is_header_flit = 1'b0;
    end
  end

  always @(posedge clk) begin
    current_state <= next_state;
  end


  // move state machine
  always @ (posedge clk) begin
    if ((current_state ==  WRITE_REQ_BODY) || (current_state ==  READ_RESP_BODY)) begin
      toggle_fsm <= ~toggle_fsm;
    end
  end

//---------------------------------------------------------------------
  always @(current_state, i_protocol_bus, counter, toggle_fsm) begin
    o_flit_valid = 1'b0;
    
    case (current_state)
//---------------------------------------------------------------------
      IDLE : begin

        counter = 'b0;
        o_flit_valid = 1'b0;
        o_flit = 'b0;
        cycles2hflit = 'b0;

        // setting the fsm ready bit to retieve new packet information from chiplet
        if ((i_valid == 1'b1) && (w_valid == 1'b1)) begin // TODO: add cycles to header flit logic for o_ready in state machine
          o_ready = 1'b0;
        end else begin
          o_ready = 1'b1;
        end

        // Lightweight mode
        if ((i_valid == 1'b1) && (w_valid == 1'b1)) begin

	  if (w_mode == 1'b0) begin
            if (w_cmd == 3'b000) begin // Read Req
              next_state = READ_REQ_HEADER;
            end else if (w_cmd == 3'b001) begin // Write Req
              next_state = WRITE_REQ_HEADER;
            end else if (w_cmd == 3'b010) begin // Read Resp
              next_state = READ_RESP_HEADER;
            end else begin
              next_state = IDLE;
            end
          // Extended mode
          end else begin
            if (w_cmd == 3'b000) begin // Read Req TODO
              next_state = READ_REQ_EX_HEADER;
            end else if (w_cmd == 3'b001) begin // Write Req
              next_state = WRITE_REQ_EX_HEADER;
            end else if (w_cmd == 3'b010) begin // Read Resp
              next_state = READ_RESP_EX_HEADER;
            end else begin
              next_state = IDLE;
            end
          end

        end else begin
          next_state = IDLE;
        end

      end
//---------------------------------------------------------------------
      WRITE_REQ_HEADER : begin
        counter = 'b0;
        o_ready = 1'b0;
        o_flit_valid = 1'b1;

        o_flit = {w_address, w_length, w_cmd, w_valid, w_mode};

        if (length2 == 3'b000) begin // 4B
          cycles2hflit = 6'b1; 
        end else if (length2 == 3'b001) begin // 8B
          cycles2hflit = 6'b10;
        end else if (length2 == 3'b010) begin // 16B
          cycles2hflit = 6'b100;
        end else if (length2 == 3'b011) begin // 32B
          cycles2hflit = 6'b1000;
        end else if (length2 == 3'b100) begin // 64B
          cycles2hflit = 6'b10000;
        end else if (length2 == 3'b101) begin // 128B
          cycles2hflit = 6'b100000;
        end

        next_state = WRITE_REQ_BODY;

      end
//---------------------------------------------------------------------
      WRITE_REQ_EX_HEADER : begin
        counter = 'b0;
        o_ready = 1'b0;
        o_flit_valid = 1'b1;

        o_flit = {w_feature1, w_feature0, w_length, w_cmd, w_valid, w_mode};

        if (length2 == 3'b000) begin // 4B
          cycles2hflit = 6'b1; 
        end else if (length2 == 3'b001) begin // 8B
          cycles2hflit = 6'b10;
        end else if (length2 == 3'b010) begin // 16B
          cycles2hflit = 6'b100;
        end else if (length2 == 3'b011) begin // 32B
          cycles2hflit = 6'b1000;
        end else if (length2 == 3'b100) begin // 64B
          cycles2hflit = 6'b10000;
        end else if (length2 == 3'b101) begin // 128B
          cycles2hflit = 6'b100000;
        end

        next_state = WRITE_REQ_BODY;
      end

//---------------------------------------------------------------------
      WRITE_REQ_BODY : begin
        counter = counter + 1'b1;
        o_ready = 1'b0;
        o_flit_valid = 1'b1;
        if ((w_mode == 1'b1) && (counter == 1)) begin
          o_flit = {w_address};
          cycles2hflit = cycles2hflit + 1'b1;
        end else begin
          if (w_mode == 1'b0) begin
            o_flit = w_data[ (counter*32-1) -: 32];
          end else begin
            o_flit = w_data[ ((counter-1)*32-1) -: 32];
          end
        end
        if (counter == cycles2hflit) begin
          next_state = IDLE;
        end else begin
          next_state = WRITE_REQ_BODY;
        end
      end

//---------------------------------------------------------------------
      READ_REQ_HEADER : begin
        counter = 'b0;
        o_ready = 1'b0;
        o_flit_valid = 1'b1;

        o_flit = {w_address, w_length, w_cmd, w_valid, w_mode};


        next_state = IDLE;
      end

//---------------------------------------------------------------------
      READ_REQ_EX_HEADER : begin
        counter = 'b0;
        o_ready = 1'b0;
        o_flit_valid = 1'b1;

        o_flit = {w_feature1, w_feature0, w_length, w_cmd, w_valid, w_mode};

        next_state = READ_REQ_EX_BODY;
      end

//---------------------------------------------------------------------
      READ_REQ_EX_BODY : begin
        counter = 'b0;
        o_ready = 1'b0;
        o_flit_valid = 1'b1;

        o_flit = {w_address};

        next_state = IDLE;
      end

//---------------------------------------------------------------------
      READ_RESP_HEADER : begin
        counter = 'b0;
        o_ready = 1'b0;
        o_flit_valid = 1'b1;

        o_flit = {w_data, w_length, w_cmd, w_valid, w_mode};

        if (length2 == 3'b000) begin // 4B
          cycles2hflit = 6'b0; 
        end else if (length2 == 3'b001) begin // 8B
          cycles2hflit = 6'b01;
        end else if (length2 == 3'b010) begin // 16B
          cycles2hflit = 6'b011;
        end else if (length2 == 3'b011) begin // 32B
          cycles2hflit = 6'b0111;
        end else if (length2 == 3'b100) begin // 64B
          cycles2hflit = 6'b01111;
        end else if (length2 == 3'b101) begin // 128B
          cycles2hflit = 6'b011111;
        end

        next_state = READ_RESP_BODY;

      end

//---------------------------------------------------------------------
      READ_RESP_EX_HEADER : begin
        counter = 'b0;
        o_ready = 1'b0;
        o_flit_valid = 1'b1;

        o_flit = {w_feature1, w_feature0, w_length, w_cmd, w_valid, w_mode};

        if (length2 == 3'b000) begin // 4B
          cycles2hflit = 6'b1; 
        end else if (length2 == 3'b001) begin // 8B
          cycles2hflit = 6'b10;
        end else if (length2 == 3'b010) begin // 16B
          cycles2hflit = 6'b100;
        end else if (length2 == 3'b011) begin // 32B
          cycles2hflit = 6'b1000;
        end else if (length2 == 3'b100) begin // 64B
          cycles2hflit = 6'b10000;
        end else if (length2 == 3'b101) begin // 128B
          cycles2hflit = 6'b100000;
        end

        next_state = READ_RESP_BODY;
      end

//---------------------------------------------------------------------
      READ_RESP_BODY : begin
        counter = counter + 1'b1;
        o_ready = 1'b0;
        o_flit_valid = 1'b1;

        if (w_mode == 1'b0) begin
          o_flit = w_data[ ((counter+1)*32-1) -: 32];
        end else begin
          o_flit = w_data[ ((counter)*32-1) -: 32];
        end

        if (counter == cycles2hflit) begin
          next_state = IDLE;
        end else begin
          next_state = READ_RESP_BODY;
        end

      end

//---------------------------------------------------------------------
      default: begin
        next_state = IDLE;
      end
//---------------------------------------------------------------------
    endcase
  end


  
endmodule
