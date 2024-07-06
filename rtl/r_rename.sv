`include "a_define.h"

module r_rename #(
    parameter int unsigned DEPTH = 32,
    parameter int unsigned ADDR_DEPTH   = (DEPTH > 1) ? $clog2(DEPTH) : 1
) (
    input  clk,
    input  rst_n,   
    // R级输入
    handshake_if.receiver d_r_receiver, // 和D级的握手接口
    // data 包含 D 级传入的控制信息，我们要用到的是 读寄存器和写寄存器的 id
    // R级输出
    handshake_if.sender   r_p_sender,   // 和P级的握手接口
    // data 包含 R 级已经读取的ARF的数据及有效性，以及读出 ARF的id在RAT中的映射结果及有效性
    // C级信号
    input  c_flush_i,
    output c_flush_ack_o,
    // ……
);



// RAT表的实现
registers_file_banked # (
    .DATA_WIDTH(6),
    .DEPTH(32),
    .R_PORT_COUNT(4), // CHANGEABLE
    .W_PORT_COUNT(2), // CHANGEABLE
    .NEED_RESET(1),
    .NEED_FORWARD(0)
)
r_rename_table (
    .clk(clk),
    .rst_n(rst_n && !c_flush_i),
    .raddr_i(r_rarid_i),
    .rdata_o(r_rename_result),
    .waddr_i(r_warid_i),
    .we_i(r_issue & {{(|r_warid_i[1])}, {(|r_warid_i[0])}}),
    .wdata_i(r_rename_new)
);

endmodule