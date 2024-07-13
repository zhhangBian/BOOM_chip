`include "a_defines.svh"

typedef struct packed {
    logic r_valid; // 指令有效
    // 写寄存器相关控制信息
    logic   w_reg;   // 要写寄存器
    rob_id_t rob_id;   // rob_id
    word_t w_data;   // 写的数据


} cdb_info_t;

module cdb #(
    parameter int PORT_COUNT = 4
) (
    input   logic clk,
    input   logic rst_n,
    input   logic flush,
    // input   cdb_info_t [PORT_COUNT - 1:0] cdb_data_i,
    // input   logic      [PORT_COUNT - 1:0] ready_i,
    handshake_if.receiver    fifo_handshake[PORT_COUNT - 1 : 0],
    // output  cdb_info_t [PORT_COUNT - 1:0] cdb_data_o,
    // 分奇偶传输，仅保留两路
    output  cdb_info_t [1:0] cdb_data_o
);

cdb_info_t [PORT_COUNT - 1 : 0] cdb_data_i;
cdb_info_t [             1 : 0] cdb_data_sel;
always_comb begin
    for (genvar i = 0; i < PORT_COUNT; i++) begin
        cdb_data_i[i] = fifo_handshake[i].data; //传输握手数据
        fifo_handshake[i].ready = sel_cdb[0][i] | sel_cdb[1][i];
    end
end

logic [1 : 0][PORT_COUNT - 1 : 0] sel_cdb;

// PORT_PTR从0到3分别是：ALU0，ALU1，MDU，LSU
always_comb begin
    sel_cdb = '0;
    cdb_data_sel = '0;
    for (genvar arb = 0; arb < 2 ; arb++) begin
        for (genvar i = PORT_COUNT - 1; i >= 0; i++) begin
            if (cdb_data_i[i].rob_id[0] == arb && cdb_data_i[i].r_valid && fifo_handshake[i].valid) begin
                sel_cdb[arb]      = '0;
                sel_cdb[arb][i]  |=  1;
                cdb_data_sel[arb] = '0;
                cdb_data_sel[arb] = cdb_data_i[i];
            end
        end
    end
end

always_ff @(posedge clk) begin
    for (genvar i = 0; i < 2; i++) begin
        cdb_data_o[i] <= cdb_data_sel[i];
    end
end




endmodule