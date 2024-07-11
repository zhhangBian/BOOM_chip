`include "a_iq_defines.svh"

// 用于统一在 IQ发射时做数据前递的工作
module data_forward #() (
    input logic clk,
    input logic rst_n,
    input logic flush,

    input logic ready_i,

    input logic [1:0][1:0] wkup_src_i,
    input word_t [1:0] data_i,

    input word_t [1:0] wkup_data_i,
    output word_t [1:0] data_o
);

logic [1:0][1:0] wkup_src_q;
word_t [1:0] data_q;

always_ff @(posedge clk) begin
    if(ready_i) begin
        wkup_src_q <= wkup_src_i;
        data_q <= data_i;
    end
    else begin
        wkup_src_q <= '0;
        data_q <= data_o;
    end
end

always_comb begin
    for(genvar i = 0; i < 2; i += 1) begin
        data_o[i] = (|(wkup_src_q[i])) ? '0 : data_q[i];
        for(integer j = 0 ; j < 2 ; j += 1) begin
            data_o[i] |= wkup_src_q[i][j] ? wkup_data_i[i][j] : '0;
        end
    end
    
end

endmodule
