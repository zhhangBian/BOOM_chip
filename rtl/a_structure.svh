`ifndef _BOOM_STRUCTURE_HEAD
`define _BOOM_STRUCTURE_HEAD

/*============================== Branch Predict ==============================*/
// BPU 类型定义
typedef enum logic[1:0] {
    BR_NORMAL, // 立即数跳转指令, BEQ, BNE, BGT, BGE, BLT, BLE
    BR_B, // LA 中的 B 指令
    BR_CALL, // LA 中的 BL 指令
    BR_RET // LA 中的 JIRL 指令
} br_type_t;

typedef struct packed {
    logic [31:0]                    target_pc; // 跳转到的目标 PC 
    logic [31:0]                    next_pc;
    logic                           is_branch;
    br_type_t                       br_type;
    logic                           taken;
    logic [ 1:0]                    scnt;
    logic                           need_update;
    logic [`BPU_HISTORY_LEN-1:0]    history; // 最新的历史放 0 位，旧的历史往高位移
    // ras_ptr???    
} predict_info_t;

typedef struct packed { // TODO: 后端不能同时提交两条分支指令
    logic  [31:0]   pc;
    logic           flush; // TODO: 放到 correct_info 外面
    logic  [31:0]   redir_addr; // TODO: 放到 correct_info 外面 如果跳转错误,后端得到正确的跳转地址之后反馈给前端

    logic           target_miss; // TODO:目标地址预测错误，需要更新BTB. taken预测错了也要将target_miss置有效。TODO: 暂时可能用不上
    logic           type_miss; // TODO:类型预测错误，说明一定这条指令一定不在表中，全部更新 TODO: 暂时可能用不上
    logic           taken; // 是否跳转
    logic           is_branch;
    br_type_t       branch_type; // 分支类型，用于更新 BTB
    logic           update; // 如果这条指令是分支或者预测成了分支，就要置 1 。
    logic  [31:0]   target_pc; // 正确的跳转地址，用于更新 BTB
    logic  [`BPU_HISTORY_LEN-1:0] history; // 历史记录，最新的历史往 0 位放，旧的历史左移一位。
    logic  [ 1:0]   scnt; // 饱和计数器的值。
} correct_info_t;

typedef struct packed {
    logic                           is_branch;
    logic  [`BPU_TAG_LEN-1 : 0]     tag;
    logic  [31:0]                   target_pc;
    br_type_t                       br_type;
} bpu_btb_entry_t;

typedef struct packed {
    logic  [`BPU_HISTORY_LEN-1 : 0]  history;
} bpu_bht_entry_t;

typedef struct packed {
    logic  [1:0]    scnt;
} bpu_pht_entry_t;

/* ============================== Decoder ==============================*/
typedef logic [0 : 0] ertn_inst_t;
typedef logic [0 : 0] priv_inst_t;
typedef logic [0 : 0] idle_inst_t;
typedef logic [0 : 0] syscall_inst_t;
typedef logic [0 : 0] break_inst_t;
typedef logic [1 : 0] csr_op_type_t;
typedef logic [0 : 0] tlbsrch_inst_t;
typedef logic [0 : 0] tlbrd_inst_t;
typedef logic [0 : 0] tlbwr_inst_t;
typedef logic [0 : 0] tlbfill_inst_t;
typedef logic [0 : 0] invtlb_inst_t;
typedef logic [0 : 0] flush_inst_t;
typedef logic [0 : 0] ibar_inst_t;
typedef logic [3 : 0] fpu_op_t;
typedef logic [0 : 0] fpu_mode_t;
typedef logic [3 : 0] rnd_mode_t;
typedef logic [0 : 0] fpd_inst_t;
typedef logic [0 : 0] fcsr_upd_t;
typedef logic [0 : 0] fcmp_t;
typedef logic [0 : 0] fcsr2gr_t;
typedef logic [0 : 0] gr2fcsr_t;
typedef logic [0 : 0] upd_fcc_t;
typedef logic [0 : 0] fsel_t;
typedef logic [0 : 0] fclass_t;
typedef logic [0 : 0] bceqz_t;
typedef logic [0 : 0] bcnez_t;
typedef logic [31: 0] inst_t;
typedef logic [0 : 0] alu_inst_t;
typedef logic [0 : 0] mdu_inst_t;
typedef logic [0 : 0] lsu_inst_t;
typedef logic [0 : 0] fpu_inst_t;
typedef logic [0 : 0] fbranch_inst_t;
typedef logic [2 : 0] reg_type_r0_t;
typedef logic [2 : 0] reg_type_r1_t;
typedef logic [1 : 0] reg_type_w_t;
typedef logic [2 : 0] imm_type_t;
typedef logic [1 : 0] addr_imm_type_t;
typedef logic [0 : 0] slot0_t;
typedef logic [0 : 0] refetch_t;
typedef logic [0 : 0] need_fa_t;
typedef logic [0 : 0] fr0_t;
typedef logic [0 : 0] fr1_t;
typedef logic [0 : 0] fr2_t;
typedef logic [0 : 0] fw_t;
typedef logic [2 : 0] alu_grand_op_t;
typedef logic [2 : 0] alu_op_t;
typedef logic [0 : 0] target_type_t;
typedef logic [3 : 0] cmp_type_t;
typedef logic [0 : 0] jump_inst_t;
typedef logic [2 : 0] mem_type_t;
typedef logic [0 : 0] mem_signed_t;
typedef logic [1 : 0] mem_size_t;
typedef logic [0 : 0] mem_write_t;
typedef logic [0 : 0] mem_read_t;
typedef logic [0 : 0] cacop_inst_t;
typedef logic [0 : 0] sc_inst_t;
typedef logic [0 : 0] ll_inst_t;
typedef logic [0 : 0] dbar_inst_t;
typedef logic [0 : 0] rdcnt_inst_t;
typedef logic [0 : 0] rdcntvl_inst_t;
typedef logic [0 : 0] rdcntvh_inst_t;
typedef logic [0 : 0] rdcntid_inst_t;
typedef logic [0 : 0] tlb_inst_t;

typedef struct packed {
    addr_imm_type_t addr_imm_type; // 地址是 S12, S14, S16 还是 S26
    alu_grand_op_t  alu_grand_op; // alu大类，分别来源于算术运算、逻辑运算、位移运算以及其他（LU12I, PCADDU12I, PC+4(link)）
    alu_inst_t      alu_inst; // 是否是需要使用 alu 的指令
    alu_op_t        alu_op; // alu 子类，在不同大类下有不同含义
    break_inst_t    break_inst; // 是否是 break 指令
    br_type_t       br_type; // 是否是 break 指令
    cacop_inst_t    cacop_inst; // 是否是 cacop 指令
    csr_op_type_t   csr_op_type; // csr 指令类型
    dbar_inst_t     dbar_inst; // 是否是 DBAR 指令
    logic           decode_err; // 出现未知指令
    ertn_inst_t     ertn_inst; // 是否是 ertn 指令
    flush_inst_t    flush_inst;
    ibar_inst_t     ibar_inst;
    idle_inst_t     idle_inst; // 仅在 IDLE 指令下置1.
    imm_type_t      imm_type; // 立即数类型 _IMM_...
    inst_t          inst; // 指令本身
    invtlb_inst_t   invtlb_inst; // 是否是invtlb指令
    jump_inst_t     jump_inst; // 是否是跳转指令
    ll_inst_t       ll_inst; // 是否是原子访问指令
    lsu_inst_t      lsu_inst; // load, store, cacop, dbar指令
    mem_read_t      mem_read; // 是否需要读取内存
    mem_signed_t    mem_signed; // 读取出来的数据是否会有符号扩展
    mem_size_t      mem_size; // 读取出来的数据的字节数目-1; WORD 为 3, HALF-WORD 为 1, BYTE 为 0.
    mem_write_t     mem_write; // 是否会写入内存
    mdu_inst_t      mdu_inst; // 是否是 mdu 指令
    priv_inst_t     priv_inst; // 是否是特权指令
    rdcnt_inst_t    rdcnt_inst; // 是否是 rdcnt 类型指令
    rdcntid_inst_t  rdcntid_inst;
    rdcntvh_inst_t  rdcntvh_inst;
    rdcntvl_inst_t  rdcntvl_inst;
    reg_type_r0_t   reg_type_r0; // 
    reg_type_r1_t   reg_type_r1; // 
    reg_type_w_t    reg_type_w; // RD, RJD(RJ寄存器，仅RDCNTID指令会用), BL1(R1寄存器), None
    sc_inst_t       sc_inst; // 是否是原子存储指令
    syscall_inst_t  syscall_inst; // 是否是 syscall 指令
    target_type_t   target_type; // 只有JIRL的目标地址和寄存器有关，其余均之和PC有关，因此要做区分
    tlb_inst_t      tlb_inst;
    tlbfill_inst_t  tlbfill_inst;
    tlbrd_inst_t    tlbrd_inst;
    tlbsrch_inst_t  tlbsrch_inst;
    tlbwr_inst_t    tlbwr_inst;
} d_decode_info_t;

// 数据通路

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
    logic w_check;
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
    logic   [5 :0]  wid;        // 写回地址
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
    // 给rename的check信号
    logic           check;

    // 在CSR指令中复用为rd寄存器的值
    logic   [31: 0] w_data;
    logic   [1:0][31: 0] s_data;
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

    logic   rdcnt_en;
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

// 控制信息表项
typedef struct packed {
    // 异常控制信号流，其他控制信号流，后续补充
    exc_info_t exc_info;
    // logic bpu_fail;
} rob_ctrl_entry_t;

typedef struct packed {
    logic [`ROB_WIDTH - 1 : 0] w_preg;
    logic [31             : 0] w_data;
    logic [1:0][31:0]          s_data;
    logic                      w_valid;  // valid
    rob_ctrl_entry_t           ctrl;
    lsu_iq_pkg_t                 lsu_info;
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
    word_t [1:0] s_data;
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
    logic [5 : 0] preg;
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
    logic [1:0][31: 0]       s_data;
    logic                    w_valid;  // valid
    rob_ctrl_entry_t         ctrl;
    lsu_iq_pkg_t               lsu_info;
} rob_data_entry_t;

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
