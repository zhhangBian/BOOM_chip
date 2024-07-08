`include "a_defines.svh"

module rename_rat #(
    parameter int unsigned DATA_WIDTH = 7,
    parameter int unsigned DEPTH = 32,
    parameter int unsigned R_PORT_COUNT = 4,
    parameter int unsigned REGISTERS_FILE_TYPE = 0, // optional: 0:ff, 1:latch
    parameter bit NEED_RESET = 1,
    parameter logic[DEPTH-1:0][DATA_WIDTH-1:0] RESET_VAL = '0,
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

    for(genvar r = 0 ; r < 2 ; r += 1) begin
        assign rdata_o[r] = rdata[r];
    end
    // FORWARD
    assign rdata_o[2] = equal1? wdata_i[0] : rdata[2];
    assign rdata_o[3] = equal2? wdata_i[0] : rdata[3];

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
        assign rdata[i] = regfiles[raddr_i[i]];
    end

endmodule
