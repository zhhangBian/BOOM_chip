`ifndef _BOOM_MACROS_HEAD
`define _BOOM_MACROS_HEAD

`define ARF_WIDTH 5
`define ROB_WIDTH 6

`define ALU_TYPE   'd1
`define MDU_TYPE   'd2
`define LSU_TYPE   'd3
`define RESERVE    'd0

// BPU macro

`define BPU_HISTORY_LEN 5 // 历史总共 5 位
`define BPU_PHT_PC_LEN 7 // PC[9:3] 共 7 位
`define BPU_PHT_LEN (`BPU_HISTORY_LEN + `BPU_PHT_PC_LEN) // = 12
`define BPU_PHT_DEPTH (1 << `BPU_PHT_LEN) // PHT大小 = 4096 项，奇偶共 8192 项，共 16324 bits

`define BPU_RAS_LEN 3 // 足够用了
`define BPU_RAS_DEPTH (1 << `BPU_RAS_LEN) //  RAS 的栈的大小 = 8

`define BPU_BTB_LEN 9
`define BPU_BTB_DEPTH (1 << `BPU_BTB_LEN) // 奇偶 BTB 各 512 项，共 1024 项
`define BPU_TAG_LEN 6 // tag存储pc[17:12]为作为tag

`define BPU_BHT_LEN `BPU_BTB_LEN // the same len as btb
`define BPU_BHT_DEPTH (1 << `BPU_BHT_LEN)

`define BPU_INIT_PC 32'h1c00_0000

// Decoder Macro

`define D_BEFORE_QUEUE_DEPTH 2 // decoder 前的队列深度，共 8 条指令
`define D_AFTER_QUEUE_DEPTH 4 // decoder 后的队列深度，共 16 条指令

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

`endif
