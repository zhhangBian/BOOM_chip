`include "a_defines.svh"

module dcache #(
    // Cache 规格设置
    parameter int unsigned WAY_NUM = 2,
    parameter int unsigned WORD_SIZE = 32,
    parameter int unsigned DATA_DEPTH = 256,
    parameter int unsigned BLOCK_SIZE = 4 * 32, //4个字
    parameter int unsigned SB_SIZE = 4,
    parameter int unsigned TAG_ADDR_LOW = 12 - $clog2(DATA_DEPTH),
    parameter int unsigned DATA_ADDR_LOW = $clog2(WORD_SIZE / 8)
) (
    input logic clk,
    input logic rst_n,
    input logic flush_i,
    // 控制信息CSR
    input csr_t csr_i,
    // cpu侧信号
    handshake_if.receiver cpu_lsu_receiver,
    handshake_if.sender   lsu_cpu_sender,
    // commit级信号
    input logic              stall_i, // 全局stall信号
    input commit_cache_req_t commit_cache_req,
    output cache_commit_resp_t cache_commit_resp,

    input tlb_write_req_t  tlb_write_req_i
);
// global stall
logic sb_stall;
wire  stall = stall_i | sb_stall;
logic stall_q;
always_ff @(posedge clk) begin
    stall_q <= stall;
end

logic valid_q;
always_ff @(posedge clk) begin
    valid_q <= cpu_lsu_receiver.valid;
end

// commit 传入请求
// commit_cache_req_t commit_cache_req;
logic  [1:0] commit_way_choose, commit_way_choose_q;
logic  [31:0] commit_addr, commit_addr_q;
assign commit_way_choose = commit_cache_req.way_choose;
assign commit_addr       = commit_cache_req.addr;
always_ff @(posedge clk) begin
    commit_way_choose_q <= commit_way_choose;
    commit_addr_q       <= commit_addr;
end
// cpu传入数据
iq_lsu_pkg_t iq_lsu_pkg;
assign iq_lsu_pkg = cpu_lsu_receiver.data;
logic [31:0] va;
assign va = iq_lsu_pkg.vaddr;
// MMU类型数据
wire [1:0] mem_type = |iq_lsu_pkg.strb ? `_MEM_STORE : `_MEM_LOAD;
trans_result_t trans_result;
tlb_exception_t tlb_exception;
// mmu结果 TODO
mmu #(
    .TLB_ENTRY_NUM(`_TLB_ENTRY_NUM),
    .TLB_SWITCH_OFF(0)
) mmu_ins (
    .clk(clk),
    .rst_n(rst_n),
    .flush(flush_i),
    .va(iq_lsu_pkg.vaddr),
    .csr(csr_i),
    .mmu_mem_type(mem_type), // ? dcache中，只有读和写两种情况:分别是
    .tlb_write_req_i(tlb_write_req_i),
    .trans_result_o(trans_result),
    .tlb_exception_o(tlb_exception)
);

`ifdef _DIFFTEST
logic [31:0] va_diff;
always_ff @(posedge clk) begin
    va_diff <= iq_lsu_pkg.vaddr;
end
`endif

logic [31 : 0] paddr; // 假设从mmu打一拍传来的paddr
logic [19 : 0] ppn;
logic          uncache;
assign paddr = trans_result.pa;
assign ppn   = paddr[31:12];
assign uncache = !trans_result.mat[0];
//tlb传来的异常也应当与其一起


// TAG SRAM
cache_tag_t [WAY_NUM - 1 : 0] tag_ans0, tag_ans1;
for (genvar i = 0; i < WAY_NUM; i++) begin
    // conflict 逻辑
    logic conflict, conflict_q;
    assign conflict = (va[11 : TAG_ADDR_LOW] == commit_cache_req.addr[11 : TAG_ADDR_LOW] /* commit请求的写地址*/ );
    always_ff @(posedge clk) begin
        conflict_q <= conflict;
    end 
    cache_tag_t rtag0, rtag1; 
    assign tag_ans0[i] = conflict_q ? rtag1 : rtag0;
    assign tag_ans1[i] = rtag1;
    // sram 本体
    dpsram #(
        .DATA_WIDTH($bits(cache_tag_t)),
        .DATA_DEPTH(DATA_DEPTH),
        .BYTE_SIZE($bits(cache_tag_t))
    ) tag_sram (
        // 0端口
        .clk0(clk),
        .rst_n0(rst_n),
        .addr0_i(va[11 : TAG_ADDR_LOW]),
        .en0_i(!conflict),
        .we0_i('0),
        .wdata0_i('0),
        .rdata0_o(rtag0),
        // 1端口
        .clk1(clk),
        .rst_n1(rst_n),
        .addr1_i(commit_cache_req.addr[11 : TAG_ADDR_LOW]/* commit请求 */),
        .en1_i('1),
        .we1_i(commit_cache_req.way_choose[i] & commit_cache_req.tag_we/* commit请求 */),
        .wdata1_i(commit_cache_req.tag_data/* commit请求 */),
        .rdata1_o(rtag1)
    );
end




/**********************M1 数据传输**********************/
iq_lsu_pkg_t m1_iq_lsu_pkg;
always_ff @(posedge clk) begin
    m1_iq_lsu_pkg <= iq_lsu_pkg;
end

// DATA SRAM
logic [WAY_NUM - 1 : 0][WORD_SIZE - 1 : 0] data_ans0, data_ans1;
for (genvar i = 0 ; i < WAY_NUM ; i++) begin
    // conflict 逻辑
    logic conflict, conflict_q;
    assign conflict = (va[11 : DATA_ADDR_LOW] == commit_cache_req.addr[11 : DATA_ADDR_LOW]/* commit请求的写地址*/ );
    always_ff @(posedge clk) begin
        conflict_q <= conflict;
    end 
    logic [WORD_SIZE - 1 : 0] rdata0, rdata1; 
    assign data_ans0[i] = conflict_q ? rdata1 : rdata0;
    assign data_ans1[i] = rdata1;
    // sram 本体
    dpsram #(
        .DATA_WIDTH(WORD_SIZE),
        .DATA_DEPTH(DATA_DEPTH * BLOCK_SIZE / WORD_SIZE),
        .BYTE_SIZE(8)
    ) data_sram (
        // 0端口
        .clk0(clk),
        .rst_n0(rst_n),
        .addr0_i(va[11 : DATA_ADDR_LOW]),
        .en0_i(!conflict),
        .we0_i('0),
        .wdata0_i('0),
        .rdata0_o(rdata0),
        // 1端口
        .clk1(clk),
        .rst_n1(rst_n),
        .addr1_i(commit_cache_req.addr[11 : DATA_ADDR_LOW]/* commit请求 */),
        .en1_i('1),
        .we1_i({4{commit_cache_req.way_choose[i]}} & commit_cache_req.strb/* commit请求 */),
        .wdata1_i(commit_cache_req.data_data/* commit请求 */),
        .rdata1_o(rdata1)
    );
end  

/**************************EXCEPTION**************************/
// input       exc_code;
logic          execute_exception;
logic   [5:0]  exc_code_new;
logic   [31:0] badv;
logic          ade_exc;
logic          not_exc;
assign  not_exc  = m1_iq_lsu_pkg.is_cacop && (m1_iq_lsu_pkg.cache_code[2:0] == 3'd1) && ((m1_iq_lsu_pkg.cache_code[4:3] == 1) || (m1_iq_lsu_pkg.cache_code[4:3] == 0));
assign  ade_exc  = (m1_iq_lsu_pkg.msize == 3) ? |badv[1:0] : (m1_iq_lsu_pkg.msize == 1) ? badv[0] : '0;
assign  exc_code_new  =  not_exc ? '0 : ade_exc ? `_ECODE_ALE : tlb_exception.ecode;
assign  execute_exception = ~not_exc & (ade_exc | (|tlb_exception.ecode));
assign  badv     = m1_iq_lsu_pkg.vaddr;

/**************************HIT DATA***************************/
logic [31 : 0] tmp_data;

/*************************M1 SB INST**************************/
logic      [31          : 0] sb_tmp_data; // , sb_w_data;  
sb_entry_t [SB_SIZE - 1 : 0] sb_entry;
sb_entry_t                   w_sb_entry, r_sb_entry;
// sb_entry_t                   top_sb_entry;
handshake_if #(.T(sb_entry_t)) sb_entry_receiver();
handshake_if #(.T(sb_entry_t)) sb_entry_sender();

// handshake
assign sb_entry_receiver.valid = !flush_i & !stall_q & |m1_iq_lsu_pkg.strb & valid_q;
assign sb_entry_receiver.data  = w_sb_entry;
assign sb_entry_sender.ready   = commit_cache_req.fetch_sb;/* commit提交sw指令请求 */
assign r_sb_entry              = sb_entry_sender.data;

storebuffer #(
    .SB_SIZE(SB_SIZE)
) sb_inst (
    .clk,
    .rst_n,
    .flush_i,
    .sb_entry_o(sb_entry),
    .sb_stall(sb_stall),
    // .top_entry_o(top_sb_entry),
    .sb_entry_receiver(sb_entry_receiver.receiver), // M1 级写握手
    .sb_entry_sender(sb_entry_sender.sender) // 和 commit 握手 传出最旧表项
);

/*************************M1 HIT LOGIC************************/
logic      [WAY_NUM - 1 : 0]  tag_hit;
logic      [31          : 0]  ram_tmp_data;
logic      [3           : 0]  sb_hit; //one hot
logic      [3           : 0]  byte_hit; // one hot
// TAG HIT LOGIC
always_comb begin
    tag_hit = '0;
    ram_tmp_data = '0;
    for (integer i = 0; i < WAY_NUM; i++) begin
        if (tag_ans0[i].tag == ppn) begin
            tag_hit[i] |= '1;
            ram_tmp_data  = '0;
            ram_tmp_data |= data_ans0[i];
        end
    end
end
always_comb begin
    sb_hit = '0;
    sb_tmp_data = '0;
    for (integer i = 0; i < SB_SIZE; i++) begin
        for (integer j = 0; j < 4; j++) begin
            if (sb_entry[i].valid & sb_entry[i].wstrb[j] & (sb_entry[i].target_addr[31:2] == paddr[31:2])) begin
                sb_hit[j]     |= '1;
                sb_tmp_data[8*j+7-:8]  = '0;
                sb_tmp_data[8*j+7-:8] |= sb_entry[i].write_data[8*j+7-:8];
            end
        end
    end
end
always_comb begin
    byte_hit = '0;
    for (integer i = 0; i < 4 ;i++) begin
        byte_hit[i] |= (|tag_hit) | (sb_hit[i]);
    end
end
assign tmp_data[7 : 0] = sb_hit[0] ? sb_tmp_data[7 : 0] : ram_tmp_data[7 : 0];
assign tmp_data[15: 8] = sb_hit[1] ? sb_tmp_data[15: 8] : ram_tmp_data[15: 8];
assign tmp_data[23:16] = sb_hit[2] ? sb_tmp_data[23:16] : ram_tmp_data[23:16];
assign tmp_data[31:24] = sb_hit[3] ? sb_tmp_data[31:24] : ram_tmp_data[31:24];
/*************************SB WRITE DATA*********************/
// SB WRITE DATA
always_comb begin
    w_sb_entry.target_addr = paddr;
    w_sb_entry.write_data  = m1_iq_lsu_pkg.wdata;
    w_sb_entry.wstrb       = m1_iq_lsu_pkg.strb;
    w_sb_entry.valid       = '1;
    w_sb_entry.uncached    = uncache;/* MMU结果 */
    w_sb_entry.hit         = tag_hit;
end
/**************************LW VALID*************************/
logic lw_valid;
assign lw_valid = ((m1_iq_lsu_pkg.rmask & byte_hit) == m1_iq_lsu_pkg.rmask);

/***************************handshake***********************/
assign cpu_lsu_receiver.ready = lsu_cpu_sender.ready & sb_entry_receiver.ready & !stall & !flush_i;
assign lsu_cpu_sender.valid = valid_q & !stall_q & !flush_i;

lsu_iq_pkg_t lsu_iq_pkg;
assign lsu_cpu_sender.data  = lsu_iq_pkg;
logic  [31 : 0] lw_data;
logic           sign;
always_comb begin
    lw_data = '0;
    sign    = '0;
    if (m1_iq_lsu_pkg.msize == 2'd0) begin
        for (integer i = 0; i < 4; i++) begin
            lw_data[7 : 0]     |= m1_iq_lsu_pkg.rmask[i] ? tmp_data[(i << 3) + 7 -: 8]    : '0;
            sign               |= m1_iq_lsu_pkg.rmask[i] ? tmp_data[(i << 3) + 7]         : '0;
        end
        lw_data[31: 8]         |= {24{sign & m1_iq_lsu_pkg.msigned}};
    end else if (m1_iq_lsu_pkg.msize == 2'd1) begin
        for (integer i = 0; i < 2; i++) begin
            lw_data[15: 0]     |= m1_iq_lsu_pkg.rmask[2*i] ? tmp_data[(i << 4) + 15 -: 16]    : '0;
            sign               |= m1_iq_lsu_pkg.rmask[2*i] ? tmp_data[(i << 4) * i + 15]          : '0;
        end
        lw_data[31:16]         |= {16{sign & m1_iq_lsu_pkg.msigned}};
    end else begin
        lw_data                |= tmp_data;
    end
end
// REFILL LOGIC
logic [1:0] refill_way;
always_ff @(posedge clk) begin
    if (!rst_n) begin
        refill_way <= 2'd01;
    end else begin
        refill_way <= ~refill_way;
    end
end
// LSU_PKG
always_comb begin
    lsu_iq_pkg.strb     = m1_iq_lsu_pkg.strb;
    lsu_iq_pkg.rmask    = m1_iq_lsu_pkg.rmask;
    lsu_iq_pkg.msigned  = m1_iq_lsu_pkg.msigned;
    lsu_iq_pkg.msize    = m1_iq_lsu_pkg.msize;
    lsu_iq_pkg.uncached = uncache;
    lsu_iq_pkg.hit      = (lw_valid & (|m1_iq_lsu_pkg.rmask)) | (|tag_hit);
    lsu_iq_pkg.wid      = m1_iq_lsu_pkg.wid;
    lsu_iq_pkg.paddr    = paddr;
    `ifdef _DIFFTEST
    lsu_iq_pkg.vaddr    = va_diff;
    `endif
    lsu_iq_pkg.rdata    = lw_data; //组合逻辑有点长，后续考虑拆两级流水
    lsu_iq_pkg.tlb_exception = tlb_exception;
    lsu_iq_pkg.refill   = refill_way;
    lsu_iq_pkg.cache_dirty_addr = refill_way[0] ? {tag_ans0[0].tag, paddr[11:0]} : {tag_ans0[1].tag, paddr[11:0]};
    lsu_iq_pkg.dirty    = refill_way[0] ? tag_ans0[0].d : tag_ans0[1].d;
    lsu_iq_pkg.tag_hit  = tag_hit;
    lsu_iq_pkg.cacop_dirty = paddr[0] ? tag_ans0[1].d : tag_ans0[0].d;
    lsu_iq_pkg.hit_dirty   = tag_hit[0] ? tag_ans0[0].d : tag_ans0[1].d;
    lsu_iq_pkg.cacop_addr  = paddr[0] ? {tag_ans0[1].tag, paddr[11:0]} : {tag_ans0[0].tag, paddr[11:0]};
    lsu_iq_pkg.wdata       = m1_iq_lsu_pkg.wdata;
    lsu_iq_pkg.execute_exc_info.execute_exception  = execute_exception;          
    lsu_iq_pkg.execute_exc_info.exc_code           = exc_code_new; 
    lsu_iq_pkg.execute_exc_info.badv               = badv;
end
/*****************************cache2commit***********************/
always_comb begin
    cache_commit_resp.addr = commit_addr_q;
    cache_commit_resp.data = commit_way_choose_q[0] ? data_ans1[0] : data_ans1[1];
    cache_commit_resp.data_other = data_ans1[1];
    cache_commit_resp.sb_entry = r_sb_entry;
end

endmodule
