`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    strawman_rx_fsm
// Author:	   Eric Qin

// Description:    State Machine of Strawman FSM (RX Module)
    

//////////////////////////////////////////////////////////////////////////////////
module strawman_rx_fsm (
  clk,
  i_flit,
  i_slave_rx_ready, // to prevent false writing

  o_slave_rx_ren,

  o_address_valid,
  o_data_valid,
  o_data,
  o_address,

  o_cmd,
  o_cmd_valid,

  o_feature1,
  o_feature1_valid,

  o_feature2,
  o_feature2_valid,

  // for read requests
  o_length,
  o_length_valid

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
  input [DATA_LINE_WIDTH-1:0] i_flit;
  input i_slave_rx_ready;
  output reg o_address_valid;
  output reg o_data_valid;
  output reg o_slave_rx_ren;
  output reg [WORD_SIZE-1:0] o_data;
  output reg [WORD_SIZE-1:0] o_address;

  output reg [2:0] o_cmd;
  output reg o_cmd_valid;

  output reg [5:0] o_feature1;
  output reg o_feature1_valid;

  output reg [5:0] o_feature2;
  output reg o_feature2_valid;

  output reg [2:0] o_length;
  output reg o_length_valid;


  reg [LOG2_NUM_STATES-1:0] current_state = 'b0; // start at IDLE
  reg [LOG2_NUM_STATES-1:0] next_state = 'b0; // start at IDLE

  // counter variable
  reg [7:0] counter = 'b0;
  reg [5:0] cycles2hflit = 'b0;

  reg is_header_flit;

  reg protocol_select;
  wire valid_packet;
  wire [3:0] cmd_value;
  wire [3:0] length;

  reg [DATA_LINE_WIDTH-1:0] i_flit2, i_flit3;
  wire protocol_select2;
  wire valid_packet2;
  wire [3:0] cmd_value2;
  wire [3:0] length2;

  reg toggle_fsm = 1'b0;
  reg w_mode;

  assign valid_packet = i_flit[1];
  assign cmd_value = i_flit[4:2];
  assign length = i_flit[7:5];

  assign protocol_select2 = i_flit2[0];
  assign valid_packet2 = i_flit2[1];
  assign cmd_value2 = i_flit2[4:2];
  assign length2 = i_flit2[7:5];


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

  // reg for 1 cycle delay of in_flit
  always @ (posedge clk) begin
    i_flit2 <= i_flit;
    i_flit3 <= i_flit2;
  end

  // move state machine
  always @ (posedge clk) begin
    if ((current_state ==  WRITE_REQ_BODY) || (current_state ==  READ_RESP_BODY)) begin
      counter <= counter + 1'b1;
      toggle_fsm <= ~toggle_fsm;
    end else begin
      counter <= 'b0;
    end
  end

//---------------------------------------------------------------------
  always @(current_state, i_flit, counter, i_flit2) begin // this causes a time count of x2
    o_address_valid = 1'b0;
    o_data_valid = 1'b0;
    o_cmd_valid = 1'b0;
    o_feature1_valid = 1'b0;
    o_feature2_valid = 1'b0;
    o_length_valid = 1'b0;
    
    case (current_state)
//---------------------------------------------------------------------
      IDLE : begin

        o_slave_rx_ren = 1'b1;
        o_address_valid = 1'b0;
        o_data_valid = 1'b0;
        o_cmd_valid = 1'b0;
        o_feature1_valid = 1'b0;
        o_feature2_valid = 1'b0;
        cycles2hflit = 'b0;

        protocol_select = i_flit[0];


        // Lightweight mode
        if (valid_packet == 1'b1) begin

	  if (protocol_select == 1'b0) begin
            if (cmd_value == 3'b000) begin // Read Req
              w_mode = 1'b0;
              next_state = READ_REQ_HEADER;
            end else if (cmd_value == 3'b001) begin // Write Req
              w_mode = 1'b0;
              next_state = WRITE_REQ_HEADER;
            end else if (cmd_value == 3'b010) begin // Read Resp
              w_mode = 1'b0;
              next_state = READ_RESP_HEADER;
            end else begin
              next_state = IDLE;
            end
          // Extended mode
          end else begin
            if (cmd_value == 3'b000) begin // Read Req 
              w_mode = 1'b1;
              next_state = READ_REQ_EX_HEADER;
            end else if (cmd_value == 3'b001) begin // Write Req
              w_mode = 1'b1;
              next_state = WRITE_REQ_EX_HEADER;
            end else if (cmd_value == 3'b010) begin // Read Resp
              w_mode = 1'b1;
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
        o_slave_rx_ren = 1'b1;

        o_data_valid = 1'b0;
        o_address_valid = 1'b1;
        o_address = i_flit2[39:8];
        o_cmd_valid = 1'b1;
        o_cmd = i_flit2[4:2];


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
        o_slave_rx_ren = 1'b1;

        o_data_valid = 1'b0;
        o_address_valid = 1'b1;
        o_address = i_flit[31:0];
        o_cmd_valid = 1'b1;
        o_cmd = i_flit2[4:2];
        o_feature1_valid = 1'b1;
        o_feature1 = i_flit2[13:8];
        o_feature2_valid = 1'b1;
        o_feature2 = i_flit2[19:14];

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
        o_slave_rx_ren = 1'b1;
        o_address_valid = 1'b0;
        o_cmd_valid = 1'b0;
        o_data_valid = 1'b1;

        if (w_mode == 1'b1) begin
          o_data = i_flit[31:0];
        end else begin
          o_data = i_flit2[31:0];
        end

        if ((counter+1) >= cycles2hflit) begin
          next_state = IDLE;
        end else begin
          next_state = WRITE_REQ_BODY;
        end
      end

//---------------------------------------------------------------------
      READ_REQ_HEADER : begin
        o_slave_rx_ren = 1'b0;

        o_data_valid = 1'b0;
        o_address_valid = 1'b1;
        o_address = i_flit2[39:8];

        o_length = i_flit2[7:5];
        o_length_valid = 1'b1;

        o_cmd_valid = 1'b1;
        o_cmd = i_flit2[4:2];


        next_state = IDLE;
      end

//---------------------------------------------------------------------
      READ_REQ_EX_HEADER : begin
        o_slave_rx_ren = 1'b1;

        o_data_valid = 1'b0;
        //o_address_valid = 1'b0;

        o_length = i_flit2[7:5];
        o_length_valid = 1'b1;

        o_feature1_valid = 1'b1;
        o_feature1 = i_flit2[13:8];

        o_feature2_valid = 1'b1;
        o_feature2 = i_flit2[19:14];

        o_cmd_valid = 1'b1;
        o_cmd = i_flit2[4:2];

        o_address_valid = 1'b1;
        o_address = i_flit[31:0];

        next_state = IDLE;
      end

//---------------------------------------------------------------------
/* 
// Not needed....
      READ_REQ_EX_BODY : begin
        o_slave_rx_ren = 1'b1;

        o_data_valid = 1'b0;
        o_address_valid = 1'b1;
        o_address = i_flit2[31:0];

        next_state = IDLE;
      end
*/
//---------------------------------------------------------------------
      READ_RESP_HEADER : begin
        o_slave_rx_ren = 1'b0;

        o_data_valid = 1'b1;
        o_address_valid = 1'b0;
        o_data = i_flit2[39:8];

        o_cmd_valid = 1'b1;
        o_cmd = i_flit2[4:2];


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
        o_slave_rx_ren = 1'b1;

        o_address_valid = 1'b0;

        o_data_valid = 1'b1;
        o_data = i_flit[31:0];

        o_cmd_valid = 1'b1;
        o_cmd = i_flit2[4:2];

        o_feature1_valid = 1'b1;
        o_feature1 = i_flit2[13:8];

        o_feature2_valid = 1'b1;
        o_feature2 = i_flit2[19:14];

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
        o_slave_rx_ren = 1'b1;
        o_address_valid = 1'b0;
        o_cmd_valid = 1'b0;
    
        o_data_valid = 1'b1;

        if (w_mode == 1'b0) begin
          if ((counter + 1'b1) == cycles2hflit) begin
            next_state = IDLE;
          end else begin
            next_state = READ_RESP_BODY;
          end
        end else begin
          if ((counter + 2'b10) == cycles2hflit) begin
            next_state = IDLE;
          end else begin
            next_state = READ_RESP_BODY;
          end
        end

        if (w_mode == 1'b1) begin
          o_data = i_flit[31:0];
        end else begin
          o_data = i_flit2[31:0];
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
