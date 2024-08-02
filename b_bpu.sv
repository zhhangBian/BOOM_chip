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
    return {pc[17:9 ] ^ pc[11:3]};
endfunction

function automatic logic [`BPU_TAG_LEN-1:0] get_tag(input logic[31:0] pc);
    return pc[`BPU_TAG_LEN+12-1: 12];
endfunction

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

/* ============================== MODULE BEGIN ============================== */

module bpu(
    input wire                  clk,
    input wire                  rst_n,

    input wire                  flush_i,
    input wire [31:0]           redir_addr_i,

    input  correct_info_t [1:0] correct_infos_i, // 后端反馈的修正信息
    handshake_if.sender         sender // predict_info_t [1:0] type
);

wire rst;
assign rst = ~rst_n;

/* ============================== correct_info ============================== */
// 每次选中第一条需要update的指令进行update
correct_info_t correct_info;
assign correct_info = correct_infos_i[0].update ? correct_infos_i[0] : correct_infos_i[1];


/* ============================== PC ============================== */
logic ready;
logic [31:0 ] pc_q;
logic [31:0 ] pc_next; // wire 类型 组合逻辑得出。

always_ff @(posedge clk) begin : pc_logic
    pc_q <= pc_next;
end

/* ============================== reset Counter ============================== */
// reset Counter will add 1 every posedge when reset signal is valid.
reg [`BPU_PHT_LEN-1:0] rst_cnt_q;
wire [`BPU_PHT_LEN-1:0] rst_cnt_add_1;
wire [`BPU_PHT_LEN-1:0] rst_cnt_next;

assign rst_cnt_add_1 = rst_cnt_q + 1;
assign rst_cnt_next = rst_n ? rst_cnt_q : rst_cnt_add_1;

reg sigq, sigqq;

always_ff @(posedge clk) begin
    sigq <= ~rst_n;
    sigqq <= sigq;
end

always_ff @(posedge clk) begin : rst_cnt_logic
    if (sigqq) begin
        rst_cnt_q <= rst_cnt_next;
    end
    else if (sigq) begin
        rst_cnt_q <= '0;
    end
    else begin
        rst_cnt_q <= rst_cnt_q;
    end
    // rst_cnt_q <= '0;
end

/* ============================== BTB ============================== */

bpu_btb_entry_t [1:0]       btb_rdata;
bpu_btb_entry_t             btb_wdata;
logic [`BPU_BTB_LEN-1:0]    btb_raddr;
logic [`BPU_BTB_LEN-1:0]    btb_waddr;
wire  [1:0]                 btb_we;
logic [1:0]                 btb_tag_match;
logic [1:0]                 btb_valid;

assign btb_raddr = hash(pc_next);
assign btb_waddr = rst_n ? hash(correct_info.pc) : rst_cnt_q[`BPU_BTB_LEN-1:0];

assign btb_we[0] = (~correct_info.pc[2] & correct_info.update) | rst;
assign btb_we[1] = (correct_info.pc[2] & correct_info.update) | rst;

always_comb begin : btb_wdata_logic
    btb_wdata.tag               = get_tag(correct_info.pc);
    btb_wdata.target_pc         = correct_info.target_pc;
    btb_wdata.branch_type       = correct_info.branch_type;
    btb_wdata.is_call           = (correct_info.branch_type == BR_CALL) & correct_info.is_branch;
    btb_wdata.is_ret            = (correct_info.branch_type == BR_RET) & correct_info.is_branch;
    btb_wdata.is_uncond_branch  = (correct_info.branch_type != BR_NORMAL) & correct_info.is_branch;
    btb_wdata.is_normal_branch  = (correct_info.branch_type == BR_NORMAL) & correct_info.is_branch;
    // reset logic
    btb_wdata &= {($bits(bpu_btb_entry_t)){rst_n}};
end

// BTB 的有效位需要复位，单独使用一位进行复位
(* ramstyle="distributed" *) reg [`BPU_BTB_DEPTH-1:0] valid_ram [1:0];
logic [1:0] valid_ram_rdata;
logic [1:0][`BPU_BTB_DEPTH-1:0] valid_ram_wdata;
logic [1:0] valid_ram_we;

assign valid_ram_we = btb_we;

for (genvar i = 0; i < 2; i=i+1) begin
    always_comb begin
        valid_ram_wdata[i] = valid_ram[i];
        if (rst) begin
            valid_ram_wdata[i] = '0;
        end
        else if (valid_ram_we[i]) begin
            valid_ram_wdata[i][btb_waddr] = correct_info.is_branch;
        end
    end

    always_ff @(posedge clk) begin
        valid_ram[i] <= '0;
    end

    assign valid_ram_rdata[i] = valid_ram[i][btb_raddr +: 1];
end

for (genvar i = 0; i < 2; i=i+1) begin
    dpsram #(
        .DATA_WIDTH($bits(bpu_btb_entry_t)),
        .DATA_DEPTH(`BPU_BTB_DEPTH),
        .BYTE_SIZE($bits(bpu_btb_entry_t))
    ) btb_dpsram (
        .clk0(clk),    
        .rst_n0(rst_n),
        .addr0_i(btb_raddr),
        .en0_i('1),
        .we0_i('0),
        .wdata0_i('0),
        .rdata0_o(btb_rdata[i]),

        .clk1(clk),
        .rst_n1(rst_n),
        .addr1_i(btb_waddr),
        .en1_i('1),
        .we1_i(btb_we[i]),
        .wdata1_i(btb_wdata),
        .rdata1_o(/* floating */)
    );
    assign btb_tag_match[i] = btb_rdata[i].tag == get_tag(pc_q);
    assign btb_valid[i] = valid_ram[i][btb_raddr] & btb_tag_match[i]; // this has to be none x
end

/* ============================== BHT ============================== */
/**
 * BHT 由 distributed ram 实现，但是需要模拟打一拍。
 * 其大小为 2 * `BPU_BHT_DEPTH * `BPU_HISTORY_LEN = 5120 bits ， 之后看情况
 * 看看要不要把它用 dpsram 实现 TODO.
 */

(* ramstyle = "distributed" *) reg [`BPU_HISTORY_LEN-1:0] bht0 [`BPU_BHT_DEPTH-1:0];
(* ramstyle = "distributed" *) reg [`BPU_HISTORY_LEN-1:0] bht1 [`BPU_BHT_DEPTH-1:0];

initial begin
    for (integer i = 0; i < `BPU_BHT_DEPTH; i=i+1) begin
        bht0[i] = '0;
        bht1[i] = '0;
    end
end

bpu_bht_entry_t [1:0]       bht_rdata;
bpu_bht_entry_t             bht_wdata;
logic [`BPU_BHT_LEN-1:0]    bht_raddr;
logic [`BPU_BHT_LEN-1:0]    bht_waddr;
reg   [`BPU_BHT_LEN-1:0]    bht_raddr_q;
reg   [`BPU_BHT_LEN-1:0]    bht_waddr_q;
logic [1:0]                 bht_we;

// address_logic : 需要打一拍
assign bht_raddr = bht_raddr_q;
assign bht_waddr = bht_waddr_q;
always_ff @(posedge clk) begin : bht_addr_q_logic
    bht_raddr_q <= btb_raddr; // notice: this is from BTB
    bht_waddr_q <= btb_waddr; // notice: this is from BTB
end

// 下一排的 logic
assign bht_we[0] = (~correct_info.pc[2] & correct_info.update) | rst;
assign bht_we[1] = (correct_info.pc[2] & correct_info.update) | rst;

assign bht_rdata[0] = bht0[bht_raddr];
assign bht_rdata[1] = bht1[bht_raddr];

always_comb begin: bht_wdata_logic
    bht_wdata = correct_info.type_miss ? {(`BPU_HISTORY_LEN){correct_info.taken}} : 
                {correct_info.history[`BPU_HISTORY_LEN-2:0], correct_info.taken};
    // reset logic
    bht_wdata &= {($bits(bpu_bht_entry_t)){rst_n}};
end

always_ff @(posedge clk) begin : bht_logic;
    if (rst) begin
        bht0[bht_waddr] <= bht_wdata; // 只需要是一个确定的值就行。 此外 waddr 是从 BTB 的 waddr 来的，自然能够找到rst_cnt
    end
    else if (bht_we[0]) begin
        bht0[bht_waddr] <= bht_wdata;
    end

    if (rst) begin
        bht1[bht_waddr] <= bht_wdata;
    end
    else if (bht_we[1]) begin
        bht1[bht_waddr] <= bht_wdata;
    end
end

/* ============================== RAS ============================== */
logic [`BPU_RAS_DEPTH-1:0][31:0]    ras; // the return address stack : 8*32 = 256 bits
logic [`BPU_RAS_LEN-1:0]            ras_top_ptr; // 指向栈顶元素。
logic [`BPU_RAS_LEN-1:0]            ras_w_ptr; // 指向栈顶的下一个元素。
logic [31:0]                        ras_rdata;
logic [31:0]                        ras_wdata;
logic                               ras_push; // 仅改变指针
logic                               ras_pop;// 仅改变指针
logic                               ras_we; // 写使能一定会 push

// RAS 的更新来自两个方面. 首先，如果前端预测到了 CALL 或者 RET 类型指令，则正常入栈出栈
// 如果后端发现预测信息有误，则也需要更新。
// 但是为了简单起见先**暂时**一致由后端进行更新，即后端但凡遇到 CALL 或者 RET 就反馈给前端进行更新
assign ras_wdata = btb_rdata[0].is_call ? btb_rdata[0].target_pc : btb_rdata[1].target_pc;
assign ras_rdata = ras[ras_top_ptr];

assign ras_pop = {btb_rdata[1].is_ret, btb_rdata[0].is_ret} & mask;
assign ras_push = ras_we;
assign ras_we = {btb_rdata[1].is_call, btb_rdata[0].is_call} & mask;

always_ff @(posedge clk) begin : ras_logic
    if (rst) begin
        ras[{rst_cnt_q[`BPU_RAS_LEN-1:0]}] <= ras_wdata; // 初始化为什么值不重要，重要的是不是 x.
    end
    else if (ras_we) begin
        ras[ras_w_ptr] <= ras_wdata;
    end
end

// RAS 向上增长 !!!
always_ff @(posedge clk ) begin
    if (rst) begin
        ras_top_ptr <= '1;
        ras_w_ptr <= '0;
    end
    else if (ras_push) begin
        ras_w_ptr <= ras_w_ptr + 1;
        ras_top_ptr <= ras_w_ptr;
    end
    else if (ras_pop) begin
        ras_w_ptr <= ras_top_ptr;
        ras_top_ptr <= ras_top_ptr - 1;
    end
end

/* ============================== PHT ============================== */
/**
 * 相比 BHT ，这家伙才更应该考虑是否转成dpsram吧。目前 12 为地址索引，分奇偶，
 * 共 16324 bits
 */
(* ramstyle = "distributed" *) reg [1:0] pht0 [`BPU_PHT_DEPTH - 1 : 0];
(* ramstyle = "distributed" *) reg [1:0] pht1 [`BPU_PHT_DEPTH - 1 : 0];

initial begin
    for (integer i = 0; i < `BPU_PHT_DEPTH; i=i+1) begin
        pht0[i] = 2'b01;
        pht1[i] = 2'b01;
    end
end

bpu_pht_entry_t  [1:0]              pht_rdata;
bpu_pht_entry_t                     pht_wdata;
logic [1:0][`BPU_PHT_LEN-1 : 0]     pht_raddr; // PHT的两个读地址不相同
logic [`BPU_PHT_LEN-1 : 0]          pht_waddr;
logic [1:0]                         pht_we;

assign pht_we[0] = bht_we[0];
assign pht_we[1] = bht_we[1];

assign pht_wdata = next_scnt(correct_info.scnt, correct_info.taken) & {2{rst_n}};

assign pht_rdata[0] = pht0[pht_raddr[0]];
assign pht_rdata[1] = pht1[pht_raddr[1]];

assign pht_waddr = {correct_info.history, correct_info.pc[`BPU_PHT_PC_LEN + 3 - 1:3]};

for (genvar i = 0; i < 2; i=i+1) begin
    assign pht_raddr[i] = {bht_rdata[i], pc_q[`BPU_PHT_PC_LEN + 3 - 1:3]};
end

always_ff @(posedge clk) begin
    if (pht_we[0]) begin
        pht0[pht_waddr] <= pht_wdata;
    end
    if (pht_we[1]) begin
        pht1[pht_waddr] <= pht_wdata;
    end
end

/* ============================== pc_next ============================== */
/**
 * possible value for pc_next:
 * 1. 32'h1c00_0000: if reset
 * 2. redir_addr_i : if flush
 * 3. pc_q         : if not ready
 * 4. target_pc    : if predict jump
 * 6. pc_add_4_8   : if both predict not jump
 */

logic [1:0] branch; // 表示这条指令是否跳转
logic [1:0] mask; // 指令掩码，表示送给 f 级的 pc 是否有效
logic [1:0][31:0] target_pc; // 每一条指令的目标地址, 包括 BTB 和 RAS 的读取结果 ； pc_next 是 pc_q 的下一个值
logic [1:0][31:0] npc;

wire [31:0] pc_add_4_8;
assign pc_add_4_8 = {pc_q[31:3]+29'd1, 3'b000};

for (genvar i = 0; i < 2; i++) begin
    assign branch[i] = btb_valid[i] & (btb_rdata[i].is_uncond_branch | pht_rdata[i][1]);
    assign target_pc[i] = btb_rdata[i].is_ret ? ras_rdata : btb_rdata[i].target_pc;
end

assign mask = {!branch[0] | pc_q[2], !pc_q[2]};

// pc_next logic
always_comb begin : pc_next_logic
    // TODO: optimize this f** block
    if (rst) begin
        pc_next = `BPU_INIT_PC;
    end
    else if (flush_i) begin
        pc_next = redir_addr_i;
    end
    else if (~ready) begin
        pc_next = pc_q;
    end
    else if (branch[0] && ~pc_q[2]) begin
        pc_next = target_pc[0];
    end
    else if (branch[1]) begin
        pc_next = target_pc[1];
    end
    else begin
        pc_next = pc_add_4_8;
    end
end

assign npc[0] = branch[0] ? target_pc[0] : {pc_q[31:3], 3'b100};
assign npc[1] = branch[1] ? target_pc[1] : pc_add_4_8;

/* ============================== Output Ports ============================== */
predict_info_t predict_infos[1:0];
b_f_pkg_t b_f_pkg;

for (genvar i = 0; i < 2; i=i+1) begin
    assign predict_infos[i].target_pc   =  target_pc[i];
    assign predict_infos[i].next_pc     =  npc[i];
    assign predict_infos[i].br_type     =  btb_rdata[i].branch_type;
    assign predict_infos[i].is_branch   =  valid_ram_rdata[i];
    assign predict_infos[i].taken       =  branch[i];
    assign predict_infos[i].scnt        =  pht_rdata[i];
    assign predict_infos[i].need_update =  !btb_tag_match[i]; // 没有这一项就要 update
    assign predict_infos[i].history     =  bht_rdata[i];
end

assign b_f_pkg.predict_infos = {predict_infos[1], predict_infos[0]};
assign b_f_pkg.pc = pc_q;
assign b_f_pkg.mask = mask;

// valid logic
wire valid_next;
reg valid_q;
wire valid;

assign valid_next = 1'b1; // 一拍后有效
assign valid = valid_q;

always_ff @(posedge clk) begin : valid_logic
    if (rst) begin
        valid_q <= '0;
    end
    else begin
        valid_q <= valid_next;
    end
end

// sender logic
assign sender.valid = valid; // 预测结果是打一拍才出来的，因此 valid 也要打一拍
assign ready = sender.ready;
assign sender.data = b_f_pkg;

endmodule
