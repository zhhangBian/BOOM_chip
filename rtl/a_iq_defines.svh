`ifndef _a_iq_defines
`define _a_iq_defines

typedef logic [31:0] word_t;

typedef struct packed {
    logic valid;
    rob_id_t wreg_id;
    word_t data;
} data_t;

typedef struct packed {
    data_t [1:0] data;
    logic [1:0] valid;

    logic available;
    logic valid_inst;
    decode_info_t di;
} iq_entry_t;

typedef struct packed {
    decode_info_t di;
    logic [31:0] pc;
    logic [31:0] imm;
    rob_id_t wreg_id;
} ctrl_info_t;

// 存储在指令中不变的静态信息
typedef struct packed {
    decode_info_t di;
    logic [31:0] pc;
    logic [31:0] imm;
    rob_id_t wreg_id;
} iq_static_t;

// CDB传递信号的子集
typedef struct packed {
    logic valid;
    rob_id_t wreg_id;
    word_t data;
} cdb_issue_info_t;

`endif