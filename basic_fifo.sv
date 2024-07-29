// 这是一个通用FIFO模块
`include "a_defines.svh"

module fifo #(
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned DEPTH = 32,
    parameter int unsigned ADDR_DEPTH = (DEPTH > 1) ? $clog2(DEPTH) : 1,
    parameter bit BYPASS = 1,
    parameter type T = logic[DATA_WIDTH - 1 : 0]
)(
    input   logic         clk,
    input   logic         rst_n,
    handshake_if.receiver receiver,
    handshake_if.sender   sender
);

// 进出逻辑
logic  push;
logic  pop;

assign push = receiver.ready & receiver.valid;
assign pop  = sender.ready   & sender.valid  ;

// 更新逻辑
logic [ADDR_DEPTH - 1 : 0] wptr, rptr;
logic [ADDR_DEPTH     : 0] cnt;
logic                      empty;

logic [ADDR_DEPTH - 1 : 0] wptr_q, rptr_q;
logic [ADDR_DEPTH     : 0] cnt_q;
logic                      empty_q;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        wptr_q   <=   '0;
        rptr_q   <=   '0;
        cnt_q    <=   '0;
        empty_q  <=   '0;
    end else begin
        wptr_q   <=   wptr;
        rptr_q   <=   rptr;
        cnt_q    <=   cnt;
        empty_q  <=   empty;
    end
end
assign wptr  = push ? (wptr_q + 1'd1) : wptr_q;
assign rptr  = pop  ? (rptr_q + 1'd1) : rptr_q;
assign cnt   = cnt_q + push - pop;
assign empty = BYPASS & (cnt == '0);

// 握手信号
logic  ready_tmp, valid_tmp;
logic  ready_q  , valid_q; 

assign ready_tmp = cnt < DEPTH;
assign valid_tmp = cnt > '0;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        ready_q <= '0;
        valid_q <= '0;
    end else begin
        ready_q <= ready_tmp;
        valid_q <= valid_tmp;
    end
end

// 数据存储
T [DEPTH - 1 : 0] data;
T                 data_out;
T                 data_out_q;
// read
always_ff @(posedge clk) begin
    if (!rst_n) begin
        data_out_q <= '0;
    end else begin
        data_out_q <= data_out;
    end
end
assign  data_out  =  ((cnt_q == 0 && push) || (cnt_q == 1 && push && pop)) ? receiver.data : data[rptr];
// write
always_ff @(posedge clk) begin
    if (~rst_n) begin
        data <= '0;
    end
    else if (rst_n & push) begin
        data[wptr_q] <= receiver.data;
    end
end


// 连线逻辑
// receiver
assign  receiver.ready  =  ready_q;
// sender
assign  sender.valid    =  empty_q ? receiver.valid : valid_q;
assign  sender.data     =  empty_q ? receiver.data  : data_out_q;

endmodule
