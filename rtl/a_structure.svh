`ifndef _BOOM_STRUCTURE_HEAD
`define _BOOM_STRUCTURE_HEAD

`include "a_branch_predict.svh"

typedef struct packed {
    logic [31:0]        pc;
    logic [ 1:0]        mask;
    predict_info_t [1:0]predict_infos;
} b_f_pkg_t;

typedef struct packed {
    logic          fetch_exception;
    logic  [5:0]   exc_code;
    logic  [31:0]  badv;
} fetch_exc_info_t;

typedef struct packed {
    logic          execute_exception;
    logic  [5:0]   exc_code;
    logic  [31:0]  badv;
} execute_exc_info_t;

typedef struct packed {
    logic [1:0][31:0]   insts;
    logic [31:0]        pc;
    logic [ 1:0]        mask;
    predict_info_t [1:0]predict_infos;
    fetch_exc_info_t    fetch_exc_info;
} f_d_pkg_t;

typedef logic [31:0] word_t;
typedef logic [`ARF_WIDTH - 1 :0] arf_id_t ;
typedef logic [`ROB_WIDTH - 1 :0] rob_id_t ;

typedef struct packed {
    arf_id_t [3 :0] r_arfid;
    arf_id_t [1 :0] w_arfid;
} arf_table_t;

typedef struct packed {
    logic  [1 :0][31:0] pc ; // 指令地址
    logic  [1 :0]  r_valid; // 前端发射出来的指令有效
    // ARF 与 源操作数 相关信号
    arf_table_t  arf_table; // 读写地址寄存器表
    logic  [1 :0]  w_reg;
    logic  [3 :0]  reg_need; // 指令需要的寄存器
    // else controller signals
    logic  [3 :0]   use_imm; // 指令是否使用立即数
    logic  [1 :0][31:0]   data_imm; // 数据立即数
    logic  [1 :0][31:0]   addr_imm; // 地址立即数
    // 指令类型
    logic  [1 :0]     alu_type; // 指令类型
    logic  [1 :0]     mdu_type;
    logic  [1 :0]     lsu_type;
    logic  [1 :0]     flush_inst;
    logic  [1 :0]     jump_inst; // TODO: 似乎暂时没有用到？
    logic  [1 :0]     priv_inst;
    logic  [1 :0]     rdcnt_inst;
    tlb_inst_t   [1:0]tlb_inst;
    // control info, temp, 根据需要自己调整
    predict_info_t [1 :0] predict_infos;
    logic [1:0]        if_jump; // 是否跳转 TODO: 什么意思？
    // ALU & MDU 信号
    logic [1:0][2:0]   grand_op; 
    logic [1:0][2:0]   op;
    // LSU 信号
    logic [1:0]        msigned; // 是否符号拓展（ld指令）
    logic [1:0][1:0]   msize;   // 读字节数目 - 1
    logic  [1 :0]  w_mem; // 加在这里了

    // 特殊指令独热码
    logic [1:0]        break_inst;
    logic [1:0]        cacop_inst; // lsu iq
    logic [1:0]        dbar_inst;
    logic [1:0]        ertn_inst;
    logic [1:0]        ibar_inst;
    logic [1:0]        idle_inst;
    logic [1:0]        invtlb_inst;
    logic [1:0]        ll_inst; // lsu iq

    logic [1:0]        rdcntid_inst;
    logic [1:0]        rdcntvh_inst;
    logic [1:0]        rdcntvl_inst;

    logic [1:0]        sc_inst; // lsu iq
    logic [1:0]        syscall_inst;
    logic [1:0]        tlbfill_inst;
    logic [1:0]        tlbrd_inst;
    logic [1:0]        tlbsrch_inst;
    logic [1:0]        tlbwr_inst;

    // csr
    csr_op_type_t [1:0] csr_op_type;
    logic [1:0][13:0] csr_num;

    logic [1:0][4:0]  inst_4_0; // cache_op 和 tlb_op

    //tlb
    logic        [1:0] decode_err;

    // branch
    logic        [1:0] is_branch;
    br_type_t    [1:0] br_type;
    fetch_exc_info_t    fetch_exc_info;
} d_r_pkg_t;

typedef struct packed {
    logic  [1 :0][`ARF_WIDTH - 1:0] areg;
    logic  [1 :0][`ROB_WIDTH - 1:0] preg;
    logic  [3 :0][`ROB_WIDTH - 1:0] src_preg;
    logic  [3 :0][31:0] arf_data;
    logic  [1 :0][31:0] pc ; // 指令地址
    logic  [1 :0]       r_valid;
    logic  [1 :0]       w_reg;
    logic  [1 :0]       check;
    logic  [3 :0]       use_imm; // 指令是否使用立即数
    logic  [3 :0]       data_valid; // 对应数据是否为有效，要么不需要使用该数据，要么已经准备好
    logic  [1 :0][31:0] data_imm; // 立即数
    logic  [1 :0][31:0] addr_imm; // 立即数
    predict_info_t [1 :0] predict_infos;
    // 指令类型
    logic  [1 :0]     alu_type; // 指令类型
    logic  [1 :0]     mdu_type;
    logic  [1 :0]     lsu_type;
    logic  [1 :0]     flush_inst;
    logic  [1 :0]     jump_inst; // TODO: 似乎暂时没有用到？
    logic  [1 :0]     priv_inst;
    logic  [1 :0]     rdcnt_inst;
    logic  [1 :0]     tlb_inst;
    // control info, temp, 根据需要自己调整
    predict_info_t [1 :0] predict_infos;
    logic [1:0]        if_jump; // 是否跳转 TODO: 什么意思？
    // ALU & MDU 信号
    logic [1:0][2:0]   grand_op; 
    logic [1:0][2:0]   op;
    // LSU 信号
    logic [1:0]        msigned; // 是否符号拓展（ld指令）
    logic [1:0][1:0]   msize;   // 读字节数目 - 1
    logic  [1 :0]      w_mem;

    // 特殊指令独热码
    logic [1:0]        break_inst;
    logic [1:0]        cacop_inst; // lsu iq
    logic [1:0]        dbar_inst;
    logic [1:0]        ertn_inst;
    logic [1:0]        ibar_inst;
    logic [1:0]        idle_inst;
    logic [1:0]        invtlb_inst;
    logic [1:0]        ll_inst; // lsu iq

    logic [1:0]        rdcntid_inst;
    logic [1:0]        rdcntvh_inst;
    logic [1:0]        rdcntvl_inst;

    logic [1:0]        sc_inst; // lsu iq
    logic [1:0]        syscall_inst;
    logic [1:0]        tlbfill_inst;
    logic [1:0]        tlbrd_inst;
    logic [1:0]        tlbsrch_inst;
    logic [1:0]        tlbwr_inst;

    // csr
    csr_op_type_t [1:0] csr_op_type;
    logic [1:0][13:0] csr_num;

    logic [1:0][4:0]  inst_4_0; // cache_op 和 tlb_op

    //tlb
    logic        [1:0] decode_err;

    // branch
    logic        [1:0] is_branch;
    br_type_t    [1:0] br_type;
    fetch_exc_info_t    fetch_exc_info;
} r_p_pkg_t;

typedef struct packed {
    // register write back
    logic [`ROB_WIDTH - 1 :0] rob_id;
    logic [`ARF_WIDTH - 1 :0] arf_id;
    logic [31 :0] data;
    logic w_valid; // 需要写register
    // logic w_check;
    // else information for retirement
} retire_pkg_t;

/********************cdb  to  dispatch  pkg******************/
typedef struct packed {
    logic [`ROB_WIDTH - 1 : 0] w_preg;
    logic [31             : 0] w_data;
    logic                      w_reg;
    // logic                      w_mem;
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

    logic [31:0]                                   addr_imm;

    // 指令类型
    logic  alu_type; // 指令类型
    logic  mdu_type;
    logic  lsu_type;
    logic  flush_inst;
    logic  jump_inst; // TODO: 似乎暂时没有用到？
    logic  priv_inst;
    logic  rdcnt_inst;
    logic  tlb_inst;
    // control info, temp, 根据需要自己调整
    predict_info_t predict_info;
    logic if_jump; // 是否跳转 TODO: 什么意思？
    // 特殊指令独热码
    logic break_inst;
    logic cacop_inst; // lsu iq
    logic dbar_inst;
    logic ertn_inst;
    logic ibar_inst;
    logic idle_inst;
    logic invtlb_inst;
    logic ll_inst; // lsu iq

    logic rdcntid_inst;
    logic rdcntvh_inst;
    logic rdcntvl_inst;

    logic sc_inst; // lsu iq
    logic syscall_inst;
    logic tlbfill_inst;
    logic tlbrd_inst;
    logic tlbsrch_inst;
    logic tlbwr_inst;

    csr_op_type_t csr_op_type;
    logic [13:0] csr_num;
    logic [ 4:0] inst_4_0;
    logic decode_err;
    logic is_branch;
    br_type_t br_type;
} dispatch_rob_pkg_t;

typedef struct packed {
    logic    [31:0] target_pc;
    logic           is_branch;
    br_type_t [1:0] br_type;
} branch_info_t;

typedef struct packed {
    // 在CSR指令中复用为rd寄存器的值
    logic   [31: 0] w_data;
    logic   [4 : 0] arf_id;
    logic   [`ROB_WIDTH - 1 :0] rob_id;
    logic   w_reg;
    logic   w_mem;

    logic   c_valid;

    logic   [31:0]  pc;
    logic   [31:0]  data_rk;
    logic   [31:0]  data_rj;
    logic   [31:0]  data_imm;

    logic   first_commit;
    lsu_iq_pkg_t lsu_info;

    logic   is_ll;
    logic   is_sc;
    logic   is_uncached;
    logic   [5:0]   exc_code;   // 位宽随便定的，之后调整
    logic   is_csr_fix;
    logic   [2:0]   csr_type;
    logic   [13:0]  csr_num;
    logic   is_cache_fix;
    logic   [4:0]   cache_code;
    logic   is_tlb_fix;

    logic   flush_inst;

    logic   fetch_exception;
    logic   syscall_inst;
    logic   break_inst;
    logic   decode_err;
    logic   priv_inst; //要求：不包含hit类cacop
    logic   execute_exception;

    logic   [31:0] badva;

    logic   rdcntvh_en;
    logic   rdcntvl_en;
    logic   rdcntid_en;
    logic   ertn_en;
    logic   idle_en;

    logic   tlbsrch_en;
    logic   tlbrd_en;
    logic   tlbwr_en;
    logic   tlbfill_en;
    logic   invtlb_en;

    logic   [4:0]   tlb_op;

    // 分支预测信息
    logic   is_branch;
    predict_info_t  predict_info;
    branch_info_t   branch_info;
} rob_commit_pkg_t;

typedef struct packed {
    logic [`ROB_WIDTH - 1 : 0] w_preg;
    logic [31             : 0] w_data;
    logic                      w_valid;  // valid
    rob_ctrl_entry_t           ctrl;
    lsu_info_t                 lsu_info;
} cdb_rob_pkg_t;

typedef struct packed {
    logic [1 : 0][31 : 0] rob_data;
    logic [1 : 0]         rob_complete;
} rob_dispatch_pkg_t;
/***********************cdb pkg*********************/
typedef struct packed {
    logic    r_valid;  // 指令有效
    logic    w_reg;    // 要写寄存器
    rob_id_t rob_id;   // rob_id
    word_t   w_data;   // 写的数据
    // else information for control
    // predict_info_t predict_info; // predict_info is in rob
    lsu_iq_pkg_t lsu_info;
    rob_ctrl_entry_t ctrl;
} cdb_info_t;

/**********************rob pkg**********************/

// 指令信息表项
typedef struct packed {
    logic [31: 0] pc;
    // ARF 相关
    logic [4 : 0] areg;
    logic         w_reg;
    logic         check;

    logic         w_mem;

    logic [31:0]  addr_imm;

    // 指令类型
    logic  alu_type; // 指令类型
    logic  mdu_type;
    logic  lsu_type;
    logic  flush_inst;
    logic  jump_inst; // TODO: 似乎暂时没有用到？
    logic  priv_inst;
    logic  rdcnt_inst;
    logic  tlb_inst;
    // control info, temp, 根据需要自己调整
    predict_info_t predict_info;
    logic if_jump; // 是否跳转 TODO: 什么意思？
    // 特殊指令独热码
    logic break_inst;
    logic cacop_inst; // lsu iq
    logic dbar_inst;
    logic ertn_inst;
    logic ibar_inst;
    logic idle_inst;
    logic invtlb_inst;
    logic ll_inst; // lsu iq

    logic rdcntid_inst;
    logic rdcntvh_inst;
    logic rdcntvl_inst;

    logic sc_inst; // lsu iq
    logic syscall_inst;
    logic tlbfill_inst;
    logic tlbrd_inst;
    logic tlbsrch_inst;
    logic tlbwr_inst;

    // csr
    csr_op_type_t csr_op_type;
    logic [4:0]  inst_4_0; // cache_op 和 tlb_op

    //tlb
    logic decode_err;

    // branch
    logic is_branch;
    br_type_t br_type;
} rob_inst_entry_t;

// 有效信息表项
typedef struct packed {
    logic complete;
} rob_valid_entry_t;

// 数据信息表项
typedef struct packed {
    logic [`ROB_WIDTH - 1:0] w_preg;
    logic [31: 0]            data;
    logic                    w_valid;  // valid
    rob_ctrl_entry_t         ctrl;
    lsu_info_t               lsu_info;
} rob_data_entry_t;

// 控制信息表项
typedef struct packed {
    // 异常控制信号流，其他控制信号流，后续补充
    exc_info_t exc_info;
    // logic bpu_fail;
} rob_ctrl_entry_t;

typedef struct packed {
    logic fetch_exception;    //为1表示fetch级有异常
    logic execute_exception;  //为1表示访存级有异常，当fetch级有异常这个值是什么都行
    logic [5:0] exc_code;     //fetch级有异常则存fetch级别的异常码，elif访存异常存访存异常码，如果都没有异常则存什么都行
    logic [31:0] badva;       //如果访存出现例外把地址存到这里
    // logic syscall_inst;
    // logic break_inst;
    // logic decode_err;
    // logic priv_inst;
    //上面这四个之前忘记加了，来自译码级，要求指令无效时为0（？ TODO)
} exc_info_t;

/**********************dispatch  to  execute  pkg******************/
typedef struct packed {
    word_t  pc;
    word_t  imm;
    logic   if_jump;

    logic   [2:0]   grand_op;
    logic   [2:0]   op;
    
    rob_id_t        wreg_id;
    logic   wreg;
    logic   wmem;
    // logic   [3:0]   rmask;
    // logic   [3:0]   strb;
    // logic   cacop;
    // logic   dbar;
    // logic   llsc;
    logic   msigned;
    logic   msize;

    logic   inst_valid; 

    fetch_exc_info_t    fetch_exc_info;
} decode_info_t;

typedef struct packed {
    logic    [3 :0][31:0] data; // 四个源操作数
    rob_id_t [3 :0]       preg; // 四个源操作数对应的preg id
    logic    [3 :0]       data_valid; //四个源操作数是否已经有效
    logic    [1 :0]       inst_choose;//选择送进来的哪条指令[1:0]分别对应传进来的两条指令
    logic    [1 :0]       r_valid; // 指令是否有效
    // 控制信号，包括：
    // alu计算类型 √ ，jump类型 x
    // mdu计算类型 √ 
    // lsu类型 √ 
    // 异常信号 x 
    // FU之前的一切异常信号 x 

    logic [1:0][31:0]  imm; // addr_imm
    // ALU & MDU 信号
    logic [1:0][2:0]   grand_op; 
    logic [1:0][2:0]   op;
    // LSU 信号
    logic [1:0]        msigned; // 是否符号拓展（ld指令）
    logic [1:0][1:0]   msize;   // 读字节数目 - 1
    logic [1 :0]       w_mem;

    decode_info_t [1:0] di;
} p_i_pkg_t;

/**********************store buffer pkg******************/
typedef struct packed {
    logic   [31 : 0]    target_addr;
    logic   [31 : 0]    write_data;
    logic   [3  : 0]    wstrb;
    logic               valid;
    // logic               commit;
    logic               uncached;
    logic   [1  : 0]    hit;
    // logic               complete;
} sb_entry_t;

/**************************lsu pkg*************************/
typedef struct packed {
    rob_id_t       wid;     // 写回地址
    logic      msigned;     // 有符号拓展
    logic  [1:0] msize;     // 访存大小-1
    logic [31:0] vaddr;     // 虚拟地址
    logic [31:0] wdata;     // 写数据
    logic [3 :0] rmask;     // 读掩码
    logic [3 :0] strb ;     // 写掩码
} iq_lsu_pkg_t;

// LSU 到 LSU IQ 的响应
typedef struct packed {
//   lsu_excp_t   excp;
//   fetch_excp_t f_excp;
    logic   [3:0]   strb;
    logic   [3:0]   rmask;  // 需要读的字节
    logic           msigned;     // 有符号拓展
    logic   [1:0]   msize;     // 访存大小-1
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
    logic           hit_dirty;  // 是否命中dirty位
    logic   [31:0]  cache_dirty_addr;
    // TODO cache_dirty_addr
    logic           cacop_dirty;// 专门为cacop直接地址映射准备的dirty位
    execute_exc_info_t execute_exc_info;
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
    logic   [1 :0]  way_choose;    // TODO 读写对应的路，两位分别对应两路，对应位表示对应路是否命中
    cache_tag_t     tag_data;   // 写回tag数据
    logic           tag_we;     // 写回tag使能信号
    // 向DCache发送Data SRAM请求
    logic   [31:0]  data_data;  // 写回data的数据
    logic   [3:0]   strb;       // 写回data的strb
    logic   fetch_sb;           // 进状态机的时候一定fetch_sb为0
} commit_cache_req_t;

// commit与ICache的交互
typedef struct packed {
    // 向ICache发送SRAM读写请求
    logic   [31:0]  addr;       // 地址
    logic   [1 :0]  way_choose; // TODO 读写对应的路，两位分别对应两路，对应位表示对应路是否命中
    cache_tag_t     tag_data;   // 写回tag数据
    logic           tag_we;     // 写回tag使能信号
} commit_fetch_req_t;

typedef struct packed {
    logic   [31:0]  addr;       // 反馈地址
    // logic   [31:0]  data;
    sb_entry_t      sb_entry;   // 读出的sb_entry
    // Data SRAM向commit级发送读结果
    logic   [31:0]  data;       // 返回的数据
    logic   [31:0]  data_other; // 返回的另一路数据，默认当返回两路数据的时候，data为0路，data_other为1路
} cache_commit_resp_t;

// commit与Icache的交互反馈
typedef struct packed {
    logic   [1 :0]  way_hit;    // 命中结果
    tlb_exception_t tlb_exception; // TLB异常
} fetch_commit_resp_t;

// commit与AXI的交互
typedef struct packed {
    logic   [31:0]  raddr;
    logic   [7:0]   rlen;

    logic   [31:0]  waddr;
    logic   [31:0]  wdata;
    logic   [7:0]   wlen;

    logic   [3:0]   strb;
    logic   [3:0]   rmask;
} commit_axi_req_t;

typedef struct packed {
    logic   [31:0]  rdata;
} axi_commit_resp_t;

typedef struct packed {
    logic   [31:0]  addr;
    logic   [2:0]   cache_op;
} commit_icache_req_t;

`endif
