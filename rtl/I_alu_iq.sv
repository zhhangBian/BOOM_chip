`include "a_structure.svh"
`include "a_entry_defines.svh"

module alu_iq # (
    // 设置IQ共有4个表项
    parameter int IQ_SIZE = 4,
    parameter int AGING_LENGTH = 4,
    parameter int IQ_ID = 0,
    parameter int DISPATCH_CNT = 2;
    parameter int REG_COUNT  = 2,
    parameter int CDB_COUNT  = 2,
    parameter int WKUP_COUNT = 2
)(
    input   logic           clk,
    input   logic           rst_n,
    input   logic           flush,

    // 控制信息
    input   logic [DISPATCH_CNT - 1:0]      choose,
    input   decode_info_t [REG_COUNT - 1:0] p_di_c,
    input   word_t [REG_COUNT - 1:0]        p_data_c,
    input   rob_id_t [REG_COUNT - 1:0]      p_reg_id_c,
    input   logic [REG_COUNT - 1:0]         p_valid_c,
    // IQ的ready含义是队列未满，可以继续接收指令
    output  logic           entry_ready_o,

    // CDB数据前递
    input   word_t  [CDB_COUNT - 1:0] cdb_data_i,
    input   rob_id_t[CDB_COUNT - 1:0] cdb_reg_id_i,
    input   logic   [CDB_COUNT - 1:0] cdb_valid_i,

    input   word_t  [WKUP_COUNT - 1:0] wkup_data_i,
    input   rob_id_t[WKUP_COUNT - 1:0] wkup_reg_id_i,
    input   logic   [WKUP_COUNT - 1:0] wkup_valid_i,
    
    output  word_t          wkup_data_o,
    output  rob_id_t        wkup_reg_id_o,
    output  logic           wkup_valid_o,
    // 区分了wkup和输入到后续FIFO的数据
    output  word_t          result_o,

    // 后续的FIFO是否ready
    input   logic           fifo_ready
);

decode_info_t   p_di_i;
word_t          p_data_i;
rob_id_t        p_reg_id_i;
logic           p_valid_i;

always_comb begin
    p_di_i      = '0;
    p_data_i    = '0;
    p_reg_id_i  = '0;
    p_valid_i   = '0;

    for(genvar i = 0; i < DISPATCH_CNT; i += 1) begin
        if(choose[i]) begin
            p_di_i      |= p_di_c[i];
            p_data_i    |= p_data_c[i];
            p_reg_id_i  != p_reg_id_c[i];
            p_valid_i   |= p_valid_c[i];
        end
    end
end

logic excute_ready;                 // 是否发射指令：对于单个IQ而言
logic [IQ_SIZE - 1:0] entry_ready;  // 对应的表项是否可发射
logic [IQ_SIZE - 1:0] entry_select; // 指令是否发射
logic [IQ_SIZE - 1:0] entry_init;   // 是否填入表项
logic [IQ_SIZE - 1:0] entry_empty_q;// 对应的表项是否空闲

// ------------------------------------------------------------------
// 选择发射的指令
// 根据AGING选择指令
localparam int half_IQ_SIZE = IQ_SIZE / 2;
// 对应的aging位
logic [IQ_SIZE - 1:0][AGING_LENGTH - 1:0]   aging_q;
// 目前只处理了IQ为4的情况
logic [half_IQ_SIZE:0][$bits(IQ_SIZE):0]    aging_select_1;
// 选择出发射的指令：一定ready
logic [$bits(IQ_SIZE):0]                    aging_select;

always_comb begin
    aging_select_1[0] = ({entry_ready[1], aging_q[1]} > {entry_ready[1], aging_q[0]}) ? 1 : 0;
    aging_select_1[1] = ({entry_ready[3], aging_q[3]} > {entry_ready[2], aging_q[2]}) ? 3 : 2;
    // 根据aging选出发射的指令
    aging_select = ({entry_ready[aging_select_1[0]], aging_q[aging_select_1[0]]} >
                    {entry_ready[aging_select_1[1]], aging_q[aging_select_1[1]]}) ?
                    aging_select_1[0] : aging_select_1[1];
    // 给发射的指令置位
    entry_select = '0;
    entry_select[aging_select] |= '1;
end

// AGING的移位逻辑
always_ff @(posedge clk) begin
    for(integer i = 0; i < IQ_SIZE; i += 1) begin
        if(entry_select[i]) begin
            aging_q[i] <= '0;
        end
        else begin
            if(entry_ready[i]) begin
                aging_q[i] <= (aging_q[i] == 0) ? 1 :
                              (aging_q[i] == (1 << (AGING_LENGTH - 1))) ? 
                              aging_q[i] : (aging_q[i] << 1);
            end
            else begin
                aging_q[i] <= '0;
            end
        end
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 更新entry_ready信号
logic [$bits(IQ_SIZE):0] free_cnt;
logic [$bits(IQ_SIZE):0] free_cnt_q;

always_comb begin
    free_cnt = free_cnt_q - p_valid_i + excute_ready;
    entry_ready_o = (free_cnt >= 1);
end

always_ff @(posedge clk) begin
    if(!rst_n || flush) begin
        free_cnt_q <= 4;
    end
    else begin
        free_cnt_q <= free_cnt;
    end
end

always_comb begin
    entry_init[i] = '0;
    for(genvar  i = 0; i < IQ_SIZE; i += 1) begin
        if(entry_empty_q[i]) begin
            entry_init[i] = 1;
            break;
        end
    end
end

always_ff @(posedge clk) begin
    if(!rst_n || flush) begin
        entry_empty_q <= '1;
    end
    else begin
        for(integer i = 0; i < IQ_SIZE; i += 1) begin
            if(entry_select[i]) begin
                entry_empty_q[i] <= 1;
            end
            else if(entry_init[i] & p_valid_i) begin
                entry_empty_q[i] <= 0;
            end
        end
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 生成执行信号
assign excute_ready = fifo_entry_ready;
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 创建IQ表项

// 转发后的数据
word_t  [REG_COUNT - 1:0]       real_data;
word_t  [IQ_SIZE - 1:0][1:0]    entry_data;
decode_info_t [IQ_SIZE - 1:0]   entry_di;
logic   [IQ_SIZE - 1:0][REG_COUNT - 1:0][WKUP_COUNT - 1:0] wkup_hit_q;

for(genvar i = 0; i < IQ_SIZE; i += 1) begin
    iq_entry # (
        .REG_COUNT(REG_COUNT),
        .CDB_COUNT(CDB_COUNT),
        .WKUP_COUNT(WKUP_COUNT)
    ) iq_entry(
        .clk,
        .rst_n,
        .flush,

        .select_i(entry_select[i] & excute_ready),
        .init_i(entry_init[i] & p_valid_i),

        .data_i(p_data_i),
        .data_reg_id_i(p_reg_id_i),
        .data_valid_i(p_valid_i),
        .di_i(p_di_i),

        .wkup_data_i(wkup_data_i),
        .wkup_reg_id_i(wkup_reg_id_i),
        .wkup_valid_i(wkup_valid_i),

        .cdb_data_i(cdb_data_i),
        .cdb_reg_id_i(cdb_reg_id_i),
        .cdb_valid_i(cdb_valid_i),

        .ready_o(entry_ready[i]),

        .wkup_hit_q_o(wkup_hit_q[i]),
        .data_o(entry_data[i]),
        .di_o(entry_di[i])
    );
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 填入发射指令所需的执行信息：下一个周期填入执行单元
decode_info_t   select_di, select_di_q;
word_t [REG_COUNT - 1:0] select_data;
logic [REG_COUNT - 1:0][WKUP_COUNT - 1:0] select_wkup_hit_q;

logic            wkup_valid_o;
rob_id_t         wkup_reg_id;

always_comb begin
    select_di           = '0;
    select_data         = '0;
    select_wkup_hit_q   = '0;
    // 选中了提前唤醒
    wkup_valid_o        = '0,
    wkup_reg_id         = '0;

    for(genvar i = 0; i < IQ_SIZE; i += 1) begin
        // 如果发射对应指令
        if(entry_select[i]) begin
            select_di       |= entry_di[i];
            select_data     |= entry_data[i];
            select_wkup_hit_q |= wkup_hit_q[i];
            // 选中了提前唤醒
            wkup_valid_o    |= excute_ready;
            wkup_reg_id_o   |= entry_di[i].wreg_id;
        end
    end
end

always_ff @(posedge clk) begin
    if(excute_ready) begin
        select_di_q <= select_di;
    end
end

// 用于统一在 IQ发射时等待唤醒的数据一拍
// 不唤醒则等一拍
data_wkup #(
    .REG_COUNT(REG_COUNT),
    .WKUP_COUNT(WKUP_COUNT)
) data_wkup (
    .clk,
    .rst_n,
    .flush

    .ready_i(excute_ready),
    .wkup_hit_q_i(select_wkup_hit_q),
    .data_i(select_data),
    .wkup_data_i(wkup_data_i),
    .real_data_o(real_data)
);
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 创建IQ相联的部件
word_t e_result;
word_t e_alu_result, e_alu_result_q;
logic  e_jump_o;
word_t e_jump_result;

e_alu alu(
    .r0_i(real_data[0]),
    .r1_i(real_data[1]),
    .pc_i(select_di_q.pc),

    .grand_op_i(select_di_q.grand_op),
    .op_i(select_di_q.op),
    .res_o(e_alu_result)
);

e_jump jump(
    .r0_i(real_data[0]),
    .r1_i(real_data[1]),
    .pc_i(select_di_q.pc),
    .imm_i(select_di_q.imm),

    .op_i({select_di_q.grand_op, select_di_q.op}),
    .res_o(e_jump_target),
    .jump_o(e_jump_o)
);

assign jump_o   = e_jump_o;
assign result_o = jump_o ? e_jump_result : e_alu_result;

// 配置wkup的输出信息
always_ff @(posedge clk) begin
    e_alu_result_q <= e_alu_result;
end
assign wkup_data_o = e_alu_result_q;
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

endmodule