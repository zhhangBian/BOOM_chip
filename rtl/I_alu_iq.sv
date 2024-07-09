`include "a_structure.svh"
`include "a_iq_defines.svh"

module alu_iq # (
    // 设置IQ共有8个表项
    parameter int IQ_SIZE = 8,
    parameter int AGING_LENGTH = 4
)(
    input logic clk,
    input logic rst_n,
    input logic flush,

    // 控制信息
    input ctrl_info_t [1:0]     p_ctrl_i,
    input data_pack_t [1:0]     p_data_i,
    input logic     [1:0]       p_valid_i,
    // IQ未满，可以接收指令
    output logic    [1:0]       iq_ready_o,

    // TODO: CDB

    // 唤醒的信号
    input logic     [1:0]       wkup_valid_i,
    input rob_id_t  [1:0]       wkup_rid_i,
    input word_t    [1:0]       wkup_data_i,

    output logic    [1:0]       wkup_valid_o,
    output rob_id_t [1:0]       wkup_rid_o,
    output logic    [1:0][31:0] wkup_data_o
);

// 对应的表项是否空闲
logic [IQ_SIZE - 1:0] empty_q;
// 对应的表项是否可发射
logic [IQ_SIZE - 1:0] ready_q;
// 对应的aging位
logic [IQ_SIZE - 1:0][AGING_LENGTH - 1:0] aging_q;

//////////////////////////////////////////////////
// 根据AGING选择指令
// 目前只处理了IQ为8的情况
logic [3:0][3:0] aging_sel_1;
logic [1:0][3:0] aging_sel;

always_comb begin
    aging_sel_1[0] = (aging_q[1] > aging_q[0]) ? 1 : 0;
    aging_sel_1[1] = (aging_q[3] > aging_q[2]) ? 3 : 2;
    aging_sel_1[2] = (aging_q[5] > aging_q[4]) ? 5 : 4;
    aging_sel_1[3] = (aging_q[7] > aging_q[5]) ? 7 : 6;
end

always_comb begin
    aging_sel[0] = (aging_sel_1[1] > aging_sel_1[0]) ? 1 : 0;
    aging_sel[1] = (aging_sel_1[3] > aging_sel_1[2]) ? 3 : 2;
end
// TODO：具体的移位算法之后实现
//////////////////////////////////////////////////

// 是否发射指令：同时发射
logic excute_ready;
// 指令是否可执行
logic [1:0] excute_valid;

logic [1:0][2:0] free_cnt;
logic [1:0][2:0] free_cnt_q;
for (genvar i = 0; i < 2 ; i += 1) begin
    free_cnt[i] = free_cnt_q[i] - p_valid_i[i] + (excute_ready & excute_valid[i]);
    // 更新输出信号
    iq_ready_o[i] = (free_cnt[i] >= 1);
end

always_ff @(posedge clk) begin
    if(!rst_n || flush) begin
        free_cnt_q[0] <= 4;
        free_cnt_q[1] <= 4;
    end
    else begin
        free_cnt_q <= free_cnt;
    end
end

// IQ静态部分：指令中不会改变的部分
// iq_static_t [1:0][3:0] iq_static;
// word_t [1:0][3:0][1:0] iq_data;
iq_static_t [IQ_SIZE-1:0] iq_static;
word_t [IQ_SIZE-1:0] iq_data;
// P级传入的信息
iq_static_t [1:0] p_static_i;
// 输出的static信息


for(genvar i = 0; i < 2; i += 1) begin
    always_comb begin
        // TODO：更新此部分用到的控制信号
        p_static_i[i].di        = p_ctrl_i[i].di;
        p_static_i[i].pc        = p_ctrl_i[i].pc;
        p_static_i[i].wreg_id   = p_ctrl_i[i].wreg.rob_id;
        p_static_i[i].imm       = p_ctrl_i[i].addr_imm;
    end
end

// 创建IQ表项
for(genvar i = 0; i < IQ_SIZE; i += 1) begin
    iq_entry # (
        .CDB_COUNT(CDB_COUNT),
        .IQ_SIZE(IQ_SIZE)
    )(
        .clk,
        .rst_n,
        .flush,

        .wkup_valid_i(wkup_valid_i),
        .wkup_rid_i(wkup_rid_i),
        .wkup_data_i(wkup_data_i),
        .static_i(p_static_i),

        .wkup_valid_o(wkup_valid_o),
        .wkup_rid_o(wkup_rid_o),
        .wkup_data_o(wkup_data_o),
        .static_o(iq_static)
    );
end



endmodule