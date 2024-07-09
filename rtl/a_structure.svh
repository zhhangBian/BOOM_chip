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
    logic  [1 :0]  w_reg;
    logic  [1 :0]  w_mem;
    logic  [3 :0]  reg_need; // 指令需要的寄存器
    // else controller signals
    logic  [1 :0][31:0] pc ; // 指令地址
    logic  [3 :0]   use_imm; // 指令是否使用立即数
    logic  [31:0]   data_imm; // 立即数
    logic  [1 :0][1 :0] inst_type; // 指令类型
} d_r_pkg_t;

typedef struct packed {
    logic  [1 :0][1 :0] inst_type; // 指令类型
    logic  [1 :0][`ARF_WIDTH - 1:0] areg;
    logic  [1 :0][`ROB_WIDTH - 1:0] preg;
    logic  [3 :0][`ROB_WIDTH - 1:0] src_preg;
    logic  [3 :0][31:0] arf_data;
    logic  [1 :0][31:0] pc ; // 指令地址
    logic  [1 :0]       r_valid;
    logic  [1 :0]       w_reg;
    logic  [1 :0]       w_mem;
    logic  [1 :0]       check;
    logic  [3 :0]       use_imm; // 指令是否使用立即数
    logic  [3 :0]       data_valid; // 对应数据是否为有效，要么不需要使用该数据，要么已经准备好
    logic  [31:0]       data_imm; // 立即数
} r_p_pkg_t;

typedef struct packed {
    // register write back
    logic [`ROB_WIDTH - 1 :0] rob_id;
    logic [`ARF_WIDTH - 1 :0] arf_id;
    logic [31 :0] data;
    logic w_valid; // 需要写register
    logic w_check;
    // else information for retirement
} retire_pkg_t;

/********************cdb  to  dispatch  pkg******************/
typedef struct packed {
    logic [`ROB_WIDTH - 1 : 0] w_preg;
    logic [31             : 0] w_data;
    logic                      w_reg;
    logic                      w_mem;
    logic                      w_valid;
} cdb_dispatch_pkg_t;

/********************rob  package******************/
typedef struct packed {
    // static info
    logic [1              : 0]                     inst_type; // 1: alu, 2: mdu, 3: lsu, 0: reserved
    logic [`ARF_WIDTH - 1 : 0]                     areg;  // 目的寄存器
    logic [`ROB_WIDTH - 1 : 0]                     preg;  // 物理寄存器
    logic [1              : 0][`ROB_WIDTH - 1 : 0] src_preg;  // 源寄存器对应的物理寄存器
    logic [31             : 0]                     pc;    // 指令地址
    logic                                          issue; // 是否被分配到ROB valid
    logic                                          w_reg;
    logic                                          w_mem;
    logic                                          check;
} dispatch_rob_pkg_t;

typedef struct packed {
    logic [31: 0] w_data;
    logic [4 : 0] w_areg;
    logic         w_reg;
    logic         w_mem;
    logic         c_ready;    // valid
} rob_commit_pkg_t;

typedef struct packed {
    logic [`ROB_WIDTH - 1 : 0] w_preg;
    logic [31             : 0] w_data;
    logic                      w_valid;  // valid
    rob_ctrl_entry_t           ctrl;
} cdb_rob_pkg_t;

typedef struct pack {
    logic [1 : 0][31 : 0] rob_data;
    logic [1 : 0]         rob_complete;
} rob_dispatch_pkg_t;

`endif