`include "a_jump_defines.svh"

module e_jump (
    input   logic [31:0]  r0_i,
    input   logic [31:0]  r1_i,
    input   logic [31:0]  pc_i,
    input   logic [31:0]  imm_i,    // 较ALU增加

    input   logic [5:0]   op_i,     // 与ALU不同

    output  logic [31:0]  res_o,
    output  logic jump_o            // 较ALU增加
);

logic target_type, sign_type;
logic [2:0] jump_type;
assign target = op_i[5];
assign sign_type = op_i[4];
assign jump_type = op[2:0];

logic [2:0] cmp_result;
assign cmp_result = {(r1 < r0), (r1 == r0), (r1 > r0)};

logic [32:0] r0, r1;
assign r0 = {(~r0_i[31]) & sign_type, r0_i};
assign r1 = {(~r1_i[31]) & sign_type, r1_i};

assign jump_o = |(cmp_result & jump_result);
assign res_o = {{4{imm_i[27]}}, imm_i} + (jump_type == `_TAR_REG ? r1_i : pc_i);

endmodule