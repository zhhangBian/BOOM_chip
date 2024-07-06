`ifndef a_mdu_defines
`define a_mdu_defines

`define ARF_WIDTH 5

`define _MDU_MUL    3'b001
`define _MDU_MULH   3'b010
`define _MDU_MULHU  3'b011
`define _MDU_DIV    3'b100
`define _MDU_DIVU   3'b101
`define _MDU_MOD    3'b110
`define _MDU_MODU   3'b111

typedef struct packed {
  logic [2:0]   op;
  logic [31:0]  data0;
  logic [31:0]  data1;
  // 需要写回的寄存器地址
  logic [`ARF_WIDTH-1:0] reg_addr;
} mdu_i_t;

typedef struct packed {
  logic [31:0]  result;
  // 需要写回的寄存器地址
  logic [`ARF_WIDTH-1:0] reg_addr;
} mdu_o_t;

`endif