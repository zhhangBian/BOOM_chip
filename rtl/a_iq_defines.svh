`ifndef _a_iq_defines
`define _a_iq_defines

typedef logic [31:0] word_t;

typedef struct packed {
    decode_info_t di;
    logic [31:0] pc;
    logic [31:0] imm;
    rob_id wreg_id;
} ctrl_info_t;

typedef struct packed {
    logic [1:0] valid;
    rob_id [1:0] rreg_id;
    word_t [1:0] data;
} data_pack_i;

// 存储在指令中不变的静态信息
typedef struct packed {
    decode_info_t di;
    logic [31:0] pc;
    logic [31:0] imm;
    rob_id wreg_id;
} iq_static_t;

`endif