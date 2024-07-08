`include "a_defines.svh"

// TEMP!!! 结构体定义：后面放入头文件中
typedef struct packed {
    // static info
    logic [1              : 0]                     inst_type;
    logic [`ARF_WIDTH - 1 : 0]                     areg;  // 目的寄存器
    logic [`ROB_WIDTH - 1 : 0]                     preg;  // 物理寄存器 
    logic [1              : 0][`ROB_WIDTH - 1 : 0] src_preg;  // 源寄存器对应的物理寄存器
    logic [31             : 0]                     pc;    // 指令地址
    logic                                          issue; // 是否被分配到ROB
    logic                                          w_reg;
    logic                                          w_mem;
    logic                                          tier_id;
} dispatch_rob_pkg_t;

typedef struct packed {
    logic [31: 0] w_data;
    logic [4 : 0] w_areg;
    logic         w_reg;
    logic         w_mem;
    logic         c_ready;
} commit_rob_pkg_t;

typedef struct packed {
    logic [`ROB_WIDTH - 1 : 0] w_preg;
    logic [31             : 0] w_data;
    logic                      w_valid;
    rob_ctrl_entry_t           ctrl;
} cdb_rob_pkg_t;

typedef struct pack {
    logic [1 : 0][31 : 0] rob_data; 
    logic [1 : 0]         rob_complete;
} rob_dispatch_pkg_t;

module rob #(
) (
    // input
    input   clk,
    input   rst_n,
    input   dispatch_rob_pkg_t [1 : 0] dispatch_info_i,
    input   cdb_rob_pkg_t      [1 : 0] cdb_info_i     ,

    // output
    output  rob_dispatch_pkg_t [1 : 0] rob_dispatch_o,
    output  commit_rob_pkg_t   [1 : 0] commit_info_o  ,
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
logic [`ROB_WIDTH - 1 : 0] head_ptr0,   head_ptr1,   tail_ptr0,   tail_ptr1;
reg   [`ROB_WIDTH - 1 : 0] head_ptr0_q, head_ptr1_q, tail_ptr0_q, tail_ptr1_q;

// ff
always_ff @(posedge clk) begin
    if (!rst_n || flush_i) begin
        head_ptr0_q <= '0;
        head_ptr1_q <= '1;
        tail_ptr0_q <= '0;
        tail_ptr1_q <= '1;
    end else begin
        head_ptr0_q <= head_ptr0;
        head_ptr1_q <= head_ptr1;
        tail_ptr0_q <= tail_ptr0;
        tail_ptr1_q <= tail_ptr1;
    end
end
// comb
assign head_ptr0 = head_ptr0_q + dispatch_info_i[0].issue + dispatch_info_i[1].issue;
assign head_ptr1 = head_ptr1_q + dispatch_info_i[0].issue + dispatch_info_i[1].issue;
assign tail_ptr0 = tail_ptr0_q + commit_info_o[0].c_ready + commit_info_o[1].c_ready;
assign tail_ptr1 = tail_ptr1_q + commit_info_o[0].c_ready + commit_info_o[1].c_ready;

// 指令信息表项
typedef struct packed {
    logic [1 : 0] inst_type;
    logic [4 : 0] areg;
    logic [31: 0] pc;
    logic         w_reg;
    logic         w_mem;
    logic         tier_id;
} rob_inst_entry_t;

// 有效信息表项
typedef struct packed {
    logic complete;
} rob_valid_entry_t;

// 数据信息表项
typedef struct packed {
    logic [31: 0] data;
    rob_ctrl_entry_t ctrl;
} rob_data_entry_t;

// 控制信息表项
typedef struct packed {
    // 异常控制信号流，其他控制信号流，后续补充
    logic exception;
    logic bpu_fail;
} rob_ctrl_entry_t;



// 指令信息表
// read
rob_inst_entry_t [1 : 0] commit_inst_o;
// write(comb)
rob_inst_entry_t [1 : 0] dispatch_inst_i;
logic [1 : 0][`ROB_WIDTH - 1 : 0] dispatch_preg_i;
logic [1 : 0] dispatch_issue_i;
always_comb begin
    // P级
    for (genvar i = 0; i < 2; i++) begin
        dispatch_inst_i[i].inst_type  = dispatch_info_i[i].inst_type;
        dispatch_inst_i[i].areg  = dispatch_info_i[i].areg;
        dispatch_inst_i[i].pc    = dispatch_info_i[i].pc;
        dispatch_inst_i[i].w_reg = dispatch_info_i[i].w_reg;
        dispatch_inst_i[i].w_mem = dispatch_info_i[i].w_mem;
        dispatch_inst_i[i].tier_id = dispatch_info_i[i].tier_id;
        dispatch_preg_i[i]       = dispatch_info_i[i].preg;
        dispatch_issue_i[i]      = dispatch_info_i[i].issue;
    end
    // C级
    for (genvar i = 0; i < 2; i++) begin
        commit_info_o[i].w_areg = commit_inst_o[i].areg;
        commit_info_o[i].w_reg  = commit_inst_o[i].w_reg;
        commit_info_o[i].w_mem  = commit_inst_o[i].w_mem;   
    end
end
// 表体分 bank，写入处理bank conflict
registers_file_banked #(
    .DATA_WIDTH($bits(rob_inst_entry_t)),
    .DEPTH(1 << `ROB_WIDTH),
    .R_PORT_COUNT(2),
    .W_PORT_COUNT(2),
    .REGISTERS_FILE_TYPE(2),
    .NEED_RESET(1)
) rob_inst_table (
    .clk,
    .rst_n,
    .raddr_i({tail_ptr1_q, tail_ptr0_q}),
    .rdata_o(commit_inst_o),

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
    for (genvar i = 0; i < 2; i++) begin
        // cdb
        cdb_preg_i[i] = cdb_info_i[i].w_preg;
        cdb_valid_i[i] = cdb_info_i[i].w_valid;
        cdb_data_i[i].data = cdb_info_i[i].w_data;
        cdb_data_i[i].ctrl = cdb_info_i[i].ctrl;
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
    .NEED_RESET(1)
) rob_data_table (
    .clk,
    .rst_n,
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
logic [1 : 0]           cdb_in_complete_o; // 写的两项对应的结果

always_comb begin
    for (genvar i = 0 ; i < 2; i++) begin
        commit_info_o[i].c_ready = ~(commit_complete_p_o[i] ^ commit_complete_cdb_o[i]);
        rob_dispatch_o[i].rob_complete = ~(rob_dispatch_complete_p_o[i] ^ rob_dispatch_complete_cdb_o[i]);
    end
end

// P级写
registers_file_banked # (
    .DATA_WITH($bits(rob_valid_entry_t)),
    .DEPTH(1 << `ROB_WIDTH),
    .R_PORT_COUNT(8),
    .W_PORT_COUNT(2),
    .REGISTERS_FILE_TYPE(2),
    .NEED_RESET(1)
) rob_valid_table (
    .clk,
    .rst_n,
    .raddr_i({dispatch_preg_i, tail_ptr1_q, tail_ptr0_q, dispatch_info_i[1].src_preg, dispatch_info_i[0].src_preg}),
    .rdata_o({dispatch_in_complete_o, commit_complete_p_o, rob_dispatch_complete_p_o}),

    .waddr_i(dispatch_preg_i),
    .we_i(dispatch_issue_i),
    .wdata_i(~dispatch_in_complete_o)
);

// C级写
registers_file_banked # (
    .DATA_WITH($bits(rob_valid_entry_t)),
    .DEPTH(1 << `ROB_WIDTH),
    .R_PORT_COUNT(8),
    .W_PORT_COUNT(2),
    .REGISTERS_FILE_TYPE(2),
    .NEED_RESET(1)
) rob_valid_table (
    .clk,
    .rst_n,
    .raddr_i({cdb_preg_i, tail_ptr1_q, tail_ptr0_q, dispatch_info_i[1].src_preg, dispatch_info_i[0].src_preg}),
    .rdata_o({cdb_in_complete_o, commit_complete_cdb_o, rob_dispatch_complete_cdb_o}),
    
    .waddr_i(cdb_preg_i),
    .we_i(cdb_valid_i),
    .wdata_i(~cdb_in_complete_o)
);



endmodule