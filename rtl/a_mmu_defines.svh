//a_csr.svh里面和tlb相关的内容还有wired的标记，最好删掉

//mem_type
`define _MEM_FETCH  `2'h0
`define _MEM_LOAD   `2'h1
`define _MEM_STORE  `2'h2

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
    logic           e;
    logic [9:0]  asid;
    logic           g;
    logic     huge_ps;
    logic [18:0] vppn;
} tlb_key_t;

typedef struct packed {
    logic           v;
    logic           d;
    logic [1:0]   mat;
    logic [1:0]   plv;
    logic [19:0]  ppn;
} tlb_value_t;

//tlb
typedef struct packed {
    logic [31:0]  pa;
    logic [1:0]  mat;
    logic      valid;
    exception_t exception;
} trans_result_t;

typedef struct packed {
    logic [`_TLB_ENTRY_NUM - 1 : 0] tlb_rd_index;
    logic [`_TLB_ENTRY_NUM - 1 : 0] tlb_wr_index;
    tlb_entry_t tlb_wr_entry;
} tlb_rdwr_req_t;

