`include "a_defines.svh"
`include "a_interface.svh"

module mdu_muler (
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

// 使用DSP进行优化
(* use_dsp = "yes" *) logic[63:0] cal_result_q;
// 模拟晚3拍
logic valid_s_1, valid_s_2, valid_s_3;
logic [2:0] op_s_1, op_s_2, op_s_3;
logic [`ROB_WIDTH-1:0] reg_addr_s_1, reg_addr_s_2, reg_addr_s_3;

logic [32:0] r0_q, r1_q;
logic [63:0] result_q;

assign ready_o = ready_i;

always_ff @(posedge clk) begin
  if(!rst_n || flush) begin
    valid_s_1 <= '0;
    valid_s_2 <= '0;
    valid_s_3 <= '0;
  end
  else if(ready_i) begin
    r0_q <= {!(req_i.op == `_MDU_MULHU) & req_i.data0[31], req_i.data0[0]};
    r1_q <= {!(req_i.op == `_MDU_MULHU) & req_i.data1[31], req_i.data1[0]};

    cal_result_q <= $signed(r0_q) * $signed(r1_q);
    result_q <= cal_result_q;

    valid_s_1 <= valid_i;
    reg_addr_s_1 <= req_i.reg_addr;
    op_s_1 <= req_i.op;

    valid_s_2 <= valid_s_1;
    reg_addr_s_2 <= reg_addr_s_1;
    op_s_2 <= op_s_1;

    valid_s_3 <= valid_s_2;
    reg_addr_s_3 <= reg_addr_s_2;
    op_s_3 <= op_s_2;
  end
end

// assign ready_o = ready_i;
assign valid_o = valid_s_3;
assign res_o.reg_addr = reg_addr_s_3;

always_comb begin
  case (op_s_3)
    `_MDU_MUL: begin
      res_o.result = result_q[31:0];
    end
      
    `_MDU_MULH: begin
      res_o.result = result_q[63:32];
    end

    `_MDU_MULHU: begin
      res_o.result = result_q[63:32];
    end
      
    default: begin
      res_o.result = '0;
    end
  endcase
end

endmodule