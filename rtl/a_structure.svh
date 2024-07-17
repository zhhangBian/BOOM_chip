`ifndef _BOOM_STRUCTURE_HEAD
`define _BOOM_STRUCTURE_HEAD

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

typedef logic [`ARF_WIDTH - 1 :0] arf_id;
typedef logic [`ROB_WIDTH - 1 :0] rob_id;

typedef logic [`ARF_WIDTH - 1 :0] arf_id_t ;
typedef logic [`ROB_WIDTH - 1 :0] rob_id_t ;

typedef struct packed {
    arf_id_t [3 :0] r_arfid;
    arf_id_t [1 :0] w_arfid;
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
    logic  [1 :0][31:0]   data_imm; // 数据立即数
    logic  [1 :0][31:0]   addr_imm; // 地址立即数
    // 指令类型
    logic  [1 :0]     alu_type; // 指令类型
    logic  [1 :0]     mdu_type;
    logic  [1 :0]     lsu_type;
} d_r_pkg_t;

typedef struct packed {
    logic  [1 :0]     alu_type; // 指令类型
    logic  [1 :0]     mdu_type;
    logic  [1 :0]     lsu_type;
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
    logic  [1 :0][31:0] data_imm; // 立即数
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
    // 在CSR指令中复用为rd寄存器的值
    logic   [31: 0] w_data;
    logic   [4 : 0] w_areg;
    logic   w_reg;
    logic   w_mem;
    logic   first_commit;

    logic   c_valid;

    logic [31:0] data_rd;
    logic [31:0] data_rj;
    
    iq_lsu_pkg_t lsu_info;
    logic   uncached;
    // CSR维护信息
    logic   [2:0]   csr_type;
    logic   [13:0]  csr_num;
    logic   [4:0]   cache_code;
    logic   [4:0]   tlb_type;
    logic   [3:0]   tlb_op;

    logic   [31:0]  cache_dirty_addr;
    logic   cache_dirty;

    // 特殊指令，例如uncached，tlb维护指令，写csr指令
    // cache维护指令，st指令，只能单条提交
    // 异常
    // 1/logic       has_exc,     //有异常
    // 2/logic       first_commit,//只能提交一条
    // 3/分支预测相关信息
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
/**********************rob pkg**********************/

// 指令信息表项
typedef struct packed {
    logic [4 : 0] areg;
    logic [31: 0] pc;
    logic         w_reg;
    logic         w_mem;
    logic         check;
} rob_inst_entry_t;

// 有效信息表项
typedef struct packed {
    logic complete;
} rob_valid_entry_t;

// 数据信息表项
typedef struct packed {
    logic [31: 0] data;
    rob_ctrl_entry_t ctrl;
} rob_data_entry_t;

// 控制信息表项
typedef struct packed {
    // 异常控制信号流，其他控制信号流，后续补充
    logic exception;
    logic bpu_fail;
} rob_ctrl_entry_t;


/**********************dispatch  to  execute  pkg******************/
typedef struct packed {
    logic    [3 :0][31:0] data; // 四个源操作数
    rob_id_t [3 :0]       preg; // 四个源操作数对应的preg id
    logic    [3 :0]       data_valid; //四个源操作数是否已经有效
    logic    [1 :0]       inst_choose;//选择送进来的哪条指令[1:0]分别对应传进来的两条指令
    // 控制信号，包括：
    // alu计算类型，jump类型
    // mdu计算类型
    // lsu类型
    // 异常信号
    // FU之前的一切异常信号
} p_i_pkg_t;

/**********************store buffer pkg******************/
typedef struct packed {
    logic [31 : 0] target_addr;
    logic [31 : 0] write_data;
    logic [3  : 0] wstrb;
    logic          valid;
    // logic          commit;
    logic          uncached;
    logic [1  : 0] hit;
    // logic          complete;
} sb_entry_t;

/**************************lsu pkg*************************/
typedef struct packed {
    logic   is_uncached;
    logic  [3:0]  strb;
    logic  [3:0] rmask;            // 需要读的字节
    inv_parm_e   cacop;
    logic         dbar;            // 显式 dbar
    logic         llsc;            // LL 指令，需要写权限
    rob_id_t       wid;            // 写回地址
    logic      msigned;            // 有符号拓展
    logic  [1:0] msize;            // 访存大小-1
    logic [31:0] vaddr;            // 虚拟地址
    logic [31:0] wdata;            // 写数据
} iq_lsu_pkg_t;

// LSU 到 LSU IQ 的响应
typedef struct packed {
//   lsu_excp_t   excp;
//   fetch_excp_t f_excp;
    logic        uncached;
    logic        hit;
    rob_rid_t    wid;     // 写回地址
    logic[31:0]  paddr;
    logic[31:0]  rdata;   
} lsu_iq_pkg_t;

typedef struct packed {
    logic [19 : 0] tag;
    logic          v;
    logic          d;
} cache_tag_t;

// commit与DCache的交互
typedef struct packed {
    // 向DCache发送Tag SRAM写请求
    logic   [31:0]  addr;
    logic   [1:0]   way_hit;    // TODO
    cache_tag_t     tag_data;   
    logic           tag_we;     // 写回tag使能信号
    // 向DCache发送Data SRAM请求
    logic   [31:0]  data_data;
    logic   [3:0]   strb;
    logic   fetch_sb; // 进状态机的时候一定fetch_sb为0
} commit_cache_req_t;

typedef struct packed {
    logic   [31:0]  addr;
    logic   [31:0]  data;
    sb_entry_t      sb_entry;
    // Data SRAM向commit级发送读结果
    logic   [31:0]  r_data;
} cache_commit_resp_t;

// commit与AXI的交互
typedef struct packed {
    logic   [31:0]  data;
    logic   [31:0]  addr;
    logic   [3:0]   len;
    logic   [3:0]   strb;
    logic   [3:0]   rmask;
} commit_axi_req_t;

typedef struct packed {
    logic   [31:0]  addr;
    logic   [31:0]  data;
} axi_commit_resp_t;

`endif
