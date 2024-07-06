`ifndef _BOOM_STRUCTURE_HEAD
`define _BOOM_STRUCTURE_HEAD

typedef logic [`ARF_WIDTH - 1 :0] arf_id;
typedef logic [`ROB_WIDTH - 1 :0] rob_id;

typedef struct packed {
    arf_id [3 :0] r_arfid;
    arf_id [1 :0] w_arfid;
} arf_table_t;

typedef struct packed {
    arf_table_t  arf_table; // 读写地址寄存器表
    logic  [1 :0]  r_valid; // 前端发射出来的指令有效
    // else controller signals
} d_r_pkg_t;

typedef struct packed {
    // register write back
    logic [`ROB_WIDTH - 1 :0] rob_id;
    logic [`ARF_WIDTH - 1 :0] arf_id;
    logic [31 :0] data;
    logic w_valid;
    // else information for retirement
} retire_pkg_t;

`endif