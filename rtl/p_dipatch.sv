`include "a_defines.svh"

// TEMP!!! 结构体定义：后面放入头文件中
typedef struct packed {
    logic [`ROB_WIDTH - 1 : 0] w_preg;
    logic [31             : 0] w_data;
    logic                      w_valid;
} cdb_dispatch_pkg_t;

// typedef struct packed {
//     // static info
//     logic [1              : 0]                     inst_type;
//     logic [`ARF_WIDTH - 1 : 0]                     areg;  // 目的寄存器
//     logic [`ROB_WIDTH - 1 : 0]                     preg;  // 物理寄存器 
//     logic [1              : 0][`ROB_WIDTH - 1 : 0] src_preg;  // 源寄存器对应的物理寄存器
//     logic [31             : 0]                     pc;    // 指令地址
//     logic                                          issue; // 是否被分配到ROB
//     logic                                          w_reg;
//     logic                                          w_mem;
//     logic                                          tier_id;
// } dispatch_rob_pkg_t;

// typedef struct pack {
//     logic [1 : 0][31 : 0] rob_data; 
//     logic [1 : 0]         rob_complete;
// } rob_dispatch_pkg_t;

module p_dispatch #(    
) (
    input clk,
    input rst_n,
    input cdb_dispatch_pkg_t    [1 : 0] cdb_dispatch_i,
    input rob_dispatch_pkg_t    [1 : 0] rob_dispatch_i,
    
    output dispatch_rob_pkg_t   [1 : 0] dispatch_rob_o,

    handshake_if.receiver r_p_receiver,

    handshake_if.sender   p_alu_sender,
    handshake_if.sender   p_lsu_sender,
    handshake_if.sender   p_mdu_sender,
)

