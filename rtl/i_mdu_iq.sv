`include "a_defines.svh"

module mdu_iq # (
    // 设置IQ共有4个表项
    parameter int IQ_SIZE = 8,
    parameter int PTR_LEN = $clog2(IQ_SIZE),
    parameter int IQ_ID = 0,
    parameter int REG_COUNT  = 2,
    parameter int CDB_COUNT  = 2,
    parameter int WKUP_COUNT = 2
)(
    input   logic           clk,
    input   logic           rst_n,
    input   logic           flush,

    // 控制信息
    input   logic           other_ready,
    input   logic   [1:0]   choose,
    input   decode_info_t   [1:0] p_di_i,
    input   word_t  [1:0][REG_COUNT - 1:0]  p_data_i,
    input   rob_id_t[1:0][REG_COUNT - 1:0]  p_reg_id_i,
    input   logic   [1:0][REG_COUNT - 1:0]  p_valid_i,
    // IQ的ready含义是队列未满，可以继续接收指令
    output  logic           entry_ready_o,

    // CDB数据前递
    input   word_t  [CDB_COUNT - 1:0]   cdb_data_i,
    input   rob_id_t[CDB_COUNT - 1:0]   cdb_reg_id_i,
    input   logic   [CDB_COUNT - 1:0]   cdb_valid_i,

    input   word_t  [WKUP_COUNT - 1:0]  wkup_data_i,
    input   rob_id_t[WKUP_COUNT - 1:0]  wkup_reg_id_i,
    input   logic   [WKUP_COUNT - 1:0]  wkup_valid_i,

    // 区分了wkup和输入到后续FIFO的数据
    output  cdb_info_t      result_o,
    output  decode_info_t   di_o,
    // 后续的FIFO是否ready
    input   logic           fifo_ready,
    output  logic           entry_valid_o
);

logic excute_ready;                 // 是否发射指令：对于单个IQ而言
logic excute_valid, excute_valid_q; // 执行结果是否有效
logic [IQ_SIZE - 1:0] entry_ready;  // 对应的表项是否可发射
logic [IQ_SIZE - 1:0] entry_select; // 指令是否发射
logic [IQ_SIZE - 1:0] entry_init;   // 是否填入表项
logic [IQ_SIZE - 1:0] entry_empty_q;// 对应的表项是否空闲

// ------------------------------------------------------------------
// 配置IQ逻辑
// 当前的表项数
logic [PTR_LEN - 1:0]   free_cnt, free_cnt_q;
// 执行的指针
logic [PTR_LEN - 1:0]   iq_head, iq_head_q;
// 写的指针
logic [PTR_LEN - 1:0]   iq_tail, iq_tail_q;

always_ff @(posedge clk) begin
    if(!rst_n || flush) begin
        iq_head_q       <= '0;
        iq_tail_q       <= '0;
        free_cnt_q      <= IQ_SIZE;
        entry_ready_o   <= '1;
    end 
    else begin
        iq_head_q       <= iq_head;
        iq_tail_q       <= iq_tail;
        free_cnt_q      <= free_cnt;
        // 有可能同时接收两条指令
        entry_ready_o   <= (free_cnt >= 2);
    end
end

// 执行的指令
always_comb begin
    iq_head = iq_head_q;
    // 只能一条条发射
    if(excute_ready & excute_valid) begin
        iq_head = iq_head_q + 1;
    end
end

// 进入的指令
always_comb begin
    iq_tail = iq_tail_q;
    // 上一拍允许这一拍进入
    if(entry_ready_o) begin
        iq_tail = iq_tail_q + choose[0] + choose[1];
    end
end

// 存在IQ中的指令数
always_comb begin
    free_cnt = free_cnt_q - (choose[0] + choose[1]) + (excute_ready & excute_valid);
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 选择进入IQ的数据
word_t   [IQ_SIZE - 1:0]    iq_data;
rob_id_t [IQ_SIZE - 1:0]    iq_reg_id;
logic    [IQ_SIZE - 1:0]    iq_valid;
decode_info_t [IQ_SIZE - 1:0] iq_di;

always_comb begin
    entry_select = '0;
    for(integer i = 0; i < IQ_SIZE; i += 1) begin
        if(i[PTR_LEN - 1:0] == iq_head_q) begin
            entry_select[i] |= entry_ready[i];
        end
    end
end

always_comb begin
    entry_init = '0;
    if(^choose) begin
        entry_init[iq_tail_q]     |= other_ready;
    end
    else if(&choose) begin
        entry_init[iq_tail_q]     |= other_ready;
        entry_init[iq_tail_q + 1] |= other_ready;
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
            else if(entry_init[i]) begin
                entry_empty_q[i] <= 0;
            end
        end
    end
end

always_comb begin
    iq_data     = '0;
    iq_reg_id   = '0;
    iq_valid    = '0;
    iq_di       = '0;

    if(^choose) begin
        iq_data[iq_tail_q]      |= choose[0] ? p_data_i[0] : p_data_i[1];
        iq_reg_id[iq_tail_q]    |= choose[0] ? p_reg_id_i[0] : p_reg_id_i[1];
        iq_valid[iq_tail_q]     |= choose[0] ? p_valid_i[0] : p_valid_i[1];
        iq_di[iq_tail_q]        |= choose[0] ? p_di_i[0] : p_di_i[1];
    end
    else if(&choose) begin
        iq_data[iq_tail_q]      |= p_data_i[0] ;
        iq_reg_id[iq_tail_q]    |= p_reg_id_i[0];
        iq_valid[iq_tail_q]     |= p_valid_i[0];
        iq_di[iq_tail_q]        |= p_di_i[0];

        iq_data[iq_tail_q + 1]  |= p_data_i[1] ;
        iq_reg_id[iq_tail_q + 1]|= p_reg_id_i[1];
        iq_valid[iq_tail_q + 1] |= p_valid_i[1];
        iq_di[iq_tail_q + 1]    |= p_di_i[1];
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 生成执行信号
assign excute_ready = (!excute_valid_q) || mdu_ready_i;
assign excute_valid = |entry_ready;

always_ff @(posedge clk) begin
    if(!rst_n || flush) begin
        excute_valid_q <= '0;
    end
    else begin
        if(excute_ready) begin
            excute_valid_q <= excute_valid;
        end
    end
end
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
        .init_i(entry_init[i]),

        .data_i(iq_data[i]),
        .data_reg_id_i(iq_reg_id[i]),
        .data_valid_i(iq_valid[i]),
        .di_i(iq_di[i]),

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
    wkup_valid_o        = '0;
    wkup_reg_id         = '0;

    for(integer i = 0; i < IQ_SIZE; i += 1) begin
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
    .flush,

    .ready_i(excute_ready),
    .wkup_hit_q_i(select_wkup_hit_q),
    .data_i(select_data),
    .wkup_data_i(wkup_data_i),
    .real_data_o(real_data)
);
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 创建IQ相联的部件
mud_i_t req_i;
mdu_o_t res_o;
word_t [1:0] data_s;

logic   mdu_valid_i, mdu_ready_o;
logic   mdu_valid_o, mdu_ready_i;

assign mdu_valid_i  = excute_valid_q;
assign entry_valid_o= mdu_valid_o;
assign mdu_ready_i  = fifo_ready;

always_comb begin
    req_i.data      = select_data_q;
    req_i.op        = op;
    req_i.reg_id    = wkup_reg_id;

    result_o.w_data   = res_o.data;
    result_o.rob_id   = res_o.reg_id;
    result_o.w_reg    = di_o.wreg;
    result_o.r_valid  = di_o.inst_valid;
    result_o.lsu_info = '0;
    result_o.ctrl.exc_info.fetch_exception      =  di_o.fetch_exc_info.fetch_exception;
    result_o.ctrl.exc_info.execute_exception    =  '0;
    result_o.ctrl.exc_info.exc_code             =  di_o.fetch_exc_info.exc_code;
    result_o.ctrl.exc_info.badva                =  di_o.fetch_exc_info.badv;
end

mdu mdu_inst (
    .clk,
    .rst_n,
    .flush,

    .req_i(req_i),
    .di_i(select_data_q),
    .res_o(res_o),
    .di_o(di_o),
    .data_s_o(data_s),

    .valid_i(mdu_valid_i),
    .ready_o(mdu_ready_o),
    .valid_o(mdu_valid_o),
    .ready_i(mdu_ready_i),
);
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

endmodule
