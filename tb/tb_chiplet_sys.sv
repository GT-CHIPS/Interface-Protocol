`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    tb_chiplet_sys
// Author:	   Eric Qin

// Description:    Testbench of chiplet sys with FSMs
//////////////////////////////////////////////////////////////////////////////////
module tb_chiplet_sys ();


  parameter FIFO_DEPTH = 32;
  parameter LOG2_FIFO_DEPTH = 5;
  parameter DATA_LINE_WIDTH = 40;
  parameter CONTROL_LINE_WIDTH = 0;
  parameter WORD_SIZE = 32;

  reg clk = 0;

  reg [WORD_SIZE-1:0] o_slave_rx_data;
  reg o_slave_rx_data_valid;
  reg [WORD_SIZE-1:0] o_slave_rx_addr;
  reg o_slave_rx_addr_valid;  
  reg [2:0] o_slave_rx_cmd;
  reg o_slave_rx_cmd_valid;
  reg [5:0] o_slave_rx_feature0; 
  reg o_slave_rx_feature0_valid;
  reg [5:0] o_slave_rx_feature1; 
  reg o_slave_rx_feature1_valid;
  reg [2:0] o_slave_rx_length; 
  reg o_slave_rx_length_valid;

  reg [5:0] stream_counter = 0;
  reg [1075:0] i_stream_2_fsm;
  reg i_stream_2_fsm_valid;
  reg o_m_tx_fsm_ready;

  reg w_master_tx_packetstream_valid;

  integer i;


  //---------------------------------------------

  // Stream bank for TB purposes, input to tx fsm from chiplet

  // mode = 0 for lightweight
  // mode = 1 for extended
  reg [0:0] mode_bank [0:5] = {
    1'b0,
    1'b1,
    1'b0,
    1'b1,
    1'b0,
    1'b1};

  reg [0:0] valid_bank [0:5] = {
    1'b1,
    1'b1,
    1'b1,
    1'b1,
    1'b1,
    1'b1};


  // CMD = 000 for read request 
  // CMD = 001 for write request
  // CMD = 010 for read response
  reg [2:0] cmd_bank [0:5] = {
    3'b001,
    3'b001,
    3'b000,
    3'b000,
    3'b010,
    3'b010};

  // Length = 000 for 4B
  // Length = 001 for 8B
  // Length = 010 for 16B
  // Length = 011 for 32B
  // Length = 100 for 64B
  // Length = 101 for 128B
  reg [2:0] length_bank [0:5] = {
    3'b001,
    3'b010,
    3'b001,
    3'b010,
    3'b001,
    3'b010};

  reg [31:0] address_bank [0:5] = {
    32'hFFDD0000,
    32'h00000888,
    32'hAABB0000,
    32'h00000AAA,
    32'hFFDD0000, // doesnt matter
    32'h00000888}; // doesnt matter

  reg [1023:0] data_bank [0:5] = {
    1023'h000000BB000000AA,
    1023'h00003666000024440000567800001234,
    1023'h0,
    1023'h0,
    1023'h000000BB000000AA,
    1023'h00003666000024440000567800001234};

  reg [5:0] feature0_bank [0:5] = {
    6'b000000,
    6'b000001,
    6'b000000,
    6'b000010,
    6'b000000,
    6'b000011};

  reg [5:0] feature1_bank [0:5] = {
    6'b000000,
    6'b111111,
    6'b000000,
    6'b000111,
    6'b000000,
    6'b111000};

  //---------------------------------------------
/*
  // FIXME: FSM TO GENERATE STREAM BANK
  reg [DATA_LINE_WIDTH-1:0] stream_bank [0:15] = {
    40'h0000000000,
    40'h0000000000,
    40'h0000000000,
    40'hFFDD000026, // Write Request Lightweight 8B , address upper 32 bits
    40'h00000000AA, // Write Stream data, 4B
    40'h00000000BB, // Write Stream data, 4B
    40'h0000000000,
    40'h0000000000,
    40'h0000000000,
    40'h0000000047, // Write Request Extended 16B, 
    40'h0000000888, // Address
    40'h0000001234, // Write Stream data, 4B
    40'h0000005678, // Write Stream data, 4B
    40'h0000002444, // Write Stream data, 4B
    40'h0000003666, // Write Stream data, 4B
    40'h0000000000};

*/  



  initial begin
    clk = 0;
  end  

  // Generate simulation clock
  always #1 clk = !clk;

  always @ (posedge clk) begin

    if (o_m_tx_fsm_ready == 1'b1) begin
      stream_counter = stream_counter + 1'b1;
      i_stream_2_fsm_valid = 1'b1;
    end else begin
      stream_counter = stream_counter;
      i_stream_2_fsm_valid = 1'b0;
    end

    if ( (stream_counter < 5) || (stream_counter > 10) ) begin
      i_stream_2_fsm = 'b0;
    end else begin
      // create a merged structure for all of the streams
      i_stream_2_fsm = {  feature1_bank[stream_counter-5],
			feature0_bank[stream_counter-5], 					
			data_bank[stream_counter-5],
			address_bank[stream_counter-5],
			length_bank[stream_counter-5],
			cmd_bank[stream_counter-5],
			valid_bank[stream_counter-5],
			mode_bank[stream_counter-5]};
     end

  end


  // instantiate fifo system
  chiplet_sys chipletsys(

    .clk(clk),

    .i_master_tx_packetstream(i_stream_2_fsm), // input to master tx fsm
    .i_master_tx_packetstream_valid(i_stream_2_fsm_valid),
    .o_master_tx_fsm_ready(o_m_tx_fsm_ready),  // prevent streaming if master tx fsm is not ready TODO 

    .i_slave_tx_packetstream(), // input to slave tx fsm
    .i_slave_tx_packetstream_wen(),
    .o_slave_tx_fsm_ready(),

    .i_slave_rx_ready(1'b1),
    .i_master_rx_ready(1'b1),

    .o_slave_rx_data(o_slave_rx_data),
    .o_slave_rx_data_valid(o_slave_rx_data_valid), 
    .o_slave_rx_addr(o_slave_rx_addr), 
    .o_slave_rx_addr_valid(o_slave_rx_addr_valid), 
    .o_slave_rx_cmd(o_slave_rx_cmd),
    .o_slave_rx_cmd_valid(o_slave_rx_cmd_valid),
    .o_slave_rx_feature0(o_slave_rx_feature0),
    .o_slave_rx_feature0_valid(o_slave_rx_feature0_valid),
    .o_slave_rx_feature1(o_slave_rx_feature1),
    .o_slave_rx_feature1_valid(o_slave_rx_feature1_valid),
    .o_slave_rx_length(o_slave_rx_length),
    .o_slave_rx_length_valid(o_slave_rx_length_valid),

    .o_master_rx_data(), // for writes
    .o_master_rx_data_valid(), // for writes
    .o_master_rx_addr(), // for reads and writes
    .o_master_rx_addr_valid(), // for reads and writes
    .o_master_rx_cmd(),
    .o_master_rx_cmd_valid(),
    .o_master_rx_feature0(),
    .o_master_rx_feature0_valid(),
    .o_master_rx_length(),
    .o_master_rx_length_valid()
  );   

  // Print out all valid data to a textfile && timestamp
  // Ending testbench time

  integer f;
  initial begin
    f = $fopen("output_dump.txt","w");
    $fwrite(f, "\n------------------------------------------\n");
    $fwrite(f, "Field - Timestamp - Value ");
    $fwrite(f, "\n------------------------------------------\n");
  end

  always @ (posedge clk) begin
    if (o_slave_rx_cmd_valid == 1'b1) begin
        $fwrite(f, "------------------------------------------ \n");
        $fwrite(f, "CMD value %d, %h\n",$time, o_slave_rx_cmd);
    end
    if (o_slave_rx_addr_valid == 1'b1) begin
        $fwrite(f, "Addr value %d, %h\n",$time, o_slave_rx_addr);
    end
    if (o_slave_rx_data_valid == 1'b1) begin
        $fwrite(f, "Data value %d, %h\n",$time, o_slave_rx_data);
    end
    if (o_slave_rx_feature0_valid == 1'b1) begin
        $fwrite(f, "feature0 value %d, %h\n",$time, o_slave_rx_feature0);
    end
    if (o_slave_rx_feature1_valid == 1'b1) begin
        $fwrite(f, "feature1 value %d, %h\n",$time, o_slave_rx_feature1);
    end
    if (o_slave_rx_length_valid == 1'b1) begin
        $fwrite(f, "Length value %d, %h\n",$time, o_slave_rx_length);
    end
  end

  integer g;
  initial begin
    g = $fopen("input_dump.txt","w");
    $fwrite(g, "\n------------------------------------------\n");
    $fwrite(g, "Timestamp - Generated Flit ");
    $fwrite(g, "\n------------------------------------------\n");
  end

  always @ (posedge clk) begin
    if (chipletsys.w_m_tx_fsm_packet_valid == 1'b1) begin
        $fwrite(g, "------------------------------------------ \n");
        $fwrite(g, "%d, %h\n", $time, chipletsys.w_m_tx_fsm_packet);
    end
  end

  initial begin
    #1000 $finish;
  end


endmodule






