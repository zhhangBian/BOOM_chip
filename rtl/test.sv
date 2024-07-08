`include "a_defines.svh"

module boom_top #(
    parameter type T = logic[31:0]
); (
    input clk,
    input rst_n
);

type T1 = logic[31:0];
handshake_if #(.T(T1)) handshake_interface ();
fifo #(
    .DATA_WIDTH(32),
    .DEPTH(4)
) my_fifo (
    .clk,
    .rst_n,

);

type T2 = d_r_pkg_t;
handshake_if #(.T(T2)) d_r_handshake_interface ();
type T3 



endmodule