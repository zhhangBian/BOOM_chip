/**
 * This is an npc module in place of bpu module. 
 * It only generate pc+8 result.
 */

`include "define.svh"

module f_npc (
    input logic clk,
    input logic rst_n,
    
    input  logic            ready_i,
    output logic            valid_o,

    input  correct_info_t   correct_info_i, // 后端反馈的修正信息

    output logic [31:0 ]    pc_o, // 指令PC，传递给ICACHE
    output logic [ 1:0 ]    mask_o, // 掩码，表示当前的两条指令中那一条需要被取出来。比如2'b10表明偶数PC需要取，而奇数PC不需要
    output predict_info_t   predict_info_o // 预测信息
);

logic [31:0] pc;

always_ff @( clk ) begin : pc_logic
    if (!rst_n) begin
        pc <= BPU_INIT_PC;
    end
    else if (correct_info_i.redir) begin
        pc <= correct_info_i.redir_addr;
    end
    else if (ready_i) begin
        if (pc[3]) begin
            pc <= pc + 32'd4;
        end
        else begin
            pc <= pc + 32'd8;
        end
    end
    else begin
        pc <= pc;
    end
end

assign pc_o = pc
    
endmodule