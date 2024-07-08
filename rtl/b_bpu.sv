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

`include "a_defines.svh"

// saturating counter
function automatic logic [1:0] next_scnt(input logic[1:0] last_scnt, input logic taken);
    case (last_scnt)
        default: // strongly not taken
            // default has to be not taken, brcause don't know target pc?
            return {1'b0, taken};
        2'b01: // weakly not taken
            return {taken, 1'b0};
        2'b10: // weakly taken
            return {taken, 1'b1};
        2'b11: // strongly taken
            return {1'b1, taken};
    endcase
endfunction

// combination logic
// this function rely on the value of BPU_BTB_LEN. if the value is
// updated, this function need updated as well.
function automatic logic [`BPU_BTB_LEN-1:0] btb_hash(input logic[31:0] pc);
    // 将pc的[17:3] hash 到 [11:3], 将高12位hash成6位，然后与pc的第三位拼接.
    return {pc[17:12] ^ pc[11:6], pc[5:3]};
endfunction

function automatic logic [`BPU_TAG_LEN-1:0] get_tag(input logic[31:0] pc);
    return pc[`BPU_TAG_LEN+12-1: 12];
endfunction

module f_bpu(
    input                   clk,
    input                   rst_n,

    input  logic            ready_i,
    output logic            valid_o,

    input  correct_info_t     correct_info_i, // 后端反馈的修正信息

    output logic [31:0 ]    pc_o, // 指令PC，传递给ICACHE
    output logic [ 1:0 ]    mask_o, // 掩码，表示当前的两条指令中那一条需要被取出来。比如2'b10表明偶数PC需要取，而奇数PC不需要
    output predict_info_t   predict_info_o // 预测信息
);

/* ============================== PC ============================== */
logic [31:0 ] pc;
logic [31:0 ] npc; // wire 类型 组合逻辑得出。

always_ff @(clk) begin : pc_logic
    if (!rst_n) begin
        pc <= `BPU_INIT_PC;
    end
    else if (ready_i) begin
        pc <= npc;
    end
    else begin
        pc <= pc;
    end
end
assign pc_o = pc;

/* ============================== BTB ============================== */
// BTB 应当存储除了正常指令和 ret(JIRL) 类型指令以外的所有分支指令的目标地址
bpu_btb_entry_t [1:0]               btb_rdata;
logic [`BPU_BTB_LEN-1 : 0]           btb_raddr;
logic [`BPU_BTB_LEN-1 : 0]           btb_waddr;
// logic [31:2]                        btb_target_pc;
logic                               btb_tag_match;
(* ramstyle = "distributed" *) reg [`BPU_BTB_DEPTH - 1 : 0][$bits(bpu_btb_entry_t)-1:0] btb [1:0];

assign btb_raddr = btb_hash(npc);
assign btb_waddr = btb_hash(correct_info_i.pc);
assign btb_tag_match = (btb_rdata.tag[`BPU_TAG_LEN-1:0] == get_tag(pc));// TODO: index  of btb_rdata is missing

always_ff @( clk ) begin : btb_logic
    // reset btb to ZERO
    if (!rst_n) begin
        btb <= '0;
        btb_rdata <= '0;
    end
    for (integer i = 0; i < 2; i++) begin
        if (ready_i) begin
            btb_rdata[i] <= btb[i][btb_raddr];
        end
        if (correct_info_i.update) begin
            if (correct_info_i.pc[2]) begin
                btb[1][btb_waddr].target_pc <= correct_info_i.target;
            end 
            else begin
                btb[0][btb_waddr].target_pc <= correct_info_i.target;
            end
        end
    end
end

/* ============================== BHT ============================== */
/**
 * 跳转历史和 BTB 不同. BTB 的更新依赖于后端计算出来的目标地址，
 * 而历史（也就是跳转或者不跳）可以在前端更新。也可以因后端而更新.
 * 目前为了简便暂时全部使用后端进行更新。
 */
(* ramstyle = "distributed" *) reg [`BPU_BHT_DEPTH - 1 : 0][$bits(bpu_bht_entry_t)-1:0] bht [1:0];

bpu_bht_entry_t [1:0]               bht_rdata;
bpu_bht_entry_t [1:0]               bht_wdata;
logic [`BPU_BTB_LEN-1 : 0]           bht_raddr;
logic [`BPU_BTB_LEN-1 : 0]           bht_waddr;
logic                               bht_tag_match;

assign bht_raddr = btb_hash(npc);
assign bht_waddr = btb_hash(correct_info_i.update ? correct_info_i.pc : pc);
assign btb_tag_match = (bht_rdata.tag == get_tag(pc));

always_comb begin
    for (integer i = 0; i < 2; i++) begin
        bht_wdata[i].valid = 1;
        bht_wdata[i].tag = get_tag(correct_info_i.update ? correct_info_i.target : pc);
        bht_wdata[i].history = correct_info_i.type_miss ? {4'b0, correct_info_i.taken} :
                               correct_info_i.pc_miss ? {correct_info_i.history[3:0], correct_info_i.taken} :
                               {bht[i][bht_waddr].history[3:0], predict_info_o.taken};
    end
end

always_ff @( clk ) begin : bht_logic
    if (!rst_n) begin
        bht <= '0;
    end
    if (ready_i) begin
        bht_rdata[0] <= bht[0][bht_raddr];
        bht_rdata[1] <= bht[1][bht_raddr];
    end
    if (correct_info_i ? correct_info_i.pc[2] : pc[2]) begin
        bht[1][bht_waddr] <= bht_wdata;
    end
    else begin
        bht[0][bht_waddr] <= bht_wdata;
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
        ras_w_ptr <= ras_w_ptr + 32'd1;
        ras_top_ptr <= ras_w_ptr;
    end
    if (correct_info_i.target_type == BR_RET) begin
        ras_w_ptr = ras_top_ptr;
        ras_top_ptr = ras_top_ptr - 32'd1;
    end
end

/* ============================== PHT ============================== */
(* ramstyle = "distributed" *) reg [`BPU_PHT_DEPTH - 1 : 0][$bits(bpu_pht_entry_t)-1:0] pht [1:0];

bpu_pht_entry_t                     pht_rdata[1:0];
bpu_pht_entry_t                     pht_wdata[1:0];
logic [`BPU_PHT_LEN-1 : 0]           pht_waddr;
logic [`BPU_PHT_LEN-1 : 0]           pht_raddr;

assign pht_raddr = {bht_rdata.history, pc[`BPU_PHT_PC_LEN + 3 - 1:3]};

always_comb begin
    for (integer i = 0; i < 2; i++) begin
        pht_wdata[i].valid = 1;
        pht_wdata[i].scnt = next_scnt(correct_info_i.scnt);
    end
end

always_ff @( clk ) begin : pht_logic
    if (!rst_n) begin
        pht <= '0;
    end
    if (ready_i) begin
        pht_rdata[0] <= pht[0][pht_raddr];
        pht_rdata[1] <= pht[1][pht_raddr];
    end
    if (correct_info_i.pc[2]) begin
        pht[1][pht_waddr] <= pht_wdata[1];
    end
    else begin
        pht[0][pht_waddr] <= pht_wdata[0];
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
logic [31:0] next_npc;

assign branch = {pht_rdata[1].scnt[1], pht_rdata[0].scnt[1]};

always_comb begin
    mask = {1'b1, branch[0] && !pc[2]};
    npc = {pc[31:2] + '1, 2'b0};

    if (btb_rdata[0].br_type != BR_NPC && branch[0] && !pc[2]) begin
        mask = {1'b0, branch[0]};
        npc = btb_rdata[0].br_type == BR_RET ? ras_rdata : btb_rdata[0].target_pc;
    end
    else if (btb_rdata[1].br_type != BR_NPC && branch[1]) begin
        npc = btb_rdata[1].br_type == BR_RET ? ras_rdata : btb_rdata[1].target_pc;
    end
end

assign mask_o = mask;


endmodule