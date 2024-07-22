`ifndef _BOOM_DECODER_HEAD
`define _BOOM_DECODER_HEAD

`define D_BEFORE_QUEUE_DEPTH 4 // decoder 前的队列深度，共 8 条指令
`define D_AFTER_QUEUE_DEPTH 8 // decoder 后的队列深度，共 16 条指令

`define _INV_TLB_ALL (4'b1111)
`define _INV_TLB_MASK_G (4'b1000)
`define _INV_TLB_MASK_NG (4'b0100)
`define _INV_TLB_MASK_ASID (4'b0010)
`define _INV_TLB_MASK_VA (4'b0001)
// `define _CSR_NONE (2'b00) // define at "a_csr.svh"
// `define _CSR_RD (2'b01) // define at "a_csr.svh"
// `define _CSR_WR (2'b10) // define at "a_csr.svh"
// `define _CSR_XCHG (2'b11) // define at "a_csr.svh"
`define _RDCNT_NONE (2'd0)
`define _RDCNT_ID_VLOW (2'd1)
`define _RDCNT_VHIGH (2'd2)
`define _RDCNT_VLOW (2'd3) // 未使用
`define _REG_ZERO (3'b000)
`define _REG_RD (3'b001)
`define _REG_RJ (3'b010)
`define _REG_RK (3'b011)
`define _REG_IMM (3'b100)
`define _REG_W_NONE (2'b00)
`define _REG_W_RD (2'b01)
`define _REG_W_RJ (2'b10)
`define _REG_W_R1 (2'b11)
`define _IMM_U12 (3'd0)
`define _IMM_U5 (3'd1)
`define _IMM_S12 (3'd2)
`define _IMM_S20 (3'd3)
`define _IMM_S16 (3'd4)
`define _IMM_F1 (3'd5)
`define _IMM_S21 (3'd6)
`define _ADDR_IMM_S26 (2'd0)
`define _ADDR_IMM_S12 (2'd1)
`define _ADDR_IMM_S14 (2'd2)
`define _ADDR_IMM_S16 (2'd3)
`define _ALU_GTYPE_BW (2'd0)
`define _ALU_GTYPE_LI (2'd1)
`define _ALU_GTYPE_INT (2'd2)
`define _ALU_GTYPE_SFT (2'd3)
`define _ALU_STYPE_NOR (2'b00)
`define _ALU_STYPE_AND (2'b01)
`define _ALU_STYPE_OR (2'b10)
`define _ALU_STYPE_XOR (2'b11)
`define _ALU_STYPE_PCPLUS4 (2'b10)
`define _ALU_STYPE_PCADDUI (2'b11)
`define _ALU_STYPE_LUI (2'b01)
`define _ALU_STYPE_ADD (2'b00)
`define _ALU_STYPE_SUB (2'b01)
`define _ALU_STYPE_SLT (2'b10)
`define _ALU_STYPE_SLTU (2'b11)
`define _ALU_STYPE_SRL (2'b00)
`define _ALU_STYPE_SLL (2'b01)
`define _ALU_STYPE_SRA (2'b10)
`define _MDU_TYPE_MULL (2'b00)
`define _MDU_TYPE_MULH (2'b01)
`define _MDU_TYPE_MULHU (2'b11)
`define _MDU_TYPE_DIV (2'b00)
`define _MDU_TYPE_DIVU (2'b01)
`define _MDU_TYPE_MOD (2'b10)
`define _MDU_TYPE_MODU (2'b11)
`define _TARGET_REL (1'b0)
`define _TARGET_ABS (1'b1)
`define _CMP_NOCONDITION (4'b1110)
`define _CMP_E (4'b0100)
`define _CMP_NE (4'b1010)
`define _CMP_LE (4'b1101)
`define _CMP_GT (4'b0011)
`define _CMP_LT (4'b1001)
`define _CMP_GE (4'b0111)
`define _CMP_LTU (4'b1000)
`define _CMP_GEU (4'b0110)
`define _MEM_TYPE_NONE (3'd0)
`define _MEM_TYPE_WORD (3'd1)
`define _MEM_TYPE_HALF (3'd2)
`define _MEM_TYPE_BYTE (3'd3)
`define _MEM_TYPE_UWORD (3'd5)
`define _MEM_TYPE_UHALF (3'd6)
`define _MEM_TYPE_UBYTE (3'd7)

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

/*
typedef struct packed {
    fcmp_t fcmp;
    upd_fcc_t upd_fcc;
} decode_info_c_fcc_common_t;

typedef struct packed {
    cmp_type_t cmp_type;
    csr_op_inst_t csr_op_inst;
    invtlb_inst_t invtlb_inst;
    target_type_t target_type;
} decode_info_c_alu_common_t;

typedef struct packed {
    alu_grand_op_t alu_grand_op;
    alu_op_t alu_op;
} decode_info_alu_mdu_common_t;

typedef struct packed {
    dbarrier_t dbarrier;
    llsc_inst_t llsc_inst;
    cacop_inst_t cacop_inst;
    mem_read_t mem_read;
    mem_write_t mem_write;
} decode_info_c_lsu_common_t;

typedef struct packed {
    cmp_type_t cmp_type;
    csr_op_inst_t csr_op_inst;
    dbarrier_t dbarrier;
    fcmp_t fcmp;
    inst_t inst;
    invtlb_inst_t invtlb_inst;
    jump_inst_t jump_inst;
    llsc_inst_t llsc_inst;
    lsu_inst_t lsu_inst;
    cacop_inst_t cacop_inst;
    mem_read_t mem_read;
    mem_write_t mem_write;
    refetch_t refetch;
    target_type_t target_type;
    upd_fcc_t upd_fcc;
    idle_inst_t idle_inst;
} decode_info_c_t;

typedef struct packed {
    bceqz_t bceqz;
    bcnez_t bcnez;
    fclass_t fclass;
    fcmp_t fcmp;
    fsel_t fsel;
    upd_fcc_t upd_fcc;
} decode_info_fcc_t;

typedef struct packed {
    fpu_mode_t fpu_mode;
    fpu_op_t fpu_op;
    rnd_mode_t rnd_mode;
} decode_info_fpu_t;

typedef struct packed {
    alu_grand_op_t alu_grand_op;
    alu_op_t alu_op;
} decode_info_mdu_t;

typedef struct packed {
    dbarrier_t dbarrier;
    llsc_inst_t llsc_inst;
    cacop_inst_t cacop_inst;
    mem_read_t mem_read;
    mem_type_t mem_type;
    mem_write_t mem_write;
} decode_info_lsu_t;

typedef struct packed {
    alu_grand_op_t alu_grand_op;
    alu_op_t alu_op;
    cmp_type_t cmp_type;
    csr_op_inst_t csr_op_inst;
    invtlb_inst_t invtlb_inst;
    target_type_t target_type;
} decode_info_alu_t;

typedef struct packed {
    cmp_type_t cmp_type;
    csr_op_inst_t csr_op_inst;
    csr_rdcnt_t csr_rdcnt;
    dbarrier_t dbarrier;
    ertn_inst_t ertn_inst;
    fcmp_t fcmp;
    fcsr2gr_t fcsr2gr;
    fcsr_upd_t fcsr_upd;
    gr2fcsr_t gr2fcsr;
    inst_t inst;
    invtlb_inst_t invtlb_inst;
    jump_inst_t jump_inst;
    llsc_inst_t llsc_inst;
    lsu_inst_t lsu_inst;
    cacop_inst_t cacop_inst;
    mem_read_t mem_read;
    mem_write_t mem_write;
    priv_inst_t priv_inst;
    refetch_t refetch;
    slot0_t slot0;
    target_type_t target_type;
    tlbfill_inst_t tlbfill_inst;
    tlbrd_inst_t tlbrd_inst;
    tlbsrch_inst_t tlbsrch_inst;
    tlbwr_inst_t tlbwr_inst;
    upd_fcc_t upd_fcc;
    idle_inst_t idle_inst;
} decode_info_rob_t;

typedef struct packed {
    alu_grand_op_t alu_grand_op;
    alu_inst_t alu_inst;
    alu_op_t alu_op;
    bceqz_t bceqz;
    bcnez_t bcnez;
    break_inst_t break_inst;
    cmp_type_t cmp_type;
    csr_op_inst_t csr_op_inst;
    csr_rdcnt_t csr_rdcnt;
    dbarrier_t dbarrier;
    div_inst_t div_inst;
    ertn_inst_t ertn_inst;
    fbranch_inst_t fbranch_inst;
    fclass_t fclass;
    fcmp_t fcmp;
    fcsr2gr_t fcsr2gr;
    fcsr_upd_t fcsr_upd;
    fpd_inst_t fpd_inst;
    fpu_inst_t fpu_inst;
    fpu_mode_t fpu_mode;
    fpu_op_t fpu_op;
    fsel_t fsel;
    gr2fcsr_t gr2fcsr;
    inst_t inst;
    invtlb_inst_t invtlb_inst;
    lsu_inst_t lsu_inst;
    cacop_inst_t cacop_inst;
    mem_read_t mem_read;
    mem_type_t mem_type;
    mem_write_t mem_write;
    mdu_inst_t mdu_inst;
    need_fa_t need_fa;
    priv_inst_t priv_inst;
    refetch_t refetch;
    rnd_mode_t rnd_mode;
    slot0_t slot0;
    syscall_inst_t syscall_inst;
    target_type_t target_type;
    tlbfill_inst_t tlbfill_inst;
    tlbrd_inst_t tlbrd_inst;
    tlbsrch_inst_t tlbsrch_inst;
    tlbwr_inst_t tlbwr_inst;
    upd_fcc_t upd_fcc;
    idle_inst_t idle_inst;
} decode_info_p_t;
*/

typedef struct packed {
    addr_imm_type_t addr_imm_type; // 地址是 S12, S14, S16 还是 S26
    alu_grand_op_t  alu_grand_op; // alu大类，分别来源于算术运算、逻辑运算、位移运算以及其他（LU12I, PCADDU12I, PC+4(link)）
    alu_inst_t      alu_inst; // 是否是需要使用 alu 的指令
    alu_op_t        alu_op; // alu 子类，在不同大类下有不同含义
    break_inst_t    break_inst; // 是否是 break 指令
    br_type_t       br_type; // 是否是 break 指令
    cacop_inst_t    cacop_inst; // 是否是 cacop 指令
    cmp_type_t      cmp_type; // TODO: 不需要。跳转条件类型，包括无条件跳转。实际上是一个独热码。四位分别表示{小于，等于，大于，有符号}。比如BLE就是1101(有符号)
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
    jump_inst_t     jump_inst; // 是否是跳转指令 // TODO: 目前似乎还没有用到
    ll_inst_t       ll_inst; // 是否是原子访问指令
    lsu_inst_t      lsu_inst; // load, store, cacop, dbar指令
    mem_read_t      mem_read; // 是否需要读取内存
    mem_signed_t    mem_signed; // 读取出来的数据是否会有符号扩展
    mem_size_t      mem_size; // 读取出来的数据的字节数目-1; WORD 为 3, HALF-WORD 为 1, BYTE 为 0.
    mem_write_t     mem_write; // 是否会写入内存
    mdu_inst_t      mdu_inst; // 是否是 mdu 指令
    need_fa_t       need_fa; // 完全没有用到 TODO
    priv_inst_t     priv_inst; // 是否是特权指令
    rdcnt_inst_t    rdcnt_inst; // 是否是 rdcnt 类型指令
    rdcntid_inst_t  rdcntid_inst;
    rdcntvh_inst_t  rdcntvh_inst;
    rdcntvl_inst_t  rdcntvl_inst;
    refetch_t       refetch; // TODO: CSR, CACOP, ERTN, IDLE, TLB-relate, DBAR, IBAR, RDCNTVL.W, RD
    reg_type_r0_t   reg_type_r0; // 
    reg_type_r1_t   reg_type_r1; // 
    reg_type_w_t    reg_type_w; // RD, RJD(RJ寄存器，仅RDCNTID指令会用), BL1(R1寄存器), None
    sc_inst_t       sc_inst; // 是否是原子存储指令
    slot0_t         slot0; // TODO:不懂，一些奇怪的指令都会用到, 保罗ertn这些
    syscall_inst_t  syscall_inst; // 是否是 syscall 指令
    target_type_t   target_type; // 只有JIRL的目标地址和寄存器有关，其余均之和PC有关，因此要做区分
    tlb_inst_t      tlb_inst;
    tlbfill_inst_t  tlbfill_inst;
    tlbrd_inst_t    tlbrd_inst;
    tlbsrch_inst_t  tlbsrch_inst;
    tlbwr_inst_t    tlbwr_inst;
    /* Float point control signals
    bceqz_t         bceqz; // 是否否是bceqz指令
    bcnez_t         bcnez; // 是否是bcnez指令
    fbranch_inst_t  fbranch_inst; // 是否是浮点分支指令
    fclass_t        fclass; // 是否是fclass指令
    fcmp_t          fcmp; // 是否是FCMP.cond.S指令
    fcsr2gr_t       fcsr2gr; // 是否是
    fcsr_upd_t      fcsr_upd; // TODO：未使用
    fpd_inst_t      fpd_inst; // 不懂
    fpu_inst_t      fpu_inst; // 不懂
    fpu_mode_t      fpu_mode; // 不懂
    fpu_op_t        fpu_op; // 不懂
    fr0_t           fr0; // 不懂
    fr1_t           fr1; // 不懂
    fr2_t           fr2; // 不懂
    fsel_t          fsel; // 不懂
    fw_t            fw; // 不懂
    gr2fcsr_t       gr2fcsr; // 不懂
    rnd_mode_t      rnd_mode; // 不懂
    upd_fcc_t       upd_fcc; // 浮点，更新cf。
    */
} d_decode_info_t;

function logic [31:0] inst_to_data_imm (input logic[31:0] inst, input imm_type_t data_imm_type);
    logic [31:0] ret;
    // inst[4:0] and [31:25] unused
    case (data_imm_type)
        `_IMM_S12:  ret =  {{20{inst[21]}}, inst[21:10]};
        `_IMM_S20:  ret =  {{12{inst[24]}}, inst[24: 5]};
        `_IMM_U5:   ret =  {27'b0,          inst[14:10]};
        // `_IMM_U12:
        default:    ret =  {20'b0,          inst[21:10]}; 
    endcase
    return ret;
endfunction

function logic [31:0] inst_to_addr_imm (input logic[31:0] inst, input addr_imm_type_t addr_imm_type);
    logic [31:0] ret;
    // inst[31:26] unused
    case (addr_imm_type)
        `_ADDR_IMM_S12: ret =  {{20{inst[21]}}, inst[21:10]}; // 仅用于store/load指令，低位不补零;
        `_ADDR_IMM_S14: ret =  {{16{inst[23]}}, inst[23:10], 2'b0}; // 仅用于原子访存指令，低位补两个0;
        `_ADDR_IMM_S16: ret =  {{14{inst[25]}}, inst[25:10], 2'b0}; // 仅用于计算分支offset，低位补两个0;
        // _ADDR_IMM_S21:  // 仅用于浮点分支指令使用，也就是暂时不使用
        // `_ADDR_IMM_S26:
        default:        ret =  {{4 {inst[ 9]}}, inst[ 9:0 ], inst[25:10], 2'b0};
    endcase
    return ret;
endfunction

`endif

// 所有特权, rdcnt, dbar, ibar, 3csr, 5tlb, cacop, ertn, idle