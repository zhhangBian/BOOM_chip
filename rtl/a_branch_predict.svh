`ifndef _BOOM_BRANCH_PREDICT_HEAD
`define _BOOM_BRANCH_PREDICT_HEAD

// 不区分 branch 和 jump 类指令，一律使用 branch 进行描述。
// 也就是说 branch 指令包括  指令

`define BPU_HISTORY_LEN 5 // 历史总共 5 位
`define BPU_PHT_PC_LEN 8 // PC[10:3] 共 8 位
`define BPU_PHT_LEN (`BPU_HISTORY_LEN + `BPU_PHT_PC_LEN) // = 13
`define BPU_PHT_DEPTH (1 << `BPU_PHT_LEN) // PHT大小 = 8192 项，奇偶共16324项

`define BPU_RAS_LEN 4
`define BPU_RAS_DEPTH (1 << `BPU_RAS_LEN) //  RAS 的栈的大小 = 16

`define BPU_BTB_LEN 9
`define BPU_BTB_DEPTH (1 << `BPU_BTB_LEN) // 奇偶 BTB 各 512 项，共 1024 项
`define BPU_TAG_LEN 6 // tag存储pc[17:12]为作为tag

`define BPU_BHT_LEN `BPU_BTB_LEN // the same len as btb
`define BPU_BHT_DEPTH (1 << `BPU_BHT_LEN)

`define BPU_INIT_PC 32'h1c00_0000

// Branch target type
typedef enum logic[1:0] { 
    BR_NONE, // 正常指令
    BR_NORMAL, // 立即数跳转指令
    BR_CALL, // LA 中的 BL 指令
    BR_RET // LA 中的 JIRL 指令
} br_type_t;

typedef struct packed {
    logic [31:0]                        target_pc; // 跳转到的目标 PC 
    br_type_t [1:0]                     br_type;
    logic [ 1:0]                        taken;
    logic [ 1:0][ 1:0]                  scnt;
    logic [ 1:0]                        need_update;
    logic [ 1:0][`BPU_HISTORY_LEN-1:0]  history; // 最新的历史放 0 位，旧的历史往高位移
    // ras_ptr???    
} predict_info_t;

typedef struct packed { // TODO: 后端不能同时提交两条分支指令
    logic  [31:0]   pc;

    logic  [31:0]   redir_addr; // 如果跳转错误,后端得到正确的跳转地址之后反馈给前端

    logic           target_miss; // 目标地址预测错误，需要更新BTB. taken预测错了也要将target_miss置有效。
    logic           type_miss; // 类型预测错误，说明一定这条指令一定不在表中，全部更新
    logic           taken; // 是否跳转
    logic           is_cond_br; // 是否是条件跳转指令。无条件跳转指令仅包括JIRL, B, BL
    br_type_t       branch_type; // 分支类型，用于更新 BTB
    logic           update; // 如果这条指令是分支或者预测成了分支，就要置 1 。
    logic  [31:0]   target_pc; // 正确的跳转地址，用于更新 BTB
    logic  [`BPU_HISTORY_LEN-1:0] new_history; // 历史记录，最新的历史往 0 位放，旧的历史左移一位。
    logic  [ 1:0]   new_scnt; // 饱和计数器的值。
} correct_info_t;

typedef struct packed {
    logic                           valid; // 这个位和 br_type != BR_NONE 是一致的。
    logic  [`BPU_TAG_LEN-1 : 0]     tag;
    logic  [31:0]                   target_pc;
    br_type_t                       br_type;
    logic                           is_cond_br;
} bpu_btb_entry_t;

typedef struct packed {
    logic  [`BPU_HISTORY_LEN-1 : 0]  history;
} bpu_bht_entry_t;

typedef struct packed {
    logic  [1:0]    scnt;
} bpu_pht_entry_t;

// saturating counter
function automatic logic [1:0] next_scnt(input logic[1:0] last_scnt, input logic taken);
    case (last_scnt)
        default: // strongly not taken
            // default has to be not taken, brcause don't know target pc?
            return {1'b0, taken};
        2'b01: // weakly not taken
            return {taken, 1'b0};
        2'b10: // weakly taken
            return {taken, 1'b1};
        2'b11: // strongly taken
            return {1'b1, taken};
    endcase
endfunction

`endif