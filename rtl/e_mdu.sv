`include "a_mdu_defines.svh"

module mdu (
    input   wire    clk,
    input   wire    rst_n,
    input   wire    flush,

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

mdu_o_t mul_res_o, div_res_o;
logic mul_valid_o, div_valid_o;
logic mul_ready_o, div_ready_o;

mdu_muler muler(
    .clk,
    .rst_n,
    .flush,

    .req_i(req_i),
    .res_o(mul_res_o),

    .valid_i(valid_i),
    .ready_o(mul_read_o),
    .valid_o(mul_valid_o),
    .ready_i(ready_i)
);

mdu_diver diver(
    .clk,
    .rst_n,
    .flush,

    .req_i(req_i),
    .res_o(div_res_o),

    .valid_i(valid_i),
    .ready_o(div_ready_o),
    .valid_o(div_valid_o),
    .ready_i(ready_i)
);

assign res_o = (req_i.op == `_MDU_MUL || req_i.op == `_MDU_MULH || req_i.op == `_MDU_MULHU) ?
                mul_res_o : div_res_o;

assign ready_o = (req_i.op == `_MDU_MUL || req_i.op == `_MDU_MULH || req_i.op == `_MDU_MULHU) ?
                mul_ready_o : div_ready_o;

assign valid_o = (req_i.op == `_MDU_MUL || req_i.op == `_MDU_MULH || req_i.op == `_MDU_MULHU) ?
                mul_valid_o : div_valid_o;

endmodule