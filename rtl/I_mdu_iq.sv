`include "a_structure.svh"
`include "a_iq_defines.svh"

module mdu_iq # (
    // 设置IQ共有8个表项
    parameter int IQ_SIZE = 8,
    parameter int AGING_LENGTH = 4
)(
    input logic clk,
    input logic rst_n,
    input logic flush,

);


endmodule