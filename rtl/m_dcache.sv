`include "a_defines.svh"

typedef struct packed {
    logic [19 : 0] tag;
    logic          v;
    logic          d;
} cache_tag_t;

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
    input clk,
    input rst_n,
    input flush_i,
    // 控制信息CSR
    input csr_t csr_i,
    // cpu侧信号
    handshake_if.receiver cpu_lsu_receiver,
    hadnshake_if.sender   lsu_cpu_sender,
    // commit级信号
    input logic              stall, // 全局stall信号
    input commit_cache_req_t commit_cache_req,
    output cache_commit_resp_t cache_commit_resp
);
// globa stall
logic stall_q;
always_ff @(posedge clk) begin
    stall_q <= stall;
end

// cpu传入数据
iq_lsu_pkg_t iq_lsu_pkg;
assign iq_lsu_pkg = cpu_lsu_receiver.data;

// mmu结果 TODO
logic [31 : 0] paddr; // 假设从mmu打一拍传来的paddr
logic [19 : 0] ppn;
//tlb传来的异常也应当与其一起


// TAG SRAM
cache_tag_t [WAY_NUM - 1 : 0] tag_ans0, tag_ans1;
for (genvar i = 0; i < WAY_NUM; i++) begin
    // conflict 逻辑
    logic conflict, conflict_q;
    assign conflict = (va[11 : TAG_ADDR_LOW] == /* TODO commit请求的写地址*/ );
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
        .addr1_i(/* TODO commit请求 */),
        .en1_i('1),
        .we1_i(/* TODO commit请求 */),
        .wdata1_i(/* TODO commit请求 */),
        .rdata1_o(rtag1)
    );
end

/**********************M1 数据传输**********************/
iq_lsu_pkg_t m1_iq_lsu_pkg;
always_ff @(posedge clk) begin
    m1_iq_lsu_pkg <= iq_lsu_pkg;
end

// DATA SRAM
logic [WAY_NUM - 1 : 0][DATA_WIDTH - 1 : 0] data_ans0, data_ans1;
for (genvar i = 0 ; i < WAY_NUM ; i++) begin
    // conflict 逻辑
    logic conflict, conflict_q;
    assign conflict = (va[11 : DATA_ADDR_LOW] == /* TODO commit请求的写地址*/ );
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
        .addr1_i(/* TODO commit请求 */),
        .en1_i('1),
        .we1_i(/* TODO commit请求 */),
        .wdata1_i(/* TODO commit请求 */),
        .rdata1_o(rdata1)
    );
end  
/**************************HIT DATA***************************/
logic [31 : 0] tmp_data;

/*************************M1 SB INST**************************/
logic      [31          : 0] sb_tmp_data; // , sb_w_data;  
sb_entry_t [SB_SIZE - 1 : 0] sb_entry;
sb_entry_t                   w_sb_entry, r_sb_entry;
// sb_entry_t                   top_sb_entry;
hadnshake_if #(.T(sb_entry_t)) sb_entry_receiver();
hadnshake_if #(.T(sb_entry_t)) sb_entry_sender();

// handshake
assign sb_entry_receiver.valid = !flush_i & !stall_q & |m1_iq_lsu_pkg.strb;
assign sb_entry_receiver.data  = w_sb_entry;
assign sb_entry_sender.ready   = /* TODO commit提交sw指令请求 */
assign r_sb_entry              = sb_entry_sender.data; 

storebuffer #(
    .SB_SIZE(SB_SIZE)
) sb_inst (
    .clk,
    .rst_n,
    .flush_i,
    .sb_entry_o(sb_entry),
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
            if (sb_entry[i].valid & sb_entry[i].wstrb[j] & (sb_entry[i].target_addr[31:2] == pa[31:2])) begin
                sb_hit[j]     = '0;
                sb_tmp_data[8*j+7:8*j]  = '0;
                sb_tmp_data[8*j+7:8*j] |= sb_entry[i].write_data[8*j+7:8*j];
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
    w_sb_entry.uncached    = /* TODO MMU结果 */
    w_sb_entry.hit         = tag_hit;
end
/**************************LW VALID*************************/
logic lw_valid;
assign lw_valid = ((m1_iq_lsu_pkg.rmask & byte_hit) == m1_iq_lsu_pkg.rmask);

/***************************handshake***********************/
assign cpu_lsu_receiver.ready = lsu_cpu_sender.ready & sb_entry_receiver.ready & !stall & !flush_i;
logic valid_q;
always_ff @(posedge clk) begin
    valid_q <= cpu_lsu_receiver.valid;
end
assign lsu_cpu_sender.valid = valid_q & !stall_q & !flush_i;

endmodule;