`include "a_defines.svh"

`ifdef _VERILATOR
module core_top (
    input    [ 7:0] intrpt,
`endif
`ifdef _FPGA
module mycpu_top (
    input    [ 7:0] ext_int, 
`endif
    // other axi interface
    input           aclk,
    input           aresetn,
    //AXI interface 
    //read reqest
    output   [ 3:0] arid,
    output   [31:0] araddr,
    output   [ 7:0] arlen,
    output   [ 2:0] arsize,
    output   [ 1:0] arburst,
    output   [ 1:0] arlock,
    output   [ 3:0] arcache,
    output   [ 2:0] arprot,
    output          arvalid,
    input           arready,
    //read back
    input    [ 3:0] rid,
    input    [31:0] rdata,
    input    [ 1:0] rresp,
    input           rlast,
    input           rvalid,
    output          rready,
    //write request
    output   [ 3:0] awid,
    output   [31:0] awaddr,
    output   [ 7:0] awlen,
    output   [ 2:0] awsize,
    output   [ 1:0] awburst,
    output   [ 1:0] awlock,
    output   [ 3:0] awcache,
    output   [ 2:0] awprot,
    output          awvalid,
    input           awready,
    //write data
    output   [ 3:0] wid, // TODO: axi-crossbar 没有 wid
    output   [31:0] wdata,
    output   [ 3:0] wstrb,
    output          wlast,
    output          wvalid,
    input           wready,
    //write back
    input    [ 3:0] bid,
    input    [ 1:0] bresp,
    input           bvalid,
    output          bready,

    //debug
    input           break_point,
    input           infor_flag,
    input  [ 4:0]   reg_num,
    output          ws_valid,
    output [31:0]   rf_rdata,

`ifdef _VERILATOR
    // chiplab 的接口
    output [31:0] debug0_wb_pc,
    output [ 3:0] debug0_wb_rf_wen,
    output [ 4:0] debug0_wb_rf_wnum,
    output [31:0] debug0_wb_rf_wdata,
    output [31:0] debug0_wb_inst
`endif
`ifdef _FPGA
    // 官方发布包接口
    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_we, // !!!注意这里不是 wen
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
    // ,output [31:0] debug_wb_inst // 官方包不会使用到这个接口
`endif
);

logic g_flush; // wire, 全局 flush 信号

/*============================== Branch Predicting ==============================*/

handshake_if #(b_f_pkg_t) b_fifo_handshake();

bpu bpu_inst(
    .clk(clk),
    .rst_n(rst_n),
    .g_flush(g_flush),

    .correct_info_i(/* TODO: correct info from backend */),
    .sender(b_fifo_handshake.sender)
);

handshake_if #(b_f_pkg_t) fifo_f_handshake();

// 实际上是一个 skidbuf
basic_fifo #(
    .DEPTH(1),
    .BYPASS(1),
    .T(b_f_pkg_t)
) b_f_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .receiver(b_fifo_handshake.receiver),
    .sender(fifo_f_handshake.sender)
);

/*============================== Inst Fetch ==============================*/

handshake_if #(f_d_pkg_t) f_fifo_handshake();

i_cache i_cache_inst(
    .fetch_icache_receiver(fifo_f_handshake.receiver),
    .icache_decoder_sender(f_fifo_handshake.sender)
)

/*============================== Decoder ==============================*/

// decode 前的队列
basic_fifo #(
    .DEPTH(`D_BEFORE_QUEUE_DEPTH),
    .BYPASS(0), // 不允许 bypass ，因为这个 fifo 也充当了 d 级的流水寄存器。
    .T(f_d_pkg_t)
) f_d_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .receiver(f_fifo_handshake.receiver),
    .sender(fifo_d_handshake.sender)
)

handshake_if #(.T(d_r_pkg_t)) d_fifo_handshake();

// decoder 是纯组合逻辑的，其流水寄存器是前面的FIFO
decoder decoder_inst(
    .receiver(fifo_d_handshake.receiver),
    .sender(d_fifo_handshake.sender)
)

handshake_if #(.T(d_r_pkg_t)) fifo_r_handshake();

// decoder 后的队列

basic_fifo #(
    .DEPTH(`D_AFTER_QUEUE_DEPTH),
    .BYPASS(0), // 不允许 BYPASS ，充当前后端之间的流水寄存器
    .T(d_r_pkd_t)
) d_r_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .receiver(d_fifo_handshake.receiver),
    .sender(fifo_r_handshake.sender)
);

/*============================== 2x1 AXI Bridge ==============================*/

axi_crossbar # (
    .S_COUNT(2), // 连接两个cache, == 2
    .M_COUNT(1), // 连接总线，== 1
    .DATA_WIDTH(32), // 数据位宽 官方包是 32 位，需要使用 burst 传输
    .ADDR_WIDTH(32), // 地址位宽， 32 位
    .S_ID_WIDTH(4), // 官方包是 4 
    .M_ADDR_WIDTH(32'd32), // ICACHE和DCACHE的数据位宽应该都是32位？TODO: 取决于物理地址宽度
    .M_CONNECT_WRITE(2'b01), // TODO: 设置成仅 DCache 侧可写
) axi_crossbar_2x1_inst (
    .clk(aclk),
    .rst(!aresetn), // TODO: recheck

    /*
     * AXI slave interfaces
     */
    .s_axi_awid( ),
    .s_axi_awaddr( ),
    .s_axi_awlen( ),
    .s_axi_awsize( ),
    .s_axi_awburst( ),
    .s_axi_awlock( ),
    .s_axi_awcache( ),
    .s_axi_awprot( ),
    .s_axi_awqos( ),
    .s_axi_awuser( ),
    .s_axi_awvalid( ),
    .s_axi_awready( ),
    .s_axi_wdata( ),
    .s_axi_wstrb( ),
    .s_axi_wlast( ),
    .s_axi_wuser( ),
    .s_axi_wvalid( ),
    .s_axi_wready( ),
    .s_axi_bid( ),
    .s_axi_bresp( ),
    .s_axi_buser( ),
    .s_axi_bvalid( ),
    .s_axi_bready( ),
    .s_axi_arid( ),
    .s_axi_araddr( ),
    .s_axi_arlen( ),
    .s_axi_arsize( ),
    .s_axi_arburst( ),
    .s_axi_arlock( ),
    .s_axi_arcache( ),
    .s_axi_arprot( ),
    .s_axi_arqos( ),
    .s_axi_aruser( ),
    .s_axi_arvalid( ),
    .s_axi_arready( ),
    .s_axi_rid( ),
    .s_axi_rdata( ),
    .s_axi_rresp( ),
    .s_axi_rlast( ),
    .s_axi_ruser( ),
    .s_axi_rvalid( ),
    .s_axi_rready( ),

    /*
     * AXI master interfaces
     */
    .m_axi_awid(awid),
    .m_axi_awaddr(awaddr),
    .m_axi_awlen(awlen),
    .m_axi_awsize(awsize),
    .m_axi_awburst(awburst),
    .m_axi_awlock(awlock),
    .m_axi_awcache(awcache),
    .m_axi_awprot(awprot),
    .m_axi_awqos(/*TODO: 悬空，官方接口不会用到*/),
    .m_axi_awregion(/*TODO: check: 默认参数下只有一个 REGION, 即 0 号 region*/'0),
    .m_axi_awuser(/*TODO: 悬空，在默认参数下不会使用到这个信号*/),
    .m_axi_awvalid(awvalid),
    .m_axi_awready(awready),
    .m_axi_wdata(/*TODO*/ wdata),
    .m_axi_wstrb(wstrb),
    .m_axi_wlast(wlast),
    .m_axi_wuser(wuser),
    .m_axi_wvalid(wvalid),
    .m_axi_wready(wready),
    .m_axi_bid(bid),
    .m_axi_bresp(bresp),
    .m_axi_buser(/*TODO: 悬空*/),
    .m_axi_bvalid(bvalid),
    .m_axi_bready(bready),
    .m_axi_arid(arid),
    .m_axi_araddr(araddr),
    .m_axi_arlen(arlen),
    .m_axi_arsize(arsize),
    .m_axi_arburst(arbutst),
    .m_axi_arlock(arlock),
    .m_axi_arcache(arcache),
    .m_axi_arprot(arprot),
    .m_axi_arqos(/*TODO: 悬空*/),
    .m_axi_arregion(/*TODO: check*/'0),
    .m_axi_aruser(/*TODO: 悬空*/),
    .m_axi_arvalid(arvalid),
    .m_axi_arready(arready),
    .m_axi_rid(rid),
    .m_axi_rdata(rdata),
    .m_axi_rresp(rresp),
    .m_axi_rlast(rlast),
    .m_axi_ruser(/*TODO: 悬空*/),
    .m_axi_rvalid(rvalid),
    .m_axi_rready(rready)
);

endmodule