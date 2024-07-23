`ifndef _BOOM_MMU_HEAD
`define _BOOM_MMU_HEAD
//a_csr.svh里面和tlb相关的内容还有wired的标记，最好删掉

//mmu_mem_type
`define _MEM_FETCH  2'h0
`define _MEM_LOAD   2'h1
`define _MEM_STORE  2'h2

//csr
`define _CRMD_PLV   1:0
`define _CRMD_DA    3
`define _CRMD_PG    4
`define _CRMD_DATF  6:5
`define _CRMD_DATM  8:7

`define _DMW_PLV0   0
`define _DMW_PLV3   3
`define _DMW_PSEG   27:25
`define _DMW_VSEG   31:29

//tlb
typedef struct packed {
    logic [31:0]  pa;
    logic [1:0]  mat;
    logic      valid;
    // exception_t exception;
} trans_result_t;

typedef struct packed {
    logic [5:0]    ecode;
    logic [8:0]    esubcode;
} tlb_exception_t;

typedef struct packed {
    logic [`_TLB_ENTRY_NUM - 1 : 0] tlb_write_req;
    tlb_entry_t tlb_write_entry;
} tlb_write_req_t;

`endif
