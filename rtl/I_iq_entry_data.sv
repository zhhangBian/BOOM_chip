`include "a_structure.svh"
`include "a_iq_defines.svh"

module iq_entry_data # (
    parameter int CDB_COUNT = 2,
    parameter int WAKEUP_SRC_CNT = 2
)(
    input logic clk,
    input logic rst_n,
    input logic flush,

    // 原先存储的指令被发射
    input logic sel_i,
    // 更新存储的指令
    input logic update_i,
    input logic valid_inst_i,

    input logic         data_valid_i,
    input rob_id_t      wreg_id_i,
    input word_t        data_i,

    // 背靠背唤醒
    // 这里的发射是随机发射
    input logic     [WAKEUP_SRC_CNT-1:0] wkup_valid_i,
    // 唤醒指令对应的id
    input rob_id_t  [WAKEUP_SRC_CNT-1:0] wkup_wreg_id_i,
    input logic     [WAKEUP_SRC_CNT-1:0][31:0] wkup_data_i,

    // CDB 数据前递
    input cdb_issue_info_t [CDB_COUNT-1:0] cdb_i,
    // 指令数据 已获得 或 可被转发
    output logic  value_ready_o,

    // 唤醒数据源
    output logic  [WAKEUP_SRC_CNT-1:0] wkup_sel_o,
    output word_t data_o
);

// 存储的信息：实际也就是CDB传递进来的信息
// 记录数据
word_t data_q;
// 记录数据是否ready
logic data_ready_q;
// 记录的目的寄存器
rob_id_t wreg_id_q;

logic [WAKEUP_SRC_CNT-1:0] wkup_sel_q;
assign wkup_sel_o = wkup_sel_q;
assign data_o = (|wkup_sel_q) ? wkup_sel_result : data_q;

always_ff @(posedge clk) begin
    if(update_i) begin
        data_q <= data_i;
    end
    else if(cdb_forward) begin
        data_q <= cdb_result;
    end
    else if(|wkup_sel_q) begin
        data_q <= wkup_sel_result;
    end
end

// 组合逻辑信号
logic   [CDB_COUNT-1:0] cdb_hit;
logic   cdb_forward;
word_t  cdb_result;

logic   [WAKEUP_SRC_CNT-1:0] wkup_hit;
logic   wkup_forward;
logic   word_t wkup_sel_result;

always_comb begin
    wkup_sel_result = '0;
    for(integer i = 0 ; i < WAKEUP_SRC_CNT ; i += 1) begin
        wkup_sel_result |= wkup_sel_q[i] ? wkup_data_i[i] : '0;
    end
end

// 监听CDB上的数据
assign cdb_forward = (|cdb_hit) & (!data_ready_q);
always_comb begin
    cdb_result = '0;
    for(genvar i = 0 ; i < 2 ; i++) begin
        cdb_hit[i] = (j[0] == wreg_id_q[0]) && cdb_i[i].valid &&
                    (cdb_i[i].wreg_id == wreg_id_q);
        cdb_result |= cdb_hit[i] ? cdb_i[i].data : '0;
    end
end

// 更新逻辑
always_ff @(posedge clk) begin
    if(sel_i) begin
        wkup_sel_q <= '0;
    end
    else begin
        wkup_sel_q <= wkup_hit;
    end
end

always_ff @(posedge clk) begin
    if(update_i) begin
        data_ready_q <= data_valid_i;
        wreg_id_q <= wreg_id_i;
    end
    else if(cdb_forward | wkup_forward) begin
        data_ready_q <= '1;
    end
end

// 背靠背唤醒机制
assign wkup_forward = |wkup_hit;
for(genvar j = 0 ; j < WAKEUP_SRC_CNT ; j++) begin
    assign wkup_hit[j] = valid_inst_i && (!data_ready_q) && wkup_valid_i[j] && 
                        (wkup_wreg_id_i[j] == wreg_id_q);
end

// 组合逻辑生成下一周期数据有效信息
always_comb begin
    value_ready_o = '0;
    if(valid_inst_i) begin
        value_ready_o = data_ready_q;

        if(update_i) begin
            value_ready_o = data_valid_i;
        end
        else if(sel_i) begin
            value_ready_o = '0;
        end
        else begin
            if(cdb_forward | wkup_forward) begin
                value_ready_o = '1;
            end
        end
    end
    else begin
        if(update_i) begin
            value_ready_o = data_valid_i;
        end
    end
end

endmodule