`include "a_defines.svh"

module f_fetch(
    input logic             clk,
    input logic             rst,
    input logic             g_flush,

    handshake_if.receiver   receiver, // predict_info_t type
    handshake_if.sender     sender
);
// TODO: 需要一个流水寄存器
predict_info_t in = receiver

icache icache_inst #(
    // TODO
) (
    // TODO
    .pc(receiver.data.pc),
    .mask(receiver.data.mask),

    .insts(f_insts)
);

// ICache只需要 PC ，只会将 PC 和 mask 存入流水寄存器中。还需要存储其他流水下来的指令信息(打一拍)
// 为了方便直接将 predict_info 流水下去先，在ICache得到数据之后对指令信息打包
predict_info_t f_predict_info_q;
logic valid_q;

always_ff @(clk) begin
    if ((!rst_n) | g_flush) begin
        f_predict_info_q <= '0;
        valid_q <= '0;
    end
    else if (sender.ready && |receiver.data.mask) begin
        f_predict_info_q <= receiver.data;
        valid_q <= receiver.valid;
    end
end

// output
f_d_pkg_t f_d_data;
assign f_d_data.predict_info = f_predict_info_q;
assign f_d_data.insts = f_insts;

assign sender.data = f_d_data;
assign sender.valid = // TODO

endmodule