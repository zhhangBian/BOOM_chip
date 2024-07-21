`include "a_define.h"

module r_rename #(
    parameter int unsigned DEPTH = 32,
    parameter int unsigned ADDR_DEPTH   = (DEPTH > 1) ? $clog2(DEPTH) : 1
)(
    input  logic clk,
    input  logic rst_n,   
    // R级输入
    handshake_if.receiver d_r_receiver, // 和D级的握手接口
    // data 包含 D 级传入的控制信息，我们要用到的是 读寄存器和写寄存器的 id
    // R级输出
    handshake_if.sender   r_p_sender,   // 和P级的握手接口
    // data 包含 R 级已经读取的ARF的数据及有效性，以及读出 ARF的id在RAT中的映射结果及有效性
    // C级信号
    input  logic c_flush_i,
    // 是否有指令退休
    input  logic [1 :0] c_retire_i,
    input  retire_pkg_t [1 :0] c_retire_info_i,
    // …… TODO: C级其他信号
);

// rob控制信号及分配
logic   [`ROB_WIDTH - 1 :0] rob_cnt, rob_cnt_q;
logic   rob_available, rob_available_q;
// rob的相应写指针
rob_id_t  rob_ptr1, rob_ptr2;
rob_id_t  rob_ptr1_q, rob_ptr2_q;


always_ff @(posedge clk) begin
    if (!rst_n || c_flush_i) begin // 如果flush,则全都清空 ok!
        rob_cnt_q       <= '0;
        rob_ptr1_q      <= '0;
        rob_ptr2_q      <=  1;
        rob_available_q <=  1;
    end else begin
        rob_cnt_q       <= rob_cnt;
        rob_ptr1_q      <= rob_ptr1;
        rob_ptr2_q      <= rob_ptr2;
        rob_available_q <= rob_available;
    end
end

always_comb begin
    rob_cnt       = rob_cnt_q  + r_issue[0] + r_issue[1] - c_retire_i[0] - c_retire_i[1];
    rob_ptr1      = rob_ptr1_q + r_issue[0] + r_issue[1];
    rob_ptr2      = rob_ptr2_q + r_issue[0] + r_issue[1];
    rob_available = (rob_cnt_q <= 60);
end

assign d_r_receiver.ready = rob_available_q & !c_flush_i & r_p_sender.ready; 
// 和前模块握手的ready信号当且仅当rob能继续进指令，且非flush，且后模块也ready
assign r_p_sender.valid   = '1;
// 始终允许向后模块发送指令，区分指令有效仅依靠于r_valid

// rat entry
typedef struct packed {
    logic check;
    logic [`ROB_WIDTH - 1 :0] robid;
} rat_entry_t;

// id信号
arf_id_t [3 :0] r_rarid;  // 读寄存器的id
arf_id_t [1 :0] r_warid;  // 写寄存器的id
logic  [1 :0] r_issue;  // 指令是否发射
rob_id_t [3 :0] r_rrobid; // 读寄存器的rob_id
rob_id_t [1 :0] r_wrobid; // 写寄存器的rob_id
rat_entry_t  [3 :0] r_rename_result; 
rat_entry_t  [1 :0] r_rename_new;
logic  [1 :0] r_we;     // 写寄存器是否发射
assign r_we = r_issue & {{(|r_warid[1])}, {(|r_warid[0])}} & {d_r_receiver.data.w_reg};
// commit 表结果
rat_entry_t  [3 :0] cr_result;
rat_entry_t  [1 :0] cw_result; 
rat_entry_t  [1 :0] c_new;
arf_id_t     [1 :0] c_warid;
logic        [1 :0] c_we;

assign r_rarid = d_r_receiver.data.arftable.r_arfid;
assign r_warid = d_r_receiver.data.arftable.w_arfid;
assign r_issue = d_r_receiver.data.r_valid & 
                {d_r_receiver.valid, d_r_receiver.valid} & 
                {d_r_receiver.ready, d_r_receiver.ready};
assign r_wrobid = {rob_ptr2_q, rob_ptr1_q};

for (genvar i = 0; i < 4; i++) begin
    assign r_rrobid[i] = r_rename_result[i].robid;
end

for (genvar i = 0; i < 2; i++) begin
    assign r_rename_new[i].robid = r_wrobid[i];
    assign r_rename_new[i].check = ~cw_result[i].check;
end


// R级RAT表的实现
rename_rat # (
    .DATA_WIDTH(7),
    .DEPTH(32),
    .R_PORT_COUNT(4), 
    .NEED_RESET(1)
) r_rename_table (
    .clk(clk),
    .rst_n(rst_n && !c_flush_i),
    .raddr_i(r_rarid),
    .rdata_o(r_rename_result),
    .waddr_i(r_warid),
    .we_i(r_we),
    .wdata_i(r_rename_new)
);

// C级RAT表的实现
// TODO: C级RAT表的实现

assign c_we = c_retire_i & 
            {(c_retire_info_i[1].w_valid),(c_retire_info_i[0].w_valid)} & 
            {(|c_retire_info_i[1].arf_id),(|c_retire_info_i[0].arf_id)};

assign c_warid = {c_retire_info_i[1].arf_id, c_retire_info_i[0].arf_id};

for (genvar i = 0; i < 2; i++) begin
    assign c_new[i].check = c_retire_info_i[i].w_check;
    assign c_new[i].robid = c_retire_info_i[i].rob_id;
end

commit_rat # (
    .DATA_WIDTH(7),
    .DEPTH(32),
    .R_PORT_COUNT(4 + 2), 
    .W_PORT_COUNT(2),     
    .NEED_RESET(1),
    .NEED_FORWARD(1)
) c_rename_table (
    .clk(clk),
    .rst_n(rst_n && !c_flush_i),
    .raddr_i({r_rarid, r_warid}),
    .rdata_o({cr_result, cw_result}),
    .waddr_i(c_warid),
    .we_i(c_we),
    .wdata_i(c_new)
);

// ARF的实现
logic [3 :0][31:0] r_arf_data;
logic [1 :0][31:0] write_data;
assign write_data = {c_retire_info_i[1].data, c_retire_info_i[0].data};

arf # (
    .DATA_WIDTH(32),
    .DEPTH(32),
    .R_PORT_COUNT(4), 
    .W_PORT_COUNT(2), 
    .NEED_RESET(1),
    .NEED_FORWARD(1)
) arf_inst (
    .clk(clk),
    .rst_n(rst_n),
    .raddr_i(r_rarid),
    .rdata_o(r_arf_data),
    .waddr_i(c_warid),
    .we_i(c_we),
    .wdata_i(write_data)
);

// 打包P级信号，并握手
r_p_pkg_t r_p_pkg_o, r_p_pkg_temp;
d_r_pkg_t d_r_pkg_i;
assign d_r_pkg_i = d_r_receiver.data;
assign r_p_sender.data = r_p_pkg_o;
logic   [3 : 0]  r_p_arfdata_valid;
for (genvar i = 0; i < 4; i++) begin
    r_p_arfdata_valid[i] = '0;
    if (r_rename_result[i] == cr_result[i]) begin
        r_p_arfdata_valid[i] |= '1;
    end
end

always_ff @(posedge clk) begin
    if (!rst_n || flush_i) begin
        r_p_pkg_o <= '0;
    end else begin
        if (r_p_sender.valid & r_p_sender.ready) begin
            r_p_pkg_o <= r_p_pkg_temp;
        end else begin
            r_p_pkg_o <= r_p_pkg_o;
        end
    end
end

always_comb begin
    r_p_pkg_temp.alu_type = d_r_pkg_i.alu_type;
    r_p_pkg_temp.mdu_type = d_r_pkg_i.mdu_type;
    r_p_pkg_temp.lsu_type = d_r_pkg_i.lsu_type;
    r_p_pkg_temp.areg      = d_r_pkg_i.arf_table.w_arfid;
    r_p_pkg_temp.preg      = r_wrobid;
    r_p_pkg_temp.src_preg  = r_rrobid; 
    r_p_pkg_temp.arf_data  = r_arf_data;
    r_p_pkg_temp.pc        = d_r_pkg_i.pc;
    r_p_pkg_temp.r_valid   = d_r_pkg_i.r_valid;
    r_p_pkg_temp.w_reg     = d_r_pkg_i.w_reg;
    r_p_pkg_temp.w_mem     = d_r_pkg_i.w_mem;
    r_p_pkg_temp.check     = {r_rename_new[1].check, r_rename_new[0].check};
    r_p_pkg_temp.use_imm   = d_r_pkg_i.use_imm;
    r_p_pkg_temp.data_imm  = d_r_pkg_i.data_imm;
    r_p_pkg_temp.data_valid= (~d_r_pkg_i.reg_need) | r_p_arfdata_valid;
end


endmodule