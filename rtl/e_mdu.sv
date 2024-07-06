`include "a_defines.svh"

module mdu (
  input wire    clk,
  input wire    rst_n,
  input wire    flush,

  // 需要的操作数
  input   mdu_i_t req_i,
  output  mdu_o_t res_o,

  input   logic   valid_i,
  output  logic   ready_o,
  output  logic   valid_o,
  input   logic   ready_i,

  // 定义握手信号的接口
  // handshake_if.receiver receiver,
  // handshake_if.sender   sender
);

mdu_muler muler(
  .clk,
  .rst_n,
  .flush,
  .req_i,
  .res_o,
  .valid_i,
  .ready_o,
  .valid_o,
  .ready_i
);

mdu_diver diver(
  .clk,
  .rst_n,
  .flush,
  .req_i,
  .res_o,
  .valid_i,
  .ready_o,
  .valid_o,
  .ready_i
);

endmodule