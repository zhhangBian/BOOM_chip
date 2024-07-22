`include "a_defines.svh"

// 用于统一在 IQ发射时等待唤醒的数据一拍
module data_wkup #(
    parameter int REG_COUNT = 2,
    parameter int WKUP_COUNT = 2
) (
    input   logic   clk,
    input   logic   rst_n,
    input   logic   flush,

    // 指令是否发射
    input   logic   ready_i,
    // 指令的操作数
    input   word_t  [REG_COUNT - 1:0]   data_i,

    input   logic   [REG_COUNT - 1:0][WKUP_COUNT - 1:0] wkup_hit_q_i,
    input   word_t  [WKUP_COUNT - 1:0]  wkup_data_i,

    output  word_t  [REG_COUNT - 1:0]   real_data_o
);

logic   [REG_COUNT - 1:0][WKUP_COUNT - 1:0] wkup_hit_qq;
word_t  [REG_COUNT - 1:0] data_q;

always_ff @(posedge clk) begin
    if(ready_i) begin
        wkup_hit_qq <= wkup_hit_q_i;
        data_q <= data_i;
    end
    else begin
        wkup_hit_qq <= '0;
        data_q <= real_data_o;
    end
end

always_comb begin
    for(integer i = 0; i < REG_COUNT - 1; i += 1) begin
        real_data_o[i] = (|(wkup_hit_qq[i])) ? '0 : data_q[i];

        for(integer j = 0 ; j < WKUP_COUNT - 1 ; j += 1) begin
            real_data_o[i] |= wkup_hit_qq[i][j] ? wkup_data_i[i][j] : '0;
        end
    end
end

endmodule
