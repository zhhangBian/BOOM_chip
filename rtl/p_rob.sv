`include "a_defines.svh"

module rob # () (
    // input
    input   logic clk,
    input   logic rst_n,
    input   logic flush_i,
    input   dispatch_rob_pkg_t  dispatch_info_i [1 : 0],
    input   cdb_rob_pkg_t       cdb_info_i [1 : 0],

    // output
    output  rob_dispatch_pkg_t  rob_dispatch_o [1 : 0],
    input   logic               [1 : 0] commit_req, // commit 级根据 rob 的信息判断是否选择指令提交
    output  rob_commit_pkg_t    commit_info_o [1 : 0],
    output  logic              [1 : 0] commit_valid
);

///////////////////////////////////////////////////////////////////////////////////////
// P级行为：
// 1. 分配ROB表项，并将指令控制信息和有效信息写入ROB；
// 2. 从PRF中尝试读出所需数据，例如源操作数，以及是否使用PRF中的数据；
///////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////
// C级行为：
// 1. 根据指令是否有效，决定是否需要将数据写入ROB对应表项中PRF；
// 2. 取出ROB最旧的且有效的表项，并将其中数据写入ARF中，或者将数据由SB写入Cache中；
///////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////
// E级行为：
// 1. 将执行完成的结果以CDB写入ROB对应表项中；
///////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////
// 规格说明： ROB 共 64 项
// 指   针： 两个头指针对应最新的两项，两个尾指针对应最旧的两项，每次选择退休的指令为最旧的指令
// 指令信息： 指令类型(TYPE)、写入的目的寄存器(AREG)、对应PC地址
// 有效信息： 指令是否已经被执行完毕(COMPLETE)
// 数据信息： 指令产生的数据(DATA)
// 控制信息： 指令产生的控制信号(CTRL)
///////////////////////////////////////////////////////////////////////////////////////

/*
指令信息表项： | TYPE(1:0) | AREG(4:0) | PC(31:0) |
有效信息表项： | COMPLETE(0:0) |
数据信息表项： | DATA(31:0) |
控制信息表项： | EXCEPTION | BPU FAIL |
*/

// 头指针 & 尾指针  头为写入新表项， 尾为读出旧表项
logic [`ROB_WIDTH - 1 : 0] tail_ptr0,   tail_ptr1;
reg   [`ROB_WIDTH - 1 : 0] tail_ptr0_q, tail_ptr1_q;
logic [`ROB_WIDTH     : 0] rob_cnt;
logic [             1 : 0] dispatch_valid;
reg   [`ROB_WIDTH     : 0] rob_cnt_q;

// ff
always_ff @(posedge clk) begin
    if (!rst_n || flush_i) begin
        rob_cnt_q   <= '0;
        tail_ptr0_q <= '0;
        tail_ptr1_q <=  1;
    end else begin
        rob_cnt_q   <= rob_cnt;
        tail_ptr0_q <= tail_ptr0;
        tail_ptr1_q <= tail_ptr1;
    end
end

// comb
assign tail_ptr0 = tail_ptr0_q + commit_req[0] + commit_req[1];
assign tail_ptr1 = tail_ptr1_q + commit_req[0] + commit_req[1];
assign dispatch_valid = {dispatch_info_i[1].issue, dispatch_info_i[0].issue};
assign rob_cnt = rob_cnt_q + dispatch_valid[1] + dispatch_valid[0] - commit_req[1] - commit_req[0];



// 指令信息表
// read
rob_inst_entry_t [1 : 0] commit_inst_o;
// write(comb)
rob_inst_entry_t [1 : 0] dispatch_inst_i;
logic [1 : 0][`ROB_WIDTH - 1 : 0] dispatch_preg_i;
logic [1 : 0] dispatch_issue_i;
always_comb begin
    // P级
    for (integer i = 0; i < 2; i++) begin
        dispatch_inst_i[i].areg  = dispatch_info_i[i].areg;
        dispatch_inst_i[i].pc    = dispatch_info_i[i].pc;
        dispatch_inst_i[i].w_reg = dispatch_info_i[i].w_reg;
        dispatch_inst_i[i].w_mem = dispatch_info_i[i].w_mem;
        dispatch_inst_i[i].check = dispatch_info_i[i].check;

        dispatch_inst_i[i].addr_imm = dispatch_info_i[i].addr_imm;

        // 指令类型
        dispatch_inst_i[i].alu_type     = dispatch_info_i[i].alu_type ; 
        dispatch_inst_i[i].mdu_type     = dispatch_info_i[i].mdu_type ;
        dispatch_inst_i[i].lsu_type     = dispatch_info_i[i].lsu_type ;
        dispatch_inst_i[i].flush_inst   = dispatch_info_i[i].flush_inst ;
        dispatch_inst_i[i].jump_inst    = dispatch_info_i[i].jump_inst ; // TODO: 似乎暂时没有用到？
        dispatch_inst_i[i].priv_inst    = dispatch_info_i[i].priv_inst ;
        dispatch_inst_i[i].rdcnt_inst   = dispatch_info_i[i].rdcnt_inst ;
        dispatch_inst_i[i].tlb_inst     = dispatch_info_i[i].tlb_inst;
        // control info, temp, 根据需要自己调整
        dispatch_inst_i[i].predict_info = dispatch_info_i[i].predict_info ;
        dispatch_inst_i[i].if_jump      = dispatch_info_i[i].if_jump ; // 是否跳转 TODO: 什么意思？
        // 特殊指令独热码
        dispatch_inst_i[i].break_inst   = dispatch_info_i[i].break_inst ;
        dispatch_inst_i[i].cacop_inst   = dispatch_info_i[i].cacop_inst ; // lsu iq
        dispatch_inst_i[i].dbar_inst    = dispatch_info_i[i].dbar_inst ;
        dispatch_inst_i[i].ertn_inst    = dispatch_info_i[i].ertn_inst ;
        dispatch_inst_i[i].ibar_inst    = dispatch_info_i[i].ibar_inst ;
        dispatch_inst_i[i].idle_inst    = dispatch_info_i[i].idle_inst ;
        dispatch_inst_i[i].invtlb_inst  = dispatch_info_i[i].invtlb_inst ;
        dispatch_inst_i[i].ll_inst      = dispatch_info_i[i].ll_inst ; // lsu iq
        
        dispatch_inst_i[i].rdcntid_inst = dispatch_info_i[i].rdcntid_inst ;
        dispatch_inst_i[i].rdcntvh_inst = dispatch_info_i[i].rdcntvh_inst ;
        dispatch_inst_i[i].rdcntvl_inst = dispatch_info_i[i].rdcntvl_inst ;
        
        dispatch_inst_i[i].sc_inst      = dispatch_info_i[i].sc_inst ; // lsu iq
        dispatch_inst_i[i].syscall_inst = dispatch_info_i[i].syscall_inst ;
        dispatch_inst_i[i].tlbfill_inst = dispatch_info_i[i].tlbfill_inst ;
        dispatch_inst_i[i].tlbrd_inst   = dispatch_info_i[i].tlbrd_inst ;
        dispatch_inst_i[i].tlbsrch_inst = dispatch_info_i[i].tlbsrch_inst ;
        dispatch_inst_i[i].tlbwr_inst   = dispatch_info_i[i].tlbwr_inst ;

        dispatch_inst_i[i].csr_op_type  = dispatch_info_i[i].csr_op_type ;
        dispatch_inst_i[i].inst_4_0     = dispatch_info_i[i].inst_4_0 ;
        dispatch_inst_i[i].decode_err   = dispatch_info_i[i].decode_err ;
        dispatch_inst_i[i].is_branch    = dispatch_info_i[i].is_branch ;
        dispatch_inst_i[i].br_type      = dispatch_info_i[i].br_type ;

        dispatch_preg_i[i]       = dispatch_info_i[i].preg;
        dispatch_issue_i[i]      = dispatch_info_i[i].issue;
    end
    // C级
    for (integer i = 0; i < 2; i++) begin
        // rename补充check
        commit_info_o[i].check  = commit_inst_o[i].check;
        commit_info_o[i].w_data = commit_data_o[i].data;
        commit_info_o[i].s_data = commit_data_o[i].s_data;
        commit_info_o[i].arf_id = commit_inst_o[i].areg;
        commit_info_o[i].rob_id = commit_inst_o[i].w_preg;
        commit_info_o[i].w_reg  = commit_inst_o[i].w_reg;
        commit_info_o[i].w_mem  = commit_inst_o[i].w_mem;

        commit_info_o[i].c_valid  = commit_inst_o[i].w_valid; // TODO

        commit_info_o[i].pc = commit_inst_o[i].pc;

        commit_info_o[i].data_rk = commit_data_o[i].s_data[0];
        commit_info_o[i].data_rj = commit_data_o[i].s_data[1];
        commit_info_o[i].data_imm = commit_inst_o[i].addr_imm;

        commit_info_o[i].first_commit = '0;
        commit_info_o[i].lsu_info = commit_data_o[i].lsu_info;

        commit_info_o[i].is_ll = commit_inst_o[i].ll_inst;
        commit_info_o[i].is_sc = commit_inst_o[i].sc_inst;
        commit_info_o[i].is_uncached = commit_data_o[i].lsu_info.uncached;
        commit_info_o[i].exc_code = commit_data_o[i].ctrl.exc_info.exc_code;   // 位宽随便定的，之后调整
        commit_info_o[i].is_csr_fix = |commit_info_o[i].csr_op_type;
        commit_info_o[i].csr_type = commit_info_o[i].csr_op_type;
        commit_info_o[i].csr_num = commit_info_o[i].csr_num;
        commit_info_o[i].is_cache_fix = commit_inst_o[i].cacop_inst;
        commit_info_o[i].cache_code = commit_inst_o[i].inst_4_0;
        commit_info_o[i].is_tlb_fix = commit_inst_o[i].tlb_inst;

        commit_info_o[i].flush_inst = commit_inst_o[i].flush_inst;

        commit_info_o[i].fetch_exception = commit_data_o[i].ctrl.exc_info.fetch_exception;/* TODO */;
        commit_info_o[i].syscall_inst = commit_inst_o[i].syscall_inst;
        commit_info_o[i].break_inst = commit_inst_o[i].break_inst;
        commit_info_o[i].decode_err = commit_inst_o[i].decode_err;
        commit_info_o[i].priv_inst = commit_inst_o[i].priv_inst; //要求：不包含hit类cacop
        commit_info_o[i].execute_exception = commit_data_o[i].ctrl.exc_info.execute_exception;// TODO: 访存异常???

        commit_info_o[i].badva      = commit_data_o[i].ctrl.exc_info.badva; // TODO: 访存异常

        commit_info_o[i].rdcnt_en = commit_inst_o[i].rdcnt_inst;
        commit_info_o[i].rdcntvh_en = commit_inst_o[i].rdcntvh_inst;
        commit_info_o[i].rdcntvl_en = commit_inst_o[i].rdcntvl_inst;
        commit_info_o[i].rdcntid_en = commit_inst_o[i].rdcntid_inst;
        commit_info_o[i].ertn_en = commit_inst_o[i].ertn_inst;
        commit_info_o[i].idle_en = commit_inst_o[i].idle_inst;

        commit_info_o[i].tlbsrch_en = commit_inst_o[i].tlbsrch_inst;
        commit_info_o[i].tlbrd_en = commit_inst_o[i].tlbrd_inst;
        commit_info_o[i].tlbwr_en = commit_inst_o[i].tlbwr_inst;
        commit_info_o[i].tlbfill_en = commit_inst_o[i].tlbfill_inst;
        commit_info_o[i].invtlb_en = commit_inst_o[i].invtlb_inst;

        commit_info_o[i].tlb_op = commit_inst_o[i].inst[4:0];

        // 分支预测信息
        commit_info_o[i].is_branch = commit_inst_o[i].is_branch;
        commit_info_o[i].predict_info = commit_inst_o[i].predict_info;
        commit_info_o[i].branch_info.br_type = commit_inst_o[i].br_type;
        commit_info_o[i].branch_info.is_branch = commit_inst_o[i].is_branch;
        commit_info_o[i].branch_info.target = '0; // TODO: branch_info 似乎不需要 target 域

        commit_info_o[i].csr_op_type = commit_inst_o[i].csr_op_type;
        commit_info_o[i].csr_num = commit_inst_o[i].csr_num;
        end
end

// 表体分 bank，写入处理bank conflict
// 这里改用了两读一写的fpga_ram CHANGE
registers_file_banked #(
    .DATA_WIDTH($bits(rob_inst_entry_t)),
    .DEPTH(1 << `ROB_WIDTH),
    .R_PORT_COUNT(2),
    .W_PORT_COUNT(2),
    .REGISTERS_FILE_TYPE(2),
    .NEED_RESET(0)
) rob_inst_table (
    .clk,
    .rst_n(rst_n & !flush_i),
    .raddr_i({tail_ptr1_q, tail_ptr0_q}),
    .rdata_o(commit_inst_o), // 读低位的两个项

    .waddr_i(dispatch_preg_i),
    .we_i(dispatch_issue_i),
    .wdata_i(dispatch_inst_i)
);

// 指令数据表
// read
rob_data_entry_t [1 : 0] commit_data_o;
rob_data_entry_t [1 : 0] dispatch_src1_data_o;
rob_data_entry_t [1 : 0] dispatch_src0_data_o;
// write(comb)
logic [1 : 0][`ROB_WIDTH - 1 : 0] cdb_preg_i;
rob_data_entry_t          [1 : 0] cdb_data_i;
logic [1 : 0]                     cdb_valid_i;

always_comb begin
    // P级
    rob_dispatch_o[1].rob_data = {dispatch_src1_data_o[1].data, dispatch_src1_data_o[0].data};
    rob_dispatch_o[0].rob_data = {dispatch_src0_data_o[1].data, dispatch_src0_data_o[0].data};
    for (integer i = 0; i < 2; i++) begin
        // cdb
        cdb_preg_i[i] = cdb_info_i[i].w_preg;
        cdb_valid_i[i] = cdb_info_i[i].w_valid;

        cdb_data_i[i].w_preg    = cdb_info_i[i].w_preg;
        cdb_data_i[i].data      = cdb_info_i[i].w_data;
        cdb_data_i[i].s_data    = cdb_info_i[i].s_data;
        cdb_data_i[i].w_valid   = cdb_info_i[i].w_valid;
        cdb_data_i[i].ctrl      = cdb_info_i[i].ctrl;
        cdb_data_i[i].lsu_info  = cdb_info_i[i].lsu_info;
        // C级
        commit_info_o[i].w_data = commit_data_o[i].data;
    end
end

// 表体分 bank，写入处理bank conflict
registers_file_banked #(
    .DATA_WIDTH($bits(rob_data_entry_t)),
    .DEPTH(1 << `ROB_WIDTH),
    .R_PORT_COUNT(6),
    .W_PORT_COUNT(2),
    .REGISTERS_FILE_TYPE(2),
    .NEED_RESET(0)
) rob_data_table (
    .clk,
    .rst_n(rst_n & !flush_i),
    .raddr_i({tail_ptr1_q, tail_ptr0_q, dispatch_info_i[1].src_preg, dispatch_info_i[0].src_preg}),
    .rdata_o({commit_data_o[1], commit_data_o[0], dispatch_src1_data_o, dispatch_src0_data_o}),

    .waddr_i(cdb_preg_i),
    .we_i(cdb_valid_i),
    .wdata_i(cdb_data_i)
);

// TODO complete 状态表，两张表比对实现
logic [1 : 0]           commit_complete_p_o;
logic [1 : 0][1 : 0]    rob_dispatch_complete_p_o;
logic [1 : 0]           dispatch_in_complete_o; // 写的两项对应的结果

logic [1 : 0]           commit_complete_cdb_o;
logic [1 : 0][1 : 0]    rob_dispatch_complete_cdb_o;
logic [1 : 0]           cdb_in_complete_o;      // 写的两项对应的结果

always_comb begin
    for (integer i = 0 ; i < 2; i++) begin
        rob_dispatch_o[i].rob_complete = (rob_dispatch_complete_p_o[i] ^ rob_dispatch_complete_cdb_o[i]); //debug
    end
    commit_info_o[0].c_valid = (commit_complete_p_o[0] ^ commit_complete_cdb_o[0]) & (rob_cnt_q > 0);
    commit_info_o[1].c_valid = (commit_complete_p_o[1] ^ commit_complete_cdb_o[1]) & (rob_cnt_q > 1);
    commit_valid[0] = commit_info_o[0].c_valid;
    commit_valid[1] = commit_info_o[1].c_valid;
end

// P级写
registers_file_banked # (
    .DATA_WIDTH($bits(rob_valid_entry_t)),
    .DEPTH(1 << `ROB_WIDTH),
    .R_PORT_COUNT(8),
    .W_PORT_COUNT(2),
    .REGISTERS_FILE_TYPE(2),
    .NEED_RESET(0)
) dispatch_valid_table (
    .clk,
    .rst_n(rst_n & !flush_i),
    .raddr_i({cdb_preg_i, tail_ptr1_q, tail_ptr0_q, dispatch_info_i[1].src_preg, dispatch_info_i[0].src_preg}),
    .rdata_o({cdb_in_complete_o, commit_complete_p_o, rob_dispatch_complete_p_o}),

    .waddr_i(dispatch_preg_i),
    .we_i(dispatch_issue_i),
    // 将相应位置反
    .wdata_i(dispatch_in_complete_o)
);

// CDB级写
registers_file_banked # (
    .DATA_WIDTH($bits(rob_valid_entry_t)),
    .DEPTH(1 << `ROB_WIDTH),
    .R_PORT_COUNT(8),
    .W_PORT_COUNT(2),
    .REGISTERS_FILE_TYPE(2),
    .NEED_RESET(0)
) cdb_valid_table (
    .clk,
    .rst_n(rst_n & !flush_i),
    .raddr_i({dispatch_preg_i, tail_ptr1_q, tail_ptr0_q, dispatch_info_i[1].src_preg, dispatch_info_i[0].src_preg}),
    .rdata_o({dispatch_in_complete_o, commit_complete_cdb_o, rob_dispatch_complete_cdb_o}),

    .waddr_i(cdb_preg_i),
    .we_i(cdb_valid_i),
    .wdata_i(~cdb_in_complete_o)
);


endmodule
