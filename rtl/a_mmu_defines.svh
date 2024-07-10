//a_csr.svh里面和tlb相关的内容还有wired的标记，最好删掉

`define _TLB_ENTRY_NUM 64

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
