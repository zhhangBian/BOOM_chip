`include "a_defines.svh"

module commit #(
    
) (
    input logic clk,
    input logic rst_n,
    output logic flush,    

    input rob_commit_pkg_t [1:0] rob_commit_i,

    output logic [1:0] commit_request_o,
);

//TODO1 选择提交指令，将指令信息（写寄存器，读写内存）
assign commit_request_o[0] = rob_commit_i[0].c_valid;

assign commit_request_o[1] = rob_commit_i[0].c_valid
                            &rob_commit_i[1].c_valid
                            &!rob_commit_i[0].first_commit
                            &!rob_commit_i[1].first_commit;

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


endmodule