`include "a_defines.svh"

module mdu_muler (
  input   wire    clk,
  input   wire    rst_n,

  input logic [2:0]   op,
  input logic [31:0]  data0,
  input logic [31:0]  data1,
  input logic [5-1:0] reg_addr,

  handshake_if.receiver receiver,
  handshake_if.sender   sender
);



endmodule