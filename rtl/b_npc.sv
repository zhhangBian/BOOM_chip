/**
 * This is an npc module in place of bpu module. 
 * It only generate pc+8 result.
 */

`include "a_defines.svh"

module f_npc (
    input wire                  clk,
    input wire                  rst_n,
    input wire                  g_flush,

    input  correct_info_t [1:0] correct_infos_i, // 后端反馈的修正信息
    handshake_if.sender         sender // predict_infos_t type
);

logic [31:0] pc;
logic [31:0] npc;

assign npc = {pc[31:3] + 1, 3'b000};

always_ff @(posedge clk ) begin : pc_logic
    if (!rst_n) begin
        pc <= `BPU_INIT_PC;
    end
    else if (g_flush) begin
        pc <= correct_infos_i.redir_addr;
    end
    else if (ready_i) begin
        pc <= npc;
    end
end

assign sender.data.pc = pc;
assign sender.data.mask = pc[2] ? 2'b01 : 2'b11;

predict_info_t predict_info;
assign predict_info.target_pc   = npc;
assign predict_info.is_branch   = '0;
assign predict_info.br_type     = '0;
assign predict_info.taken       = '0;
assign predict_info.scnt        = '0;
assign predict_info.need_update = '0;
assign predict_info.history     = '0;

assign sender.data.predict_info = predict_info;
    
endmodule
