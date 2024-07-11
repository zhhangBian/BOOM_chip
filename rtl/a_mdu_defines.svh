`ifndef a_mdu_defines
`define a_mdu_defines


`define _MDU_MUL    3'b001
`define _MDU_MULH   3'b010
`define _MDU_MULHU  3'b011
`define _MDU_DIV    3'b100
`define _MDU_DIVU   3'b101
`define _MDU_MOD    3'b110
`define _MDU_MODU   3'b111

typedef struct packed {
    logic   [2:0]   op;
    word_t  [1:0]   data;
    // 需要写回的寄存器地址
    logic   [`ROB_WIDTH-1:0]    wreg_id;
} mdu_i_t;

typedef struct packed {
    word_t          data;
    // 需要写回的寄存器地址
    logic   [`ROB_WIDTH-1:0]    wreg_id;
} mdu_o_t;

`endif