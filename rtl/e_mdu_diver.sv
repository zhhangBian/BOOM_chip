`include "a_defines.svh"

module mdu_diver (
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

logic valid_q;
logic [2:0] op_q;
logic [`ARF_WIDTH-1:0] reg_addr_q;
logic busy;

always_ff @(posedge clk) begin
  if(flush_i || !rst_n) begin
    valid_q <= '0;
  end
  else if(ready_o) begin
    valid_q <= valid_i;
    op_q <= req_i.op;
    wid_q <= req_i.wid;
  end
end

logic [31:0] mod_res, div_res;
divide_high_pace divider(
  .clk(clk),
  .rst_n(rst_n),

  .num0(req_i.data0),
  .num1(req_i.data1),

  .start(valid_i & ready_o),
  .sign((req_i.op == `_MDU_DIV) | (req_i.op == `_MDU_MOD)),

  .busy(busy),
  .mod_res(mod_res),
  .div_res(div_res)
);

assign valid_o = valid_q & ~busy;
assign ready_o = (ready_i && !busy) || !valid_q;
assign res_o.reg_addr = reg_addr_q;
assign res_o.result = (op_q == `_MDU_DIV) ? div_res : mod_res;

endmodule