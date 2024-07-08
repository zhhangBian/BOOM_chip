`ifndef _BOOM_STRUCTURE_HEAD
`define _BOOM_STRUCTURE_HEAD

`include "a_macros.svh"

/*============================== BPU start ============================== */

// Branch target type
typedef enum logic[1:0] { 
    BR_NPC, // 正常指令
    BR_IMM, // 立即数跳转指令
    BR_CALL, // LA 中的 BL 指令
    BR_RET // LA 中的 JIRL 指令
} br_type_t;

typedef struct packed {
    logic [31:0 ]               target_pc;
    br_type_t                   br_type;
    logic                       taken;
    logic [ 1:0 ]               scnt;
    logic [`BPU_HISTORY_LEN-1:0] history; // 最新的历史放 0 位，旧的历史往高位移
    // ras_ptr???    
} predict_info_t;

typedef struct packed {
    logic  [31:0]   pc;

    logic           redir; // 是否跳转错误
    logic  [31:0]   redir_addr; // 如果跳转错误,后端得到正确的跳转地址之后反馈给前端

    logic           taken; // 是否跳转
    logic           cond_br; // 是否是条件跳转指令。无条件跳转指令仅包括JIRL, B, BL
    logic           target_miss; // 目标地址预测错误，需要更新BTB. taken预测错了也要将target_miss置有效。
    logic           type_miss; // 类型预测错误，说明一定这条指令一定不在表中，全部更新
    logic           update; // update = pc_miss | type_miss;
    br_type_t       target_type;
    logic  [31:0]   target; // 正确的跳转地址，用于更新 BTB
    logic  [`BPU_HISTORY_LEN-1:0] history; // 历史记录
    logic  [ 1:0]   scnt;
} correct_info_t;

typedef struct packed {
    logic       is_call;
    logic       is_ret;
    logic       is_cond_br; // 是否是条件跳转指令
    br_type_t   br_type;
} branch_info_t;

typedef struct packed {
    logic                           valid;
    logic  [`BPU_TAG_LEN-1 : 0]  tag;
    logic  [31:0]                   target_pc;
    branch_info_t                   br_info;
} bpu_btb_entry_t;

typedef struct packed {
    logic                           valid;
    logic  [`BPU_TAG_LEN-1 : 0]      tag;
    logic  [`BPU_HISTORY_LEN-1 : 0]  history;
} bpu_bht_entry_t;

typedef struct packed {
    logic           valid;
    logic  [1:0]    scnt;
} bpu_pht_entry_t;

/*============================== BPU end ============================== */

typedef logic [`ARF_WIDTH - 1 :0] arf_id;
typedef logic [`ROB_WIDTH - 1 :0] rob_id;

typedef struct packed {
    arf_id [3 :0] r_arfid;
    arf_id [1 :0] w_arfid;
} arf_table_t;

typedef struct packed {
    arf_table_t  arf_table; // 读写地址寄存器表
    logic  [1 :0]  r_valid; // 前端发射出来的指令有效
    logic  [3 :0]  reg_need; // 指令需要的寄存器
    // else controller signals
    logic  [1 :0][31:0] pc ; // 指令地址
    logic  [3 :0]   use_imm; // 指令是否使用立即数
    logic  [1 :0][31:0] imm; // 立即数
} d_r_pkg_t;

typedef struct packed {

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

`endif