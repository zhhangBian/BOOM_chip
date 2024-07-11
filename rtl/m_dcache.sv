`include "a_defines.svh"

typedef struct packed {
    logic  [3:0]  strb;
    // inv_parm_e   cacop;
    // logic  dbar;         // 显式 dbar
    // logic  llsc;         // LL 指令，需要写权限
    rob_id_t       wid;     // 写回地址
    logic      msigned;     // 有符号拓展
    logic  [1:0] msize;     // 访存大小-1
    logic [31:0] vaddr;     // 虚拟地址
    logic [31:0] wdata;     // 写数据
} iq_lsu_pkg_t;


typedef struct packed {
    logic [19 : 0] tag;
    logic          v;
    logic          d;
} cache_tag_t;

module dcache #(
    // Cache 规格设置
    parameter int unsigned WAY_NUM = 2,
    parameter int unsigned WORD_SIZE = 32,
    parameter int unsigned BLOCK_SIZE = 32 * 16, //16个字
    parameter int unsigned SB_SIZE = 4
) (
    input clk,
    input rst_n,
    input flush_i,

    input csr_t csr_i,

    // cpu侧信号
    handshake_if.receiver cpu_lsu_receiver,


)

iq_lsu_pkg_t iq_lsu_pkg;
assign iq_lsu_pkg = cpu_lsu_receiver.data;
logic [31 : 0] va;
assign va = iq_lsu_pkg.vaddr;

trans_result_t trans_result;
logic [31 : 0] pa;
assign pa = trans_result.pa;

// 获取翻译后的地址 ，两路的 TAG 和两路的 DATA
mmu #(
    .TLB_ENTRY_NUM(64),
    .TLB_SWITCH_OFF(0)
) (
    .clk,
    .rst_n,
    .flush_i,
    .va(va),
    .csr(csr_i),
    .mem_type(), // ?
    .trans_result_o(trans_result)
);


logic [1 : 0][19 : 0] tag_read;
//TAG ram
for (genvar i = 0; i < WAY_NUM; i++) begin
    logic conflict;
    logic conflict_q;
    assign conflict = (va[11:4] == bus_addr[11:4]) & bus_we[i];//TODO
    always_ff @(posedge clk) begin
        conflict_q <= conflict;
    end
    cache_tag_t raw_tag0, raw_tag1;
    assign tag_read[i] = conflict_q ? raw_tag1 : raw_tag0;
    
    dpsram #(
        .DATA_WIDTH($bits(cache_tag_t)),
        .DATA_DEPTH(512),
        .BYTE_SIZE($bits(cache_tag_t))
    ) tag_sram (
        .clk0(clk),
        .rst_n0(rst_n),
        .clk1(clk),
        .rst_n1(rst_n),
        // 端口 0，只读
        .addr0_i(va[11:4]),
        .en0_i(!conflict), // 出现冲突时，不使能
        .we0_i('0),
        .wdata0_i('0),
        .rdata0_o(raw_tag0),
        // 端口 1，读写
        .addr1_i(bus_addr[11:4]), // UNDEFINE
        .en1_i('1),        // 一直使能
        .we1_i(bus_we[i]), // 写使能信号 // UNDEFINE
        .wdata1_i(bus_wtag), //UNDEFINE
        .rdata1_o(raw_tag1)
    );
end

typedef logic [BLOCK_SIZE/WORD_SIZE - 1 : 0][WORD_SIZE - 1 : 0] data_type;
data_type [1 : 0] data_read;
//DATA ram
for (genvar i = 0; i < WAY_NUM; i++) begin
    logic conflict;
    logic conflict_q;
    assign conflict = (va[11:4] == bus_addr[11:4]) & bus_we[i];//TODO
    always_ff @(posedge clk) begin
        conflict_q <= conflict;
    end
    data_type raw_data0, raw_data1;
    assign data_read[i] = conflict_q ? raw_data1 : raw_data0;

    dpsram #(
        .DATA_WIDTH(BLOCK_SIZE),
        .DATA_DEPTH(512), // 512 / 1024
        .BYTE_SIZE(8)
    ) data_sram (
        .clk0(clk),
        .rst_n0(rst_n),
        .clk1(clk),
        .rst_n1(rst_n),
        // 端口0
        .addr0_i(va[11:4]),
        .en0_i(!conflict),
        .we0_i('0),
        .wdata0_i('0),
        .rdata0_o(raw_data0),
        // 端口1
        .addr1_i(w_addr[11:4]),
        .en1_i('1),
        .we1_i(w_strb[i]),
        .wdata1_i(w_wdata),
        .rdata1_o(raw_data1)
    );
end

// M1 级， 检查hit命中情况，sb_hit, tag_hit
// 例化 store buffer
// store指令将数据写入store buffer
sb_entry_t [SB_SIZE - 1 : 0] sb_entry;
storebuffer #(
    .SB_SIZE(4)
) storebuffer_inst (
    .clk,
    .rst_n,
    .flush_i,

    // input   logic [1 : 0] c_w_mem_i,

    // output  logic [SB_DEPTH_LEN - 1 : 0] sb_num,
    // output  sb_entry_t [SB_SIZE - 1 : 0] sb_entry_o,
    .sb_entry_o(sb_entry),

    // handshake_if.receiver  sb_entry_receiver,

    // handshake_if.sender    sb_fifo_entry_sender
);

logic [1           : 0] tag_hit,  tag_hit_q;
logic [SB_SIZE - 1 : 0]  sb_hit,   sb_hit_q;

always_comb begin
    // tag hit
    for (genvar i = 0; i < 2 ; i++) begin
        tag_hit[i] = (tag_read[i].tag == pa[31 : 12]) & tag_read[i].v;
    end
    // sb_hit
    for (genvar i = 0; i < SB_SIZE; i++) begin
        sb_hit[i] = sb_entry[i].valid & (sb_entry[i].target_addr[31 : 12] == pa[31 : 12]);
    end

    // snoop_hit

end 



// M2 级， 根据命中情况输入状态机，
// 如果命中或者为store指令，则输出给lsu
// FSM: IDLE(空闲)， NORMAL(正常工作)，MISS_DIRTY(缺失且选中路脏位为1)，MISS_REFILL(向总线侧发重填请求)，REFILL(开始重填)，WRITE_BACK(SB数据写回)……
// IDLE和NORMAL之外的状态阻塞之前的指令
// 当storebuffer有指令需要提交写入CACAHE里，阻塞LSU


endmodule