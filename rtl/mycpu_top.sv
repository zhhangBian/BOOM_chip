`include "a_defines.svh"

module mycpu_top (
    input clk,
    input rst_n,

    // other axi interface
);

logic g_flush; // wire, 全局 flush 信号

/*============================== Branch Predicting ==============================*/

handshake_if #(predict_info_t) b_fifo_handshake();

bpu bpu_inst(
    .clk(clk),
    .rst_n(rst_n),
    .g_flush(g_flush),

    .correct_info_i(/* TODO: correct info from backend */),
    .sender(b_fifo_handshake.sender)
);

handshake_if #(predict_info_t) fifo_f_handshake();

// 实际上是一个 skidbuf
basic_fifo #(
    .DEPTH(1),
    .BYPASS(1),
    .T(predict_info_t)
) b_f_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .receiver(b_fifo_handshake.receiver),
    .sender(fifo_f_handshake.sender)
);

/*============================== Inst Fetch ==============================*/

handshake_if #(f_d_pkg_t) f_fifo_handshake();

f_fetch fetch_inst(
    .receiver(fifo_f_handshake.receiver),
    .sender(f_fifo_handshake.sender)
)

/*============================== Decoder ==============================*/

// decode 前的队列
basic_fifo #(
    .DEPTH(`D_BEFORE_QUEUE_DEPTH),
    .BYPASS(0), // 不允许 bypass ，因为这个 fifo 也充当了 d 级的流水寄存器。
    .T(f_d_pkg_t)
) f_fifo_inst (
    .clk(clk),
    .rst_n(rst_n),
    .receiver(f_fifo_handshake.receiver),
    .sender(fifo_d_handshake.sender)
)

handshake_if #(.T(d_r_pkg_t)) d_fifo_handshake();

// decoder 是纯组合逻辑的，其流水寄存器是前面的FIFO
decoder decoder_inst(
    .receiver(fifo_d_handshake.receiver),
    .sender(d_fifo_handshake.sender)
)

handshake_if #(.T(d_r_pkg_t)) fifo_r_handshake();

// decoder 后的队列

basic_fifo #(
    .DEPTH(`D_AFTER_QUEUE_DEPTH),
    .BYPASS(0), // 不允许 BYPASS ，充当前后端之间的流水寄存器
    .T(d_r_pkd_t)
) fifo_r_inst (
    .clk(clk),
    .rst_n(rst_n),
    .receiver(d_fifo_handshake.receiver),
    .sender(fifo_r_handshake.sender)
);

endmodule