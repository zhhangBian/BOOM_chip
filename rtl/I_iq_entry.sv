`include "a_structure.svh"

// 将IQ分为了静态信息和动态信息

module iq_entry # ()(
    input logic clk,
    input logic rst_n,
    input logic flush,

    // 指令被发射标记
    input logic sel_i,

    // 新的指令加入标记
    input logic updata_i,
    // 新指令的输入数据
    input data_t [1:0] data_i,
    // 新指令的控制数据
    input decode_info_t di_i,

    // 背靠背唤醒
    input data_t [1:0] wkup_data_i,

    // CDB 数据前递
    input data_t [1:0] cdb_i,
    // IQ 项目有效
    output logic  data_ready_o, 
    // 指令数据就绪，可以发射
    output logic  ready_o, 

    // 唤醒数据源
    output logic  [1:0][1:0] wkup_sel_o,
    output word_t [1:0] data_o,
    output decode_info_t di_o,
);

logic [1:0] value_ready;
logic [1:0] wkup_sel;

always_ff @(posedge clk) begin
    ready_o <= &(value_ready);
    data_ready_o <= value_ready;
end

iq_entry_t entry_data;
assign di_o = entry_data.di;
assign data_o = (|wkup_sel) ? wkup_sel_result : {entry_data.data[0], entry_data.data[1]};

always_ff @(posedge clk) begin
    if(~rst_n) begin
        entry_data <= '0;
    end
    else if begin
        if(updata_i) begin
            entry_data.valid_inst_inst <= '1;
        end
        else if(sel_i) begin
            entry_data.valid_inst_inst <= '0;
        end
    end
end

logic [1:0] data_ready_q;
logic [1:0] data_ready;

logic [1:0][1:0] cdb_hit;
logic [1:0] cdb_forward;
word_t [1:0] cdb_result;

logic [1:0][1:0] wkup_hit;
logic [1:0] wkup_forward;
word_t [1:0] wkup_result;

logic [1:0][1:0] wkup_sel_q;

// 处理数据的更新逻辑
// 静态数据仅可以在最初更新
// 对于动态数据的更新
// 1. 数据更新：包含指令一开始加入
// 2. CDB前递
// 3. 选中时的唤醒
always_ff @(posedge clk) begin
    if(updata_i) begin
        data_entry.di <= di_i;
        data_entry.data[0] <= data_i.data[0];
        data_entry.data[1] <= data_i.data[1];
    end
    else if(|cdb_forward) begin
        data_entry.data[0] <= cdb_forward[0] ? cdb_result[0] : data_entry.data[0];
        data_entry.data[1] <= cdb_forward[1] ? cdb_result[1] : data_entry.data[1];
    end
    else if(wkup_data_i[0].valid || wkup_data_i[1].valid) begin
        data_entry.data[0] <= wkup_data_i[0].valid ? wkup_data_i[0].data : data_entry.data[0];
        data_entry.data[1] <= wkup_data_i[1].valid ? wkup_data_i[1].data : data_entry.data[1];
    end
end

// 处理相应的信号逻辑

for (genvar i = 0; i < 2; i += 1) begin
    always_comb begin
        wkup_result[i] = '0;
        for(genvar j = 0; j < 2; j += 1) begin
            wkup_result[i] |= wkup_sel_q[j] ? wkup_data_i[j] : '0;
        end
    end

    assign cdb_forward[i] = (|(cdb_hit[i])) & (!data_ready[i]);
    always_comb begin
        cdb_result[i] = '0;
        for(genvar j = 0; j < 2; i += 1) begin
            cdb_hit[i][j] = (j[0] == 
                entry_data[i].reg_id[i][0]) && 
                cdb_i[j].valid && 
                (cdb_i[j].wreg_id == entry_data[i].reg_id[i]);
            cdb_result[i] |= cdb_hit[i][j] ? cdb_i[i].data[j] : '0;
        end
    end

    // 更新逻辑
    always_ff @(posedge clk) begin
        if(sel_i) begin
            wkup_sel_q[i] <= '0;
        end
        else begin
            wkup_sel_q[i] <= wkup_hit[i];
        end
    end

    always_ff @(posedge clk) begin
        if(update_i) begin
            data_ready_q[i] <= data_i[i].valid;
            entry_data.data[i].wreg_id <= data_i[i].wreg_id;
        end
        else if(cdb_forward[i] | wkup_forward[i]) begin
            data_ready_q[i] <= '1;
        end
    end

    // 背靠背唤醒机制
    assign wkup_forward[i] = |(wkup_hit[i]);
    for(genvar j = 0 ; j < 2 ; j += 1) begin
        assign wkup_hit[i][j] = 
            entry_data.valid_inst && 
            !data_ready_q[i] && 
            wkup_data_i[j].valid &&
            (wkup_data_i[j].wreg_id == wreg_id_q);
    end

    // 组合逻辑生成下一周期数据有效信息
    always_comb begin
        value_ready_o[i] = '0;
        if(entry_data.valid_inst) begin
            value_ready_o[i] = data_ready_q;

            if(update_i) begin
                value_ready_o[i] = entry_data.data[i].valid;
            end
            else if(sel_i) begin
                value_ready_o[i] = '0;
            end
            else begin
                if(cdb_forward[i] | wkup_forward[i]) begin
                    value_ready_o[i] = '1;
                end
            end
        end
        else begin
            if(update_i) begin
                value_ready_o[i] = entry_data.data[i].valid;
            end
        end
    end
end

endmodule