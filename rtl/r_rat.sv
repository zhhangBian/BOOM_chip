`include "a_defines.svh"

module rat #(
    parameter int unsigned DATA_WIDTH = 7,
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

    // RPORT
    wire [R_PORT_COUNT-1:0][DATA_WIDTH-1:0] rdata;
    wire equal1, equal2; // 第二条指令的源寄存器与第一条指令的写寄存器是否相等
    assign equal1 = (raddr_i[2] == waddr_i[0]) & we_i[0];
    assign equal2 = (raddr_i[3] == waddr_i[0]) & we_i[0];

    for(genvar r = 0 ; r < R_PORT_COUNT/2 ; r += 1) begin
        assign rdata_o[r] = rdata[r];
    end
// FORWARD
    assign rdata_o[2] = equal1? wdata_i[0] : rdata[2];
    assign rdata_o[3] = equal2? wdata_i[0] : rdata[3];

    wire [DEPTH-1:0][DATA_WIDTH-1:0] regfiles;
    if(REGISTERS_FILE_TYPE == 0) begin
        registers_file_ff_tp #(
            .DATA_WIDTH(DATA_WIDTH),
            .DEPTH(DEPTH),
            .NEED_RESET(NEED_RESET),
            .RESET_VAL(RESET_VAL)
        ) regcore_ff (
            .clk,
            .rst_n,
            .waddr_i,
            .we_i,
            .wdata_i,
            // outport
            .regfiles_o(regfiles)
        );
    end

    // Read port generation
    for(genvar i = 0 ; i < R_PORT_COUNT ; i++) begin
        assign rdata[i] = regfiles[raddr_i[i]];
    end

endmodule
