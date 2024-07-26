`include "a_defines.svh"

module cdb #(
    parameter int PORT_COUNT = 4
) (
    input   logic clk,
    input   logic rst_n,
    input   logic flush,
    // input   cdb_info_t [PORT_COUNT - 1:0] cdb_data_i,
    // input   logic      [PORT_COUNT - 1:0] ready_i,
    handshake_if.receiver    fifo_handshake[PORT_COUNT],
    // output  cdb_info_t [PORT_COUNT - 1:0] cdb_data_o,
    // 分奇偶传输，仅保留两路
    output  cdb_info_t [1:0] cdb_data_o
);

cdb_info_t [PORT_COUNT - 1 : 0] cdb_data_i;
cdb_info_t [             1 : 0] cdb_data_sel;
logic [1 : 0][PORT_COUNT - 1 : 0] sel_cdb;
logic      [PORT_COUNT - 1 : 0] fifo_valid;

for (genvar i = 0; i < PORT_COUNT; i++) begin
    assign cdb_data_i[i]           = fifo_handshake[i].data; //传输握手数据
    assign fifo_handshake[i].ready = sel_cdb[0][i] | sel_cdb[1][i] | (!cdb_data_i[i].r_valid);
    assign fifo_valid[i]           = fifo_handshake[i].valid;
end

// PORT_PTR从0到3分别是：ALU0，ALU1，MDU，LSU
always_comb begin
    sel_cdb = '0;
    cdb_data_sel = '0;
    for (integer arb = 0; arb < 2 ; arb++) begin
        for (integer i = PORT_COUNT - 1; i >= 0; i--) begin
            if ((cdb_data_i[i].rob_id[0] == arb[0]) && (cdb_data_i[i].r_valid) && (fifo_valid[i])) begin
                sel_cdb[arb]       = '0;
                sel_cdb[arb][i]   |= '1;
                cdb_data_sel[arb]  = '0;
                cdb_data_sel[arb] |= cdb_data_i[i];
            end
        end
    end
end

always_ff @(posedge clk) begin
    for (integer i = 0; i < 2; i++) begin
        if (!rst_n | flush) begin
            cdb_data_o[i] <= '0;
        end else begin
            cdb_data_o[i] <= cdb_data_sel[i];
        end
    end
end

endmodule
