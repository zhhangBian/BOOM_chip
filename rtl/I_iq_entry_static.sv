`include "a_structure.svh"
`include "a_iq_defines.svh"

module iq_entry_static(
    input logic clk,
    input logic rst_n,
    input logic flush,

    // 指令被发射标记
    input logic sel_i,
    // 新的指令加入标记
    input logic updata_i,
    // 新存储的静态数据
    input word_t static_i,
    // 原先存储的静态数据
    output word_t static_o,
    // IQ项目有效
    output logic valid_inst_o
);

// 标记 IQ Entry 中存储的是一条有效的指令
logic valid_inst_q;
// 存储原先的控制信息
word_t static_q;

assign static_o = static_q;
assign valid_inst_o = valid_inst_q;
assign empty_o = ~valid_inst_o;

always_ff @(posedge clk) begin
    if(~rst_n) begin
        valid_inst_q <= '0;
    end
    else begin
        if(updata_i) begin
            valid_inst_q <= '1;
        end
        else if(sel_i) begin
            valid_inst_q <= '0;
        end
    end
end

always_ff @(posedge clk) begin
    if(updata_i) begin
        static_q <= static_i;
    end
end

endmodule