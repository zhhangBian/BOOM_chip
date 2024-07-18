`include "a_defines.svh"

module icache #(
    // Cache 规格设置
    parameter int unsigned WAY_NUM = 2,
    parameter int unsigned WORD_SIZE = 64,
    parameter int unsigned DATA_DEPTH = 128,
    parameter int unsigned BLOCK_SIZE = 4 * 64, //8个字 ，或者理解为 4 个长字
    parameter int unsigned TAG_ADDR_LOW = 12 - $clog2(DATA_DEPTH),
    parameter int unsigned DATA_ADDR_LOW = $clog2(WORD_SIZE / 8)
) (
    input clk,
    input rst_n,
    input flush_i,
    // 控制信息CSR
    input csr_t csr_i,
    // cpu侧信号
    handshake_if.receiver    fetch_lsu_receiver,
    hadnshake_if.sender      lsu_decoder_sender,
    // 全局信号
    input logic                stall_i, // 全局stall信号，来自于重填和cache维护
    input commit_fetch_req_t   commit_cache_req, // commit维护cache时的请求
    output fetch_commit_resp_t cache_commit_resp // cache向提交级反馈结果
)
// 打一拍整理数据

// stall逻辑，重填和维护都阻塞，阻塞时注意要

// MMU
wire [1:0] mem_type = `_MEM_FETCH;
trans_result_t trans_result;
tlb_exception_t tlb_exception;
mmu #(
    .TLB_ENTRY_NUM(64),
    .TLB_SWITCH_OFF(0)
) (
    .clk,
    .rst_n,
    .flush_i,
    .va(/*TODO 改成PC*/),
    .csr(csr_i),
    .mmu_mem_type(mem_type), // icache中，取指
    .trans_result_o(trans_result),
    .tlb_exception_o(tlb_exception)
);
logic [31 : 0] paddr; // 假设从mmu打一拍传来的paddr
logic [19 : 0] ppn;
logic          uncache;
assign paddr   = trans_result.pa;
assign ppn     = paddr[31:12];
assign uncache = !trans_result.mat[0];

// tag sram
cache_tag_t [WAY_NUM - 1 : 0] tag_ans0, tag_ans1;
for (genvar i = 0; i < WAY_NUM; i++) begin
    // conflict 逻辑
    logic conflict, conflict_q;
    assign conflict = (va[11 : TAG_ADDR_LOW] == commit_cache_req.addr[11 : TAG_ADDR_LOW] /* TODO commit请求的写地址*/ );
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
        .addr1_i(commit_cache_req.addr[11 : TAG_ADDR_LOW]/* TODO commit请求 */),
        .en1_i('1),
        .we1_i(commit_cache_req.way_hit[i] & commit_cache_req.tag_we/* TODO commit请求 */),
        .wdata1_i(commit_cache_req.tag_data/* TODO commit请求 */),
        .rdata1_o(rtag1)
    );
end

// data sram
logic [WAY_NUM - 1 : 0][DATA_WIDTH - 1 : 0] data_ans0, data_ans1;
for (genvar i = 0 ; i < WAY_NUM ; i++) begin
    // conflict 逻辑
    logic conflict, conflict_q;
    assign conflict = (va[11 : DATA_ADDR_LOW] == commit_cache_req.addr[11 : DATA_ADDR_LOW]/* TODO commit请求的写地址*/ );
    always_ff @(posedge clk) begin
        conflict_q <= conflict;
    end 
    logic [DATA_WIDTH - 1 : 0] rdata0, rdata1; 
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
        .addr1_i(commit_cache_req.addr[11 : DATA_ADDR_LOW]/*TODO commit请求 */),
        .en1_i('1),
        .we1_i({4{commit_cache_req.way_hit[i]}} & commit_cache_req.strb/* TODO commit请求 */),
        .wdata1_i(commit_cache_req.data_data/* TODO commit请求 */),
        .rdata1_o(rdata1)
    );
end  

// hit逻辑，比dcache简单得多
logic [WAY_NUM - 1 : 0] tag_hit;
for (integer i = 0; i < WAY_NUM ; i++) begin
    assign tag_hit[i] = (tag_ans0[i].tag == ppn);
end
// uncache
// 根据实际情况选择向axi拿的数量

// fsm , NORMAL -> REFILL(ONLY AXI -> SRAM) -> FINISH -> NORMAL

endmodule