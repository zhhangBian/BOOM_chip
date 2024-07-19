`ifndef _BOOM_STRUCTURE_HEAD
`define _BOOM_STRUCTURE_HEAD

/*============================== BPU start ============================== */

typedef struct packed {
    logic [31:0]    pc;
    logic [ 1:0]    mask;
    predict_info_t  predict_info;
} b_d_pkg_t;

typedef struct packed {
    logic [1:0][31:0]   insts;
    logic [31:0]        pc;
    logic [ 1:0]        mask;
    predict_info_t      predict_info;
} f_d_pkg_t;

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

    logic   c_valid;

    logic   [31:0]  data_rd;
    logic   [31:0]  data_rj;
    logic   [31:0]  data_imm;

    logic   first_commit;
    lsu_iq_pkg_t lsu_info;

    logic   is_uncached;
    logic   [5:0]   exc_code;   // 位宽随便定的，之后调整
    logic   is_csr_fix;
    logic   [2:0]   csr_type;
    logic   [13:0]  csr_num;
    logic   is_cache_fix;
    logic   [4:0]   cache_code;
    logic   is_tlb_fix;
    logic   [4:0]   tlb_type;
    logic   [3:0]   tlb_op;

    logic   [31:0]  cache_dirty_addr;
    logic   cache_dirty;

    // TODO：分支预测信息
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
    exc_info_t exc_info;
    logic bpu_fail;
} rob_ctrl_entry_t;

typedef struct packed {
    logic fetch_exception;    //为1表示fetch级有异常
    logic execute_exception;  //为1表示访存级有异常，当fetch级有异常这个值是什么都行
    logic [5:0] exc_code;     //fetch级有异常则存fetch级别的异常码，elif访存异常存访存异常码，如果都没有异常则存什么都行
} exc_info_t;

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
    logic   [31 : 0]    target_addr;
    logic   [31 : 0]    write_data;
    logic   [3  : 0]    wstrb;
    logic               valid;
    // logic               commit;
    // logic               uncached;
    logic   [1  : 0]    hit;
    // logic               complete;
} sb_entry_t;

/**************************lsu pkg*************************/
typedef struct packed {
    logic   is_uncached;
    logic  [3:0]  strb;
    logic  [3:0] rmask;     // 需要读的字节
    inv_parm_e   cacop;
    logic         dbar;     // 显式 dbar
    logic         llsc;     // LL 指令，需要写权限
    rob_id_t       wid;     // 写回地址
    logic      msigned;     // 有符号拓展
    logic  [1:0] msize;     // 访存大小-1
    logic [31:0] vaddr;     // 虚拟地址
    logic [31:0] wdata;     // 写数据
} iq_lsu_pkg_t;

// LSU 到 LSU IQ 的响应
typedef struct packed {
//   lsu_excp_t   excp;
//   fetch_excp_t f_excp;
    logic   [3:0]   strb;
    logic   [3:0]   rmask;  // 需要读的字节
    logic   [31:0]  wdata;      // 需要写的数据
    logic           uncached;   // uncached 特性
    logic           hit;        // 是否命中，总判断
    logic   [1 :0]  tag_hit;    // tag是否命中
    rob_rid_t       wid;        // 写回地址
    logic   [31:0]  paddr;      // 物理地址
    logic   [31:0]  rdata;      // 读出的数据结果
    tlb_exception_t tlb_exception; // TLB异常
    logic   [1 :0]  refill;     // 选择哪一路重填
    logic           dirty;      // 是否需要写回
    logic           cacop_dirty;// 专门为cacop直接地址映射准备的dirty位
} lsu_iq_pkg_t;

typedef struct packed {
    logic [19 : 0] tag;
    logic          v;
    logic          d;
} cache_tag_t;

// commit与DCache的交互
typedef struct packed {
    // 向DCache发送Tag SRAM写请求
    logic   [31:0]  addr;       // 地址
    logic   [1 :0]  way_hit;    // TODO 读写对应的路，两位分别对应两路，对应位表示对应路是否命中
    cache_tag_t     tag_data;   // 写回tag数据
    logic           tag_we;     // 写回tag使能信号
    // 向DCache发送Data SRAM请求
    logic   [31:0]  data_data;  // 写回data的数据
    logic   [3:0]   strb;       // 写回data的strb
    logic   fetch_sb;           // 进状态机的时候一定fetch_sb为0
} commit_cache_req_t;

typedef struct packed {
    logic   [31:0]  addr;       // 反馈地址
    // logic   [31:0]  data;
    sb_entry_t      sb_entry;   // 读出的sb_entry
    // Data SRAM向commit级发送读结果
    logic   [31:0]  data;       // 返回的数据
    logic   [31:0]  data_other; // 返回的另一路数据，默认当返回两路数据的时候，data为0路，data_other为1路
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
