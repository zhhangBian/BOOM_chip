`include "a_defines.svh"

module arf #(
    parameter int unsigned DATA_WIDTH = 32,
    parameter int unsigned DEPTH = 32,
    parameter int unsigned R_PORT_COUNT = 4,
    parameter int unsigned REGISTERS_FILE_TYPE = 0, // optional: 0:ff, 1:latch
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
    if(REGISTERS_FILE_TYPE == 0) begin
        registers_file_ff_tp #(
            .DATA_WIDTH(DATA_WIDTH),
            .DEPTH(DEPTH),
            .NEED_RESET(NEED_RESET),
            .RESET_VAL(RESET_VAL)
        ) regcore_ff (
            `_WIRED_GENERAL_CONN,
            .waddr_i,
            .we_i,
            .wdata_i,
            // outport
            .regfiles_o(regfiles)
        );
    end

    // Read port generation
    for(genvar i = 0 ; i < R_PORT_COUNT ; i++) begin
        assign rdata_o[i] = (NEED_FORWARD && we_i[1] && raddr_i[i] == waddr_i[1]) ? wdata_i[1] : 
                            (NEED_FORWARD && we_i[0] && raddr_i[i] == waddr_i[0]) ? wdata_i[0] :
                                               regfiles[raddr_i[i]];
    end

endmodule
