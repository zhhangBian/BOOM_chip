`include "a_structure.svh"

// 将IQ分为了静态信息和动态信息
// IQ_entry的表项
// | data0 | ready0 | data1 | ready1 | valid（指令） | di |

module iq_entry # ()(
    input logic clk,
    input logic rst_n,
    input logic flush,

    // 指令被发射标记
    input logic select_i,

    // 新的指令加入标记
    input logic init_i,
    // 新指令的输入数据
    input data_t [1:0] data_i,
    // 新指令的控制数据
    input decode_info_t di_i,

    // 背靠背唤醒
    input data_t [1:0] wkup_data_i,
    // CDB 数据前递
    input data_t [1:0] cdb_i,

    // 指令的data已经Ready
    output logic [1:0]  data_ready_o,
    // 指令数据就绪，可以发射
    output logic  ready_o,

    // 唤醒数据源
    output logic  [1:0][1:0] wkup_select_o,
    output word_t [1:0] data_o,
    output decode_info_t di_o,
);

// 指令中的数据是否已经就绪
logic [1:0] data_ready_q;
logic [1:0] data_ready;

// 是否进行CDB前递
logic [1:0] cdb_forward;
// 第i个data是否hit了第j个CDB
logic [1:0][1:0] cdb_hit;
// 获得的data结果
word_t [1:0] cdb_result;

// 是否进行wkup
logic [1:0] wkup_forward;
// 第i个data是否hit了第j个wkup
logic [1:0][1:0] wkup_hit;
// 获得的data结果
word_t [1:0] wkup_result;
// wkup是否被选中
logic [1:0][1:0] wkup_select;
// 打一拍等结果
logic [1:0][1:0] wkup_select_q;


assign wkup_select_o = wkup_select;

always_ff @(posedge clk) begin
    ready_o <= &data_ready;
    data_ready_o <= data_ready;
end

iq_entry_t entry_data;

always_ff @(posedge clk) begin
    if(~rst_n) begin
        entry_data <= '0;
    end
    else if begin
        if(updata_i) begin
            entry_data.valid_inst_inst <= '1;
        end
        else if(select_i) begin
            entry_data.valid_inst_inst <= '0;
        end
    end
end

assign di_o = entry_data.di;
for(genvar i = 0; i < 2; i += 1) begin
    always_comb begin
        data_o[i] = (|(wkup_select[i])) ? wkup_result[i] : entry_data.data[i];
    end
end

// ------------------------------------------------------------------
// 处理数据的更新逻辑
// 静态数据仅可以在最初更新
// 对于动态数据的更新
// 1. 数据更新：包含指令一开始加入
// 2. CDB前递
// 3. 选中时的唤醒
always_ff @(posedge clk) begin
    if(updata_i) begin
        data_entry.di <= di_i;
        data_entry.data [0] <= data_i.data[0];
        data_entry.ready[0] <= '1;
        data_entry.data [1] <= data_i.data[1];
        data_entry.ready[1] <= '1;
    end
    else if(|cdb_forward) begin
        data_entry.data [0] <= cdb_forward[0] ? cdb_result[0] : data_entry.data[0];
        data_entry.ready[0] <= '1;
        data_entry.data [1] <= cdb_forward[1] ? cdb_result[1] : data_entry.data[1];
        data_entry.ready[1] <= '1;
    end
    else if(|wkup_forward) begin
        data_entry.data [0] <= wkup_forward[0] ? wkup_result[0] : data_entry.data[0];
        data_entry.ready[0] <= '1;
        data_entry.data [1] <= wkup_forward[1] ? wkup_result[1] : data_entry.data[1];
        data_entry.ready[1] <= '1;
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 生成相应的数据
for (genvar i = 0; i < 2; i += 1) begin
    // ------------------------------------------------------------------
    // 组合逻辑生成下一周期数据有效信息
    always_comb begin
        data_ready_o[i] = '0;

        if(init_i) begin
            data_ready_o[i] = entry_data.data[i].valid;
        end
        else if(select_i) begin
            if(entry_data.valid_inst) begin
                data_ready_o[i] = '0;
            end
        end
        else begin
            if((cdb_forward[i] | wkup_forward[i]) & entry_data.valid_inst) begin
                data_ready_o[i] = '1;
            end
        end
    end
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
end

for(genvar i = 0; i < 2; i += 1) begin
    // ------------------------------------------------------------------
    // 生成wkup数据
    assign wkup_forward[i] = |(wkup_hit[i]);
    always_comb begin
        wkup_result[i] = '0;
        for(genvar j = 0; j < 2; j += 1) begin
            wkup_hit[i][j] = (wkup_data_i[j].wreg_id == wreg_id_q) &
                            entry_data.valid_inst &
                            !data_ready_q[i] &
                            wkup_data_i[j].valid;
            wkup_result[i] |= wkup_select_q[i][j] ? wkup_data_i[j] : '0;
        end
    end

    always_ff @(posedge clk) begin
        if(select_i) begin
            wkup_select[i]     <= '0;
            wkup_select_q[i]   <= '0;
        end
        else begin
            wkup_select[i]     <= wkup_hit[i];
            wkup_select_q[i]   <= wkup_select[i];
        end
    end
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    // ------------------------------------------------------------------
    // 生成CDB逻辑：要求数据还没准备好
    assign cdb_forward[i] = (|(cdb_hit[i])) & (!data_ready[i]);
    always_comb begin
        cdb_result[i] = '0;
        // 监听CDB上的数据
        for(genvar j = 0; j < 2; i += 1) begin
            cdb_hit[i][j] = (cdb_i[j].wreg_id == entry_data[i].reg_id[i]) &
                            (j[0] == entry_data[i].reg_id[i][0]) &
                            cdb_i[j].valid;
            cdb_result[i] |= cdb_hit[i][j] ? cdb_i[i].data[j] : '0;
        end
    end
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
end

endmodule