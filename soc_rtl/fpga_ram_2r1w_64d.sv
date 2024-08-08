`include "a_defines.svh"
module fpga_ram_2r1w_64d#(
    parameter int WIDTH = 32
)( 
    input                          clk,
    input  [5 : 0] addr0,
    input  [5 : 0] addr1,
    input  [5 : 0] addrw,
    output [WIDTH - 1:0]           dout0,
    output [WIDTH - 1:0]           dout1,
    input  [WIDTH - 1:0]           din,
    input                          wea
);

for(genvar i = 0 ; i < WIDTH; i++) begin : gen_qpram
    qpram_64x1 qpram_inst(
        .CLK(clk),
        .CEN(1'b1), 
        .WEN(wea),
        .A0(addr0),
        .A1(addr1),
        .AW(addrw),
        .DI(  din[i]),
        .Q0(dout0[i]),
        .Q1(dout1[i])
    );
end

endmodule
