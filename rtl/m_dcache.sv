`include "a_defines.svh"

typedef struct packed {
    logic  [3:0]  strb;
    logic  [3:0] rmask;            // 需要读的字节
    inv_parm_e   cacop;
    logic         dbar;            // 显式 dbar
    logic         llsc;            // LL 指令，需要写权限
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
    parameter int unsigned DATA_DEPTH = 256,
    parameter int unsigned BLOCK_SIZE = 4 * 32, //4个字
    parameter int unsigned SB_SIZE = 4
) (
    input clk,
    input rst_n,
    input flush_i,

    input csr_t csr_i,

    // cpu侧信号
    handshake_if.receiver cpu_lsu_receiver,


)
/*******************************global*********************************/
logic stall, stall_q;
always_ff @(posedge clk) begin
    stall_q <= stall;
end

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


cache_tag_t [WAY_NUM - 1 : 0] tag_read;
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
        .DATA_DEPTH(DATA_DEPTH),
        .BYTE_SIZE($bits(cache_tag_t))
    ) tag_sram (
        .clk0(clk),
        .rst_n0(rst_n),
        .clk1(clk),
        .rst_n1(rst_n),
        // 端口 0，只读
        .addr0_i(va[11:4]),
        .en0_i(!conflict),          // 出现冲突时，不使能
        .we0_i('0),
        .wdata0_i('0),
        .rdata0_o(raw_tag0),
        // 端口 1，读写
        .addr1_i(bus_addr[11:4]),   // UNDEFINE
        .en1_i('1),                 // 一直使能
        .we1_i(bus_we[i]),          // 写使能信号 // UNDEFINE
        .wdata1_i(bus_wtag),        //UNDEFINE
        .rdata1_o(raw_tag1)
    );
end

typedef logic [(WORD_SIZE/BYTE_SIZE) - 1 : 0][BYTE_SIZE - 1 : 0] data_type;
data_type [WAY_NUM - 1 : 0] data_read;
//DATA ram
for (genvar i = 0; i < WAY_NUM; i++) begin
    logic conflict;
    logic conflict_q;
    assign conflict = (va[11:$clog2(WORD_SIZE/BYTE_SIZE)] == w_addr[11:$clog2(WORD_SIZE/BYTE_SIZE)]);
    always_ff @(posedge clk) begin
        conflict_q <= conflict;
    end
    data_type raw_data0, raw_data1;
    assign data_read[i] = conflict_q ? raw_data1 : raw_data0;

    dpsram #(
        .DATA_WIDTH(WORD_SIZE),
        .DATA_DEPTH(DATA_DEPTH * BLOCK_SIZE / WORD_SIZE), 
        .BYTE_SIZE(8)
    ) data_sram (
        .clk0(clk),
        .rst_n0(rst_n),
        .clk1(clk),
        .rst_n1(rst_n),
        // 端口0
        .addr0_i(va[11:$clog2(WORD_SIZE/BYTE_SIZE)]),
        .en0_i(!conflict),
        .we0_i('0),
        .wdata0_i('0),
        .rdata0_o(raw_data0),
        // 端口1
        .addr1_i(w_addr[11:$clog2(WORD_SIZE/BYTE_SIZE)]),
        .en1_i('1),
        .we1_i(w_strb[i]),
        .wdata1_i(w_wdata),
        .rdata1_o(raw_data1)
    );
end

/********************************M1*********************************/

typedef struct packed {
    iq_lsu_pkg_t m1_iq_lsu_pkg;
    logic [31 : 0] p_addr;
    cache_tag_t [WAY_NUM - 1 : 0] m1_tag_read;
    data_type   [WAY_NUM - 1 : 0] m1_data_read;
    // else info
} m1_pkg_t;

m1_pkg_t m1_front, m1_reg, m1;
iq_lsu_pkg_t iq_lsu_pkg_q;

always_ff @(posedge clk) begin
    if (!rst_n || flush_i) begin
        iq_lsu_pkg_q <= '0;
        m1_reg       <= '0;
    end else begin
        iq_lsu_pkg_q <= iq_lsu_pkg；
        m1_reg       <= m1;
    end
end

always_comb begin
    m1 = stall_q ? m1_reg : m1_front;
    m1_front.m1_iq_lsu_pkg = iq_lsu_pkg_q; 
    m1_front.p_addr        = pa;
    m1_front.m1_tag_read   = tag_read;
    m1_front.m1_data_read  = data_read;
    m1_front.m1_uncached   = !trans_result.mat[0];
end

// M1 级， 检查hit命中情况，sb_hit, tag_hit
// 例化 store buffer
// store指令将数据写入store buffer
// 例化接口
handshake_if #(.T(sb_entry_t)) sb_lsu_receiver();
handshake_if #(.T(sb_entry_t)) sb_lsu_sender();
sb_entry_t [SB_SIZE - 1 : 0] sb_entry;
sb_entry_t sb_entry_i, sb_entry_o;
storebuffer #(
    .SB_SIZE(4)
) storebuffer_inst (
    .clk,
    .rst_n,
    .flush_i,
    // input   logic [1 : 0] c_w_mem_i,
    // output  logic [SB_DEPTH_LEN - 1 : 0] sb_num,
    .sb_entry_o(sb_entry),
    .sb_entry_receiver(sb_lsu_receiver.receiver),
    .sb_entry_sender(sb_lsu_sender.sender)
);
always_comb begin
    sb_entry_i.target_addr = m1.p_addr;
    sb_entry_i.write_data  = m1.m1_iq_lsu_pkg.wdata;
    sb_entry_i.wstrb       = m1.m1_iq_lsu_pkg.strb;
    sb_entry_i.valid       = '1;
    sb_entry_i.commit      = '0;
end
assign sb_lsu_receiver.data  = sb_entry_i;
assign sb_lsu_receiver.valid = |sb_entry_i.wstrb;
logic m1_hit;
logic [31          : 0] choose_data;
logic [1           : 0] tag_hit,  tag_hit_q;
logic [SB_SIZE - 1 : 0]  sb_hit,   sb_hit_q;
always_comb begin
    // hit
    m1_hit = (|tag_hit) | (|sb_hit); // 命中
    // tag hit
    for (genvar i = 0; i < 2 ; i++) begin
        tag_hit[i] = (m1.m1_tag_read[i].tag == m1.p_addr[31 : 12]) & m1.m1_tag_read[i].v;
    end
    // sb_hit
    for (genvar i = 0; i < SB_SIZE; i++) begin
        sb_hit[i] = sb_entry[i].valid 
        && (sb_entry[i].target_addr[31 : $clog2(WORD_SIZE/BYTE_SIZE)] == m1.p_addr[31 : $clog2(WORD_SIZE/BYTE_SIZE)]);
        // && (m1.rmask & (sb_entry[i].wstrb | 4{tag_hit[0]} | 4{tag_hit[1]}) == m1.rmask);
    end
    // snoop_hit
    // TODO
end 

/***********************************M2**********************************/





// M2 级， 根据命中情况输入状态机，
// 如果命中或者为store指令，则输出给lsu
// FSM: IDLE(空闲)， NORMAL(正常工作)，MISS_DIRTY(缺失且选中路脏位为1)，
// MISS_REFILL(向总线侧发重填请求)，REFILL(开始重填)，WRITE_BACK(SB数据写回)……
// IDLE和NORMAL之外的状态阻塞之前的指令
// 当storebuffer有指令需要提交写入CACAHE里，阻塞LSU


endmodule