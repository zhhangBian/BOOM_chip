`include "a_defines.svh"

module commit #(

) (
    input   logic clk,
    input   logic rst_n,
    // 唯一一处flush的输出
    output  logic flush,

    input   rob_commit_pkg_t [1:0] rob_commit_i,

    // 给ROB的输出信号，确定提交相关指令
    output  logic [1:0] commit_request_o,

    // commit与DCache的接口
    output  
    input   logic writre_hit,
    input
);

word_t [1:0] wdata;
arf_id_t [1:0] arf_id;


assign wdata = {rob_commit[1].w_data, rob_commit[0].w_data};
assign arf_id = {rob_commit[1].w_areg, rob_commit[0].w_areg};



//TODO1 选择提交指令，将指令信息（写寄存器，读写内存）
// TODO：细化提交的具体逻辑
// assign commit_request_o[0] = rob_commit_i[0].c_valid;

// assign commit_request_o[1] = rob_commit_i[0].c_valid &
//                             rob_commit_i[1].c_valid &
//                             ~rob_commit_i[0].first_commit &
//                             ~rob_commit_i[1].first_commit;

// ------------------------------------------------------------------
// 与DCache的一级流水交互


// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


// 信息梳理

// TODO2 特殊处理
// tlb维护指令
// uncached指令
// cache维护指令
// dbar,ibar
/*******************************/
// 分支预测失败
// 写csr指令
// 异常处理

// 以上所有指令只允许单条提交

// tlb 维护，在commit级统一管理TLB，对应有一个ITLB和DTLB的映射
// cache维护指令
// dbar, ibar

csr_t csr;
tlb_entry_t [63 : 0] tlb_entrys;

endmodule

// ------------------------------------------------------------------

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/* 不出bug
__________████████_____██████
_________█░░░░░░░░██_██░░░░░░█
________█░░░░░░░░░░░█░░░░░░░░░█
_______█░░░░░░░███░░░█░░░░░░░░░█
_______█░░░░███░░░███░█░░░████░█
______█░░░██░░░░░░░░███░██░░░░██
_____█░░░░░░░░░░░░░░░░░█░░░░░░░░███
____█░░░░░░░░░░░░░██████░░░░░████░░█
____█░░░░░░░░░█████░░░████░░██░░██░░█
___██░░░░░░░███░░░░░░░░░░█░░░░░░░░███
__█░░░░░░░░░░░░░░█████████░░█████████
_█░░░░░░░░░░█████_████___████_█████___█
_█░░░░░░░░░░█______█_███__█_____███_█___█
█░░░░░░░░░░░░█___████_████____██_██████
░░░░░░░░░░░░░█████████░░░████████░░░█
░░░░░░░░░░░░░░░░█░░░░░█░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░██░░░░█░░░░░░██
░░░░░░░░░░░░░░░░░░██░░░░░░░███████
░░░░░░░░░░░░░░░░██░░░░░░░░░░█░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░█████████░░░░░░░░░░░░░░██
░░░░░░░░░░█▒▒▒▒▒▒▒▒███████████████▒▒█
░░░░░░░░░█▒▒███████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█
░░░░░░░░░█▒▒▒▒▒▒▒▒▒█████████████████
░░░░░░░░░░████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█
░░░░░░░░░░░░░░░░░░██████████████████
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
██░░░░░░░░░░░░░░░░░░░░░░░░░░░██
▓██░░░░░░░░░░░░░░░░░░░░░░░░██
▓▓▓███░░░░░░░░░░░░░░░░░░░░█
▓▓▓▓▓▓███░░░░░░░░░░░░░░░██
▓▓▓▓▓▓▓▓▓███████████████▓▓█
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█
    */