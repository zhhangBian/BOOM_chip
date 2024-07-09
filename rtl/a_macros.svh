`ifndef _BOOM_MACROS_HEAD
`define _BOOM_MACROS_HEAD

`define ARF_WIDTH 5
`define ROB_WIDTH 6

/* ============================== BPU ============================== */
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

`define ALU_TYPE   'd1
`define MDU_TYPE   'd2
`define LSU_TYPE   'd3
`define RESERVE    'd0

`endif
