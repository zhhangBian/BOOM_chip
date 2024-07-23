`ifndef _BOOM_INTERFACE_HEAD
`define _BOOM_INTERFACE_HEAD

// 握手信号的Interface实现
interface handshake_if#(type T = logic[31:0]);
    logic ready, valid;
    T     data;
    modport sender (
        output data,
        input  ready,
        output valid
    );
    modport receiver (
        input  data,
        output ready,
        input  valid
    );
endinterface //handshake_if

`endif
