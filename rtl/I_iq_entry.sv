`include "a_structure.svh"

// 将IQ分为了静态信息和动态信息

module iq_entry # (
    // 设置IQ共有8个表项
    parameter int CDB_COUNT = 2,
    parameter int IQ_SIZE = 8;
)(
    input logic clk,
    input logic rst_n,
    input logic flush,

    // input 相应的控制信息
    input logic [1:0]       wkup_valid_i,
    input rob_id_t [1:0]    wkup_rid_i,
    input word_t [1:0]      wkup_data_i,
    input word_t            static_i,

    output logic            wkup_valid_o,
    output rob_id_t [1:0]   wkup_rid_o,
    output word_t [1:0]     wkup_data_o,
    output word_t           static_o
);

localparam int RREG_CNT = 2;
logic [RREG_CNT-1:0] value_ready;
// 当前指令是否有效
wire valid_inst;

always_ff @(posedge clk) begin
    ready_o <= &(value_ready | ready_mask_i);
    data_ready_o <= value_ready;
end

// 生成静态部分
iq_entry_static iq_entry_static (
    .clk,
    .rst_n,
    .flush,

    .sel_i(sel_i),
    .updata_i(updata_i),

    .static_i(static_i),
    .static_o(static_o),
    .valid_inst_o(valid_inst)
);

// 生成动态捕获部分
for(genvar i = 0 ; i < RREG_CNT ; i += 1) begin
    iq_entry_data # (
        .CDB_COUNT(CDB_COUNT)
    ) iq_entry_data (
        .clk,
        .rst_n,
        .flush,

        .sel_i(sel_i),
        .updata_i(updata_i),
        .valid_inst_i(valid_inst),

        .data_valid_i(data_i.valid[i]),
        .data_rid_i(data_i.rreg[i]),
        .data_i(data_i.rdata[i]),

        .wkup_valid_i(wkup_valid_i[i]),
        .wkup_rid_i(wkup_rid_i[i]),
        .wkup_data_i(wkup_data_i[i]),

        .cdb_i(cdb_i),
        .value_ready_o(value_ready[i]),

        .wkup_sel_o(wkup_sel_o[i]),
        .data_o(data_o[i])
    );
end

endmodule