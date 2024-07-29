`include "a_defines.svh"

module mdu (
    input   wire    clk,
    input   wire    rst_n,
    input   wire    flush,

    // 需要的操作数
    input   mdu_i_t         req_i,
    input   decode_info_t   di_i,
    output  mdu_o_t         res_o,
    output  decode_info_t   di_o,
    output  word_t [1:0]    data_s_o,

    input   logic   valid_i,
    output  logic   ready_o,
    output  logic   valid_o,
    input   logic   ready_i
);

mdu_o_t mul_res_o, div_res_o;
word_t [1:0] data_s;
logic mul_valid_i, div_valid_i;
logic mul_valid_o, div_valid_o;
logic mul_ready_o, div_ready_o;

mdu_muler muler(
    .clk,
    .rst_n,
    .flush,

    .req_i(req_i),
    .res_o(mul_res_o),

    .valid_i(mul_valid_i),
    .ready_o(mul_ready_o),
    .valid_o(mul_valid_o),
    .ready_i(ready_i)
);

mdu_diver diver(
    .clk,
    .rst_n,
    .flush,

    .req_i(req_i),
    .res_o(div_res_o),

    .valid_i(div_valid_i),
    .ready_o(div_ready_o),
    .valid_o(div_valid_o),
    .ready_i(ready_i)
);

logic [2:0] op_q;
logic is_wait;

assign mul_valid_i = valid_i & 
                    (req_i.op == `_MDU_MUL || req_i.op == `_MDU_MULH || req_i.op == `_MDU_MULHU);
assign div_valid_i = valid_i & 
                    ~(req_i.op == `_MDU_MUL || req_i.op == `_MDU_MULH || req_i.op == `_MDU_MULHU);

assign res_o = (op_q == `_MDU_MUL || op_q == `_MDU_MULH || op_q == `_MDU_MULHU) ?
                mul_res_o : div_res_o;

assign data_s_o = data_s;

assign ready_o = ((~is_wait) || (is_wait & valid_o)) & ready_i;

assign valid_o = (op_q == `_MDU_MUL || op_q == `_MDU_MULH || op_q == `_MDU_MULHU) ?
                mul_valid_o : div_valid_o;

decode_info_t di_q;
assign di_o = di_q;
always_ff @(posedge clk) begin
    if(~rst_n || flush) begin
        di_q <= 0;
        data_s <= '0;
    end
    else if(valid_i && ready_o) begin
        di_q <= di_i;
        data_s <= req_i.data;
    end
    else begin
        di_q <= di_q;
        data_s <= data_s;
    end
end

always_ff @(posedge clk) begin
    if(~rst_n || flush) begin
        op_q <= '0;
    end
    else if(ready_o) begin
        op_q <= req_i.op;
    end
    else begin
        op_q <= op_q;
    end
end

always_ff @(posedge clk) begin
    if(~rst_n || flush) begin
        is_wait <= '0;
    end
    else begin
        if(is_wait) begin
            if(valid_o) begin
                is_wait <= valid_i;
            end
            else begin
                is_wait <= is_wait;
            end
        end
        else begin
            if(valid_i) begin
                is_wait <= '1;
            end
            else begin
                is_wait <= '0;
            end
        end
    end
end

endmodule
