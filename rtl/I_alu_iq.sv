`include "a_structure.svh"
`include "a_iq_defines.svh"

module alu_iq # (
    // 设置IQ共有4个表项
    parameter int IQ_SIZE = 4,
    parameter int AGING_LENGTH = 4
)(
    input   logic           clk,
    input   logic           rst_n,
    input   logic           flush,

    // 控制信息
    input   decode_info_t   p_di_i,
    input   data_t          p_data_i,
    input   logic           p_valid_i,
    // IQ未满，可以接收指令
    output  logic           iq_ready_o,

    input   data_t [1:0]    cdb_i,
    output  iq_cdb_t        cdb_o,

    // 唤醒的信号
    input   data_t [1:0]    wkup_data_i,
    output  data_t [1:0]    wkup_data_o,

    output  data_t          result_o,
    output  logic           jump_o     
);


logic [IQ_SIZE - 1:0] empty_q;      // 对应的表项是否空闲
logic [IQ_SIZE - 1:0] ready_q;      // 对应的表项是否可发射
logic [IQ_SIZE - 1:0] select_q;     // 指令是否发射
logic [IQ_SIZE - 1:0] update_q;     // 指令是否填入
logic excute_ready;                 // 是否发射指令：对于单个IQ而言
logic [1:0] excute_valid;           // 指令是否可执行

always_comb begin
    update_q[i] = '0;
    for(genvar  j = 0; j < IQ_SIZE; j += 1) begin
        if(empty_q[i]) begin
            update_q[i] = '0;
            update_q[i][j] = '1;
        end
    end
end

//////////////////////////////////////////////////
// 根据AGING选择指令
localparam int half_IQ_SIZE = IQ_SIZE / 2;
// 对应的aging位
logic [IQ_SIZE - 1:0][$bit(IQ_SIZE) - 1:0] aging_q;
// 目前只处理了IQ为4的情况
logic [half_IQ_SIZE:0][$bit(IQ_SIZE):0] aging_sel_1;
logic [$bit(IQ_SIZE):0]                 aging_sel;

always_comb begin
    aging_sel_1[0] = (aging_q[1] > aging_q[0]) & ready_q[1] ? 1 : 0;
    aging_sel_1[1] = (aging_q[3] > aging_q[2]) & ready_q[3] ? 3 : 2;

    aging_sel = (aging_q[aging_sel_1[0]] > aging_q[aging_sel_1[1]]) & 
                ready_q[aging_sel_1[0]] ? aging_sel_1[0] : aging_sel_1[1];
end

for(genvar i = 0; i < IQ_SIZE; i += 1) begin
    always_comb begin
        select_q[i] = (i == aging_sel) ? '1 : '0;
    end
end

// AGING的移位逻辑
for(genvar i = 0; i < IQ_SIZE; i += 1) begin
    if(select_q[i]) begin
        aging_q[i] <= '0;
    end
    else begin
        aging_q[i] <= (aging_q[i] == half_IQ_SIZE) ? half_IQ_SIZE : (aging_q[i] << 1);
    end
end
//////////////////////////////////////////////////

logic [$bit(IQ_SIZE):0] free_cnt;
logic [$bit(IQ_SIZE):0] free_cnt_q;

always_comb begin
    free_cnt = free_cnt_q - p_valid_i + (excute_ready & excute_valid);
    // 更新输出信号
    iq_ready_o = (free_cnt >= 1);
end

always_ff @(posedge clk) begin
    if(!rst_n || flush) begin
        free_cnt_q <= 4;
    end
    else begin
        free_cnt_q <= free_cnt;
    end
end

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
    assign update_by = update_q[i] & p_valid_i;

    iq_entry # ()(
        .clk,
        .rst_n,
        .flush,

        .sel_i(select_q[i] & excute_ready),
        .update_i(|update_by),
        .data_i(p_data_i),
        .di_i(p_di_i),

        .wkup_data_i(wkup_data_i),
        // 同时连接两个cdb_i
        .cdb_i(cdb_i),

        .ready_o(ready_q),

        .wkup_sel_o(wkup_src),
        .data_o(iq_data),
        .di_o(iq_di)
    );
end

decode_info_t sel_di_q;
decode_info_t sel_di;
data_t sel_data;
logic [1:0] sel_wkup_src;

always_comb begin
    sel_di = '0;
    sel_data = '0;
    sel_wkup_src = '0;
    wkup_valid_o = '0,
    wkup_rid_o = '0;
    // 如果指令发射，选择相应的数据
    for(genvar j = 0; j < IQ_SIZE; j += 1) begin
        if(select_q[j]) begin
            sel_di       |= iq_di;
            sel_data     |= iq_data;
            sel_wkup_src |= wkup_src;
            wkup_valid_o |= excute_ready;
            wkup_rid_o   |= iq_di.wreg_id;
        end
    end
end

assign excute_valid = {|ready_q, (|ready_q)};

always_ff @(posedge clk) begin
    if(excute_ready) begin
        sel_di_q <= sel_di;
    end
end

rob_id_t e_reg_id;
assign e_reg_id = sel_di.wreg_id;

logic e_valid_q;
logic fifo_ready_q;

assign excute_ready = (!e_valid_q) | fifo_ready_q;

always_ff @(clk) begin
    if(!rst_n || flush) begin
        e_valid_q <= '0;
    end
    else begin
        if(excute_ready) begin
            e_valid_q <= e_valid;
        end
        else begin
            if(e_valid_q && fifo_ready_q) begin
                e_valid_q <= '0;
            end
        end
    end
end

logic  e_jump;
logic [31:0] e_jump_result;
word_t e_data;

// 转化后的数据
word_t [1:0] real_data;

e_alu alu(
    .r0_i(real_data[0]),
    .r1_i(real_data[1]),
    .pc_i(sel_di_q.pc),

    .grand_op_i(sel_di_q.di.alu_grand_op),
    .op_i(sel_di_q.di.alu_op),
    .res_o(e_data)
);

e_jump jump(
    .r0_i(real_data[0]),
    .r1_i(real_data[1]),
    .pc_i(sel_di_q.pc),
    .imm_i(sel_di_q.imm),

    .op_i({sel_di_q.di.alu_grand_op, sel_di_q.di.alu_op}),
    .res_o(e_jump_target),
    .jump_o(e_jump)
);

assign jump_o = e_jump;
// TODO：根据控制信号选择ALU还是JUMP结果

endmodule