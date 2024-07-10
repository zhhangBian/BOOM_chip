`include "a_defines.svh"

// store buffer entry
/*
    |   target addr   |  write data  |  wstrb  |  valid  |  commit  | complete  |
in: |     addr        |     data     |   strb  |    1    |     0    |     0     |
out:|     addr        |     data     |   strb  |    1    |     1    |     1     |
    valid    : 有没有表项占用
    commit   : 有没有提交
    complete : 有没有完成（后续优化）
*/

typedef struct packed {
    logic [31 : 0] target_addr;
    logic [31 : 0] write_data;
    logic [3  : 0] wstrb;
    logic          valid;
    logic          commit;
    // logic          complete;
} sb_entry_t;

module storebuffer #(
    parameter int unsigned SB_SIZE = 4, //默认大小为4，后续配置可更改
    parameter int unsigned SB_DEPTH_LEN = $clog2(SB_SIZE)
) (
    input   clk,
    input   rst_n,
    input   flush_i,

    input   logic [1 : 0] c_w_mem_i;

    output  logic [SB_DEPTH_LEN - 1 : 0] sb_num,

    handshake_if.receiver  sb_entry_receiver,

    handshake_if.sender    sb_fifo_entry_sender
)

handshake_if #(.T(sb_entry_t)) sb_entry_sender ();

logic [SB_DEPTH_LEN - 1 : 0] sb_ptr_head  ,   sb_ptr_tail  ;
logic [SB_DEPTH_LEN - 1 : 0] sb_ptr_head_q,   sb_ptr_tail_q;
logic [SB_DEPTH_LEN - 1 : 0] sb_cnt       ,   sb_cnt_q;
logic [SB_DEPTH_LEN - 1 : 0] sb_commit_cnt,   sb_commit_cnt_q ;

logic push, pop;

assign push = sb_entry_receiver.ready & sb_entry_receiver.valid;
assign pop  = sb_entry_sender.ready   & sb_entry_sender.valid;

always_comb begin
    sb_cnt      = sb_cnt_q + push - pop;
    sb_ptr_head = sb_ptr_head_q + push;
    sb_ptr_tail = sb_ptr_tail_q + pop;
    sb_num      = sb_ptr_head_q;
end

always_ff @(posedge clk) begin
    if (!rst_n || flush_i) begin
        sb_cnt_q  <= '0;
        sb_ptr_head_q <= sb_ptr_tail_q + sb_commit_cnt_q;
        // sb_ptr_tail_q <= '0;
        if (!rst_n) begin
            sb_commit_cnt_q <= '0;
            sb_ptr_head_q <= '0;
            sb_ptr_tail_q <= '0;
        end
    end else begin
        sb_cnt_q <= sb_cnt;
        sb_ptr_head_q <= sb_ptr_head;
        sb_ptr_tail_q <= sb_ptr_tail;
        sb_commit_cnt_q <= sb_commit_cnt;
    end
end

// 例化storebuffer_entry
sb_entry_t [SB_SIZE - 1 : 0] sb_entry_inst;
sb_entry_t                   sb_entry_in;

assign sb_entry_in = sb_entry_receiver.data;
assign sb_entry_sender.data = sb_entry_inst[sb_ptr_tail_q];

logic [1 : 0] w_mem;
assign w_mem = {c_w_mem_i[1] & c_w_mem_i[0] & sb_entry_inst[sb_ptr_tail_q + 1].valid, (c_w_mem_i[0] ^ c_w_mem_i[1]) & sb_entry_inst[sb_ptr_tail_q].valid};
assign sb_commit_cnt = sb_commit_cnt_q + w_mem[0] + w_mem[1] - pop;

always_ff @(posedge clk) begin
    for (genvar i = 0; i < SB_SIZE; i++) begin
        if (!rst_n || flush_i) begin
            if (!sb_entry_inst[i].commit) begin // 若已经提交，则不会被刷掉
                sb_entry_inst[i] <= '0;
            end
        end else begin
            if ((i[SB_DEPTH_LEN - 1 : 0] == sb_ptr_head_q) & push) begin
                sb_entry_inst[i] <= sb_entry_in;
            end else if ((i[SB_DEPTH_LEN - 1 : 0] == sb_ptr_tail_q) & w_mem[0]) begin
                sb_entry_inst[i].commit <= 1; 
            end else if ((i[SB_DEPTH_LEN - 1 : 0] == sb_ptr_tail_q + 1) & w_mem[1]) begin
                sb_entry_inst[i].commit <= 1;
            end else if ((i[SB_DEPTH_LEN - 1 : 0] == sb_ptr_tail_q) & pop) begin
                sb_entry_inst[i].commit <= 0;
                sb_entry_inst[i].valid  <= 0;
            end
        end
    end
end

assign sb_entry_receiver.ready = (sb_cnt_q < SB_SIZE);
assign sb_entry_sender.valid   = sb_entry_inst[sb_ptr_tail_q].valid & sb_entry_inst[sb_ptr_tail_q].commit; 


// sb的数据在commit之后会提交到fifo里面，fifo选择指令提交，若fifo暂时为空，则相当于通路。
fifo #(
    .DATA_WIDTH($bits(sb_entry_t)),
    .DEPTH(SB_SIZE),
    .BYPASS(1)
) sb_out_fifo (
    .clk,
    .rst_n,
    .receiver(sb_entry_sender.receiver),
    .sender(sb_fifo_entry_sender.sender)
)

endmodule