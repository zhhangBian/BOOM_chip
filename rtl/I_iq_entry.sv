`include "a_structure.svh"

// 将IQ分为了静态信息和动态信息
// IQ_entry的表项
// | data0 | ready0 | data1 | ready1 | valid（指令） | di |

module iq_entry # (
    parameter int REG_COUNT  = 2,
    parameter int CDB_COUNT  = 2,
    parameter int WKUP_COUNT = 2
)(
    input logic     clk,
    input logic     rst_n,
    input logic     flush,

    // 指令被发射标记
    input   logic   select_i,

    // 新的指令加入标记
    input   logic   init_i,
    // 新指令的输入数据
    input   word_t  [REG_COUNT - 1:0] data_i,
    input   rob_id_t[REG_COUNT - 1:0] data_reg_id_i,
    input   logic   [REG_COUNT - 1:0] data_valid_i,
    // 新指令的控制数据
    input   decode_info_t di_i,

    // 背靠背唤醒
    input   word_t  [WKUP_COUNT - 1:0] wkup_data_i,
    input   rob_id_t[WKUP_COUNT - 1:0] wkup_reg_id_i,
    input   logic   [WKUP_COUNT - 1:0] wkup_valid_i,
    // CDB数据前递
    input   word_t  [CDB_COUNT - 1:0] cdb_data_i,
    input   rob_id_t[CDB_COUNT - 1:0] cdb_reg_id_i,
    input   logic   [CDB_COUNT - 1:0] cdb_valid_i,

    // 指令数据就绪，可以发射
    output  logic   ready_o,

    // 唤醒数据源
    output  logic   [REG_COUNT - 1:0][WKUP_COUNT - 1:0] wkup_hit_q_o,
    output  word_t  [REG_COUNT - 1:0] data_o,
    output  decode_info_t di_o,
);

// ------------------------------------------------------------------
// 定义变量
// 保存的表项数据
word_t  [REG_COUNT - 1:0]   entry_data;
rob_id_t[REG_COUNT - 1:0]   entry_reg_id;
logic   [REG_COUNT - 1:0]   data_ready, data_ready_q;
logic                       entry_valid;
decode_info_t               entry_di;

// 第i个reg是否hit了第j个CDB
logic [REG_COUNT - 1:0][CDB_COUNT - 1:0]    cdb_hit;
// 获得第i个reg的结果
word_t [REG_COUNT - 1:0]                    cdb_result;

// 第i个reg是否hit了第j个wkup：需要打两排等待结果
logic [REG_COUNT - 1:0][WKUP_COUNT - 1:0]   wkup_hit;
logic [REG_COUNT - 1:0][WKUP_COUNT - 1:0]   wkup_hit_q;
logic [REG_COUNT - 1:0][WKUP_COUNT - 1:0]   wkup_hit_qq;
// 获得第i个reg的结果
word_t [REG_COUNT - 1:0]                    wkup_result;

// 没有准备好的数据都有相应的转发
assign ready_o = &(data_ready_q | wkup_hit_qq);
assign di_o = di;
for(genvar i = 0; i < REG_COUNT; i += 1) begin
    always_comb begin
        // 打两排以后数据来了
        data_o[i] = |wkup_hit_qq[i] ? wkup_result[i] : entry_data[i];
    end
end
assign wkup_hit_q_o = wkup_hit_q;
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 处理数据的更新逻辑
always_ff @(posedge clk) begin
    if(~rst_n || flush) begin
        entry_valid     <= '0;
    end
    else if begin
        if(init_i) begin
            entry_valid <= '1;
        end
        else if(select_i) begin
            entry_valid <= '0;
        end
    end
end

// 静态数据仅可以在最初更新
// 对于动态数据的更新
// 1. 数据更新：包含指令一开始加入
// 2. CDB前递
// 3. 选中时的唤醒
always_ff @(posedge clk) begin
    if(~rst_n || flush) begin
        entry_di <= '0;
    end
    else if(init_i) begin
        entry_di <= di_i;
    end
end

// 更新数据
for(integer i = 0; i < REG_COUNT; i += 1) begin
    always_ff @(posedge clk) begin
        if(~rst_n || flush) begin
            entry_data[i]   <= '0;
        end
        else if(init_i) begin
            entry_data[i]   <= data_i[i];
        end
        else if(|cdb_hit[i]) begin
            entry_data[i]   <= cdb_result[i];
        end
        else if(|wkup_hit_qq[i]) begin
            entry_data[i]   <= wkup_result[i];
        end
    end
end

always_ff @(posedge clk) begin
    if(~rst_n || flush) begin
        entry_ready_q <= '0;
    end
    else begin
        entry_ready_q <= entry_ready;
    end
end

for (genvar i = 0; i < REG_COUNT; i += 1) begin
    // 组合逻辑生成下一周期数据有效信息
    always_comb begin
        data_ready[i] = data_ready_q[i];

        if(init_i) begin
            data_ready[i] = data_valid_i[i];
        end
        else if(select_i) begin
            if(entry_valid) begin
                data_ready[i] = '0;
            end
        end
        else begin
            if(((|cdb_hit[i]) | (wkup_hit[i])) & entry_valid) begin
                data_ready[i] = '1;
            end
        end
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 生成wkup数据
for(integer i = 0; i < REG_COUNT; i += 1) begin
    always_comb begin
        wkup_hit = '0;
        wkup_result[i] = '0;

        for(genvar j = 0; j < WKUP_COUNT; j += 1) begin
            wkup_hit[i][j] |= (wkup_reg_id_i[j] == entry_reg_id[i]) &
                              wkup_valid_i[j].valid &
                              entry_valid &
                              !data_ready_q[i];
        end
    end
end

always_comb begin
    wkup_result = '0;
    for(integer i = 0; i < REG_COUNT; i += 1) begin
        for(integer j = 0; j < WKUP_COUNT; j += 1) begin
            wkup_result[i] |= wkup_hit_qq[i][j] ? wkup_data_i[j] : '0;
        end
    end
end

// wkup等待两拍后唤醒
for (integer i = 0; i < REG_COUNT; i++) begin
    always_ff @(posedge clk) begin
        if(~rst_n || flush) begin
            wkup_hit_q[i]   <= '0;
            wkup_hit_qq[i]  <= '0;
        end
        else if(select_i) begin
            wkup_hit_q[i]   <= '0;
            wkup_hit_qq[i]  <= '0;
        end
        else begin
            wkup_hit_q[i]   <= wkup_hit[i];
            wkup_hit_qq[i]  <= wkup_hit_q[i];
        end
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 生成CDB数据
for(integer i = 0; i < REG_COUNT; i += 1) begin
    always_comb begin
        cdb_hit[i] = '0;
        cdb_result[i] = '0;

        for(genvar j = 0; j < CDB_COUNT; j += 1) begin
            cdb_hit[i][j] = (cdb_reg_id_i[j] == entry_reg_id[i]) &
                            cdb_valid_i[i] &
                            (~data_ready[i]);

            cdb_result[i] |= cdb_hit[i][j] ? cdb_data_i[j] : '0;
        end
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

endmodule