`include "a_defines.svh"

module lsu_iq # (
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

    // 写Cache的握手数据
    output  logic           iq_lsu_valid_o,
    input   logic           iq_lsu_ready_i,
    output  iq_lsu_pkg_t    iq_lsu_req_o,

    // 读Cache的握手信息
    input   logic           lsu_iq_valid_i,
    output  logic           lsu_iq_ready_o,
    input   lsu_iq_pkg_t    lsu_iq_resp_i,

    // 读LSU的读出的数据
    output  cdb_info_t      result_o,
    // 与后续FIFO的握手信号
    input   logic           fifo_ready,
    output  logic           entry_valid_o
);

logic excute_ready;                 // 是否发射指令：对于单个IQ而言
logic excute_valid, excute_valid_q; // 执行结果是否有效
logic [IQ_SIZE - 1:0] entry_ready;  // 对应的表项是否可发射
logic [IQ_SIZE - 1:0] entry_select; // 指令是否发射
logic [IQ_SIZE - 1:0] entry_init;   // 是否填入表项

// ------------------------------------------------------------------
// 配置IQ逻辑
// 当前的表项数
logic [PTR_LEN    :0]   free_cnt, free_cnt_q;
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
word_t   [IQ_SIZE - 1:0][REG_COUNT - 1:0] iq_data;
rob_id_t [IQ_SIZE - 1:0][REG_COUNT - 1:0] iq_reg_id;
logic    [IQ_SIZE - 1:0][REG_COUNT - 1:0] iq_valid;
decode_info_t           [IQ_SIZE - 1:0]   iq_di;

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

always_comb begin
    iq_data     = '0;
    iq_reg_id   = '0;
    iq_valid    = '0;
    iq_di       = '0;

    if(^choose) begin
        iq_data   [iq_tail_q]        |= choose[0] ? p_data_i[0]   : p_data_i[1];
        iq_reg_id [iq_tail_q]        |= choose[0] ? p_reg_id_i[0] : p_reg_id_i[1];
        iq_valid  [iq_tail_q]        |= choose[0] ? p_valid_i[0]  : p_valid_i[1];
        iq_di     [iq_tail_q]        |= choose[0] ? p_di_i[0]     : p_di_i[1];
    end
    else if(&choose) begin
        iq_data   [iq_tail_q]        |= p_data_i[0] ;
        iq_reg_id [iq_tail_q]        |= p_reg_id_i[0];
        iq_valid  [iq_tail_q]        |= p_valid_i[0];
        iq_di     [iq_tail_q]        |= p_di_i[0];

        iq_data   [iq_tail_q + 1]    |= p_data_i[1] ;
        iq_reg_id [iq_tail_q + 1]    |= p_reg_id_i[1];
        iq_valid  [iq_tail_q + 1]    |= p_valid_i[1];
        iq_di     [iq_tail_q + 1]    |= p_di_i[1];
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 生成执行信号
assign excute_ready = (!excute_valid_q) || iq_lsu_ready_i;
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
decode_info_t   select_di, select_di_q, select_di_qq;
word_t [REG_COUNT - 1:0] select_data;
logic [REG_COUNT - 1:0][WKUP_COUNT - 1:0] select_wkup_hit_q;

always_comb begin
    select_di           = '0;
    select_data         = '0;
    select_wkup_hit_q   = '0;

    for(integer i = 0; i < IQ_SIZE; i += 1) begin
        // 如果发射对应指令
        if(entry_select[i]) begin
            select_di       |= entry_di[i];
            select_data     |= entry_data[i];
            select_wkup_hit_q |= wkup_hit_q[i];
        end
    end
end

word_t [1:0] real_data_q;

always_ff @(posedge clk) begin
    if (!rst_n | flush) begin
        select_di_q  <= '0;
        select_di_qq <= '0;
        real_data_q  <= '0;
    end
    else if(excute_ready) begin
        select_di_q  <= select_di;
        select_di_qq <= select_di_q;
        real_data_q  <= real_data;
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
// 匹配给DCache的接口
iq_lsu_pkg_t    iq_lsu_request;
assign iq_lsu_req_o     = iq_lsu_request;
assign iq_lsu_valid_o   = excute_valid_q;
assign lsu_iq_ready_o   = fifo_ready;
assign entry_valid_o    = lsu_iq_valid_i;

// 配置iq到lsu的信息
always_comb begin
    iq_lsu_request          = '0;
    iq_lsu_request.wid      = select_di_q.wreg_id;
    iq_lsu_request.msigned  = select_di_q.msigned;
    iq_lsu_request.msize    = select_di_q.msize;
    // 约定0号为数据，1号为地址
    iq_lsu_request.vaddr    = real_data[1] + select_di_q.imm;
    iq_lsu_request.wdata    = real_data[0];
    iq_lsu_request.rmask    = select_di_q.wmem ? '0 :
                              (select_di_q.msize == 0) ? (1'b1 << iq_lsu_request.vaddr[1:0]) :
                              (select_di_q.msize == 1) ? (2'b11 << iq_lsu_request.vaddr[1]) :
                              4'b1111;
    iq_lsu_request.strb     = ~select_di_q.wmem ? '0 :
                              (select_di_q.msize == 0) ? (1'b1 << iq_lsu_request.vaddr[1:0]) :
                              (select_di_q.msize == 1) ? (2'b11 << iq_lsu_request.vaddr[1]) :
                              4'b1111;
end

// 配置lsu到iq的信息，向FIFO输出
always_comb begin
    result_o.w_data   = lsu_iq_resp_i.rdata;
    result_o.s_data   = real_data_q;
    result_o.rob_id   = select_di_qq.wreg_id;
    result_o.w_reg    = select_di_qq.wreg;
    result_o.r_valid  = select_di_qq.inst_valid;
    result_o.lsu_info = lsu_iq_resp_i;
    result_o.ctrl.exc_info.fetch_exception      =  select_di_qq.fetch_exc_info.fetch_exception;
    result_o.ctrl.exc_info.execute_exception    =  lsu_iq_resp_i.execute_exc_info.execute_exception;
    result_o.ctrl.exc_info.exc_code             =  result_o.ctrl.exc_info.fetch_exception ? select_di_qq.fetch_exc_info.exc_code : lsu_iq_resp_i.execute_exc_info.exc_code;
    result_o.ctrl.exc_info.badva                =  result_o.ctrl.exc_info.fetch_exception ? select_di_qq.fetch_exc_info.badv     : lsu_iq_resp_i.execute_exc_info.badv    ;
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

endmodule
