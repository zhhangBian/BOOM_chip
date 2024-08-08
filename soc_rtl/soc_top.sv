`timescale 1ns / 1ps

module soc_top(
    //input[5:0]      ext_int,
    input           HW0,
    input           HW1,
    input           HW2,
    input           HW3,
    input           HW4,
    input           aclk,
    input           aresetn,
    //ar
    output[3:0]     arid,
    output[31:0]    araddr,
    output[3:0]     arlen,
    output[2:0]     arsize,
    output[1:0]     arburst,
    output[1:0]     arlock,
    output[3:0]     arcache,
    output[2:0]     arprot,
    output          arvalid,
    input           arready,
    //r
    input[3:0]      rid,
    input[31:0]     rdata,
    input[1:0]      rresp,
    input           rlast,
    input           rvalid,
    output          rready,
    //aw
    output[3:0]     awid,
    output[31:0]    awaddr,
    output[3:0]     awlen,
    output[2:0]     awsize,
    output[1:0]     awburst,
    output[1:0]     awlock,
    output[3:0]     awcache,
    output[2:0]     awprot,
    output          awvalid,
    input           awready,
    //w
    output[3:0]     wid,
    output[31:0]    wdata,
    output[3:0]     wstrb,
    output          wlast,
    output          wvalid,
    input           wready,
    //b
    input[3:0]      bid,
    input[1:0]      bresp,
    input           bvalid,
    output          bready
    );


//pseudo
    wire[31:0]    debug_wb_pc0;
    wire          debug_wb_rf_wen0;
    wire[4:0]     debug_wb_rf_wnum0;
    wire[31:0]    debug_wb_rf_wdata0;
    wire[31:0]    debug_wb_pc1;
    wire          debug_wb_rf_wen1;
    wire[4:0]     debug_wb_rf_wnum1;
    wire[31:0]    debug_wb_rf_wdata1;


mycpu_top mycpu_rop_instance (
    .ext_int({1'b0, HW4, HW3, HW2, HW1, HW0}),
    .aclk(aclk),
    .aresetn(aresetn),
        //ar
    .arid(arid),
    .araddr(araddr),
    .arlen(arlen),
    .arsize(arsize),
    .arburst(arburst),
    .arlock(arlock),
    .arcache(arcache),
    .arprot(arprot),
    .arvalid(arvalid),
    .arready(arready),
        //r
    .rid(rid),
    .rdata(rdata),
    .rresp(rresp),
    .rlast(rlast),
    .rvalid(rvalid),
    .rready(rready),
        //aw
    .awid(awid),
    .awaddr(awaddr),
    .awlen(awlen),
    .awsize(awsize),
    .awburst(awburst),
    .awlock(awlock),
    .awcache(awcache),
    .awprot(awprot),
    .awvalid(awvalid),
    .awready(awready),
        //w
    .wid(wid),
    .wdata(wdata),
    .wstrb(wstrb),
    .wlast(wlast),
    .wvalid(wvalid),
    .wready(wready),
        //b
    .bid(bid),
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready),
        //debug
    .debug_wb_pc0(debug_wb_pc0),
    .debug_wb_rf_wen0(debug_wb_rf_wen0),
    .debug_wb_rf_wnum0(debug_wb_rf_wnum0),
    .debug_wb_rf_wdata0(debug_wb_rf_wdata0),
    .debug_wb_pc1(debug_wb_pc1),
    .debug_wb_rf_wen1(debug_wb_rf_wen1),
    .debug_wb_rf_wnum1(debug_wb_rf_wnum1),
    .debug_wb_rf_wdata1(debug_wb_rf_wdata1)
);


endmodule
