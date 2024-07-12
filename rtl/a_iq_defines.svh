`ifndef _a_iq_defines
`define _a_iq_defines

typedef logic [31:0] word_t;

typedef struct packed {
    word_t  pc;
    word_t  imm;
    logic   if_jump;
    logic [2:0] grand_op;
    logic [2:0] op;
    rob_id_t    wreg_id;
} decode_info_t;

`endif