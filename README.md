---------------------------------------------
Interface Protocol Design
---------------------------------------------
Contact: Eric Qin <ecqin@gatech.edu>

![alt text](https://i.postimg.cc/tJ6xFMw2/protocol.png)

Summary: This is a simple RTL implementation of a strawman-like chiplet protocol. 
The aim of the protocol is to provide lightweight communication with minimal IO connections.

File Structure: <br />
  src/chiplet_sys.v - top file connecting the fifo queues and RX / TX FSMs <br />
  src/fifo.v - simple fifo implementation <br />
  src/fifos_interface.v - fifos interface between Master and Slave <br />
  src/strawman_rx_fsm.v - recieving protocol fsm <br />
  src/strawman_tx_fsm.v - transmitting protocol fsm <br />
  tb/tb_chiplet_sys.sv - top level testbench <br />
  tb_fifo.v - simple fifo testbench <br />
  tb_fifos_interface.v -simple fifo interface testbench <br />
  
Tools Needed:  <br />
  Verilog Compiler / Waveform Viewer of your choice: <br />
    - Icarus Verilog <br />
    - ModelSim <br />
    - Verilator <br />
    - Xilinx ISE <br />
    - Altera Quartus <br />
    - GTKWave <br />
  
Alternative Online Verilog Compiler
  https://www.edaplayground.com/ 
  
To run the code, upload all of the code and similate tb_chiplet_sys.v.

This work was supported by the DARPA CHIPS program.

