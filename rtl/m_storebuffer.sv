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

module storebuffer #(
    parameter int unsigned SB_SIZE = 4, //默认大小为4，后续配置可更改
    parameter int unsigned SB_DEPTH_LEN = $clog2(SB_SIZE)
) (
    input   clk,
    input   rst_n,
    input   flush_i,

    input   logic c_w_mem_i, //改成单条提交

    output  logic [SB_DEPTH_LEN - 1 : 0] sb_num,
    output  sb_entry_t [SB_SIZE - 1 : 0] sb_entry_o,
    output  logic [SB_DEPTH_LEN - 1 : 0] sb_oldest_ptr,

    handshake_if.receiver  sb_entry_receiver,

    handshake_if.sender    sb_entry_sender
);

// handshake_if #(.T(sb_entry_t)) sb_entry_sender ();

logic [SB_DEPTH_LEN - 1 : 0] sb_ptr_head  ,   sb_ptr_tail  ;
logic [SB_DEPTH_LEN - 1 : 0] sb_ptr_head_q,   sb_ptr_tail_q;
logic [SB_DEPTH_LEN - 1 : 0] sb_ptr_commit,   sb_ptr_commit_q;
logic [SB_DEPTH_LEN     : 0] sb_cnt       ,   sb_cnt_q;
logic [SB_DEPTH_LEN     : 0] sb_commit_cnt,   sb_commit_cnt_q ;

logic push, pop;
logic w_mem;

assign push = sb_entry_receiver.ready & sb_entry_receiver.valid & !flush_i;
assign pop  = sb_entry_sender.ready   & sb_entry_sender.valid;
assign sb_oldest_ptr = sb_ptr_tail_q;
always_comb begin
    sb_cnt      = sb_cnt_q + push - pop;
    sb_ptr_head = sb_ptr_head_q + push;
    sb_ptr_tail = sb_ptr_tail_q + pop;
    sb_num      = sb_ptr_head_q;
    sb_ptr_commit = sb_ptr_commit_q + w_mem;
end

always_ff @(posedge clk) begin
    if (!rst_n || flush_i) begin
        // sb_ptr_head_q <= sb_ptr_tail_q + sb_commit_cnt_q;
        // sb_ptr_tail_q <= '0;
        if (!rst_n) begin
            sb_ptr_commit_q <= '0;
            sb_commit_cnt_q <= '0;
            sb_ptr_head_q <= '0;
            sb_ptr_tail_q <= '0;
            sb_cnt_q  <= '0;
        end else begin 
            sb_ptr_head_q   <= sb_ptr_tail_q + sb_commit_cnt_q;
            sb_cnt_q        <= sb_commit_cnt;
            sb_commit_cnt_q <= sb_commit_cnt;
            sb_ptr_tail_q   <= sb_ptr_tail;
            sb_ptr_commit_q <= sb_ptr_commit_q;
        end
    end else begin
        sb_cnt_q <= sb_cnt;
        sb_ptr_head_q <= sb_ptr_head;
        sb_ptr_tail_q <= sb_ptr_tail;
        sb_commit_cnt_q <= sb_commit_cnt;
        sb_ptr_commit_q <= sb_ptr_commit;
    end
end

// 例化storebuffer_entry

sb_entry_t [SB_SIZE - 1 : 0] sb_entry_inst;
sb_entry_t                   sb_entry_in;

assign sb_entry_o = sb_entry_inst;
assign sb_entry_in = sb_entry_receiver.data;
assign sb_entry_sender.data = sb_entry_inst[sb_ptr_tail_q];


assign w_mem = c_w_mem_i & sb_entry_inst[sb_ptr_commit_q].valid & !flush_i;
assign sb_commit_cnt = sb_commit_cnt_q + w_mem - pop;

always_ff @(posedge clk) begin
    for (integer i = 0; i < SB_SIZE; i++) begin
        if (!rst_n || flush_i) begin
            if (!sb_entry_inst[i].commit) begin // 若已经提交，则不会被刷掉
                sb_entry_inst[i] <= '0;
            end
        end else begin
            if ((i[SB_DEPTH_LEN - 1 : 0] == sb_ptr_head_q) & push) begin
                sb_entry_inst[i] <= sb_entry_in;
            end else if ((i[SB_DEPTH_LEN - 1 : 0] == sb_ptr_commit_q) & w_mem) begin
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
// fifo #(
//     .DATA_WIDTH($bits(sb_entry_t)),
//     .DEPTH(SB_SIZE),
//     .BYPASS(1)
// ) sb_out_fifo (
//     .clk,
//     .rst_n,
//     .receiver(sb_entry_sender.receiver),
//     .sender(sb_fifo_entry_sender.sender)
// )

endmodule