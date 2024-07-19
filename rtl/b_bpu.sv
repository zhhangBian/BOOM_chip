/**
 * BOOM 的分支预测模块（BPU）。吞吐量为1，即一个周期可以只能预测一条指令。
 * @config: 以 {PC[10:3], history[4:0]} 共13位作为Pattern进行局部历史 + 
 * 2位饱和计数器预测。
 **** 
 * 0704会议：
 *   BTB hash
 *   dpsram 可以试着使用 distributed ram
 *   Tier ID 优化
 * 0708反思：
 *   流水级有大问题。
 *   调整成单周期比较合适
 */

/**
 * 无条件跳转指令有：JIRL, B, BL
 * 有条件跳转指令有：BEQ, BNE, BLT, BGE, BLTU, BGEU, 
 */

`include "a_defines.svh"

// combination logic
// this function rely on the value of BPU_BTB_LEN. if the value is
// updated, this function need updated as well.
function automatic logic [`BPU_BTB_LEN-1:0] hash(input logic[31:0] pc);
    // 将pc的[17:3] hash 到 [11:3], 将高12位hash成6位，然后与pc的第三位拼接.
    return {pc[17:9 ] ^ pc[11:3]};
endfunction

function automatic logic [`BPU_TAG_LEN-1:0] get_tag(input logic[31:0] pc);
    return pc[`BPU_TAG_LEN+12-1: 12];
endfunction

/* ============================== MODULE BEGIN ============================== */

module bpu(
    input                   clk,
    input                   rst_n,
    input                   g_flush, // TODO: g_flush is the same as redir signal

    input  correct_info_t   correct_info_i, // 后端反馈的修正信息
    handshake_if.sender     sender, // predict_info_t type
);

logic ready_i;
logic valid_o;
predict_info_t predict_info_o;

assign sender.data = predict_info_o; // 预测信息, 组合逻辑输出
assign sender.valid = valid_o;
assign ready_i = sender.ready;

/* ============================== PC ============================== */
logic [31:0 ] pc;
logic [31:0 ] npc; // wire 类型 组合逻辑得出。

always_ff @(clk) begin : pc_logic
    if (!rst_n) begin
        pc <= `BPU_INIT_PC;
    end
    else if (g_flush) begin // TODO: might remove redir signal
        pc <= redir_addr;
    end
    else if (ready_i) begin
        pc <= npc;
    end
end

/* ============================== BTB ============================== */
// BTB 应当存储除了正常指令和 ret(JIRL) 类型指令以外的所有分支指令的目标地址
bpu_btb_entry_t [1:0]       btb_rdata;
logic [`BPU_BTB_LEN-1 : 0]  btb_raddr;
logic [`BPU_BTB_LEN-1 : 0]  btb_waddr;
logic [1:0]                 btb_tag_match;
logic                       btb_we;
logic [1:0]                 btb_valid;
(* ramstyle = "distributed" *) bpu_btb_entry_t btb [1:0][`BPU_BTB_DEPTH - 1 : 0];

assign btb_raddr = hash(pc);
assign btb_waddr = hash(correct_info_i.pc);
assign btb_we = correct_info_i.type_miss | correct_info_i.target_miss;

for (genvar i = 0; i < 2; i++) begin
    // btb_valid 表示是否有这一项在 BTB 中。表项 !valid 或者 !tag_match 都表示没有这一项
    assign btb_valid[i] = btb_rdata[i].valid & btb_tag_match[i];
end

always_comb begin
    for (integer i = 0; i < 2; i++) begin
        btb_rdata[i] = btb[i][btb_raddr];
        btb_tag_match[i] = (btb_rdata[i].tag[`BPU_TAG_LEN-1:0] == get_tag(pc));
    end
end

always_ff @( clk ) begin : btb_logic
    // reset btb to ZERO
    if (!rst_n) begin
        btb <= '0; // TODO: there is a error about it;
        btb_rdata <= '0;
    end
    // 写入
    else if (btb_we) begin
        btb[correct_info_i.pc[2]][btb_waddr].target_pc <= correct_info_i.target;
        btb[correct_info_i.pc[2]][btb_waddr].tag       <= get_tag(correct_info_i.pc);
        btb[correct_info_i.pc[2]][btb_waddr].br_info   <= correct_info_i.br_type;
    end
end

/* ============================== BHT ============================== */
/**
 * 跳转历史和 BTB 不同. BTB 的更新依赖于后端计算出来的目标地址，
 * 而历史（也就是跳转或者不跳）可以在前端更新。也可以因后端而更新.
 * 目前为了简便暂时全部使用后端进行更新。
 */
(* ramstyle = "distributed" *) bpu_bht_entry_t bht [1:0][`BPU_BHT_DEPTH - 1 : 0];

bpu_bht_entry_t [1:0]               bht_rdata;
bpu_bht_entry_t [1:0]               bht_wdata;
logic [`BPU_BTB_LEN-1 : 0]          bht_raddr;
logic [`BPU_BTB_LEN-1 : 0]          bht_waddr;
logic                               bht_we;

assign bht_raddr = btb_raddr // = hash(pc);
assign bht_waddr = btb_waddr// = hash(correct_info_i.pc);

assign bht_we = correct_info_i.update;

always_comb begin
    for (integer i = 0; i < 2; i++) begin
        // 写入数据逻辑
        bht_wdata[i].history = correct_info_i.type_miss ? {4'b0, correct_info_i.taken} : // 一条新指令
                               correct_info_i.target_miss ? {correct_info_i.history[3:0], correct_info_i.taken} : // taken miss
                               {bht[i][bht_waddr].history[3:0], correct_info_i.taken};
        bht_wdata[i].is_cond_br = correct_info_i.cond_br;
        // 读取数据
        bht_rdata[i] = bht[i][bht_raddr];
        btb_tag_match[i] = (bht_rdata[i].tag == get_tag(pc));
    end
end

always_ff @( clk ) begin : bht_logic
    if (!rst_n) begin
        bht <= '0;
    end
    if (bht_we) begin
        bht[correct_info_i.pc[2]][bht_waddr] <= bht_wdata[correct_info_i.pc[2]];
    end
end

/* ============================== RAS ============================== */
logic [`BPU_RAS_DEPTH-1:0][31:0]    ras; // the return address stack
logic [`BPU_RAS_LEN-1:0]            ras_top_ptr; // 指向栈顶元素。
logic [`BPU_RAS_LEN-1:0]            ras_w_ptr; // 指向栈顶的下一个元素。
logic [31:0]                        ras_rdata;
logic [31:0]                        ras_wdata;

// RAS 的更新来自两个方面. 首先，如果前端预测到了 CALL 或者 RET 类型指令，则正常入栈出栈
// 如果后端发现预测信息有误，则也需要更新。
// 但是为了简单起见先**暂时**一致由后端进行更新，即后端但凡遇到 CALL 或者 RET 就反馈给前端进行更新
assign ras_wdata = correct_info_i.target_type == BR_CALL ? correct_info_i.pc + 32'd4 : '0;
assign ras_rdata = ras[ras_top_ptr];

always_ff @( clk ) begin
    if (!rst_n) begin
        ras <= '0;
        ras_top_ptr <= {`BPU_RAS_LEN{1'b1}};
        ras_w_ptr <= '0;
    end
    if (correct_info_i.target_type == BR_CALL) begin
        ras[ras_w_ptr] <= ras_wdata;
        ras_w_ptr <= ras_w_ptr + '1;
        ras_top_ptr <= ras_w_ptr;
    end
    if (correct_info_i.target_type == BR_RET) begin
        ras_w_ptr <= ras_top_ptr;
        ras_top_ptr <= ras_top_ptr - '1;
    end
end

/* ============================== PHT ============================== */
(* ramstyle = "distributed" *) reg [`BPU_PHT_DEPTH - 1 : 0][$bits(bpu_pht_entry_t)-1:0] pht [1:0];

bpu_pht_entry_t  [1:0]              pht_rdata;
bpu_pht_entry_t  [1:0]              pht_wdata;
logic [`BPU_PHT_LEN-1 : 0]          pht_waddr;
logic [1:0][`BPU_PHT_LEN-1 : 0]     pht_raddr; // PHT的两个读地址不相同
logic                               pht_we;

assign pht_we = correct_info_i.update;

always_comb begin
    for (integer i = 0; i < 2; i++) begin
        pht_wdata[i].scnt = next_scnt(correct_info_i.scnt, correct_info_i.taken);
        pht_raddr[i] = {bht_rdata[i].history[`BPU_HISTORY_LEN-1:0], pc[`BPU_PHT_PC_LEN + 3 - 1:3]};
    end
end

always_ff @( clk ) begin : pht_logic
    if (!rst_n) begin
        pht <= '0; // TODO: there is a warning about it
    end
    if (pht_we) begin
        pht[correct_info_i.pc[2]][pht_waddr] <= pht_wdata[correct_info_i.pc[2]];
    end
end

/* ============================== NPC ============================== */
/**
 * BTB: bpu_pht_entry_t [1:0] btb_rdata
 * PHT: bpu_pht_entry_t [1:0] pht_rdata
 * RAS: logic[31:0] ras_rdata;
 */
logic [1:0] branch;
logic [1:0] mask;

for (genvar i = 0;  < 2; i++) begin
    // branch[i] 表示第 i 条指令是否要分支
    // branch 的可能：
    // 1. !btb_rdata[i].is_cond_br 
    // 2. pht_rdata[i].scnt[1]
    assign branch[i] = btb_valid & (!btb_rdata[i].is_cond_br | pht_rdata[i].scnt[1]);
end

always_comb begin
    // 根据 btb_valid, btb_rdata[i].br_type, branch 来判断npc
    mask = {branch[0] && !pc[2], !pc[2]};
    npc = {pc[31:2] + '1, 2'b0};

    if (branch[0] && !pc[2]) begin
        mask = {1'b0, 1'b1};
        npc = btb_rdata[0].br_info.br_type == BR_RET ? ras_rdata : btb_rdata[0].target_pc;
    end
    else if (branch[1]) begin
        npc = btb_rdata[1].br_info.br_type == BR_RET ? ras_rdata : btb_rdata[1].target_pc;
    end
end

assign predict_info_o.pc                 =  pc;
assign predict_info_o.mask               =  mask;
assign predict_info_i.target_pc          =  npc;
for (genvar i = 0; i < 2; i++) begin
    assign predict_info_o.br_type[i]     =  btb_rdata[i].br_type;
    assign predict_info_o.taken[i]       =  branch[i];
    assign predict_info_o.scnt[i]        =  pht_rdata[i].scnt;
    assign predict_info_o.need_update[i] =  !btb_rdata[i].valid; // 没有这一项就要 update
    assign predict_info_o.history[i]     =  bht_rdata[i].history;
end

// predict_info_o is with npc_logic

endmodule