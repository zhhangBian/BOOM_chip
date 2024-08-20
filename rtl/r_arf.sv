`include "a_defines.svh"

module arf #(
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned DEPTH = 32,
    parameter int unsigned R_PORT_COUNT = 4,
    parameter bit NEED_RESET = 1,
    parameter bit NEED_FORWARD = 0,
    parameter logic[DEPTH-1:0][DATA_WIDTH-1:0] RESET_VAL = '0,
    // DO NOT MODIFY
    parameter type T = logic[DATA_WIDTH - 1 : 0],
    parameter int unsigned ADDR_DEPTH   = (DEPTH > 1) ? $clog2(DEPTH) : 1
)(
    input    clk,
    input    rst_n,
    input    [R_PORT_COUNT-1:0][ADDR_DEPTH-1:0] raddr_i,
    output T [R_PORT_COUNT-1:0]                 rdata_o,

    input    [1:0][ADDR_DEPTH-1:0] waddr_i,
    input    [1:0]                    we_i,
    input  T [1:0]                 wdata_i
);

    wire [DEPTH-1:0][DATA_WIDTH-1:0] regfiles;
    reg  [DEPTH-1:0][DATA_WIDTH-1:0] regfiles_q;
    assign regfiles = regfiles_q;

    // 这里全部使用ff作为寄存器文件，后续可以改成distributed RAM，但是bank的逻辑有点奇怪？
    for(genvar i = 0 ; i < DEPTH ; i += 1) begin
        always_ff @(posedge clk) begin
            if(NEED_RESET && ~rst_n) begin
                regfiles_q[i] <= RESET_VAL[i];
            end else if(we_i[1] && waddr_i[1] == i[ADDR_DEPTH-1:0]) begin
                regfiles_q[i] <= wdata_i[1];
            end else if(we_i[0] && waddr_i[0] == i[ADDR_DEPTH-1:0]) begin
                regfiles_q[i] <= wdata_i[0];
            end
        end
    end

    // Read port generation
    for(genvar i = 0 ; i < R_PORT_COUNT ; i++) begin
        assign rdata_o[i] = (NEED_FORWARD && we_i[1] && raddr_i[i] == waddr_i[1]) ? wdata_i[1] : 
                            (NEED_FORWARD && we_i[0] && raddr_i[i] == waddr_i[0]) ? wdata_i[0] :
                            regfiles[raddr_i[i]];
    end

endmodule
