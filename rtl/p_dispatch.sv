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
    input rename_dispatch_pkg_t [1 : 0] rename_dispatch_i,
    input cdb_dispatch_pkg_t    [1 : 0] cdb_dispatch_i,
    input rob_dispatch_pkg_t    [1 : 0] rob_dispatch_i,
    
    output dispatch_rob_pkg_t   [1 : 0] dispatch_rob_o,

    handshake_if.receiver r_p_receiver,

    handshake_if.sender   p_alu_sender, 
    handshake_if.sender   p_lsu_sender,
    handshake_if.sender   p_mdu_sender,
)

// handshake signal
logic  alu_ready, lsu_ready, mdu_ready;
assign alu_ready = p_alu_sender.ready;
assign lsu_ready = p_lsu_sender.ready;
assign mdu_ready = p_mdu_sender.ready;

assign r_p_receiver.ready = alu_ready & lsu_ready & mdu_ready;

r_p_pkg_t   r_p_pkg;
always_comb begin
    for (genvar i = 0; i < 2; i++) begin
        dispatch_rob_o[i].inst_type = r_p_pkg.inst_type[i];
        dispatch_rob_o[i].areg      = r_p_pkg.areg[i];
        dispatch_rob_o[i].preg      = r_p_pkg.preg[i];
        dispatch_rob_o[i].src_preg  = {r_p_pkg.src_preg[i * 2 + 1],r_p_pkg.src_preg[i * 2]};
        dispatch_rob_o[i].pc        = r_p_pkg.pc[i];
        dispatch_rob_o[i].issue     = r_p_pkg.r_valid[i];
        dispatch_rob_o[i].w_reg     = r_p_pkg.w_reg[i];
        dispatch_rob_o[i].w_mem     = r_p_pkg.w_mem[i];
        dispatch_rob_o[i].tier_id   = r_p_pkg.tier_id[i];
    end
end


endmodule

