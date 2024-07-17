`include "a_defines.svh"

// store buffer entry
/*
    |   target addr   |  write data  |  wstrb  |  valid  |
in: |     addr        |     data     |   strb  |    1    |
out:|     addr        |     data     |   strb  |    1    |
    valid    : 有没有表项占用
*/

module storebuffer #(
    parameter int unsigned SB_SIZE = 4, //默认大小为4，后续配置可更改
    parameter int unsigned SB_DEPTH_LEN = $clog2(SB_SIZE)
) (
    input   clk,
    input   rst_n,
    input   flush_i,
    output  sb_entry_t [SB_SIZE - 1 : 0] sb_entry_o, //按照从旧到新的顺序
    output  sb_stall,
    // output  sb_entry_t                   top_entry_o,
    handshake_if.receiver  sb_entry_receiver,
    handshake_if.sender    sb_entry_sender
);

// handshake_if #(.T(sb_entry_t)) sb_entry_sender ();

logic [SB_DEPTH_LEN - 1 : 0] sb_ptr_head  ,   sb_ptr_tail  ;
logic [SB_DEPTH_LEN - 1 : 0] sb_ptr_head_q,   sb_ptr_tail_q;
logic [SB_DEPTH_LEN     : 0] sb_cnt       ,   sb_cnt_q;

logic push, pop;

assign push = sb_entry_receiver.ready & sb_entry_receiver.valid & !flush_i;
assign pop  = sb_entry_sender.ready   & sb_entry_sender.valid;
assign sb_stall = (sb_cnt == SB_SIZE);
always_comb begin
    sb_cnt      = sb_cnt_q + push - pop;
    sb_ptr_head = sb_ptr_head_q + push;
    sb_ptr_tail = sb_ptr_tail_q + pop;
end

always_ff @(posedge clk) begin
    if (!rst_n || flush_i) begin
        sb_ptr_head_q <= '0;
        sb_ptr_tail_q <= '0;
        sb_cnt_q  <= '0;
    end else begin
        sb_cnt_q <= sb_cnt;
        sb_ptr_head_q <= sb_ptr_head;
        sb_ptr_tail_q <= sb_ptr_tail;
    end
end

// 例化storebuffer_entry

sb_entry_t [SB_SIZE - 1 : 0] sb_entry_inst;
sb_entry_t                   sb_entry_in;

// assign top_entry_o = sb_entry_inst[sb_ptr_head_q - '1];
always_comb begin
    for (integer i = 0; i < SB_SIZE; i++) begin
        sb_entry_o[i] = sb_entry_inst[i[SB_DEPTH_LEN - 1:0] + sb_ptr_tail_q];
    end
end

assign sb_entry_in = sb_entry_receiver.data;
assign sb_entry_sender.data = sb_entry_inst[sb_ptr_tail_q];

always_ff @(posedge clk) begin
    for (integer i = 0; i < SB_SIZE; i++) begin
        if (!rst_n || flush_i) begin
            sb_entry_inst[i] <= '0;
        end else begin
            if ((i[SB_DEPTH_LEN - 1 : 0] == sb_ptr_head_q) & push) begin
                sb_entry_inst[i] <= sb_entry_in;
            end else if ((i[SB_DEPTH_LEN - 1 : 0] == sb_ptr_tail_q) & pop) begin
                sb_entry_inst[i].valid  <= 0;
            end
        end
    end
end

assign sb_entry_receiver.ready = (sb_cnt_q < SB_SIZE);
assign sb_entry_sender.valid   = sb_entry_inst[sb_ptr_tail_q].valid; 


endmodule