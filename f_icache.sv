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
    input logic clk,
    input logic rst_n,
    input logic flush_i, 
    // 控制信息CSR
    input csr_t csr_i,
    // cpu侧信号
    handshake_if.receiver       fetch_icache_receiver,
    handshake_if.sender         icache_decoder_sender,
    // axi信号
    output  logic               addr_valid_o,
    output  logic  [31:0]       addr_o,
    output  logic  [7 :0]       data_len_o, /* 2024/07/24 fix*/
    input   logic               axi_resp_ready_i,
    input   logic               axi_data_valid_i,
    input   logic  [31:0]       axi_data_i,
    // commit交互信号
    input   commit_icache_req_t commit_icache_req,
    output  logic   [1:0]       icache_cacop_flush_o,
    output  tlb_exception_t     icache_cacop_tlb_exc,
    output  logic   [31:0]      icache_cacop_bvaddr, 
    input   logic               commit_req_valid_i, // commit发维护请求需要读（cacop op为2的时候）的时候
    output  logic               commit_resp_ready_o, // 状态处理完毕，即为NORMAL状态时
    output  logic               commit_resp_valid_o,

    input   tlb_write_req_t     tlb_write_req_i
);

commit_fetch_req_t   commit_cache_req;
fetch_commit_resp_t  cache_commit_resp;

logic stall, stall_q;
always_ff @(posedge clk) begin
    if (!rst_n) begin
        stall_q <= '0;
    end else begin
        stall_q <= stall;
    end
end
logic cacop_stall, cacop_stall_q;
always_ff @(posedge clk) begin
    if (!rst_n) begin
        cacop_stall_q <= '0;
    end else begin
        cacop_stall_q <= cacop_stall;
    end
end

assign commit_resp_ready_o = !stall_q;
// 打一拍整理数据

// stall逻辑，重填和维护都阻塞，阻塞时注意要
b_f_pkg_t b_f_pkg, b_f_pkg_q;
logic [31:0] pc;
// logic [1 :0] mask; /* 2024/07/24 fix */

assign b_f_pkg = fetch_icache_receiver.data;
assign pc      = b_f_pkg.pc & 32'hfffffff8; //对齐
// assign mask    = b_f_pkg.mask;

// MMU
wire [1:0] mem_type = `_MEM_FETCH;
trans_result_t trans_result;
tlb_exception_t tlb_exception, tlb_exception_q;
mmu #(
    .TLB_ENTRY_NUM(64),
    .TLB_SWITCH_OFF(0)
) mmu_inst (
    .clk(clk),
    .rst_n(rst_n),
    .flush(flush_i),
    .va(pc/*改成PC*/),
    .csr(csr_i),
    .mmu_mem_type(mem_type), // icache中，取指
    .tlb_write_req_i(tlb_write_req_i),
    .trans_result_o(trans_result),
    .tlb_exception_o(tlb_exception)
);
// MMU
trans_result_t trans_result_c;
tlb_exception_t tlb_exception_c;
mmu #(
    .TLB_ENTRY_NUM(64),
    .TLB_SWITCH_OFF(0)
) mmu_commit (
    .clk(clk),
    .rst_n(rst_n),
    .flush(flush_i),
    .va(commit_cache_req.addr),
    .csr(csr_i),
    .mmu_mem_type(mem_type), // icache中，取指
    .tlb_write_req_i(tlb_write_req_i),
    .trans_result_o(trans_result_c),
    .tlb_exception_o(tlb_exception_c)
);

logic [31 : 0] paddr; // 假设从mmu打一拍传来的paddr
logic [19 : 0] ppn;
logic [31 : 0] paddr_q;
logic          uncache;
assign paddr   = trans_result.pa;
assign ppn     = paddr[31:12];
assign uncache = !trans_result.mat[0];

// paddr打一拍
always_ff @(posedge clk) begin
    if (!rst_n) begin
        paddr_q <= '0;
        tlb_exception_q <= '0;
    end else if (!stall_q && icache_decoder_sender.ready) begin
        paddr_q <= paddr; 
        tlb_exception_q <= tlb_exception;
    end else begin
        paddr_q <= paddr_q;
        tlb_exception_q <= tlb_exception_q;
    end
end


logic back_ready_q;
always_ff @(posedge clk) begin
    if (!rst_n) begin
        back_ready_q <= '0;
    end else begin
        back_ready_q <= icache_decoder_sender.ready;
    end
end

// 写入信息
logic [31:0] refill_addr, refill_addr_q;
logic [1 :0][31:0] refill_data, refill_data_q;
cache_tag_t  refill_tag ;
logic [1 :0] refill_we, refill_we_q, refill_tag_we;
always_ff @(posedge clk) begin
    if (!rst_n) begin
        refill_addr_q <= '0;
        refill_data_q <= '0;
        refill_we_q   <= '0;
    end else begin
        refill_addr_q <= refill_addr;
        refill_data_q <= refill_data;
        refill_we_q   <= refill_we  ; 
    end 
end
// 写入仲裁
logic [31:0] real_addr;
logic [1 :0] real_we;
cache_tag_t  real_tag;

assign real_addr = stall ? refill_addr    : commit_cache_req.addr;
assign real_we   = stall ? refill_tag_we  : (commit_cache_req.way_choose & {2{commit_cache_req.tag_we}});
assign real_tag  = stall ? refill_tag     : commit_cache_req.tag_data;  

// tag sram
cache_tag_t [WAY_NUM - 1 : 0] tag_ans0, tag_ans1;
for (genvar i = 0; i < WAY_NUM; i++) begin
    // conflict 逻辑
    logic conflict, conflict_q;
    assign conflict = (pc[11 : TAG_ADDR_LOW] == real_addr[11 : TAG_ADDR_LOW] /*commit请求的写地址*/ );
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
        .addr0_i(pc[11 : TAG_ADDR_LOW]),
        .en0_i(!conflict),
        .we0_i('0),
        .wdata0_i('0),
        .rdata0_o(rtag0),
        // 1端口
        .clk1(clk),
        .rst_n1(rst_n),
        .addr1_i(real_addr[11 : TAG_ADDR_LOW]),
        .en1_i('1),
        .we1_i(real_we[i]),
        .wdata1_i(real_tag),
        .rdata1_o(rtag1)
    );
end

// data sram
logic [WAY_NUM - 1 : 0][WORD_SIZE - 1 : 0] data_ans0, data_ans1;
for (genvar i = 0 ; i < WAY_NUM ; i++) begin
    // conflict 逻辑
    logic conflict, conflict_q;
    assign conflict = (pc[11 : DATA_ADDR_LOW] == refill_addr[11 : DATA_ADDR_LOW]/*commit请求的写地址*/ );
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
        .BYTE_SIZE(WORD_SIZE)
    ) data_sram (
        // 0端口
        .clk0(clk),
        .rst_n0(rst_n),
        .addr0_i(pc[11 : DATA_ADDR_LOW]),
        .en0_i(!conflict),
        .we0_i('0),
        .wdata0_i('0),
        .rdata0_o(rdata0),
        // 1端口
        .clk1(clk),
        .rst_n1(rst_n),
        .addr1_i(refill_addr[11 : DATA_ADDR_LOW]),
        .en1_i('1),
        .we1_i(refill_we[i]),
        .wdata1_i(refill_data),
        .rdata1_o(rdata1)
    );
end  

// hit逻辑，比dcache简单得多
logic [WAY_NUM - 1 : 0] tag_hit;
for (genvar i = 0; i < WAY_NUM ; i++) begin
    assign tag_hit[i] = (tag_ans0[i].tag == ppn) | (b_f_pkg_q.mask == '0);
    assign cache_commit_resp.way_hit[i] = (tag_ans1[i].tag == trans_result_c.pa[31:12]);
end
assign cache_commit_resp.tlb_exception  = tlb_exception_c;

// uncache
// 根据实际情况选择向axi拿的数量

// b_f_pkg_q 逻辑
always_ff @(posedge clk) begin
    if (!rst_n || flush_i) begin // flush 问题解决了
        b_f_pkg_q <= '0;
    end else if (!stall && icache_decoder_sender.ready) begin
        b_f_pkg_q <= b_f_pkg  ;
    end else begin
        b_f_pkg_q <= b_f_pkg_q;
    end
end

// exception
logic          fetch_exception;
logic  [5:0]   exc_code;
logic  [31:0]  badv;
tlb_exception_t tlb_exception_tmp;

//fd_pkg
f_d_pkg_t f_d_pkg;
logic [1:0][31:0] insts, insts_q; //insts,传入后面的两条指令
always_comb begin
    f_d_pkg.insts   =  insts; //TODO
    f_d_pkg.pc      =  b_f_pkg_q.pc & 32'hfffffff8; //TODO ATTENTION:后面要分两个PC
    f_d_pkg.mask    =  b_f_pkg_q.mask;
    f_d_pkg.predict_infos = b_f_pkg_q.predict_infos;
    f_d_pkg.fetch_exc_info.fetch_exception = fetch_exception;
    f_d_pkg.fetch_exc_info.exc_code        = exc_code;
    f_d_pkg.fetch_exc_info.badv            = badv;
end
always_ff @(posedge clk) begin
    if (!rst_n) begin
        insts_q <= '0;
    end else begin
        insts_q <= insts;
    end
end
// TODO icache_decoder_sender.valid
// TODO fetch_icache_receiver.ready
assign icache_decoder_sender.data  = f_d_pkg;
assign icache_decoder_sender.valid = !stall & |f_d_pkg.mask & !flush_i;
assign fetch_icache_receiver.ready = !stall & icache_decoder_sender.ready;


assign tlb_exception_tmp = stall_q ? tlb_exception_q : tlb_exception;
assign fetch_exception   = (|tlb_exception_tmp.ecode) | (|b_f_pkg_q.pc[1:0]);
assign exc_code          = (|b_f_pkg_q.pc[1:0]) ? `_ECODE_ADEF : tlb_exception_tmp.ecode;
assign badv              = b_f_pkg_q.pc;

// fsm , NORMAL -> REFILL(ONLY AXI -> SRAM) -> FINISH -> NORMAL
// defination for axi handshake
// | addr_valid_o | addr_o |  data_len_o |
// |   axi_resp_ready_i    |
// |   axi_data_valid_i    |
// |   axi_data_i          |
//  try to use fifo to achieve the target ?
typedef enum logic [4:0] {
    F_NORMAL,
    F_UNCACHE,
    F_UNCACHE_S, // uncache握手成功
    F_MISS,      // 缺失
    F_MISS_S,    // miss握手成功
    F_CACOP,
    F_STALL
} fsm_state;

fsm_state fsm_cur, fsm_next;
logic [4:0] req_num, req_ptr, req_num_q, req_ptr_q; 
logic [1:0][31:0] temp_data_block, temp_data_block_q;
logic [DATA_DEPTH - 1:0]  refill_way, refill_way_q; 

always_ff @(posedge clk) begin
    if (!rst_n) begin
        fsm_cur <= F_NORMAL;
        req_num_q <= '0;
        req_ptr_q <= '0;
        temp_data_block_q <= '0;
        refill_way_q <= '0;
    end else begin
        fsm_cur <= fsm_next;
        req_num_q <= req_num;
        req_ptr_q <= req_ptr;
        temp_data_block_q <= temp_data_block;
        refill_way_q <= refill_way;
    end
end

// addr延时一拍
logic [31:0] cacop_bvaddr;
always_ff @(posedge clk) begin
    if(!rst_n) begin
        cacop_bvaddr <= '0;
    end else begin
        cacop_bvaddr <= commit_icache_req.addr;
    end
end

logic [31:0] addr_q;
logic [7 :0] data_len_q;
always_ff @(posedge clk) begin
    if (!rst_n) begin
        addr_q <= '0;
        data_len_q <= '0;
    end else begin
        addr_q <= addr_o;
        data_len_q <= data_len_o;
    end
end

always_comb begin
    stall    = stall_q;
    cacop_stall = cacop_stall_q;
    fsm_next = fsm_cur;
    req_num  = req_num_q;
    req_ptr  = req_ptr_q;
    insts    = insts_q;
    refill_way = refill_way_q;
    temp_data_block = temp_data_block_q;
    refill_addr     = refill_addr_q;
    refill_data     = refill_data_q;
    refill_tag      = '0;
    refill_we       = '0;
    refill_tag_we   = '0;
    commit_cache_req = '0;
    icache_cacop_flush_o = '0;
    icache_cacop_tlb_exc = '0;
    addr_o          = addr_q;
    addr_valid_o    = '0;
    data_len_o      = data_len_q;
    commit_resp_valid_o  = '0;
    icache_cacop_bvaddr  = '0;
    case(fsm_cur) 
        F_NORMAL:begin
            temp_data_block = '0;
            refill_we       = '0;
            insts = !icache_decoder_sender.ready ? insts_q : tag_hit[0] ? data_ans0[0] : data_ans0[1];
            stall = '0; // 解除stall状态
            if (b_f_pkg_q.mask == '0) begin
                stall = '0;
                fsm_next = F_NORMAL;
            end
            else if (commit_req_valid_i) begin
                case(commit_icache_req.cache_op)
                    0, 1: begin
                        commit_cache_req.addr[11:TAG_ADDR_LOW] = commit_icache_req.addr[11:TAG_ADDR_LOW];
                        commit_cache_req.way_choose            = commit_icache_req.addr[0] ? 2'b10 : 2'b01;
                        commit_cache_req.tag_data              = '0;
                        commit_cache_req.tag_we                = '1;
                        icache_cacop_flush_o                   = 2'b10;
                        commit_resp_valid_o                    = '1;
                    end
                    2: begin
                        commit_cache_req.addr[11:TAG_ADDR_LOW] = commit_icache_req.addr[11:TAG_ADDR_LOW];
                        commit_cache_req.way_choose            = '0;
                        commit_cache_req.tag_data              = '0;
                        commit_cache_req.tag_we                = '0;
                        fsm_next                               = F_CACOP;
                        cacop_stall                            = '1;
                    end
                    default : begin
                    end
                endcase
            end else if (!(|tag_hit)) begin
                stall |= '1; // 阻塞
                fsm_next = F_MISS;
                req_num  = 8;
                req_ptr  = 0;
                // TODO 请求地址和valid_o
                addr_o    = paddr & 32'hffffffe0; // 块对齐，一个块8个字
                addr_valid_o = '1;
                data_len_o   = {3'b0, req_num[4:0]};
                if (axi_resp_ready_i) begin
                    fsm_next = F_MISS_S;
                    temp_data_block = '0;
                end
            end else if (uncache) begin
                stall |= '1;
                fsm_next = F_UNCACHE;
                req_num  = b_f_pkg_q.mask[1] ? 2 : b_f_pkg_q.mask[0] ? 1 : 0; 
                req_ptr  = (b_f_pkg_q.mask == 2'b10) ? 1 : 0;
                // TODO 请求地址和valid_o，默认传入pc最后三位为0
                addr_o    = b_f_pkg_q.mask[0] ? paddr : (paddr | 32'h00000004);
                addr_valid_o = '1;
                data_len_o   = (b_f_pkg_q.mask == 2'b11) ? 8'd2 : (|b_f_pkg_q.mask) ? 8'd1 : 8'd0;
                if (axi_resp_ready_i) begin
                    fsm_next = F_UNCACHE_S;
                    temp_data_block = '0;
                end
            end else if (!icache_decoder_sender.ready) begin
                fsm_next = F_STALL;
            end
        end
        F_UNCACHE:begin
            // 如果axi握手成功，axi_resp_ready_i
            addr_valid_o = '1;
            if (axi_resp_ready_i) begin
                fsm_next = F_UNCACHE_S;
                // req_ptr  = '0;
                temp_data_block = '0;
                // TODO 关闭请求
            end
        end
        F_UNCACHE_S:begin
            // 如果已经满了 req_ptr == req_num
            if (req_ptr_q == req_num) begin
                stall    = '0;
                req_ptr  = '0;
                req_num  = '0;
                if (!icache_decoder_sender.ready) begin
                    fsm_next = F_STALL;
                end else begin
                    fsm_next = F_NORMAL;
                end
                insts    = temp_data_block;
            end
            // 等待数据,axi_data_i
            else if (axi_data_valid_i) begin
                // TODO data in
                temp_data_block[req_ptr_q[0]] = axi_data_i;
                req_ptr  = req_ptr_q + 1;
            end
        end
        F_MISS:begin
            // 如果axi握手成功，axi_resp_ready_i
            addr_valid_o = '1;
            if (axi_resp_ready_i) begin
                fsm_next = F_MISS_S;
                req_ptr  = '0;
                temp_data_block = '0;
                // TODO 关闭请求
            end
        end
        F_MISS_S:begin
            // 如果已经满了 req_ptr == req_num
            if (req_ptr_q == req_num) begin
                stall    = '0;
                req_ptr  = '0;
                req_num  = '0;
                if (!icache_decoder_sender.ready) begin
                    fsm_next = F_STALL;
                end else begin
                    fsm_next = F_NORMAL;
                end
                // refill对应位改路
                refill_way[paddr_q[11:5]] = !refill_way_q[paddr_q[11:5]];       
            end
            // 等待数据,axi_data_i
            else if (axi_data_valid_i) begin
                // TODO data in
                temp_data_block[req_ptr_q[0]] = axi_data_i;
                // refill TODO
                req_ptr = req_ptr_q + 1;
                if (!req_ptr[0] && (req_ptr[2:1] == b_f_pkg_q.pc[4:3] + 'd1)) begin
                    insts = temp_data_block;
                end
                if (!req_ptr[0]) begin
                    // TODO 写入
                    refill_addr      =  (paddr_q & 32'hffffffe0) | ((req_ptr - 'd2) << 2);
                    refill_data      =  temp_data_block;
                    refill_we        =  refill_way[paddr_q[11:5]] ? 2'b10 : 2'b01;
                    refill_tag.tag   =  paddr_q[31:12];
                    refill_tag.d     =  '0;
                    refill_tag.v     =  '1;
                    refill_tag_we    =  refill_we;
                end
            end
        end
        F_CACOP: begin
            fsm_next = F_NORMAL;
            commit_resp_valid_o  = '1;
            if (cache_commit_resp.tlb_exception.ecode != '0) begin
                icache_cacop_flush_o                   = 2'b01;
                icache_cacop_tlb_exc                   = cache_commit_resp.tlb_exception;
                icache_cacop_bvaddr                    = cacop_bvaddr;
            end else if (|cache_commit_resp.way_hit) begin
                commit_cache_req.addr[11:TAG_ADDR_LOW] = cacop_bvaddr[11:TAG_ADDR_LOW];
                commit_cache_req.way_choose            = cache_commit_resp.way_hit;
                commit_cache_req.tag_data              = '0;
                commit_cache_req.tag_we                = '1;
                icache_cacop_flush_o                   = 2'b10;  
            end else begin
                icache_cacop_flush_o                   = 2'b10;
                cacop_stall                            = '0;
            end
        end
        F_STALL: begin
            if (!icache_decoder_sender.ready) begin
                fsm_next = F_STALL;
            end else begin
                fsm_next = F_NORMAL;
            end
        end
        default:begin
            stall = '0;
            fsm_next = F_NORMAL;
        end
    endcase
end

endmodule
