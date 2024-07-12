`include "a_structure.svh"
`include "a_iq_defines.svh"

module lsu_iq # (
    // 设置IQ共有4个表项
    parameter int IQ_SIZE = 4,
    parameter int AGING_LENGTH = 4
)(
    input   logic           clk,
    input   logic           rst_n,
    input   logic           flush,

    // 控制信息
    input   logic [1:0]     choose,
    input   decode_info_t [1:0] p_di_i,
    input   data_t [1:0]    p_data_i,
    input   logic [1:0]     p_valid_i,
    // IQ的ready含义是队列未满，可以继续接收指令
    output  logic           iq_ready_o,

    input   data_t [1:0]    cdb_i,
    output  iq_cdb_t        cdb_o,

    input   data_t [1:0]    wkup_data_i,
    output  data_t [1:0]    wkup_data_o,

    output  data_t          result_o,
    output  logic           jump_o,

    // 后续的FIFO是否ready
    input   logic           fifo_ready
);

logic excute_ready;                 // 是否发射指令：对于单个IQ而言
logic excute_valid, excute_valid_q; // E级执行的FU是否有效
logic [IQ_SIZE - 1:0] ready_q;     // 对应的表项是否可发射
logic [IQ_SIZE - 1:0] select_q;    // 指令是否发射
logic [IQ_SIZE - 1:0] init_q;      // 是否填入表项
logic [IQ_SIZE - 1:0] empty_q;     // 对应的表项是否空闲

// ------------------------------------------------------------------
// 选择发射的指令
// 根据AGING选择指令
localparam int half_IQ_SIZE = IQ_SIZE / 2;
// 对应的aging位
logic [IQ_SIZE - 1:0][AGING_LENGTH - 1:0]   aging_q;
// 目前只处理了IQ为4的情况
logic [half_IQ_SIZE:0][$bits(IQ_SIZE):0]    aging_select_1;
// 选择出发射的指令：一定ready
logic [$bits(IQ_SIZE):0]                    aging_select;

always_comb begin
    aging_select_1[0] = ({ready_q[1], aging_q[1]} > {ready_q[1], aging_q[0]}) ? 1 : 0;
    aging_select_1[1] = ({ready_q[3], aging_q[3]} > {ready_q[2], aging_q[2]}) ? 3 : 2;
    // 根据aging选出发射的指令
    aging_select = ({ready_q[aging_select_1[0]], aging_q[aging_select_1[0]]} >
                    {ready_q[aging_select_1[1]], aging_q[aging_select_1[1]]}) ?
                    aging_select_1[0] : aging_select_1[1];
    // 给发射的指令置位
    select_q = '0;
    select_q[aging_select] |= ready_q[aging_select];
end

// AGING的移位逻辑
always_ff @(posedge clk) begin
    for(integer i = 0; i < IQ_SIZE; i += 1) begin
        if(select_q[i]) begin
            aging_q[i] <= '0;
        end
        else begin
            if(ready_q[i]) begin
                aging_q[i] <= (aging_q[i] == (1 << (AGING_LENGTH - 1))) ? aging_q[i] : (aging_q[i] == 0) ? '1 : (aging_q[i] << 1);
            end
            else begin
                aging_q[i] <= '0;
            end
        end
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 更新iq_ready信号
logic [$bits(IQ_SIZE):0] free_cnt;
logic [$bits(IQ_SIZE):0] free_cnt_q;

always_comb begin
    free_cnt = free_cnt_q - p_valid_i + (excute_ready & excute_valid);
    iq_ready_o = (free_cnt >= 1);
end

always_ff @(posedge clk) begin
    if(!rst_n || flush) begin
        free_cnt_q <= 4;
    end
    else begin
        free_cnt_q <= free_cnt;
    end
end

always_comb begin
    for(genvar  i = 0; i < IQ_SIZE; i += 1) begin
        init_q[i] = empty_q[i] ? '1 : '0;
    end
end

always_ff @(posedge clk) begin
    if(!rst_n || flush) begin
        empty_q <= '0;
    end
    else begin
        for(integer i = 0; i < IQ_SIZE; i += 1) begin
            if(select_q[i]) begin
                empty_q[i] <= '1;
            end
        end
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 生成执行信号
assign excute_valid = |ready_q;
assign excute_ready = (!excute_valid_q) | fifo_ready_q;

always_ff @(clk) begin
    if(!rst_n || flush) begin
        excute_valid_q <= '0;
    end
    else begin
        if(excute_ready) begin
            excute_valid_q <= excute_valid;
        end
        else begin
            if(excute_valid_q & fifo_ready_q) begin
                excute_valid_q <= '0;
            end
        end
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 创建IQ表项

// 转发后的数据
word_t [1:0] real_data;
word_t [IQ_SIZE - 1:0][1:0] iq_data;
decode_info_t [IQ_SIZE - 1:0] iq_di;
logic [IQ_SIZE - 1:0][1:0][1:0] wkup_src;

for(genvar i = 0; i < IQ_SIZE; i += 1) begin
    wire init_by;
    assign init_by = init_q[i] & p_valid_i;

    iq_entry # ()(
        .clk,
        .rst_n,
        .flush,

        .select_i(select_q[i] & excute_ready),
        .init_i(|init_by),
        .data_i(p_data_i),
        .di_i(p_di_i),

        .wkup_data_i(wkup_data_i),
        .cdb_i(cdb_i),

        .ready_o(ready_q[i]),

        .wkup_select_o(wkup_src[i]),
        .data_o(iq_data[i]),
        .di_o(iq_di[i])
    );
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 填入发射指令所需的执行信息：下一个周期填入执行单元
decode_info_t    select_di, select_di_q;
word_t [1:0]     select_data, select_data_q;
logic [1:0][1:0] select_wkup_src;
logic wkup_valid_o;
rob_id_t wkup_reg_id;

always_ff @(posedge clk) begin
    if(excute_ready) begin
        select_di_q <= select_di;
    end
end

always_comb begin
    select_di       = '0;
    select_data     = '0;
    select_wkup_src = '0;
    wkup_valid_o    = '0,
    wkup_reg_id     = '0;

    for(genvar i = 0; i < IQ_SIZE; i += 1) begin
        // 如果发射对应指令
        if(select_q[i]) begin
            select_di       |= iq_di[i];
            select_data     |= iq_data[i];
            select_wkup_src |= wkup_src[i];
            wkup_valid_o    |= excute_ready;
            wkup_reg_id     |= iq_di[i].reg_id;
        end
    end
end

// 将数据打一拍送入元件
always_ff @(posedge clk) begin
    if(excute_ready) begin
        select_di_q     <= select_di;
        select_data_q   <= select_data;
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------

// 匹配给DCache的接口即可

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

endmodule