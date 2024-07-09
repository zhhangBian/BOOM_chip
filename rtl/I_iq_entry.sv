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

    input logic [1:0]   wkup_valid_i,
    input rob_id [1:0]  wkup_rid_i,
    input logic [1:0][31:0] wkup_data_i,

    output logic wkup_valid_o,
    output rob_id [1:0] wkup_rid_o,
    output logic [1:0][31:0] wkup_data_o
);


// 生成静态部分
wire valid_inst;
iq_entry_static # (
    .PAYLOAD_SIZE(PAYLOAD_SIZE)
) iq_entry_static_inst (
    .clk,
    .rst_n,

    .sel_i(sel_i),
    .updata_i(updata_i),

    .payload_i(payload_i),
    .payload_o(payload_o),
    .valid_inst_o(valid_inst),
    .empty_o(empty_o)
);

// 生成动态捕获部分
logic [RREG_CNT-1:0] value_ready;
for(genvar i = 0 ; i < RREG_CNT ; i += 1) begin
    iq_entry_data # (
        .CDB_COUNT(CDB_COUNT),
        .WAKEUP_SRC_CNT(WAKEUP_SRC_CNT)
    ) iq_entry_data_inst (
        `_GENERAL_CONN,
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

always_ff @(posedge clk) begin
    ready_o <= &(value_ready | ready_mask_i);
    data_ready_o <= value_ready;
end

endmodule