`include "a_define.h"

module r_rename #(
    parameter int unsigned DEPTH = 32,
    parameter int unsigned ADDR_DEPTH   = (DEPTH > 1) ? $clog2(DEPTH) : 1
) (
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
    input  logic [1 :0] c_retire_i,
    output c_flush_ack_o
    // …… TODO: C级其他信号
);

// rob控制信号及分配
logic  [`ROB_WIDTH - 1 :0] rob_cnt,  rob_cnt_q;
logic         rob_available, rob_available_q;
rob_id        rob_ptr1, rob_ptr2, rob_ptr1_q, rob_ptr2_q;


always_ff @(posedge clk) begin
    if (!rst_n || c_flush_i) begin
        rob_cnt_q       <= '0;
        rob_ptr1_q      <= '0;
        rob_ptr2_q      <= '1;
        rob_available_q <= '1;
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

// rat entry
typedef struct packed {
    logic valid;
    logic [`ROB_WIDTH - 1 :0] robid;
} rat_entry_t;

// id信号
arf_id [3 :0] r_rarid;
arf_id [1 :0] r_warid;
logic  [1 :0] r_issue;
rob_id [3 :0] r_rrobid;
rob_id [1 :0] r_wrobid;
rat_entry_t  [3 :0] r_rename_result; 
rat_entry_t  [1 :0] r_rename_new;

assign r_rarid = d_r_receiver.data.arftable.r_arfid;
assign r_warid = d_r_receiver.data.arftable.w_arfid;
assign r_issue = d_r_receiver.data.r_valid & {d_r_receiver.valid, d_r_receiver.valid} & {r_p_sender.ready, r_p_sender.ready};
assign r_wrobid = {rob_ptr2_q, rob_ptr1_q};

for (genvar i = 0; i < 4; i++) begin
    assign r_rrobid[i] = r_rename_result[i].robid;
end


// RAT表的实现
rat # (
    .DATA_WIDTH(6 + 1),
    .DEPTH(32),
    .R_PORT_COUNT(4), // CHANGEABLE
    .W_PORT_COUNT(2), // CHANGEABLE
    .NEED_RESET(1),
    .NEED_FORWARD(0)
)
r_rename_table (
    .clk(clk),
    .rst_n(rst_n && !c_flush_i),
    .raddr_i(r_rarid),
    .rdata_o(r_rename_result),
    .waddr_i(r_warid),
    .we_i(r_issue & {{(|r_warid[1])}, {(|r_warid[0])}}),
    .wdata_i(r_rename_new)
);

endmodule