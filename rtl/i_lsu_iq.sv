`include "a_structure.svh"
`include "a_iq_defines.svh"

module lsu_iq # (
    // 设置IQ共有4个表项
    parameter int IQ_SIZE = 4,
    parameter int PTR_LEN = $clog2(IQ_SIZE),
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
    input   logic [DISPATCH_CNT - 1:0]          choose,
    input   decode_info_t [DISPATCH_CNT - 1:0]  p_di_i,
    input   word_t [DISPATCH_CNT - 1:0]         p_data_i,
    input   rob_id_t [DISPATCH_CNT - 1:0]       p_reg_id_i,
    input   logic [DISPATCH_CNT - 1:0]          p_valid_i,
    // IQ的ready含义是队列未满，可以继续接收指令
    output  logic                               entry_ready_o,

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

logic excute_ready;                 // 是否发射指令：对于单个IQ而言
logic excute_valid, excute_valid_q; // 执行结果是否有效
logic [IQ_SIZE - 1:0] entry_ready;  // 对应的表项是否可发射
logic [IQ_SIZE - 1:0] entry_select; // 指令是否发射
logic [IQ_SIZE - 1:0] entry_init;   // 是否填入表项
logic [IQ_SIZE - 1:0][PTR_LEN - 1:0] entry_init_id;// 填入选择的数据项在输入数据的id
logic [IQ_SIZE - 1:0] entry_empty_q;// 对应的表项是否空闲

// ------------------------------------------------------------------
// 配置IQ逻辑
// 当前的表项数
logic [PTR_LEN - 1:0]   iq_cnt, iq_cnt_q
// 写的指针
logic [PTR_LEN - 1:0]   iq_head, iq_head_q;
// 执行的指针
logic [PTR_LEN - 1:0]   iq_tail, iq_tail_q;

always_ff @(posedge clk) begin
    if(!rst_n || flush_i) begin
        iq_head_q       <= '0;
        iq_tail_q       <= '0;
        iq_cnt_q        <= '0;
        entry_ready_o   <= '1;
    end 
    else begin
        iq_head_q       <= iq_head;
        iq_tail_q       <= iq_tail;
        iq_cnt_q        <= iq_cnt;
        // 有可能同时接收两条指令
        entry_ready_o   <= (iq_cnt <= (IQ_SIZE - DISPATCH_CNT));
    end
end

always_comb begin
    iq_head = iq_head_q;
    for(genvar i = 0; i < DISPATCH_CNT; i += 1) begin
        if(entry_ready_o) begin
            iq_head += p_valid_i[i];
        end
    end
end

always_comb begin
    iq_tail = iq_tail_q;
    // 只能一条条发射
    if(excute_ready & excute_valid) begin
        iq_tail += 1;
    end
end

always_comb begin
    iq_cnt = iq_cnt_q;
    for(genvar i = 0; i < DISPATCH_CNT; i += 1) begin
        iq_cnt += p_valid_i[i];
    end

    if(excute_ready & excute_valid) begin
        iq_cnt -= 1;
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
always_comb begin
    entry_select = '0;
    for(genvar i = 0; i < IQ_SIZE; i += 1) begin
        if(i[PTR_LEN - 1:0] == iq_tail) begin
            entry_select[i] |= entry_ready[i];
        end
    end
end

logic [PTR_LEN - 1:0] valid_cnt;
logic [DISPATCH_CNT - 1:0][PTR_LEN - 1:0] valid_id; // 输入数据有效项的编号
always_comb begin
    valid_cnt = '0;
    valid_id = '0;
    for(genvar i = 0; i < DISPATCH_CNT; i += 1) begin
        if(p_valid_i[i]) begin
            valid_id[valid_cnt] |= i;
            valid_cnt += 1;
        end
    end
end

always_comb begin
    entry_init = '0;
    entry_init_id = '0;
    for(i = 0; i < valid_cnt; i += 1) begin
        entry_init[iq_head_q + i] |= '1;
        entry_init_id[iq_head_q + i] |= i;
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
assign excute_ready = (!excute_valid_q) || fifo_ready;
assign excute_valid = |entry_ready;

always_ff @(posedge clk) begin
    if(!rst_n || flush) begin
        excute_valid_q <= '0;
    end
    else begin
        if(excute_ready) begin
            excute_valid_q <= excute_valid;
        end
        else begin
            // 上一周期结果有效且FIFO可以接收
            if(excute_valid_q && fifo_ready) begin
                excute_valid_q <= '0;
            end
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

        .data_i(p_data_i[valid_id[entry_init_id[i]]]),
        .data_reg_id_i(p_reg_id_i[valid_id[entry_init_id[i]]]),
        .data_valid_i(p_valid_i[valid_id[entry_init_id[i]]]),
        .di_i(p_di_i[valid_id[entry_init_id[i]]]),

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

// 匹配给DCache的接口即可

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

endmodule