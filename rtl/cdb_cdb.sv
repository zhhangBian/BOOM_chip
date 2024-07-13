

module cdb #(
    parameter int PORT_COUNT = 4
) (
    input   logic clk,
    input   logic rst_n,
    input   logic flush,

    input   word_t [PORT_COUNT - 1:0] cdb_data_i,
    input   logic [PORT_COUNT - 1:0] ready_i,
    
    output  word_t [PORT_COUNT - 1:0] cdb_data_o,
    // 分奇偶传输，仅保留两路
    output  logic [1:0] cdb_data_o
);



endmodule