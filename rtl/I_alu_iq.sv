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
    input decode_info_t [1:0]   p_di_i,
    input data__t   [1:0]       p_data_i,
    input logic     [1:0]       p_valid_i,
    // IQ未满，可以接收指令
    output logic    [1:0]       iq_ready_o,

    input data_t    [1:0]       cdb_i,

    // 唤醒的信号
    input data_t    [1:0]       wkup_data_i,
    output data_t   [1:0]       wkup_data_o
);

// 对应的表项是否空闲
logic [IQ_SIZE - 1:0] empty_q;
// 对应的表项是否可发射
logic [IQ_SIZE - 1:0] ready_q;
logic [IQ_SIZE - 1:0] select_q;

// 是否发射指令：同时发射
logic excute_ready;
// 指令是否可执行
logic [1:0] excute_valid;

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

for(genvar i = 0; i < IQ_SIZE; i += 1) begin
    always_comb begin
        select_q = (i == aging_sel) ? '1 : '0;
    end
end
//////////////////////////////////////////////////

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
    wire [1:0] update_by;
    for(genvar j = 0; j < 2; j += 1) begin
        assign update_by = 
    end

    iq_entry # ()(
        .clk,
        .rst_n,
        .flush,

        .sel_i(),
        .update_i(|update_by),
        .data_i(p_data_i),
        .di_i(p_di_i),

        .wkup_data_i(wkup_data_i),
        .cdb_i(cdb_i),

        .ready_o(ready_q[i]),

        .wkup_sel_o(wkup_src[i]),
        .data_o(iq_data[i]),
        .di_o(iq_di[i])
    );
end

decode_info_t [1:0] sel_di_q, sel_di;
word_t [1:0][1:0] sel_data;
logic [1:0][1:0][1:0] sel_wkup_src;

for(genvar i = 0; i < 2; i += 1) begin
    always_comb begin
        sel_di[i] = '0;
        sel_data[i] = '0;
        sel_wkup_src[i] = '0;
        wkup_valid_o[i] = '0,
        wkup_rid_o[i] = '0;

        for(genvar j = 0; j < IQ_SIZE; j += 1) begin
            if(select_q[i][j]) begin
                sel_di[i] |= iq_di[j];
                sel_data[i] |= iq_data[i];
                sel_wkup_src[i] |= wkup_src[i];
                wkup_valid_o[i] |= excute_ready;
                wkup_rid_o[i] |= iq_di[i].wreg_id;
            end
        end
    end

    assign excute_valid = {|ready_q, (|ready_q) & (select_q[0] != select_q[1])};
end

always_ff @(posedge clk) begin
    if(excute_ready) begin
        sel_di_q <= sel_di;
    end
end

rob_id_t [1:0] e_reg_id;
logic [1:0] e_valid_q;
logic [1:0] l_e_ready;
logic [1:0] fifo_ready_q;

assign excute_ready = &l_e_ready;

for(genvar i = 0; i < 2; i += 1) begin
    assign e_reg_id[i] = sel_di[i].wreg_id;
    
    always_ff @(clk) begin
        if(!rst_n || flush) begin
            e_valid_q <= '0;
        end
        else begin
            if(excute_ready) begin
                e_valid_q[i] <= e_valid[i];
            end
            else begin
                if(e_valid_q[i] && fifo_ready_q[i]) begin
                    e_valid_q[i] <= '0;
                end
            end
        end
    end

    assign l_e_valid[i] = (!e_valid_q[i]) | fifo_ready_q[i];
end

logic [1:0] e_jump;
logic [1:0][31:0] e_jump_result;
logic [1:0][31:0] e_data;
// 转化后的数据
word_t [1:0][1:0] real_data;

for(genvar i = 0; i < 2; i += 1) begin
    e_alu alu(
        .r0_i(real_data[i][0]),
        .r1_i(real_data[i][1]),
        .pc_i(sel_di_q[i].pc),

        .grand_op_i(sel_di_q[i].di.alu_grand_op),
        .op_i(sel_di_q[i].di.alu_op),
        .res_o(e_data[i])
    );

    e_jump jump(
        .r0_i(real_data[i][0]),
        .r1_i(real_data[i][1]),
        .pc_i(sel_di_q[i].pc),
        .imm_i(sel_di_q[i].imm),

        .op_i({sel_di_q[i].di.alu_grand_op, sel_di_q[i].di.alu_op}),
        .res_o(e_jump_target[i]),
        .jump_o(e_jump[i])
    );
end

for(genvar i = 0; i < 2; i += 1) begin
    fifo #(

    )(
        
    )
end

endmodule