`include "a_structure.svh"
`include "a_iq_defines.svh"

module iq_entry_static #(
    parameter int PAYLOAD_SIZE = 32
)(
    input logic clk,
    input logic rst_n,
    input logic flush,

    // 指令被发射标记
    input logic sel_i,
    // 新的指令加入标记
    input logic updata_i,
    // 新指令的控制数据
    input logic [PAYLOAD_SIZE-1:0] payload_i,


    output logic [PAYLOAD_SIZE-1:0] payload_o,
    output logic valid_inst_o,
    // IQ 项目有效
    output logic empty_o
);

// 标记 IQ Entry 中存储的是一条有效的指令
logic valid_inst_q, empty_inst_q;
logic [PAYLOAD_SIZE-1:0] payload_q;

assign empty_o = empty_inst_q;
assign valid_inst_o = valid_inst_q;
assign payload_o = payload_q;

always_ff @(posedge clk) begin
    if(~rst_n) begin
        valid_inst_q <= '0;
        empty_inst_q <= '1;
    end
    else begin
        if(updata_i) begin
            valid_inst_q <= '1;
            empty_inst_q <= '0;
        end
        else if(sel_i) begin
            valid_inst_q <= '0;
            empty_inst_q <= '1;
        end
    end
end

always_ff @(posedge clk) begin
    if(updata_i) begin
        payload_q <= payload_i;
    end
end

endmodule