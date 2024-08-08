/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of
its contributors may be used to endorse or promote products derived from this
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/

`include "config.svh"

module soc_top(
    input         resetn,
    input         clk,

    //------gpio----------------
    output [15:0] led,
    output [1 :0] led_rg0,
    output [1 :0] led_rg1,
    output [7 :0] num_csn,
    output [6 :0] num_a_g,
    input  [7 :0] switch,
    output [3 :0] btn_key_col,
    input  [3 :0] btn_key_row,
    input  [1 :0] btn_step,

    //------DDR3 interface------
    inout  [15:0] ddr3_dq,
    output [12:0] ddr3_addr,
    output [2 :0] ddr3_ba,
    output        ddr3_ras_n,
    output        ddr3_cas_n,
    output        ddr3_we_n,
    output        ddr3_odt,
    output        ddr3_reset_n,
    output        ddr3_cke,
    output [1:0]  ddr3_dm,
    inout  [1:0]  ddr3_dqs_p,
    inout  [1:0]  ddr3_dqs_n,
    output        ddr3_ck_p,
    output        ddr3_ck_n,

    //------mac controller-------
    //TX
    input         mtxclk_0,
    output        mtxen_0,
    output [3:0]  mtxd_0,
    output        mtxerr_0,
    //RX
    input         mrxclk_0,
    input         mrxdv_0,
    input  [3:0]  mrxd_0,
    input         mrxerr_0,
    input         mcoll_0,
    input         mcrs_0,
    // MIIM
    output        mdc_0,
    inout         mdio_0,

    output        phy_rstn,

    //------EJTAG-------
    input         EJTAG_TRST,
    input         EJTAG_TCK,
    input         EJTAG_TDI,
    input         EJTAG_TMS,
    output        EJTAG_TDO,

    //------uart-------
    inout         UART_RX,
    inout         UART_TX,

    //------debug-uart------
    input         UART_RX2,
    output        UART_TX2,

    //------nand-------
    output        NAND_CLE ,
    output        NAND_ALE ,
    input         NAND_RDY ,
    inout [7:0]   NAND_DATA,
    output        NAND_RD  ,
    output        NAND_CE  ,  //low active
    output        NAND_WR  ,

    //------spi flash-------
    output        SPI_CLK,
    output        SPI_CS,
    inout         SPI_MISO,
    inout         SPI_MOSI,

    // ----- LCD -----
    output wire LCD_csel,
    inout wire [15:0] LCD_data_tri_io,
    output wire LCD_nrst,
    output wire LCD_rd,
    output wire LCD_rs,
    output wire LCD_wr,
    output wire LCD_lighton,


    // ----- PS2 -----
    inout wire PS2_clk_tri_io,
    inout wire PS2_dat_tri_io,

    // ----- VGA -----
    inout wire [3:0] VGA_r,
    inout wire [3:0] VGA_g,
    inout wire [3:0] VGA_b,
    output wire VGA_hsync,
    output wire VGA_vsync
);
wire        aclk;
wire        aresetn;
wire        cpu_clk;
wire        uncore_clk;

// video axi4 connection - 32bits - 33M
// DMA (AXI-4) Protocals - 64 bits
wire [31 : 0] fb_wr_video_AWADDR;
wire [7 : 0] fb_wr_video_AWLEN  ;
wire [2 : 0] fb_wr_video_AWSIZE  ;
wire [1 : 0] fb_wr_video_AWBURST;
wire [1 : 0] fb_wr_video_AWLOCK;
wire [3 : 0] fb_wr_video_AWREGION;
wire [3 : 0] fb_wr_video_AWCACHE;
wire [2 : 0] fb_wr_video_AWPROT;
wire [3 : 0] fb_wr_video_AWQOS;
wire fb_wr_video_AWVALID;
wire fb_wr_video_AWREADY;
wire [63 : 0] fb_wr_video_WDATA;
wire [7 : 0] fb_wr_video_WSTRB;
wire fb_wr_video_WLAST;
wire fb_wr_video_WVALID;
wire fb_wr_video_WREADY;
wire [1 : 0] fb_wr_video_BRESP;
wire fb_wr_video_BVALID;
wire fb_wr_video_BREADY;
wire [31 : 0] fb_wr_video_ARADDR;
wire [7 : 0] fb_wr_video_ARLEN;
wire [2 : 0] fb_wr_video_ARSIZE;
wire [1 : 0] fb_wr_video_ARBURST;
wire [1 : 0] fb_wr_video_ARLOCK;
wire [3 : 0] fb_wr_video_ARREGION;
wire [3 : 0] fb_wr_video_ARCACHE;
wire [2 : 0] fb_wr_video_ARPROT;
wire [3 : 0] fb_wr_video_ARQOS;
wire fb_wr_video_ARVALID;
wire fb_wr_video_ARREADY;
wire [63 : 0] fb_wr_video_RDATA;
wire [1 : 0] fb_wr_video_RRESP;
wire fb_wr_video_RLAST;
wire fb_wr_video_RVALID;
wire fb_wr_video_RREADY;

wire [31 : 0] fb_rd_video_AWADDR;
wire [7 : 0] fb_rd_video_AWLEN  ;
wire [2 : 0] fb_rd_video_AWSIZE  ;
wire [1 : 0] fb_rd_video_AWBURST;
wire [1 : 0] fb_rd_video_AWLOCK;
wire [3 : 0] fb_rd_video_AWREGION;
wire [3 : 0] fb_rd_video_AWCACHE;
wire [2 : 0] fb_rd_video_AWPROT;
wire [3 : 0] fb_rd_video_AWQOS;
wire fb_rd_video_AWVALID;
wire fb_rd_video_AWREADY;
wire [63 : 0] fb_rd_video_WDATA;
wire [7 : 0] fb_rd_video_WSTRB;
wire fb_rd_video_WLAST;
wire fb_rd_video_WVALID;
wire fb_rd_video_WREADY;
wire [1 : 0] fb_rd_video_BRESP;
wire fb_rd_video_BVALID;
wire fb_rd_video_BREADY;
wire [31 : 0] fb_rd_video_ARADDR;
wire [7 : 0] fb_rd_video_ARLEN;
wire [2 : 0] fb_rd_video_ARSIZE;
wire [1 : 0] fb_rd_video_ARBURST;
wire [1 : 0] fb_rd_video_ARLOCK;
wire [3 : 0] fb_rd_video_ARREGION;
wire [3 : 0] fb_rd_video_ARCACHE;
wire [2 : 0] fb_rd_video_ARPROT;
wire [3 : 0] fb_rd_video_ARQOS;
wire fb_rd_video_ARVALID;
wire fb_rd_video_ARREADY;
wire [63 : 0] fb_rd_video_RDATA;
wire [1 : 0] fb_rd_video_RRESP;
wire fb_rd_video_RLAST;
wire fb_rd_video_RVALID;
wire fb_rd_video_RREADY;

wire [8            -1 :0] tft_100M_awid;
wire [`Lawaddr     -1 :0] tft_100M_awaddr;
wire [8            -1 :0] tft_100M_awlen;
wire [`Lawsize     -1 :0] tft_100M_awsize;
wire [`Lawburst    -1 :0] tft_100M_awburst;
wire [0               :0] tft_100M_awlock;
wire [`Lawcache    -1 :0] tft_100M_awcache;
wire [`Lawprot     -1 :0] tft_100M_awprot;
wire                      tft_100M_awvalid;
wire                      tft_100M_awready;
wire [8            -1 :0] tft_100M_wid;
wire [`Lwdata      -1 :0] tft_100M_wdata;
wire [`Lwstrb      -1 :0] tft_100M_wstrb;
wire                      tft_100M_wlast;
wire                      tft_100M_wvalid;
wire                      tft_100M_wready;
wire [8            -1 :0] tft_100M_bid;
wire [`Lbresp      -1 :0] tft_100M_bresp;
wire                      tft_100M_bvalid;
wire                      tft_100M_bready;
wire [8            -1 :0] tft_100M_arid;
wire [`Laraddr     -1 :0] tft_100M_araddr;
wire [8            -1 :0] tft_100M_arlen;
wire [`Larsize     -1 :0] tft_100M_arsize;
wire [`Larburst    -1 :0] tft_100M_arburst;
wire [0               :0] tft_100M_arlock;
wire [`Larcache    -1 :0] tft_100M_arcache;
wire [`Larprot     -1 :0] tft_100M_arprot;
wire                      tft_100M_arvalid;
wire                      tft_100M_arready;
wire [8            -1 :0] tft_100M_rid;
wire [`Lrdata      -1 :0] tft_100M_rdata;
wire [`Lrresp      -1 :0] tft_100M_rresp;
wire                      tft_100M_rlast;
wire                      tft_100M_rvalid;
wire                      tft_100M_rready;

wire [`LID         -1 :0] tft_slave_33M_awid       ;
wire [`Lawaddr     -1 :0] tft_slave_33M_awaddr     ;
wire [`Lawlen      -1 :0] tft_slave_33M_awlen      ;
wire [`Lawsize     -1 :0] tft_slave_33M_awsize     ;
wire [`Lawburst    -1 :0] tft_slave_33M_awburst    ;
wire [`Lawlock     -1 :0] tft_slave_33M_awlock     ;
wire [`Lawcache    -1 :0] tft_slave_33M_awcache    ;
wire [`Lawprot     -1 :0] tft_slave_33M_awprot     ;
wire                      tft_slave_33M_awvalid    ;
wire                      tft_slave_33M_awready    ;
wire [`LID         -1 :0] tft_slave_33M_wid        ;
wire [64           -1 :0] tft_slave_33M_wdata      ;
wire [8            -1 :0] tft_slave_33M_wstrb      ;
wire                      tft_slave_33M_wlast      ;
wire                      tft_slave_33M_wvalid     ;
wire                      tft_slave_33M_wready     ;
wire [`LID         -1 :0] tft_slave_33M_bid        ;
wire [`Lbresp      -1 :0] tft_slave_33M_bresp      ;
wire                      tft_slave_33M_bvalid     ;
wire                      tft_slave_33M_bready     ;
wire [`LID         -1 :0] tft_slave_33M_arid       ;
wire [`Laraddr     -1 :0] tft_slave_33M_araddr     ;
wire [`Larlen      -1 :0] tft_slave_33M_arlen      ;
wire [`Larsize     -1 :0] tft_slave_33M_arsize     ;
wire [`Larburst    -1 :0] tft_slave_33M_arburst    ;
wire [`Larlock     -1 :0] tft_slave_33M_arlock     ;
wire [`Larcache    -1 :0] tft_slave_33M_arcache    ;
wire [`Larprot     -1 :0] tft_slave_33M_arprot     ;
wire                      tft_slave_33M_arvalid    ;
wire                      tft_slave_33M_arready    ;
wire [`LID         -1 :0] tft_slave_33M_rid        ;
wire [64           -1 :0] tft_slave_33M_rdata      ;
wire [`Lrresp      -1 :0] tft_slave_33M_rresp      ;
wire                      tft_slave_33M_rlast      ;
wire                      tft_slave_33M_rvalid     ;
wire                      tft_slave_33M_rready     ;
wire [`LID         -1 :0] tft_slave_100M_awid       ;
wire [`Lawaddr     -1 :0] tft_slave_100M_awaddr     ;
wire [`Lawlen      -1 :0] tft_slave_100M_awlen      ;
wire [`Lawsize     -1 :0] tft_slave_100M_awsize     ;
wire [`Lawburst    -1 :0] tft_slave_100M_awburst    ;
wire [`Lawlock     -1 :0] tft_slave_100M_awlock     ;
wire [`Lawcache    -1 :0] tft_slave_100M_awcache    ;
wire [`Lawprot     -1 :0] tft_slave_100M_awprot     ;
wire                      tft_slave_100M_awvalid    ;
wire                      tft_slave_100M_awready    ;
wire [`LID         -1 :0] tft_slave_100M_wid        ;
wire [64           -1 :0] tft_slave_100M_wdata      ;
wire [8            -1 :0] tft_slave_100M_wstrb      ;
wire                      tft_slave_100M_wlast      ;
wire                      tft_slave_100M_wvalid     ;
wire                      tft_slave_100M_wready     ;
wire [`LID         -1 :0] tft_slave_100M_bid        ;
wire [`Lbresp      -1 :0] tft_slave_100M_bresp      ;
wire                      tft_slave_100M_bvalid     ;
wire                      tft_slave_100M_bready     ;
wire [`LID         -1 :0] tft_slave_100M_arid       ;
wire [`Laraddr     -1 :0] tft_slave_100M_araddr     ;
wire [`Larlen      -1 :0] tft_slave_100M_arlen      ;
wire [`Larsize     -1 :0] tft_slave_100M_arsize     ;
wire [`Larburst    -1 :0] tft_slave_100M_arburst    ;
wire [`Larlock     -1 :0] tft_slave_100M_arlock     ;
wire [`Larcache    -1 :0] tft_slave_100M_arcache    ;
wire [`Larprot     -1 :0] tft_slave_100M_arprot     ;
wire                      tft_slave_100M_arvalid    ;
wire                      tft_slave_100M_arready    ;
wire [`LID         -1 :0] tft_slave_100M_rid        ;
wire [64           -1 :0] tft_slave_100M_rdata      ;
wire [`Lrresp      -1 :0] tft_slave_100M_rresp      ;
wire                      tft_slave_100M_rlast      ;
wire                      tft_slave_100M_rvalid     ;
wire                      tft_slave_100M_rready     ;

wire [`LID         -1 :0] fb_write_slave_33M_awid       ;
wire [`Lawaddr     -1 :0] fb_write_slave_33M_awaddr     ;
wire [`Lawlen      -1 :0] fb_write_slave_33M_awlen      ;
wire [`Lawsize     -1 :0] fb_write_slave_33M_awsize     ;
wire [`Lawburst    -1 :0] fb_write_slave_33M_awburst    ;
wire [`Lawlock     -1 :0] fb_write_slave_33M_awlock     ;
wire [`Lawcache    -1 :0] fb_write_slave_33M_awcache    ;
wire [`Lawprot     -1 :0] fb_write_slave_33M_awprot     ;
wire                      fb_write_slave_33M_awvalid    ;
wire                      fb_write_slave_33M_awready    ;
wire [`LID         -1 :0] fb_write_slave_33M_wid        ;
wire [64           -1 :0] fb_write_slave_33M_wdata      ;
wire [8            -1 :0] fb_write_slave_33M_wstrb      ;
wire                      fb_write_slave_33M_wlast      ;
wire                      fb_write_slave_33M_wvalid     ;
wire                      fb_write_slave_33M_wready     ;
wire [`LID         -1 :0] fb_write_slave_33M_bid        ;
wire [`Lbresp      -1 :0] fb_write_slave_33M_bresp      ;
wire                      fb_write_slave_33M_bvalid     ;
wire                      fb_write_slave_33M_bready     ;
wire [`LID         -1 :0] fb_write_slave_33M_arid       ;
wire [`Laraddr     -1 :0] fb_write_slave_33M_araddr     ;
wire [`Larlen      -1 :0] fb_write_slave_33M_arlen      ;
wire [`Larsize     -1 :0] fb_write_slave_33M_arsize     ;
wire [`Larburst    -1 :0] fb_write_slave_33M_arburst    ;
wire [`Larlock     -1 :0] fb_write_slave_33M_arlock     ;
wire [`Larcache    -1 :0] fb_write_slave_33M_arcache    ;
wire [`Larprot     -1 :0] fb_write_slave_33M_arprot     ;
wire                      fb_write_slave_33M_arvalid    ;
wire                      fb_write_slave_33M_arready    ;
wire [`LID         -1 :0] fb_write_slave_33M_rid        ;
wire [64           -1 :0] fb_write_slave_33M_rdata      ;
wire [`Lrresp      -1 :0] fb_write_slave_33M_rresp      ;
wire                      fb_write_slave_33M_rlast      ;
wire                      fb_write_slave_33M_rvalid     ;
wire                      fb_write_slave_33M_rready     ;
wire [`LID         -1 :0] fb_write_slave_100M_awid       ;
wire [`Lawaddr     -1 :0] fb_write_slave_100M_awaddr     ;
wire [`Lawlen      -1 :0] fb_write_slave_100M_awlen      ;
wire [`Lawsize     -1 :0] fb_write_slave_100M_awsize     ;
wire [`Lawburst    -1 :0] fb_write_slave_100M_awburst    ;
wire [`Lawlock     -1 :0] fb_write_slave_100M_awlock     ;
wire [`Lawcache    -1 :0] fb_write_slave_100M_awcache    ;
wire [`Lawprot     -1 :0] fb_write_slave_100M_awprot     ;
wire                      fb_write_slave_100M_awvalid    ;
wire                      fb_write_slave_100M_awready    ;
wire [`LID         -1 :0] fb_write_slave_100M_wid        ;
wire [64           -1 :0] fb_write_slave_100M_wdata      ;
wire [8            -1 :0] fb_write_slave_100M_wstrb      ;
wire                      fb_write_slave_100M_wlast      ;
wire                      fb_write_slave_100M_wvalid     ;
wire                      fb_write_slave_100M_wready     ;
wire [`LID         -1 :0] fb_write_slave_100M_bid        ;
wire [`Lbresp      -1 :0] fb_write_slave_100M_bresp      ;
wire                      fb_write_slave_100M_bvalid     ;
wire                      fb_write_slave_100M_bready     ;
wire [`LID         -1 :0] fb_write_slave_100M_arid       ;
wire [`Laraddr     -1 :0] fb_write_slave_100M_araddr     ;
wire [`Larlen      -1 :0] fb_write_slave_100M_arlen      ;
wire [`Larsize     -1 :0] fb_write_slave_100M_arsize     ;
wire [`Larburst    -1 :0] fb_write_slave_100M_arburst    ;
wire [`Larlock     -1 :0] fb_write_slave_100M_arlock     ;
wire [`Larcache    -1 :0] fb_write_slave_100M_arcache    ;
wire [`Larprot     -1 :0] fb_write_slave_100M_arprot     ;
wire                      fb_write_slave_100M_arvalid    ;
wire                      fb_write_slave_100M_arready    ;
wire [`LID         -1 :0] fb_write_slave_100M_rid        ;
wire [64           -1 :0] fb_write_slave_100M_rdata      ;
wire [`Lrresp      -1 :0] fb_write_slave_100M_rresp      ;
wire                      fb_write_slave_100M_rlast      ;
wire                      fb_write_slave_100M_rvalid     ;
wire                      fb_write_slave_100M_rready     ;

wire [`LID         -1 :0] fb_read_slave_33M_awid       ;
wire [`Lawaddr     -1 :0] fb_read_slave_33M_awaddr     ;
wire [`Lawlen      -1 :0] fb_read_slave_33M_awlen      ;
wire [`Lawsize     -1 :0] fb_read_slave_33M_awsize     ;
wire [`Lawburst    -1 :0] fb_read_slave_33M_awburst    ;
wire [`Lawlock     -1 :0] fb_read_slave_33M_awlock     ;
wire [`Lawcache    -1 :0] fb_read_slave_33M_awcache    ;
wire [`Lawprot     -1 :0] fb_read_slave_33M_awprot     ;
wire                      fb_read_slave_33M_awvalid    ;
wire                      fb_read_slave_33M_awready    ;
wire [`LID         -1 :0] fb_read_slave_33M_wid        ;
wire [64           -1 :0] fb_read_slave_33M_wdata      ;
wire [8            -1 :0] fb_read_slave_33M_wstrb      ;
wire                      fb_read_slave_33M_wlast      ;
wire                      fb_read_slave_33M_wvalid     ;
wire                      fb_read_slave_33M_wready     ;
wire [`LID         -1 :0] fb_read_slave_33M_bid        ;
wire [`Lbresp      -1 :0] fb_read_slave_33M_bresp      ;
wire                      fb_read_slave_33M_bvalid     ;
wire                      fb_read_slave_33M_bready     ;
wire [`LID         -1 :0] fb_read_slave_33M_arid       ;
wire [`Laraddr     -1 :0] fb_read_slave_33M_araddr     ;
wire [`Larlen      -1 :0] fb_read_slave_33M_arlen      ;
wire [`Larsize     -1 :0] fb_read_slave_33M_arsize     ;
wire [`Larburst    -1 :0] fb_read_slave_33M_arburst    ;
wire [`Larlock     -1 :0] fb_read_slave_33M_arlock     ;
wire [`Larcache    -1 :0] fb_read_slave_33M_arcache    ;
wire [`Larprot     -1 :0] fb_read_slave_33M_arprot     ;
wire                      fb_read_slave_33M_arvalid    ;
wire                      fb_read_slave_33M_arready    ;
wire [`LID         -1 :0] fb_read_slave_33M_rid        ;
wire [64           -1 :0] fb_read_slave_33M_rdata      ;
wire [`Lrresp      -1 :0] fb_read_slave_33M_rresp      ;
wire                      fb_read_slave_33M_rlast      ;
wire                      fb_read_slave_33M_rvalid     ;
wire                      fb_read_slave_33M_rready     ;
wire [`LID         -1 :0] fb_read_slave_100M_awid       ;
wire [`Lawaddr     -1 :0] fb_read_slave_100M_awaddr     ;
wire [`Lawlen      -1 :0] fb_read_slave_100M_awlen      ;
wire [`Lawsize     -1 :0] fb_read_slave_100M_awsize     ;
wire [`Lawburst    -1 :0] fb_read_slave_100M_awburst    ;
wire [`Lawlock     -1 :0] fb_read_slave_100M_awlock     ;
wire [`Lawcache    -1 :0] fb_read_slave_100M_awcache    ;
wire [`Lawprot     -1 :0] fb_read_slave_100M_awprot     ;
wire                      fb_read_slave_100M_awvalid    ;
wire                      fb_read_slave_100M_awready    ;
wire [`LID         -1 :0] fb_read_slave_100M_wid        ;
wire [64           -1 :0] fb_read_slave_100M_wdata      ;
wire [8            -1 :0] fb_read_slave_100M_wstrb      ;
wire                      fb_read_slave_100M_wlast      ;
wire                      fb_read_slave_100M_wvalid     ;
wire                      fb_read_slave_100M_wready     ;
wire [`LID         -1 :0] fb_read_slave_100M_bid        ;
wire [`Lbresp      -1 :0] fb_read_slave_100M_bresp      ;
wire                      fb_read_slave_100M_bvalid     ;
wire                      fb_read_slave_100M_bready     ;
wire [`LID         -1 :0] fb_read_slave_100M_arid       ;
wire [`Laraddr     -1 :0] fb_read_slave_100M_araddr     ;
wire [`Larlen      -1 :0] fb_read_slave_100M_arlen      ;
wire [`Larsize     -1 :0] fb_read_slave_100M_arsize     ;
wire [`Larburst    -1 :0] fb_read_slave_100M_arburst    ;
wire [`Larlock     -1 :0] fb_read_slave_100M_arlock     ;
wire [`Larcache    -1 :0] fb_read_slave_100M_arcache    ;
wire [`Larprot     -1 :0] fb_read_slave_100M_arprot     ;
wire                      fb_read_slave_100M_arvalid    ;
wire                      fb_read_slave_100M_arready    ;
wire [`LID         -1 :0] fb_read_slave_100M_rid        ;
wire [64           -1 :0] fb_read_slave_100M_rdata      ;
wire [`Lrresp      -1 :0] fb_read_slave_100M_rresp      ;
wire                      fb_read_slave_100M_rlast      ;
wire                      fb_read_slave_100M_rvalid     ;
wire                      fb_read_slave_100M_rready     ;

wire [`LID         -1 :0] m0_awid;
wire [`Lawaddr     -1 :0] m0_awaddr;
wire [`Lawlen      -1 :0] m0_awlen;
wire [`Lawsize     -1 :0] m0_awsize;
wire [`Lawburst    -1 :0] m0_awburst;
wire [`Lawlock     -1 :0] m0_awlock;
wire [`Lawcache    -1 :0] m0_awcache;
wire [`Lawprot     -1 :0] m0_awprot;
wire                      m0_awvalid;
wire                      m0_awready;
wire [`LID         -1 :0] m0_wid;
wire [`Lwdata      -1 :0] m0_wdata;
wire [`Lwstrb      -1 :0] m0_wstrb;
wire                      m0_wlast;
wire                      m0_wvalid;
wire                      m0_wready;
wire [`LID         -1 :0] m0_bid;
wire [`Lbresp      -1 :0] m0_bresp;
wire                      m0_bvalid;
wire                      m0_bready;
wire [`LID         -1 :0] m0_arid;
wire [`Laraddr     -1 :0] m0_araddr;
wire [`Larlen      -1 :0] m0_arlen;
wire [`Larsize     -1 :0] m0_arsize;
wire [`Larburst    -1 :0] m0_arburst;
wire [`Larlock     -1 :0] m0_arlock;
wire [`Larcache    -1 :0] m0_arcache;
wire [`Larprot     -1 :0] m0_arprot;
wire                      m0_arvalid;
wire                      m0_arready;
wire [`LID         -1 :0] m0_rid;
wire [`Lrdata      -1 :0] m0_rdata;
wire [`Lrresp      -1 :0] m0_rresp;
wire                      m0_rlast;
wire                      m0_rvalid;
wire                      m0_rready;

wire [`LID         -1 :0] peripheral_awid;
wire [`Lawaddr     -1 :0] peripheral_awaddr;
wire [`Lawlen      -1 :0] peripheral_awlen;
wire [`Lawsize     -1 :0] peripheral_awsize;
wire [`Lawburst    -1 :0] peripheral_awburst;
wire [`Lawlock     -1 :0] peripheral_awlock;
wire [`Lawcache    -1 :0] peripheral_awcache;
wire [`Lawprot     -1 :0] peripheral_awprot;
wire                      peripheral_awvalid;
wire                      peripheral_awready;
wire [`LID         -1 :0] peripheral_wid;
wire [`Lwdata      -1 :0] peripheral_wdata;
wire [`Lwstrb      -1 :0] peripheral_wstrb;
wire                      peripheral_wlast;
wire                      peripheral_wvalid;
wire                      peripheral_wready;
wire [`LID         -1 :0] peripheral_bid;
wire [`Lbresp      -1 :0] peripheral_bresp;
wire                      peripheral_bvalid;
wire                      peripheral_bready;
wire [`LID         -1 :0] peripheral_arid;
wire [`Laraddr     -1 :0] peripheral_araddr;
wire [`Larlen      -1 :0] peripheral_arlen;
wire [`Larsize     -1 :0] peripheral_arsize;
wire [`Larburst    -1 :0] peripheral_arburst;
wire [`Larlock     -1 :0] peripheral_arlock;
wire [`Larcache    -1 :0] peripheral_arcache;
wire [`Larprot     -1 :0] peripheral_arprot;
wire                      peripheral_arvalid;
wire                      peripheral_arready;
wire [`LID         -1 :0] peripheral_rid;
wire [`Lrdata      -1 :0] peripheral_rdata;
wire [`Lrresp      -1 :0] peripheral_rresp;
wire                      peripheral_rlast;
wire                      peripheral_rvalid;
wire                      peripheral_rready;

wire [`LID         -1 :0] m0_async_awid;
wire [`Lawaddr     -1 :0] m0_async_awaddr;
wire [`Lawlen      -1 :0] m0_async_awlen;
wire [`Lawsize     -1 :0] m0_async_awsize;
wire [`Lawburst    -1 :0] m0_async_awburst;
wire [`Lawlock     -1 :0] m0_async_awlock;
wire [`Lawcache    -1 :0] m0_async_awcache;
wire [`Lawprot     -1 :0] m0_async_awprot;
wire                      m0_async_awvalid;
wire                      m0_async_awready;
wire [`LID         -1 :0] m0_async_wid;
wire [`Lwdata      -1 :0] m0_async_wdata;
wire [`Lwstrb      -1 :0] m0_async_wstrb;
wire                      m0_async_wlast;
wire                      m0_async_wvalid;
wire                      m0_async_wready;
wire [`LID         -1 :0] m0_async_bid;
wire [`Lbresp      -1 :0] m0_async_bresp;
wire                      m0_async_bvalid;
wire                      m0_async_bready;
wire [`LID         -1 :0] m0_async_arid;
wire [`Laraddr     -1 :0] m0_async_araddr;
wire [`Larlen      -1 :0] m0_async_arlen;
wire [`Larsize     -1 :0] m0_async_arsize;
wire [`Larburst    -1 :0] m0_async_arburst;
wire [`Larlock     -1 :0] m0_async_arlock;
wire [`Larcache    -1 :0] m0_async_arcache;
wire [`Larprot     -1 :0] m0_async_arprot;
wire                      m0_async_arvalid;
wire                      m0_async_arready;
wire [`LID         -1 :0] m0_async_rid;
wire [`Lrdata      -1 :0] m0_async_rdata;
wire [`Lrresp      -1 :0] m0_async_rresp;
wire                      m0_async_rlast;
wire                      m0_async_rvalid;
wire                      m0_async_rready;

wire [`LID         -1 :0] spi_s_awid;
wire [`Lawaddr     -1 :0] spi_s_awaddr;
wire [`Lawlen      -1 :0] spi_s_awlen;
wire [`Lawsize     -1 :0] spi_s_awsize;
wire [`Lawburst    -1 :0] spi_s_awburst;
wire [`Lawlock     -1 :0] spi_s_awlock;
wire [`Lawcache    -1 :0] spi_s_awcache;
wire [`Lawprot     -1 :0] spi_s_awprot;
wire                      spi_s_awvalid;
wire                      spi_s_awready;
wire [`LID         -1 :0] spi_s_wid;
wire [`Lwdata      -1 :0] spi_s_wdata;
wire [`Lwstrb      -1 :0] spi_s_wstrb;
wire                      spi_s_wlast;
wire                      spi_s_wvalid;
wire                      spi_s_wready;
wire [`LID         -1 :0] spi_s_bid;
wire [`Lbresp      -1 :0] spi_s_bresp;
wire                      spi_s_bvalid;
wire                      spi_s_bready;
wire [`LID         -1 :0] spi_s_arid;
wire [`Laraddr     -1 :0] spi_s_araddr;
wire [`Larlen      -1 :0] spi_s_arlen;
wire [`Larsize     -1 :0] spi_s_arsize;
wire [`Larburst    -1 :0] spi_s_arburst;
wire [`Larlock     -1 :0] spi_s_arlock;
wire [`Larcache    -1 :0] spi_s_arcache;
wire [`Larprot     -1 :0] spi_s_arprot;
wire                      spi_s_arvalid;
wire                      spi_s_arready;
wire [`LID         -1 :0] spi_s_rid;
wire [`Lrdata      -1 :0] spi_s_rdata;
wire [`Lrresp      -1 :0] spi_s_rresp;
wire                      spi_s_rlast;
wire                      spi_s_rvalid;
wire                      spi_s_rready;

wire [`LID         -1 :0] conf_s_awid;
wire [`Lawaddr     -1 :0] conf_s_awaddr;
wire [`Lawlen      -1 :0] conf_s_awlen;
wire [`Lawsize     -1 :0] conf_s_awsize;
wire [`Lawburst    -1 :0] conf_s_awburst;
wire [`Lawlock     -1 :0] conf_s_awlock;
wire [`Lawcache    -1 :0] conf_s_awcache;
wire [`Lawprot     -1 :0] conf_s_awprot;
wire                      conf_s_awvalid;
wire                      conf_s_awready;
wire [`LID         -1 :0] conf_s_wid;
wire [`Lwdata      -1 :0] conf_s_wdata;
wire [`Lwstrb      -1 :0] conf_s_wstrb;
wire                      conf_s_wlast;
wire                      conf_s_wvalid;
wire                      conf_s_wready;
wire [`LID         -1 :0] conf_s_bid;
wire [`Lbresp      -1 :0] conf_s_bresp;
wire                      conf_s_bvalid;
wire                      conf_s_bready;
wire [`LID         -1 :0] conf_s_arid;
wire [`Laraddr     -1 :0] conf_s_araddr;
wire [`Larlen      -1 :0] conf_s_arlen;
wire [`Larsize     -1 :0] conf_s_arsize;
wire [`Larburst    -1 :0] conf_s_arburst;
wire [`Larlock     -1 :0] conf_s_arlock;
wire [`Larcache    -1 :0] conf_s_arcache;
wire [`Larprot     -1 :0] conf_s_arprot;
wire                      conf_s_arvalid;
wire                      conf_s_arready;
wire [`LID         -1 :0] conf_s_rid;
wire [`Lrdata      -1 :0] conf_s_rdata;
wire [`Lrresp      -1 :0] conf_s_rresp;
wire                      conf_s_rlast;
wire                      conf_s_rvalid;
wire                      conf_s_rready;

wire [`LID         -1 :0] mac_s_awid;
wire [`Lawaddr     -1 :0] mac_s_awaddr;
wire [`Lawlen      -1 :0] mac_s_awlen;
wire [`Lawsize     -1 :0] mac_s_awsize;
wire [`Lawburst    -1 :0] mac_s_awburst;
wire [`Lawlock     -1 :0] mac_s_awlock;
wire [`Lawcache    -1 :0] mac_s_awcache;
wire [`Lawprot     -1 :0] mac_s_awprot;
wire                      mac_s_awvalid;
wire                      mac_s_awready;
wire [`LID         -1 :0] mac_s_wid;
wire [`Lwdata      -1 :0] mac_s_wdata;
wire [`Lwstrb      -1 :0] mac_s_wstrb;
wire                      mac_s_wlast;
wire                      mac_s_wvalid;
wire                      mac_s_wready;
wire [`LID         -1 :0] mac_s_bid;
wire [`Lbresp      -1 :0] mac_s_bresp;
wire                      mac_s_bvalid;
wire                      mac_s_bready;
wire [`LID         -1 :0] mac_s_arid;
wire [`Laraddr     -1 :0] mac_s_araddr;
wire [`Larlen      -1 :0] mac_s_arlen;
wire [`Larsize     -1 :0] mac_s_arsize;
wire [`Larburst    -1 :0] mac_s_arburst;
wire [`Larlock     -1 :0] mac_s_arlock;
wire [`Larcache    -1 :0] mac_s_arcache;
wire [`Larprot     -1 :0] mac_s_arprot;
wire                      mac_s_arvalid;
wire                      mac_s_arready;
wire [`LID         -1 :0] mac_s_rid;
wire [`Lrdata      -1 :0] mac_s_rdata;
wire [`Lrresp      -1 :0] mac_s_rresp;
wire                      mac_s_rlast;
wire                      mac_s_rvalid;
wire                      mac_s_rready;

wire [`LID         -1 :0] mac_m_awid;
wire [`Lawaddr     -1 :0] mac_m_awaddr;
wire [`Lawlen      -1 :0] mac_m_awlen;
wire [`Lawsize     -1 :0] mac_m_awsize;
wire [`Lawburst    -1 :0] mac_m_awburst;
wire [`Lawlock     -1 :0] mac_m_awlock;
wire [`Lawcache    -1 :0] mac_m_awcache;
wire [`Lawprot     -1 :0] mac_m_awprot;
wire                      mac_m_awvalid;
wire                      mac_m_awready;
wire [`LID         -1 :0] mac_m_wid;
wire [`Lwdata      -1 :0] mac_m_wdata;
wire [`Lwstrb      -1 :0] mac_m_wstrb;
wire                      mac_m_wlast;
wire                      mac_m_wvalid;
wire                      mac_m_wready;
wire [`LID         -1 :0] mac_m_bid;
wire [`Lbresp      -1 :0] mac_m_bresp;
wire                      mac_m_bvalid;
wire                      mac_m_bready;
wire [`LID         -1 :0] mac_m_arid;
wire [`Laraddr     -1 :0] mac_m_araddr;
wire [`Larlen      -1 :0] mac_m_arlen;
wire [`Larsize     -1 :0] mac_m_arsize;
wire [`Larburst    -1 :0] mac_m_arburst;
wire [`Larlock     -1 :0] mac_m_arlock;
wire [`Larcache    -1 :0] mac_m_arcache;
wire [`Larprot     -1 :0] mac_m_arprot;
wire                      mac_m_arvalid;
wire                      mac_m_arready;
wire [`LID         -1 :0] mac_m_rid;
wire [`Lrdata      -1 :0] mac_m_rdata;
wire [`Lrresp      -1 :0] mac_m_rresp;
wire                      mac_m_rlast;
wire                      mac_m_rvalid;
wire                      mac_m_rready;

wire [`LID         -1 :0] s0_awid;
wire [`Lawaddr     -1 :0] s0_awaddr;
wire [`Lawlen      -1 :0] s0_awlen;
wire [`Lawsize     -1 :0] s0_awsize;
wire [`Lawburst    -1 :0] s0_awburst;
wire [`Lawlock     -1 :0] s0_awlock;
wire [`Lawcache    -1 :0] s0_awcache;
wire [`Lawprot     -1 :0] s0_awprot;
wire                      s0_awvalid;
wire                      s0_awready;
wire [`LID         -1 :0] s0_wid;
wire [`Lwdata      -1 :0] s0_wdata;
wire [`Lwstrb      -1 :0] s0_wstrb;
wire                      s0_wlast;
wire                      s0_wvalid;
wire                      s0_wready;
wire [`LID         -1 :0] s0_bid;
wire [`Lbresp      -1 :0] s0_bresp;
wire                      s0_bvalid;
wire                      s0_bready;
wire [`LID         -1 :0] s0_arid;
wire [`Laraddr     -1 :0] s0_araddr;
wire [`Larlen      -1 :0] s0_arlen;
wire [`Larsize     -1 :0] s0_arsize;
wire [`Larburst    -1 :0] s0_arburst;
wire [`Larlock     -1 :0] s0_arlock;
wire [`Larcache    -1 :0] s0_arcache;
wire [`Larprot     -1 :0] s0_arprot;
wire                      s0_arvalid;
wire                      s0_arready;
wire [`LID         -1 :0] s0_rid;
wire [`Lrdata      -1 :0] s0_rdata;
wire [`Lrresp      -1 :0] s0_rresp;
wire                      s0_rlast;
wire                      s0_rvalid;
wire                      s0_rready;

wire [`LID         -1 :0] second_mux_awid;
wire [`Lawaddr     -1 :0] second_mux_awaddr;
wire [`Lawlen      -1 :0] second_mux_awlen;
wire [`Lawsize     -1 :0] second_mux_awsize;
wire [`Lawburst    -1 :0] second_mux_awburst;
wire [`Lawlock     -1 :0] second_mux_awlock;
wire [`Lawcache    -1 :0] second_mux_awcache;
wire [`Lawprot     -1 :0] second_mux_awprot;
wire                      second_mux_awvalid;
wire                      second_mux_awready;
wire [`LID         -1 :0] second_mux_wid;
wire [`Lwdata      -1 :0] second_mux_wdata;
wire [`Lwstrb      -1 :0] second_mux_wstrb;
wire                      second_mux_wlast;
wire                      second_mux_wvalid;
wire                      second_mux_wready;
wire [`LID         -1 :0] second_mux_bid;
wire [`Lbresp      -1 :0] second_mux_bresp;
wire                      second_mux_bvalid;
wire                      second_mux_bready;
wire [`LID         -1 :0] second_mux_arid;
wire [`Laraddr     -1 :0] second_mux_araddr;
wire [`Larlen      -1 :0] second_mux_arlen;
wire [`Larsize     -1 :0] second_mux_arsize;
wire [`Larburst    -1 :0] second_mux_arburst;
wire [`Larlock     -1 :0] second_mux_arlock;
wire [`Larcache    -1 :0] second_mux_arcache;
wire [`Larprot     -1 :0] second_mux_arprot;
wire                      second_mux_arvalid;
wire                      second_mux_arready;
wire [`LID         -1 :0] second_mux_rid;
wire [`Lrdata      -1 :0] second_mux_rdata;
wire [`Lrresp      -1 :0] second_mux_rresp;
wire                      second_mux_rlast;
wire                      second_mux_rvalid;
wire                      second_mux_rready;

wire [8            -1 :0] mig_awid;
wire [`Lawaddr     -1 :0] mig_awaddr;
wire [8            -1 :0] mig_awlen;
wire [`Lawsize     -1 :0] mig_awsize;
wire [`Lawburst    -1 :0] mig_awburst;
wire [`Lawlock     -1 :0] mig_awlock;
wire [`Lawcache    -1 :0] mig_awcache;
wire [`Lawprot     -1 :0] mig_awprot;
wire                      mig_awvalid;
wire                      mig_awready;
wire [8            -1 :0] mig_wid;
wire [`Lwdata      -1 :0] mig_wdata;
wire [`Lwstrb      -1 :0] mig_wstrb;
wire                      mig_wlast;
wire                      mig_wvalid;
wire                      mig_wready;
wire [8            -1 :0] mig_bid;
wire [`Lbresp      -1 :0] mig_bresp;
wire                      mig_bvalid;
wire                      mig_bready;
wire [8            -1 :0] mig_arid;
wire [`Laraddr     -1 :0] mig_araddr;
wire [8            -1 :0] mig_arlen;
wire [`Larsize     -1 :0] mig_arsize;
wire [`Larburst    -1 :0] mig_arburst;
wire [`Larlock     -1 :0] mig_arlock;
wire [`Larcache    -1 :0] mig_arcache;
wire [`Larprot     -1 :0] mig_arprot;
wire                      mig_arvalid;
wire                      mig_arready;
wire [8            -1 :0] mig_rid;
wire [`Lrdata      -1 :0] mig_rdata;
wire [`Lrresp      -1 :0] mig_rresp;
wire                      mig_rlast;
wire                      mig_rvalid;
wire                      mig_rready;

wire [`LID         -1 :0] dma0_awid       ;
wire [`Lawaddr     -1 :0] dma0_awaddr     ;
wire [`Lawlen      -1 :0] dma0_awlen      ;
wire [`Lawsize     -1 :0] dma0_awsize     ;
wire [`Lawburst    -1 :0] dma0_awburst    ;
wire [`Lawlock     -1 :0] dma0_awlock     ;
wire [`Lawcache    -1 :0] dma0_awcache    ;
wire [`Lawprot     -1 :0] dma0_awprot     ;
wire                      dma0_awvalid    ;
wire                      dma0_awready    ;
wire [`LID         -1 :0] dma0_wid        ;
wire [64           -1 :0] dma0_wdata      ;
wire [8            -1 :0] dma0_wstrb      ;
wire                      dma0_wlast      ;
wire                      dma0_wvalid     ;
wire                      dma0_wready     ;
wire [`LID         -1 :0] dma0_bid        ;
wire [`Lbresp      -1 :0] dma0_bresp      ;
wire                      dma0_bvalid     ;
wire                      dma0_bready     ;
wire [`LID         -1 :0] dma0_arid       ;
wire [`Laraddr     -1 :0] dma0_araddr     ;
wire [`Larlen      -1 :0] dma0_arlen      ;
wire [`Larsize     -1 :0] dma0_arsize     ;
wire [`Larburst    -1 :0] dma0_arburst    ;
wire [`Larlock     -1 :0] dma0_arlock     ;
wire [`Larcache    -1 :0] dma0_arcache    ;
wire [`Larprot     -1 :0] dma0_arprot     ;
wire                      dma0_arvalid    ;
wire                      dma0_arready    ;
wire [`LID         -1 :0] dma0_rid        ;
wire [64           -1 :0] dma0_rdata      ;
wire [`Lrresp      -1 :0] dma0_rresp      ;
wire                      dma0_rlast      ;
wire                      dma0_rvalid     ;
wire                      dma0_rready     ;

wire [`LID         -1 :0] apb_connect_axi4lite_awid       ;
wire [`Lawaddr     -1 :0] apb_connect_axi4lite_awaddr     ;
wire [`Lawlen      -1 :0] apb_connect_axi4lite_awlen      ;
wire [`Lawsize     -1 :0] apb_connect_axi4lite_awsize     ;
wire [`Lawburst    -1 :0] apb_connect_axi4lite_awburst    ;
wire [`Lawlock     -1 :0] apb_connect_axi4lite_awlock     ;
wire [`Lawcache    -1 :0] apb_connect_axi4lite_awcache    ;
wire [`Lawprot     -1 :0] apb_connect_axi4lite_awprot     ;
wire                      apb_connect_axi4lite_awvalid    ;
wire                      apb_connect_axi4lite_awready    ;
wire [`LID         -1 :0] apb_connect_axi4lite_wid        ;
wire [64           -1 :0] apb_connect_axi4lite_wdata      ;
wire [8            -1 :0] apb_connect_axi4lite_wstrb      ;
wire                      apb_connect_axi4lite_wlast      ;
wire                      apb_connect_axi4lite_wvalid     ;
wire                      apb_connect_axi4lite_wready     ;
wire [`LID         -1 :0] apb_connect_axi4lite_bid        ;
wire [`Lbresp      -1 :0] apb_connect_axi4lite_bresp      ;
wire                      apb_connect_axi4lite_bvalid     ;
wire                      apb_connect_axi4lite_bready     ;
wire [`LID         -1 :0] apb_connect_axi4lite_arid       ;
wire [`Laraddr     -1 :0] apb_connect_axi4lite_araddr     ;
wire [`Larlen      -1 :0] apb_connect_axi4lite_arlen      ;
wire [`Larsize     -1 :0] apb_connect_axi4lite_arsize     ;
wire [`Larburst    -1 :0] apb_connect_axi4lite_arburst    ;
wire [`Larlock     -1 :0] apb_connect_axi4lite_arlock     ;
wire [`Larcache    -1 :0] apb_connect_axi4lite_arcache    ;
wire [`Larprot     -1 :0] apb_connect_axi4lite_arprot     ;
wire                      apb_connect_axi4lite_arvalid    ;
wire                      apb_connect_axi4lite_arready    ;
wire [`LID         -1 :0] apb_connect_axi4lite_rid        ;
wire [64           -1 :0] apb_connect_axi4lite_rdata      ;
wire [`Lrresp      -1 :0] apb_connect_axi4lite_rresp      ;
wire                      apb_connect_axi4lite_rlast      ;
wire                      apb_connect_axi4lite_rvalid     ;
wire                      apb_connect_axi4lite_rready     ;

wire [`LID         -1 :0] apb_connect_soc_clk_awid       ;
wire [`Lawaddr     -1 :0] apb_connect_soc_clk_awaddr     ;
wire [`Lawlen      -1 :0] apb_connect_soc_clk_awlen      ;
wire [`Lawsize     -1 :0] apb_connect_soc_clk_awsize     ;
wire [`Lawburst    -1 :0] apb_connect_soc_clk_awburst    ;
wire [`Lawlock     -1 :0] apb_connect_soc_clk_awlock     ;
wire [`Lawcache    -1 :0] apb_connect_soc_clk_awcache    ;
wire [`Lawprot     -1 :0] apb_connect_soc_clk_awprot     ;
wire                      apb_connect_soc_clk_awvalid    ;
wire                      apb_connect_soc_clk_awready    ;
wire [`LID         -1 :0] apb_connect_soc_clk_wid        ;
wire [64           -1 :0] apb_connect_soc_clk_wdata      ;
wire [8            -1 :0] apb_connect_soc_clk_wstrb      ;
wire                      apb_connect_soc_clk_wlast      ;
wire                      apb_connect_soc_clk_wvalid     ;
wire                      apb_connect_soc_clk_wready     ;
wire [`LID         -1 :0] apb_connect_soc_clk_bid        ;
wire [`Lbresp      -1 :0] apb_connect_soc_clk_bresp      ;
wire                      apb_connect_soc_clk_bvalid     ;
wire                      apb_connect_soc_clk_bready     ;
wire [`LID         -1 :0] apb_connect_soc_clk_arid       ;
wire [`Laraddr     -1 :0] apb_connect_soc_clk_araddr     ;
wire [`Larlen      -1 :0] apb_connect_soc_clk_arlen      ;
wire [`Larsize     -1 :0] apb_connect_soc_clk_arsize     ;
wire [`Larburst    -1 :0] apb_connect_soc_clk_arburst    ;
wire [`Larlock     -1 :0] apb_connect_soc_clk_arlock     ;
wire [`Larcache    -1 :0] apb_connect_soc_clk_arcache    ;
wire [`Larprot     -1 :0] apb_connect_soc_clk_arprot     ;
wire                      apb_connect_soc_clk_arvalid    ;
wire                      apb_connect_soc_clk_arready    ;
wire [`LID         -1 :0] apb_connect_soc_clk_rid        ;
wire [64           -1 :0] apb_connect_soc_clk_rdata      ;
wire [`Lrresp      -1 :0] apb_connect_soc_clk_rresp      ;
wire                      apb_connect_soc_clk_rlast      ;
wire                      apb_connect_soc_clk_rvalid     ;
wire                      apb_connect_soc_clk_rready     ;

wire [`LID         -1 :0] apb_connect_awid       ;
wire [`Lawaddr     -1 :0] apb_connect_awaddr     ;
wire [`Lawlen      -1 :0] apb_connect_awlen      ;
wire [`Lawsize     -1 :0] apb_connect_awsize     ;
wire [`Lawburst    -1 :0] apb_connect_awburst    ;
wire [`Lawlock     -1 :0] apb_connect_awlock     ;
wire [`Lawcache    -1 :0] apb_connect_awcache    ;
wire [`Lawprot     -1 :0] apb_connect_awprot     ;
wire                      apb_connect_awvalid    ;
wire                      apb_connect_awready    ;
wire [`LID         -1 :0] apb_connect_wid        ;
wire [64           -1 :0] apb_connect_wdata      ;
wire [8            -1 :0] apb_connect_wstrb      ;
wire                      apb_connect_wlast      ;
wire                      apb_connect_wvalid     ;
wire                      apb_connect_wready     ;
wire [`LID         -1 :0] apb_connect_bid        ;
wire [`Lbresp      -1 :0] apb_connect_bresp      ;
wire                      apb_connect_bvalid     ;
wire                      apb_connect_bready     ;
wire [`LID         -1 :0] apb_connect_arid       ;
wire [`Laraddr     -1 :0] apb_connect_araddr     ;
wire [`Larlen      -1 :0] apb_connect_arlen      ;
wire [`Larsize     -1 :0] apb_connect_arsize     ;
wire [`Larburst    -1 :0] apb_connect_arburst    ;
wire [`Larlock     -1 :0] apb_connect_arlock     ;
wire [`Larcache    -1 :0] apb_connect_arcache    ;
wire [`Larprot     -1 :0] apb_connect_arprot     ;
wire                      apb_connect_arvalid    ;
wire                      apb_connect_arready    ;
wire [`LID         -1 :0] apb_connect_rid        ;
wire [64           -1 :0] apb_connect_rdata      ;
wire [`Lrresp      -1 :0] apb_connect_rresp      ;
wire                      apb_connect_rlast      ;
wire                      apb_connect_rvalid     ;
wire                      apb_connect_rready     ;

wire [`LID         -1 :0] mem_loop_awid       ;
wire [`Lawaddr     -1 :0] mem_loop_awaddr     ;
wire [`Lawlen      -1 :0] mem_loop_awlen      ;
wire [`Lawsize     -1 :0] mem_loop_awsize     ;
wire [`Lawburst    -1 :0] mem_loop_awburst    ;
wire [`Lawlock     -1 :0] mem_loop_awlock     ;
wire [`Lawcache    -1 :0] mem_loop_awcache    ;
wire [`Lawprot     -1 :0] mem_loop_awprot     ;
wire                      mem_loop_awvalid    ;
wire                      mem_loop_awready    ;
wire [`LID         -1 :0] mem_loop_wid        ;
wire [64           -1 :0] mem_loop_wdata      ;
wire [8            -1 :0] mem_loop_wstrb      ;
wire                      mem_loop_wlast      ;
wire                      mem_loop_wvalid     ;
wire                      mem_loop_wready     ;
wire [`LID         -1 :0] mem_loop_bid        ;
wire [`Lbresp      -1 :0] mem_loop_bresp      ;
wire                      mem_loop_bvalid     ;
wire                      mem_loop_bready     ;
wire [`LID         -1 :0] mem_loop_arid       ;
wire [`Laraddr     -1 :0] mem_loop_araddr     ;
wire [`Larlen      -1 :0] mem_loop_arlen      ;
wire [`Larsize     -1 :0] mem_loop_arsize     ;
wire [`Larburst    -1 :0] mem_loop_arburst    ;
wire [`Larlock     -1 :0] mem_loop_arlock     ;
wire [`Larcache    -1 :0] mem_loop_arcache    ;
wire [`Larprot     -1 :0] mem_loop_arprot     ;
wire                      mem_loop_arvalid    ;
wire                      mem_loop_arready    ;
wire [`LID         -1 :0] mem_loop_rid        ;
wire [64           -1 :0] mem_loop_rdata      ;
wire [`Lrresp      -1 :0] mem_loop_rresp      ;
wire                      mem_loop_rlast      ;
wire                      mem_loop_rvalid     ;
wire                      mem_loop_rready     ;

wire [`LID         -1 :0] apb_s_awid;
wire [`Lawaddr     -1 :0] apb_s_awaddr;
wire [`Lawlen      -1 :0] apb_s_awlen;
wire [`Lawsize     -1 :0] apb_s_awsize;
wire [`Lawburst    -1 :0] apb_s_awburst;
wire [`Lawlock     -1 :0] apb_s_awlock;
wire [`Lawcache    -1 :0] apb_s_awcache;
wire [`Lawprot     -1 :0] apb_s_awprot;
wire                      apb_s_awvalid;
wire                      apb_s_awready;
wire [`LID         -1 :0] apb_s_wid;
wire [`Lwdata      -1 :0] apb_s_wdata;
wire [`Lwstrb      -1 :0] apb_s_wstrb;
wire                      apb_s_wlast;
wire                      apb_s_wvalid;
wire                      apb_s_wready;
wire [`LID         -1 :0] apb_s_bid;
wire [`Lbresp      -1 :0] apb_s_bresp;
wire                      apb_s_bvalid;
wire                      apb_s_bready;
wire [`LID         -1 :0] apb_s_arid;
wire [`Laraddr     -1 :0] apb_s_araddr;
wire [`Larlen      -1 :0] apb_s_arlen;
wire [`Larsize     -1 :0] apb_s_arsize;
wire [`Larburst    -1 :0] apb_s_arburst;
wire [`Larlock     -1 :0] apb_s_arlock;
wire [`Larcache    -1 :0] apb_s_arcache;
wire [`Larprot     -1 :0] apb_s_arprot;
wire                      apb_s_arvalid;
wire                      apb_s_arready;
wire [`LID         -1 :0] apb_s_rid;
wire [`Lrdata      -1 :0] apb_s_rdata;
wire [`Lrresp      -1 :0] apb_s_rresp;
wire                      apb_s_rlast;
wire                      apb_s_rvalid;
wire                      apb_s_rready;

wire          apb_ready_dma0;
wire          apb_start_dma0;
wire          apb_rw_dma0;
wire          apb_psel_dma0;
wire          apb_penable_dma0;
wire[31:0]    apb_addr_dma0;
wire[31:0]    apb_wdata_dma0;
wire[31:0]    apb_rdata_dma0;

wire         dma_int;
wire         dma_ack;
wire         dma_req;

wire                      dma0_gnt;
wire[31:0]                order_addr_in;
wire                      write_dma_end;
wire                      finish_read_order;

//spi
wire [3:0]spi_csn_o ;
wire [3:0]spi_csn_en;
wire spi_sck_o ;
wire spi_sdo_i ;
wire spi_sdo_o ;
wire spi_sdo_en;
wire spi_sdi_i ;
wire spi_sdi_o ;
wire spi_sdi_en;
wire spi_inta_o;
assign     SPI_CLK = spi_sck_o;
assign     SPI_CS  = ~spi_csn_en[0] & spi_csn_o[0];
assign     SPI_MOSI = spi_sdo_en ? 1'bz : spi_sdo_o ;
assign     SPI_MISO = spi_sdi_en ? 1'bz : spi_sdi_o ;
assign     spi_sdo_i = SPI_MOSI;
assign     spi_sdi_i = SPI_MISO;

// confreg
wire   [31:0] cr00,cr01,cr02,cr03,cr04,cr05,cr06,cr07;

//mac
wire md_i_0;      // MII data input (from I/O cell)
wire md_o_0;      // MII data output (to I/O cell)
wire md_oe_0;     // MII data output enable (to I/O cell)
IOBUF mac_mdio(.IO(mdio_0),.I(md_o_0),.T(~md_oe_0),.O(md_i_0));
assign phy_rstn = aresetn;

// LCD
assign LCD_lighton = 1'b1;
wire [15:0] LCD_data_tri_i, LCD_data_tri_o, LCD_data_tri_t;
genvar lcd_i;
generate
for(lcd_i = 0; lcd_i<16; lcd_i = lcd_i+1)begin : lcd_data
IOBUF lcd_buf(
.IO(LCD_data_tri_io[lcd_i]),
.O(LCD_data_tri_i[lcd_i]),
.I(LCD_data_tri_o[lcd_i]),
.T(LCD_data_tri_t[lcd_i])
);
end
endgenerate

// VGA
wire  [5:0] VGA_red, VGA_green, VGA_blue;
genvar VGA_i;
generate
for (VGA_i = 0; VGA_i < 4; VGA_i = VGA_i+1) begin : VGA_gen
//match on-board DAC built by resistor
assign VGA_r[VGA_i] = VGA_red[VGA_i+2] ? 1'b1 : 1'bZ;
assign VGA_g[VGA_i] = VGA_green[VGA_i+2] ? 1'b1 : 1'bZ;
assign VGA_b[VGA_i] = VGA_blue[VGA_i+2] ? 1'b1 : 1'bZ;
end
endgenerate

// PS2
(* MARK_DEBUG = "TRUE" *)wire PS2_clk_tri_i;
(* MARK_DEBUG = "TRUE" *)wire PS2_clk_tri_o;
(* MARK_DEBUG = "TRUE" *)wire PS2_clk_tri_t;
(* MARK_DEBUG = "TRUE" *)wire PS2_dat_tri_i;
(* MARK_DEBUG = "TRUE" *)wire PS2_dat_tri_o;
(* MARK_DEBUG = "TRUE" *)wire PS2_dat_tri_t;
IOBUF PS2_clk_tri_iobuf(.I(PS2_clk_tri_o),
    .IO(PS2_clk_tri_io),
    .O(PS2_clk_tri_i),
    .T(PS2_clk_tri_t)
);
IOBUF PS2_dat_tri_iobuf(
    .I(PS2_dat_tri_o),
    .IO(PS2_dat_tri_io),
    .O(PS2_dat_tri_i),
    .T(PS2_dat_tri_t)
);


//nand
wire       nand_cle   ;
wire       nand_ale   ;
wire [3:0] nand_rdy   ;
wire [3:0] nand_ce    ;
wire       nand_rd    ;
wire       nand_wr    ;
wire       nand_dat_oe;
wire [7:0] nand_dat_i ;
wire [7:0] nand_dat_o ;
wire       nand_int   ;
assign     NAND_CLE = nand_cle;
assign     NAND_ALE = nand_ale;
assign     nand_rdy = {3'd0,NAND_RDY};
assign     NAND_RD  = nand_rd;
assign     NAND_CE  = nand_ce[0];  //low active
assign     NAND_WR  = nand_wr;
generate
    genvar i;
    for(i=0;i<8;i=i+1)
    begin: nand_data_loop
        IOBUF nand_data(.IO(NAND_DATA[i]),.I(nand_dat_o[i]),.T(nand_dat_oe),.O(nand_dat_i[i]));
    end
endgenerate

//uart
wire UART_CTS,   UART_RTS;
wire UART_DTR,   UART_DSR;
wire UART_RI,    UART_DCD;
assign UART_CTS = 1'b0;
assign UART_DSR = 1'b0;
assign UART_DCD = 1'b0;
wire uart0_int   ;
wire uart0_txd_o ;
wire uart0_txd_i ;
wire uart0_txd_oe;
wire uart0_rxd_o ;
wire uart0_rxd_i ;
wire uart0_rxd_oe;
wire uart0_rts_o ;
wire uart0_cts_i ;
wire uart0_dsr_i ;
wire uart0_dcd_i ;
wire uart0_dtr_o ;
wire uart0_ri_i  ;
assign     UART_RX     = uart0_rxd_oe ? 1'bz : uart0_rxd_o ;
assign     UART_TX     = uart0_txd_oe ? 1'bz : uart0_txd_o ;
assign     UART_RTS    = uart0_rts_o ;
assign     UART_DTR    = uart0_dtr_o ;
assign     uart0_txd_i = UART_TX;
assign     uart0_rxd_i = UART_RX;
assign     uart0_cts_i = UART_CTS;
assign     uart0_dcd_i = UART_DCD;
assign     uart0_dsr_i = UART_DSR;
assign     uart0_ri_i  = UART_RI ;

//interrupt
wire mac_int;
wire [7:0] int_out;
wire [7:0] int_n_i;

wire ps2_int;

wire ps2_int_cpu;

xpm_cdc_single #(
    .DEST_SYNC_FF(2),   // DECIMAL; range: 2-10
    .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .SRC_INPUT_REG(1)   // DECIMAL; 0=do not register input, 1=register input
) xpm_cdc_single_inst (
    .dest_out(ps2_int_cpu), // 1-bit output: src_in synchronized to the destination clock domain. This output is registered.
    .dest_clk(cpu_clk), // 1-bit input: Clock signal for the destination clock domain.
    .src_clk(clk_100),   // 1-bit input: optional; required when SRC_INPUT_REG = 1
    .src_in(ps2_int)      // 1-bit input: Input signal to be synchronized to dest_clk domain.
);

// reg [15:0] ps2_int_reg;

// always @(posedge clk_100) begin
//   ps2_int_reg[0] <= ps2_int;
//   ps2_int_reg[1] <= ps2_int_reg[0];
//   ps2_int_reg[2] <= ps2_int_reg[1];
//   ps2_int_reg[3] <= ps2_int_reg[2];
//   ps2_int_reg[4] <= ps2_int_reg[3];
//   ps2_int_reg[5] <= ps2_int_reg[4];
//   ps2_int_reg[6] <= ps2_int_reg[5];
//   ps2_int_reg[7] <= ps2_int_reg[6];
//   ps2_int_reg[8] <= ps2_int_reg[7];
//   ps2_int_reg[9] <= ps2_int_reg[8];
//   ps2_int_reg[10] <= ps2_int_reg[9];
//   ps2_int_reg[11] <= ps2_int_reg[10];
//   ps2_int_reg[12] <= ps2_int_reg[11];
//   ps2_int_reg[13] <= ps2_int_reg[12];
//   ps2_int_reg[14] <= ps2_int_reg[13];
//   ps2_int_reg[15] <= ps2_int_reg[14];
// end

assign int_out = {2'b0, ps2_int_cpu, dma_int,nand_int,spi_inta_o,uart0_int,mac_int};
assign int_n_i = ~int_out;

// reg cpu_aresetn_1;
// reg cpu_aresetn_2;

wire cpu_aresetn;

// always @(posedge cpu_clk) begin
//     cpu_aresetn_1 <= aresetn;
//     cpu_aresetn_2 <= cpu_aresetn_1;
// end

wire cpu_reset_p;

assign cpu_aresetn = ~cpu_reset_p;


// reg clk100_aresetn_1;
// reg clk100_aresetn_2;

// always @(posedge clk_100) begin
//     clk100_aresetn_1 <= aresetn;
//     clk100_aresetn_2 <= clk100_aresetn_1;
// end

// assign aresetn = clk100_aresetn_2;

//uart_ram signals
wire [3 :0] uart_arid   ;
wire [31:0] uart_araddr ;
wire [7 :0] uart_arlen  ;
wire [2 :0] uart_arsize ;
wire [1 :0] uart_arburst;
wire [1 :0] uart_arlock ;
wire [3 :0] uart_arcache;
wire [2 :0] uart_arprot ;
wire        uart_arvalid;
wire        uart_arready;
wire [3 :0] uart_rid    ;
wire [31:0] uart_rdata  ;
wire [1 :0] uart_rresp  ;
wire        uart_rlast  ;
wire        uart_rvalid ;
wire        uart_rready ;

wire        infom_flag;
wire [31:0] start_addr;
wire        mem_flag;
wire [ 7:0] mem_rdata;

//axi_2x1 signals
wire [`LID         -1 :0] m1_arid;
wire [`Laraddr     -1 :0] m1_araddr;
wire [`Larlen      -1 :0] m1_arlen;
wire [`Larsize     -1 :0] m1_arsize;
wire [`Larburst    -1 :0] m1_arburst;
wire [`Larlock     -1 :0] m1_arlock;
wire [`Larcache    -1 :0] m1_arcache;
wire [`Larprot     -1 :0] m1_arprot;
wire                      m1_arvalid;
wire                      m1_arready;
wire [`LID         -1 :0] m1_rid;
wire [`Lrdata      -1 :0] m1_rdata;
wire [`Lrresp      -1 :0] m1_rresp;
wire                      m1_rlast;
wire                      m1_rvalid;
wire                      m1_rready;

// cpu
mycpu_top core_top(
    .ext_int      (int_out),
    .aclk         (cpu_clk),
    .aresetn      (cpu_aresetn  ),
    //AXI interface 
    //read reqest
    .arid         (m0_arid[3:0] ),
    .araddr       (m0_araddr    ),
    .arlen        (m0_arlen     ),
    .arsize       (m0_arsize    ),
    .arburst      (m0_arburst   ),
    .arlock       (m0_arlock    ),
    .arcache      (m0_arcache   ),
    .arprot       (m0_arprot    ),
    .arvalid      (m0_arvalid   ),
    .arready      (m0_arready   ),
    //read back
    .rid          (m0_rid[3:0]  ),
    .rdata        (m0_rdata     ),
    .rresp        (m0_rresp     ),
    .rlast        (m0_rlast     ),
    .rvalid       (m0_rvalid    ),
    .rready       (m0_rready    ),
    //write request
    .awid         (m0_awid[3:0] ),
    .awaddr       (m0_awaddr    ),
    .awlen        (m0_awlen     ),
    .awsize       (m0_awsize    ),
    .awburst      (m0_awburst   ),
    .awlock       (m0_awlock    ),
    .awcache      (m0_awcache   ),
    .awprot       (m0_awprot    ),
    .awvalid      (m0_awvalid   ),
    .awready      (m0_awready   ),
    //write data
    .wid          (m0_wid[3:0]  ),
    .wdata        (m0_wdata     ),
    .wstrb        (m0_wstrb     ),
    .wlast        (m0_wlast     ),
    .wvalid       (m0_wvalid    ),
    .wready       (m0_wready    ),
    //write back
    .bid          (m0_bid[3:0]  ),
    .bresp        (m0_bresp     ),
    .bvalid       (m0_bvalid    ),
    .bready       (m0_bready    )
);

// 这是一个IP
// cpu_axi asyn
axi_clock_converter_0 AXI_CLK_CONVERTER (
    .s_axi_awid       (m0_awid[3:0]       ),
    .s_axi_awaddr     (m0_awaddr          ),
    .s_axi_awlen      (m0_awlen           ),
    .s_axi_awsize     (m0_awsize          ),
    .s_axi_awburst    (m0_awburst         ),
    .s_axi_awlock     (m0_awlock          ),
    .s_axi_awcache    (m0_awcache         ),
    .s_axi_awprot     (m0_awprot          ),
    .s_axi_awqos      (4'b0               ),
    .s_axi_awvalid    (m0_awvalid         ),
    .s_axi_awready    (m0_awready         ),
    .s_axi_wid        (m0_wid[3:0]        ),
    .s_axi_wdata      (m0_wdata           ),
    .s_axi_wstrb      (m0_wstrb           ),
    .s_axi_wlast      (m0_wlast           ),
    .s_axi_wvalid     (m0_wvalid          ),
    .s_axi_wready     (m0_wready          ),
    .s_axi_bid        (m0_bid[3:0]        ),
    .s_axi_bresp      (m0_bresp           ),
    .s_axi_bvalid     (m0_bvalid          ),
    .s_axi_bready     (m0_bready          ),
    .s_axi_arid       (m0_arid[3:0]       ),
    .s_axi_araddr     (m0_araddr          ),
    .s_axi_arlen      (m0_arlen           ),
    .s_axi_arsize     (m0_arsize          ),
    .s_axi_arburst    (m0_arburst         ),
    .s_axi_arlock     (m0_arlock          ),
    .s_axi_arcache    (m0_arcache         ),
    .s_axi_arprot     (m0_arprot          ),
    .s_axi_arqos      (4'b0               ),
    .s_axi_arvalid    (m0_arvalid         ),
    .s_axi_arready    (m0_arready         ),
    .s_axi_rid        (m0_rid[3:0]        ),
    .s_axi_rdata      (m0_rdata           ),
    .s_axi_rresp      (m0_rresp           ),
    .s_axi_rlast      (m0_rlast           ),
    .s_axi_rvalid     (m0_rvalid          ),
    .s_axi_rready     (m0_rready          ),

    .s_axi_aclk	      (cpu_clk            ),
    .s_axi_aresetn    (cpu_aresetn        ),

    .m_axi_awid       (m0_async_awid[3:0] ),
    .m_axi_awaddr     (m0_async_awaddr    ),
    .m_axi_awlen      (m0_async_awlen     ),
    .m_axi_awsize     (m0_async_awsize    ),
    .m_axi_awburst    (m0_async_awburst   ),
    .m_axi_awlock     (m0_async_awlock    ),
    .m_axi_awcache    (m0_async_awcache   ),
    .m_axi_awprot     (m0_async_awprot    ),
    .m_axi_awqos      (                   ),
    .m_axi_awvalid    (m0_async_awvalid   ),
    .m_axi_awready    (m0_async_awready   ),
    .m_axi_wid        (m0_async_wid[3:0]  ),
    .m_axi_wdata      (m0_async_wdata     ),
    .m_axi_wstrb      (m0_async_wstrb     ),
    .m_axi_wlast      (m0_async_wlast     ),
    .m_axi_wvalid     (m0_async_wvalid    ),
    .m_axi_wready     (m0_async_wready    ),
    .m_axi_bid        (m0_async_bid[3:0]  ),
    .m_axi_bresp      (m0_async_bresp     ),
    .m_axi_bvalid     (m0_async_bvalid    ),
    .m_axi_bready     (m0_async_bready    ),
    .m_axi_arid       (m0_async_arid[3:0] ),
    .m_axi_araddr     (m0_async_araddr    ),
    .m_axi_arlen      (m0_async_arlen     ),
    .m_axi_arsize     (m0_async_arsize    ),
    .m_axi_arburst    (m0_async_arburst   ),
    .m_axi_arlock     (m0_async_arlock    ),
    .m_axi_arcache    (m0_async_arcache   ),
    .m_axi_arprot     (m0_async_arprot    ),
    .m_axi_arqos      (                   ),
    .m_axi_arvalid    (m0_async_arvalid   ),
    .m_axi_arready    (m0_async_arready   ),
    .m_axi_rid        (m0_async_rid[3:0]  ),
    .m_axi_rdata      (m0_async_rdata     ),
    .m_axi_rresp      (m0_async_rresp     ),
    .m_axi_rlast      (m0_async_rlast     ),
    .m_axi_rvalid     (m0_async_rvalid    ),
    .m_axi_rready     (m0_async_rready    ),

    .m_axi_aclk	      (aclk               ),
    .m_axi_aresetn    (aresetn            )
);

axi_slave_mux2 AXI_SLAVE_MUX2
(
.axi_s_aresetn     (interconnect_aresetn ),
.spi_boot          (1'b1                 ),

.axi_s_awid        (second_mux_awid        ),
.axi_s_awaddr      (second_mux_awaddr      ),
.axi_s_awlen       (second_mux_awlen       ),
.axi_s_awsize      (second_mux_awsize      ),
.axi_s_awburst     (second_mux_awburst     ),
.axi_s_awlock      (second_mux_awlock      ),
.axi_s_awcache     (second_mux_awcache     ),
.axi_s_awprot      (second_mux_awprot      ),
.axi_s_awvalid     (second_mux_awvalid     ),
.axi_s_awready     (second_mux_awready     ),
.axi_s_wready      (second_mux_wready      ),
.axi_s_wid         (second_mux_wid         ),
.axi_s_wdata       (second_mux_wdata       ),
.axi_s_wstrb       (second_mux_wstrb       ),
.axi_s_wlast       (second_mux_wlast       ),
.axi_s_wvalid      (second_mux_wvalid      ),
.axi_s_bid         (second_mux_bid         ),
.axi_s_bresp       (second_mux_bresp       ),
.axi_s_bvalid      (second_mux_bvalid      ),
.axi_s_bready      (second_mux_bready      ),
.axi_s_arid        (second_mux_arid        ),
.axi_s_araddr      (second_mux_araddr      ),
.axi_s_arlen       (second_mux_arlen       ),
.axi_s_arsize      (second_mux_arsize      ),
.axi_s_arburst     (second_mux_arburst     ),
.axi_s_arlock      (second_mux_arlock      ),
.axi_s_arcache     (second_mux_arcache     ),
.axi_s_arprot      (second_mux_arprot      ),
.axi_s_arvalid     (second_mux_arvalid     ),
.axi_s_arready     (second_mux_arready     ),
.axi_s_rready      (second_mux_rready      ),
.axi_s_rid         (second_mux_rid         ),
.axi_s_rdata       (second_mux_rdata       ),
.axi_s_rresp       (second_mux_rresp       ),
.axi_s_rlast       (second_mux_rlast       ),
.axi_s_rvalid      (second_mux_rvalid      ),

.s0_awid           (mem_loop_awid         ),
.s0_awaddr         (mem_loop_awaddr       ),
.s0_awlen          (mem_loop_awlen        ),
.s0_awsize         (mem_loop_awsize       ),
.s0_awburst        (mem_loop_awburst      ),
.s0_awlock         (mem_loop_awlock       ),
.s0_awcache        (mem_loop_awcache      ),
.s0_awprot         (mem_loop_awprot       ),
.s0_awvalid        (mem_loop_awvalid      ),
.s0_awready        (mem_loop_awready      ),
.s0_wid            (mem_loop_wid          ),
.s0_wdata          (mem_loop_wdata        ),
.s0_wstrb          (mem_loop_wstrb        ),
.s0_wlast          (mem_loop_wlast        ),
.s0_wvalid         (mem_loop_wvalid       ),
.s0_wready         (mem_loop_wready       ),
.s0_bid            (mem_loop_bid          ),
.s0_bresp          (mem_loop_bresp        ),
.s0_bvalid         (mem_loop_bvalid       ),
.s0_bready         (mem_loop_bready       ),
.s0_arid           (mem_loop_arid         ),
.s0_araddr         (mem_loop_araddr       ),
.s0_arlen          (mem_loop_arlen        ),
.s0_arsize         (mem_loop_arsize       ),
.s0_arburst        (mem_loop_arburst      ),
.s0_arlock         (mem_loop_arlock       ),
.s0_arcache        (mem_loop_arcache      ),
.s0_arprot         (mem_loop_arprot       ),
.s0_arvalid        (mem_loop_arvalid      ),
.s0_arready        (mem_loop_arready      ),
.s0_rid            (mem_loop_rid          ),
.s0_rdata          (mem_loop_rdata        ),
.s0_rresp          (mem_loop_rresp        ),
.s0_rlast          (mem_loop_rlast        ),
.s0_rvalid         (mem_loop_rvalid       ),
.s0_rready         (mem_loop_rready       ),

.s1_awid           (apb_connect_soc_clk_awid          ),
.s1_awaddr         (apb_connect_soc_clk_awaddr        ),
.s1_awlen          (apb_connect_soc_clk_awlen         ),
.s1_awsize         (apb_connect_soc_clk_awsize        ),
.s1_awburst        (apb_connect_soc_clk_awburst       ),
.s1_awlock         (apb_connect_soc_clk_awlock        ),
.s1_awcache        (apb_connect_soc_clk_awcache       ),
.s1_awprot         (apb_connect_soc_clk_awprot        ),
.s1_awvalid        (apb_connect_soc_clk_awvalid       ),
.s1_awready        (apb_connect_soc_clk_awready       ),
.s1_wid            (apb_connect_soc_clk_wid           ),
.s1_wdata          (apb_connect_soc_clk_wdata         ),
.s1_wstrb          (apb_connect_soc_clk_wstrb         ),
.s1_wlast          (apb_connect_soc_clk_wlast         ),
.s1_wvalid         (apb_connect_soc_clk_wvalid        ),
.s1_wready         (apb_connect_soc_clk_wready        ),
.s1_bid            (apb_connect_soc_clk_bid           ),
.s1_bresp          (apb_connect_soc_clk_bresp         ),
.s1_bvalid         (apb_connect_soc_clk_bvalid        ),
.s1_bready         (apb_connect_soc_clk_bready        ),
.s1_arid           (apb_connect_soc_clk_arid          ),
.s1_araddr         (apb_connect_soc_clk_araddr        ),
.s1_arlen          (apb_connect_soc_clk_arlen         ),
.s1_arsize         (apb_connect_soc_clk_arsize        ),
.s1_arburst        (apb_connect_soc_clk_arburst       ),
.s1_arlock         (apb_connect_soc_clk_arlock        ),
.s1_arcache        (apb_connect_soc_clk_arcache       ),
.s1_arprot         (apb_connect_soc_clk_arprot        ),
.s1_arvalid        (apb_connect_soc_clk_arvalid       ),
.s1_arready        (apb_connect_soc_clk_arready       ),
.s1_rid            (apb_connect_soc_clk_rid           ),
.s1_rdata          (apb_connect_soc_clk_rdata         ),
.s1_rresp          (apb_connect_soc_clk_rresp         ),
.s1_rlast          (apb_connect_soc_clk_rlast         ),
.s1_rvalid         (apb_connect_soc_clk_rvalid        ),
.s1_rready         (apb_connect_soc_clk_rready        ),

.s2_awid           (fb_write_slave_33M_awid          ),
.s2_awaddr         (fb_write_slave_33M_awaddr        ),
.s2_awlen          (fb_write_slave_33M_awlen         ),
.s2_awsize         (fb_write_slave_33M_awsize        ),
.s2_awburst        (fb_write_slave_33M_awburst       ),
.s2_awlock         (fb_write_slave_33M_awlock        ),
.s2_awcache        (fb_write_slave_33M_awcache       ),
.s2_awprot         (fb_write_slave_33M_awprot        ),
.s2_awvalid        (fb_write_slave_33M_awvalid       ),
.s2_awready        (fb_write_slave_33M_awready       ),
.s2_wid            (fb_write_slave_33M_wid           ),
.s2_wdata          (fb_write_slave_33M_wdata         ),
.s2_wstrb          (fb_write_slave_33M_wstrb         ),
.s2_wlast          (fb_write_slave_33M_wlast         ),
.s2_wvalid         (fb_write_slave_33M_wvalid        ),
.s2_wready         (fb_write_slave_33M_wready        ),
.s2_bid            (fb_write_slave_33M_bid           ),
.s2_bresp          (fb_write_slave_33M_bresp         ),
.s2_bvalid         (fb_write_slave_33M_bvalid        ),
.s2_bready         (fb_write_slave_33M_bready        ),
.s2_arid           (fb_write_slave_33M_arid          ),
.s2_araddr         (fb_write_slave_33M_araddr        ),
.s2_arlen          (fb_write_slave_33M_arlen         ),
.s2_arsize         (fb_write_slave_33M_arsize        ),
.s2_arburst        (fb_write_slave_33M_arburst       ),
.s2_arlock         (fb_write_slave_33M_arlock        ),
.s2_arcache        (fb_write_slave_33M_arcache       ),
.s2_arprot         (fb_write_slave_33M_arprot        ),
.s2_arvalid        (fb_write_slave_33M_arvalid       ),
.s2_arready        (fb_write_slave_33M_arready       ),
.s2_rid            (fb_write_slave_33M_rid           ),
.s2_rdata          (fb_write_slave_33M_rdata         ),
.s2_rresp          (fb_write_slave_33M_rresp         ),
.s2_rlast          (fb_write_slave_33M_rlast         ),
.s2_rvalid         (fb_write_slave_33M_rvalid        ),
.s2_rready         (fb_write_slave_33M_rready        ),

.s3_awid           (fb_read_slave_33M_awid          ),
.s3_awaddr         (fb_read_slave_33M_awaddr        ),
.s3_awlen          (fb_read_slave_33M_awlen         ),
.s3_awsize         (fb_read_slave_33M_awsize        ),
.s3_awburst        (fb_read_slave_33M_awburst       ),
.s3_awlock         (fb_read_slave_33M_awlock        ),
.s3_awcache        (fb_read_slave_33M_awcache       ),
.s3_awprot         (fb_read_slave_33M_awprot        ),
.s3_awvalid        (fb_read_slave_33M_awvalid       ),
.s3_awready        (fb_read_slave_33M_awready       ),
.s3_wid            (fb_read_slave_33M_wid           ),
.s3_wdata          (fb_read_slave_33M_wdata         ),
.s3_wstrb          (fb_read_slave_33M_wstrb         ),
.s3_wlast          (fb_read_slave_33M_wlast         ),
.s3_wvalid         (fb_read_slave_33M_wvalid        ),
.s3_wready         (fb_read_slave_33M_wready        ),
.s3_bid            (fb_read_slave_33M_bid           ),
.s3_bresp          (fb_read_slave_33M_bresp         ),
.s3_bvalid         (fb_read_slave_33M_bvalid        ),
.s3_bready         (fb_read_slave_33M_bready        ),
.s3_arid           (fb_read_slave_33M_arid          ),
.s3_araddr         (fb_read_slave_33M_araddr        ),
.s3_arlen          (fb_read_slave_33M_arlen         ),
.s3_arsize         (fb_read_slave_33M_arsize        ),
.s3_arburst        (fb_read_slave_33M_arburst       ),
.s3_arlock         (fb_read_slave_33M_arlock        ),
.s3_arcache        (fb_read_slave_33M_arcache       ),
.s3_arprot         (fb_read_slave_33M_arprot        ),
.s3_arvalid        (fb_read_slave_33M_arvalid       ),
.s3_arready        (fb_read_slave_33M_arready       ),
.s3_rid            (fb_read_slave_33M_rid           ),
.s3_rdata          (fb_read_slave_33M_rdata         ),
.s3_rresp          (fb_read_slave_33M_rresp         ),
.s3_rlast          (fb_read_slave_33M_rlast         ),
.s3_rvalid         (fb_read_slave_33M_rvalid        ),
.s3_rready         (fb_read_slave_33M_rready        ),

.s4_awid           (tft_slave_33M_awid          ),
.s4_awaddr         (tft_slave_33M_awaddr        ),
.s4_awlen          (tft_slave_33M_awlen         ),
.s4_awsize         (tft_slave_33M_awsize        ),
.s4_awburst        (tft_slave_33M_awburst       ),
.s4_awlock         (tft_slave_33M_awlock        ),
.s4_awcache        (tft_slave_33M_awcache       ),
.s4_awprot         (tft_slave_33M_awprot        ),
.s4_awvalid        (tft_slave_33M_awvalid       ),
.s4_awready        (tft_slave_33M_awready       ),
.s4_wid            (tft_slave_33M_wid           ),
.s4_wdata          (tft_slave_33M_wdata         ),
.s4_wstrb          (tft_slave_33M_wstrb         ),
.s4_wlast          (tft_slave_33M_wlast         ),
.s4_wvalid         (tft_slave_33M_wvalid        ),
.s4_wready         (tft_slave_33M_wready        ),
.s4_bid            (tft_slave_33M_bid           ),
.s4_bresp          (tft_slave_33M_bresp         ),
.s4_bvalid         (tft_slave_33M_bvalid        ),
.s4_bready         (tft_slave_33M_bready        ),
.s4_arid           (tft_slave_33M_arid          ),
.s4_araddr         (tft_slave_33M_araddr        ),
.s4_arlen          (tft_slave_33M_arlen         ),
.s4_arsize         (tft_slave_33M_arsize        ),
.s4_arburst        (tft_slave_33M_arburst       ),
.s4_arlock         (tft_slave_33M_arlock        ),
.s4_arcache        (tft_slave_33M_arcache       ),
.s4_arprot         (tft_slave_33M_arprot        ),
.s4_arvalid        (tft_slave_33M_arvalid       ),
.s4_arready        (tft_slave_33M_arready       ),
.s4_rid            (tft_slave_33M_rid           ),
.s4_rdata          (tft_slave_33M_rdata         ),
.s4_rresp          (tft_slave_33M_rresp         ),
.s4_rlast          (tft_slave_33M_rlast         ),
.s4_rvalid         (tft_slave_33M_rvalid        ),
.s4_rready         (tft_slave_33M_rready        ),

.axi_s_aclk        (aclk                )
);

// AXI_MUX
axi_slave_mux AXI_SLAVE_MUX
(
.axi_s_aresetn     (interconnect_aresetn ),
.spi_boot          (1'b1                 ),

.axi_s_awid        (peripheral_awid        ),
.axi_s_awaddr      (peripheral_awaddr      ),
.axi_s_awlen       (peripheral_awlen       ),
.axi_s_awsize      (peripheral_awsize      ),
.axi_s_awburst     (peripheral_awburst     ),
.axi_s_awlock      (peripheral_awlock      ),
.axi_s_awcache     (peripheral_awcache     ),
.axi_s_awprot      (peripheral_awprot      ),
.axi_s_awvalid     (peripheral_awvalid     ),
.axi_s_awready     (peripheral_awready     ),
.axi_s_wready      (peripheral_wready      ),
.axi_s_wid         (peripheral_wid         ),
.axi_s_wdata       (peripheral_wdata       ),
.axi_s_wstrb       (peripheral_wstrb       ),
.axi_s_wlast       (peripheral_wlast       ),
.axi_s_wvalid      (peripheral_wvalid      ),
.axi_s_bid         (peripheral_bid         ),
.axi_s_bresp       (peripheral_bresp       ),
.axi_s_bvalid      (peripheral_bvalid      ),
.axi_s_bready      (peripheral_bready      ),
.axi_s_arid        (peripheral_arid        ),
.axi_s_araddr      (peripheral_araddr      ),
.axi_s_arlen       (peripheral_arlen       ),
.axi_s_arsize      (peripheral_arsize      ),
.axi_s_arburst     (peripheral_arburst     ),
.axi_s_arlock      (peripheral_arlock      ),
.axi_s_arcache     (peripheral_arcache     ),
.axi_s_arprot      (peripheral_arprot      ),
.axi_s_arvalid     (peripheral_arvalid     ),
.axi_s_arready     (peripheral_arready     ),
.axi_s_rready      (peripheral_rready      ),
.axi_s_rid         (peripheral_rid         ),
.axi_s_rdata       (peripheral_rdata       ),
.axi_s_rresp       (peripheral_rresp       ),
.axi_s_rlast       (peripheral_rlast       ),
.axi_s_rvalid      (peripheral_rvalid      ),

.s0_awid           (second_mux_awid         ),
.s0_awaddr         (second_mux_awaddr       ),
.s0_awlen          (second_mux_awlen        ),
.s0_awsize         (second_mux_awsize       ),
.s0_awburst        (second_mux_awburst      ),
.s0_awlock         (second_mux_awlock       ),
.s0_awcache        (second_mux_awcache      ),
.s0_awprot         (second_mux_awprot       ),
.s0_awvalid        (second_mux_awvalid      ),
.s0_awready        (second_mux_awready      ),
.s0_wid            (second_mux_wid          ),
.s0_wdata          (second_mux_wdata        ),
.s0_wstrb          (second_mux_wstrb        ),
.s0_wlast          (second_mux_wlast        ),
.s0_wvalid         (second_mux_wvalid       ),
.s0_wready         (second_mux_wready       ),
.s0_bid            (second_mux_bid          ),
.s0_bresp          (second_mux_bresp        ),
.s0_bvalid         (second_mux_bvalid       ),
.s0_bready         (second_mux_bready       ),
.s0_arid           (second_mux_arid         ),
.s0_araddr         (second_mux_araddr       ),
.s0_arlen          (second_mux_arlen        ),
.s0_arsize         (second_mux_arsize       ),
.s0_arburst        (second_mux_arburst      ),
.s0_arlock         (second_mux_arlock       ),
.s0_arcache        (second_mux_arcache      ),
.s0_arprot         (second_mux_arprot       ),
.s0_arvalid        (second_mux_arvalid      ),
.s0_arready        (second_mux_arready      ),
.s0_rid            (second_mux_rid          ),
.s0_rdata          (second_mux_rdata        ),
.s0_rresp          (second_mux_rresp        ),
.s0_rlast          (second_mux_rlast        ),
.s0_rvalid         (second_mux_rvalid       ),
.s0_rready         (second_mux_rready       ),

// .s0_awid           (    ),
// .s0_awaddr         (    ),
// .s0_awlen          (    ),
// .s0_awsize         (    ),
// .s0_awburst        (    ),
// .s0_awlock         (    ),
// .s0_awcache        (    ),
// .s0_awprot         (    ),
// .s0_awvalid        (    ),
// .s0_awready        (1'b0),
// .s0_wid            (    ),
// .s0_wdata          (    ),
// .s0_wstrb          (    ),
// .s0_wlast          (    ),
// .s0_wvalid         (    ),
// .s0_wready         (1'b0),
// .s0_bid            (    ),
// .s0_bresp          (    ),
// .s0_bvalid         (1'b0),
// .s0_bready         (    ),
// .s0_arid           (    ),
// .s0_araddr         (    ),
// .s0_arlen          (    ),
// .s0_arsize         (    ),
// .s0_arburst        (    ),
// .s0_arlock         (    ),
// .s0_arcache        (    ),
// .s0_arprot         (    ),
// .s0_arvalid        (    ),
// .s0_arready        (1'b0),
// .s0_rid            (    ),
// .s0_rdata          (    ),
// .s0_rresp          (    ),
// .s0_rlast          (    ),
// .s0_rvalid         (    ),
// .s0_rready         (1'b0),

.s1_awid           (spi_s_awid          ),
.s1_awaddr         (spi_s_awaddr        ),
.s1_awlen          (spi_s_awlen         ),
.s1_awsize         (spi_s_awsize        ),
.s1_awburst        (spi_s_awburst       ),
.s1_awlock         (spi_s_awlock        ),
.s1_awcache        (spi_s_awcache       ),
.s1_awprot         (spi_s_awprot        ),
.s1_awvalid        (spi_s_awvalid       ),
.s1_awready        (spi_s_awready       ),
.s1_wid            (spi_s_wid           ),
.s1_wdata          (spi_s_wdata         ),
.s1_wstrb          (spi_s_wstrb         ),
.s1_wlast          (spi_s_wlast         ),
.s1_wvalid         (spi_s_wvalid        ),
.s1_wready         (spi_s_wready        ),
.s1_bid            (spi_s_bid           ),
.s1_bresp          (spi_s_bresp         ),
.s1_bvalid         (spi_s_bvalid        ),
.s1_bready         (spi_s_bready        ),
.s1_arid           (spi_s_arid          ),
.s1_araddr         (spi_s_araddr        ),
.s1_arlen          (spi_s_arlen         ),
.s1_arsize         (spi_s_arsize        ),
.s1_arburst        (spi_s_arburst       ),
.s1_arlock         (spi_s_arlock        ),
.s1_arcache        (spi_s_arcache       ),
.s1_arprot         (spi_s_arprot        ),
.s1_arvalid        (spi_s_arvalid       ),
.s1_arready        (spi_s_arready       ),
.s1_rid            (spi_s_rid           ),
.s1_rdata          (spi_s_rdata         ),
.s1_rresp          (spi_s_rresp         ),
.s1_rlast          (spi_s_rlast         ),
.s1_rvalid         (spi_s_rvalid        ),
.s1_rready         (spi_s_rready        ),

.s2_awid           (apb_s_awid         ),
.s2_awaddr         (apb_s_awaddr       ),
.s2_awlen          (apb_s_awlen        ),
.s2_awsize         (apb_s_awsize       ),
.s2_awburst        (apb_s_awburst      ),
.s2_awlock         (apb_s_awlock       ),
.s2_awcache        (apb_s_awcache      ),
.s2_awprot         (apb_s_awprot       ),
.s2_awvalid        (apb_s_awvalid      ),
.s2_awready        (apb_s_awready      ),
.s2_wid            (apb_s_wid          ),
.s2_wdata          (apb_s_wdata        ),
.s2_wstrb          (apb_s_wstrb        ),
.s2_wlast          (apb_s_wlast        ),
.s2_wvalid         (apb_s_wvalid       ),
.s2_wready         (apb_s_wready       ),
.s2_bid            (apb_s_bid          ),
.s2_bresp          (apb_s_bresp        ),
.s2_bvalid         (apb_s_bvalid       ),
.s2_bready         (apb_s_bready       ),
.s2_arid           (apb_s_arid         ),
.s2_araddr         (apb_s_araddr       ),
.s2_arlen          (apb_s_arlen        ),
.s2_arsize         (apb_s_arsize       ),
.s2_arburst        (apb_s_arburst      ),
.s2_arlock         (apb_s_arlock       ),
.s2_arcache        (apb_s_arcache      ),
.s2_arprot         (apb_s_arprot       ),
.s2_arvalid        (apb_s_arvalid      ),
.s2_arready        (apb_s_arready      ),
.s2_rid            (apb_s_rid          ),
.s2_rdata          (apb_s_rdata        ),
.s2_rresp          (apb_s_rresp        ),
.s2_rlast          (apb_s_rlast        ),
.s2_rvalid         (apb_s_rvalid       ),
.s2_rready         (apb_s_rready       ),

.s3_awid           (conf_s_awid         ),
.s3_awaddr         (conf_s_awaddr       ),
.s3_awlen          (conf_s_awlen        ),
.s3_awsize         (conf_s_awsize       ),
.s3_awburst        (conf_s_awburst      ),
.s3_awlock         (conf_s_awlock       ),
.s3_awcache        (conf_s_awcache      ),
.s3_awprot         (conf_s_awprot       ),
.s3_awvalid        (conf_s_awvalid      ),
.s3_awready        (conf_s_awready      ),
.s3_wid            (conf_s_wid          ),
.s3_wdata          (conf_s_wdata        ),
.s3_wstrb          (conf_s_wstrb        ),
.s3_wlast          (conf_s_wlast        ),
.s3_wvalid         (conf_s_wvalid       ),
.s3_wready         (conf_s_wready       ),
.s3_bid            (conf_s_bid          ),
.s3_bresp          (conf_s_bresp        ),
.s3_bvalid         (conf_s_bvalid       ),
.s3_bready         (conf_s_bready       ),
.s3_arid           (conf_s_arid         ),
.s3_araddr         (conf_s_araddr       ),
.s3_arlen          (conf_s_arlen        ),
.s3_arsize         (conf_s_arsize       ),
.s3_arburst        (conf_s_arburst      ),
.s3_arlock         (conf_s_arlock       ),
.s3_arcache        (conf_s_arcache      ),
.s3_arprot         (conf_s_arprot       ),
.s3_arvalid        (conf_s_arvalid      ),
.s3_arready        (conf_s_arready      ),
.s3_rid            (conf_s_rid          ),
.s3_rdata          (conf_s_rdata        ),
.s3_rresp          (conf_s_rresp        ),
.s3_rlast          (conf_s_rlast        ),
.s3_rvalid         (conf_s_rvalid       ),
.s3_rready         (conf_s_rready       ),

.s4_awid           (mac_s_awid         ),
.s4_awaddr         (mac_s_awaddr       ),
.s4_awlen          (mac_s_awlen        ),
.s4_awsize         (mac_s_awsize       ),
.s4_awburst        (mac_s_awburst      ),
.s4_awlock         (mac_s_awlock       ),
.s4_awcache        (mac_s_awcache      ),
.s4_awprot         (mac_s_awprot       ),
.s4_awvalid        (mac_s_awvalid      ),
.s4_awready        (mac_s_awready      ),
.s4_wid            (mac_s_wid          ),
.s4_wdata          (mac_s_wdata        ),
.s4_wstrb          (mac_s_wstrb        ),
.s4_wlast          (mac_s_wlast        ),
.s4_wvalid         (mac_s_wvalid       ),
.s4_wready         (mac_s_wready       ),
.s4_bid            (mac_s_bid          ),
.s4_bresp          (mac_s_bresp        ),
.s4_bvalid         (mac_s_bvalid       ),
.s4_bready         (mac_s_bready       ),
.s4_arid           (mac_s_arid         ),
.s4_araddr         (mac_s_araddr       ),
.s4_arlen          (mac_s_arlen        ),
.s4_arsize         (mac_s_arsize       ),
.s4_arburst        (mac_s_arburst      ),
.s4_arlock         (mac_s_arlock       ),
.s4_arcache        (mac_s_arcache      ),
.s4_arprot         (mac_s_arprot       ),
.s4_arvalid        (mac_s_arvalid      ),
.s4_arready        (mac_s_arready      ),
.s4_rid            (mac_s_rid          ),
.s4_rdata          (mac_s_rdata        ),
.s4_rresp          (mac_s_rresp        ),
.s4_rlast          (mac_s_rlast        ),
.s4_rvalid         (mac_s_rvalid       ),
.s4_rready         (mac_s_rready       ),

.axi_s_aclk        (aclk                )
);


//SPI
spi_flash_ctrl SPI
(
.aclk           (aclk              ),
.aresetn        (aresetn           ),
.spi_addr       (16'h1fe8          ),
.fast_startup   (1'b0              ),
.s_awid         (spi_s_awid        ),
.s_awaddr       (spi_s_awaddr      ),
.s_awlen        (spi_s_awlen       ),
.s_awsize       (spi_s_awsize      ),
.s_awburst      (spi_s_awburst     ),
.s_awlock       (spi_s_awlock      ),
.s_awcache      (spi_s_awcache     ),
.s_awprot       (spi_s_awprot      ),
.s_awvalid      (spi_s_awvalid     ),
.s_awready      (spi_s_awready     ),
.s_wready       (spi_s_wready      ),
.s_wid          (spi_s_wid         ),
.s_wdata        (spi_s_wdata       ),
.s_wstrb        (spi_s_wstrb       ),
.s_wlast        (spi_s_wlast       ),
.s_wvalid       (spi_s_wvalid      ),
.s_bid          (spi_s_bid         ),
.s_bresp        (spi_s_bresp       ),
.s_bvalid       (spi_s_bvalid      ),
.s_bready       (spi_s_bready      ),
.s_arid         (spi_s_arid        ),
.s_araddr       (spi_s_araddr      ),
.s_arlen        (spi_s_arlen       ),
.s_arsize       (spi_s_arsize      ),
.s_arburst      (spi_s_arburst     ),
.s_arlock       (spi_s_arlock      ),
.s_arcache      (spi_s_arcache     ),
.s_arprot       (spi_s_arprot      ),
.s_arvalid      (spi_s_arvalid     ),
.s_arready      (spi_s_arready     ),
.s_rready       (spi_s_rready      ),
.s_rid          (spi_s_rid         ),
.s_rdata        (spi_s_rdata       ),
.s_rresp        (spi_s_rresp       ),
.s_rlast        (spi_s_rlast       ),
.s_rvalid       (spi_s_rvalid      ),

.power_down_req (1'b0              ),
.power_down_ack (                  ),
.csn_o          (spi_csn_o         ),
.csn_en         (spi_csn_en        ),
.sck_o          (spi_sck_o         ),
.sdo_i          (spi_sdo_i         ),
.sdo_o          (spi_sdo_o         ),
.sdo_en         (spi_sdo_en        ), // active low
.sdi_i          (spi_sdi_i         ),
.sdi_o          (spi_sdi_o         ),
.sdi_en         (spi_sdi_en        ),
.inta_o         (spi_inta_o        )
);

(* MARK_DEBUG = "TRUE" *) wire [31: 0] vga_reg;

//confreg
confreg CONFREG(
.aclk              (aclk               ),
.aresetn           (aresetn            ),
.s_awid            (conf_s_awid        ),
.s_awaddr          (conf_s_awaddr      ),
.s_awlen           (conf_s_awlen       ),
.s_awsize          (conf_s_awsize      ),
.s_awburst         (conf_s_awburst     ),
.s_awlock          (conf_s_awlock      ),
.s_awcache         (conf_s_awcache     ),
.s_awprot          (conf_s_awprot      ),
.s_awvalid         (conf_s_awvalid     ),
.s_awready         (conf_s_awready     ),
.s_wready          (conf_s_wready      ),
.s_wid             (conf_s_wid         ),
.s_wdata           (conf_s_wdata       ),
.s_wstrb           (conf_s_wstrb       ),
.s_wlast           (conf_s_wlast       ),
.s_wvalid          (conf_s_wvalid      ),
.s_bid             (conf_s_bid         ),
.s_bresp           (conf_s_bresp       ),
.s_bvalid          (conf_s_bvalid      ),
.s_bready          (conf_s_bready      ),
.s_arid            (conf_s_arid        ),
.s_araddr          (conf_s_araddr      ),
.s_arlen           (conf_s_arlen       ),
.s_arsize          (conf_s_arsize      ),
.s_arburst         (conf_s_arburst     ),
.s_arlock          (conf_s_arlock      ),
.s_arcache         (conf_s_arcache     ),
.s_arprot          (conf_s_arprot      ),
.s_arvalid         (conf_s_arvalid     ),
.s_arready         (conf_s_arready     ),
.s_rready          (conf_s_rready      ),
.s_rid             (conf_s_rid         ),
.s_rdata           (conf_s_rdata       ),
.s_rresp           (conf_s_rresp       ),
.s_rlast           (conf_s_rlast       ),
.s_rvalid          (conf_s_rvalid      ),

//dma
.order_addr_reg    (order_addr_in      ),
.write_dma_end     (write_dma_end      ),
.finish_read_order (finish_read_order  ),

//cr00~cr07
.cr00              (cr00        ),
.cr01              (cr01        ),
.cr02              (cr02        ),
.cr03              (cr03        ),
.cr04              (cr04        ),
.cr05              (cr05        ),
.cr06              (cr06        ),
.cr07              (cr07        ),

.led               (led         ),
.led_rg0           (led_rg0     ),
.led_rg1           (led_rg1     ),
.num_csn           (num_csn     ),
.num_a_g           (num_a_g     ),
.switch            (switch      ),
.btn_key_col       (btn_key_col ),
.btn_key_row       (btn_key_row ),
.btn_step          (btn_step    ),

.vga_reg(vga_reg)
);

//MAC top
ethernet_top ETHERNET_TOP(

    .hclk       (aclk   ),
    .hrst_      (aresetn),
    //axi master
    .mawid_o    (mac_m_awid    ),
    .mawaddr_o  (mac_m_awaddr  ),
    .mawlen_o   (mac_m_awlen   ),
    .mawsize_o  (mac_m_awsize  ),
    .mawburst_o (mac_m_awburst ),
    .mawlock_o  (mac_m_awlock  ),
    .mawcache_o (mac_m_awcache ),
    .mawprot_o  (mac_m_awprot  ),
    .mawvalid_o (mac_m_awvalid ),
    .mawready_i (mac_m_awready ),
    .mwid_o     (mac_m_wid     ),
    .mwdata_o   (mac_m_wdata   ),
    .mwstrb_o   (mac_m_wstrb   ),
    .mwlast_o   (mac_m_wlast   ),
    .mwvalid_o  (mac_m_wvalid  ),
    .mwready_i  (mac_m_wready  ),
    .mbid_i     (mac_m_bid     ),
    .mbresp_i   (mac_m_bresp   ),
    .mbvalid_i  (mac_m_bvalid  ),
    .mbready_o  (mac_m_bready  ),
    .marid_o    (mac_m_arid    ),
    .maraddr_o  (mac_m_araddr  ),
    .marlen_o   (mac_m_arlen   ),
    .marsize_o  (mac_m_arsize  ),
    .marburst_o (mac_m_arburst ),
    .marlock_o  (mac_m_arlock  ),
    .marcache_o (mac_m_arcache ),
    .marprot_o  (mac_m_arprot  ),
    .marvalid_o (mac_m_arvalid ),
    .marready_i (mac_m_arready ),
    .mrid_i     (mac_m_rid     ),
    .mrdata_i   (mac_m_rdata   ),
    .mrresp_i   (mac_m_rresp   ),
    .mrlast_i   (mac_m_rlast   ),
    .mrvalid_i  (mac_m_rvalid  ),
    .mrready_o  (mac_m_rready  ),
    //axi slaver
    .sawid_i    (mac_s_awid    ),
    .sawaddr_i  (mac_s_awaddr  ),
    .sawlen_i   (mac_s_awlen   ),
    .sawsize_i  (mac_s_awsize  ),
    .sawburst_i (mac_s_awburst ),
    .sawlock_i  (mac_s_awlock  ),
    .sawcache_i (mac_s_awcache ),
    .sawprot_i  (mac_s_awprot  ),
    .sawvalid_i (mac_s_awvalid ),
    .sawready_o (mac_s_awready ),
    .swid_i     (mac_s_wid     ),
    .swdata_i   (mac_s_wdata   ),
    .swstrb_i   (mac_s_wstrb   ),
    .swlast_i   (mac_s_wlast   ),
    .swvalid_i  (mac_s_wvalid  ),
    .swready_o  (mac_s_wready  ),
    .sbid_o     (mac_s_bid     ),
    .sbresp_o   (mac_s_bresp   ),
    .sbvalid_o  (mac_s_bvalid  ),
    .sbready_i  (mac_s_bready  ),
    .sarid_i    (mac_s_arid    ),
    .saraddr_i  (mac_s_araddr  ),
    .sarlen_i   (mac_s_arlen   ),
    .sarsize_i  (mac_s_arsize  ),
    .sarburst_i (mac_s_arburst ),
    .sarlock_i  (mac_s_arlock  ),
    .sarcache_i (mac_s_arcache ),
    .sarprot_i  (mac_s_arprot  ),
    .sarvalid_i (mac_s_arvalid ),
    .sarready_o (mac_s_arready ),
    .srid_o     (mac_s_rid     ),
    .srdata_o   (mac_s_rdata   ),
    .srresp_o   (mac_s_rresp   ),
    .srlast_o   (mac_s_rlast   ),
    .srvalid_o  (mac_s_rvalid  ),
    .srready_i  (mac_s_rready  ),

    .interrupt_0 (mac_int),

    // I/O pad interface signals
    //TX
    .mtxclk_0    (mtxclk_0 ),
    .mtxen_0     (mtxen_0  ),
    .mtxd_0      (mtxd_0   ),
    .mtxerr_0    (mtxerr_0 ),
    //RX
    .mrxclk_0    (mrxclk_0 ),
    .mrxdv_0     (mrxdv_0  ),
    .mrxd_0      (mrxd_0   ),
    .mrxerr_0    (mrxerr_0 ),
    .mcoll_0     (mcoll_0  ),
    .mcrs_0      (mcrs_0   ),
    // MIIM
    .mdc_0       (mdc_0    ),
    .md_i_0      (md_i_0   ),
    .md_o_0      (md_o_0   ),
    .md_oe_0     (md_oe_0  )

);

//ddr3
wire   c1_sys_clk_i;
wire   c1_clk_ref_i;
wire   c1_sys_rst_i;
wire   c1_calib_done;
wire   c1_clk0;
wire   c1_rst0;
wire        ddr_aresetn;
wire clk_100;
wire clk_25;
wire aresetn;

wire clk_locked;
wire peripheral_aresetn;
wire interconnect_aresetn;

clk_pll_33  clk_pll_33
 (
  // Clock out ports
  .clk_out1(cpu_clk),  //50MHz
  .clk_out2(uncore_clk), //33MHz
  .clk_100(clk_100), //100MHz
  .clk_25(clk_25),
 // Clock in ports
  .clk_in1(clk),        //100MHz

  .resetn(resetn),
  .locked(clk_locked)
 );

clk_wiz_0  clk_pll_1
(
    .clk_out1(c1_clk_ref_i),  //200MHz
    .clk_in1(clk)             //100MHz
);

assign c1_sys_clk_i      = clk;
assign c1_sys_rst_i      = clk_locked;
assign aclk              = uncore_clk;
//assign aclk              = c1_clk0;
// Reset to the AXI shim
// reg c1_calib_done_0;
// reg c1_calib_done_1;
// reg c1_rst0_0;
// reg c1_rst0_1;
// reg interconnect_aresetn_0;
/*always @(posedge aclk)
begin
    c1_calib_done_0 <= c1_calib_done;
    c1_calib_done_1 <= c1_calib_done_0;
    c1_rst0_0       <= c1_rst0;
    c1_rst0_1       <= c1_rst0_0;

    interconnect_aresetn_0 <= ~c1_rst0_1 && c1_calib_done_1;
    interconnect_aresetn   <= interconnect_aresetn_0 ;
end*/
// always @(posedge c1_clk0)
// begin
//     interconnect_aresetn <= ~c1_rst0 && c1_calib_done;
// end

//axi 3x1
axi_interconnect_0 mig_axi_interconnect (
    .INTERCONNECT_ACLK    (c1_clk0             ),
    .INTERCONNECT_ARESETN (interconnect_aresetn),
    .S00_AXI_ARESET_OUT_N (                    ),
    .S00_AXI_ACLK         (aclk                ),
    .S00_AXI_AWID         (s0_awid[3:0]        ),
    .S00_AXI_AWADDR       (s0_awaddr           ),
    .S00_AXI_AWLEN        ({4'b0,s0_awlen}     ),
    .S00_AXI_AWSIZE       (s0_awsize           ),
    .S00_AXI_AWBURST      (s0_awburst          ),
    .S00_AXI_AWLOCK       (s0_awlock[0:0]      ),
    .S00_AXI_AWCACHE      (s0_awcache          ),
    .S00_AXI_AWPROT       (s0_awprot           ),
    .S00_AXI_AWQOS        (4'b0                ),
    .S00_AXI_AWVALID      (s0_awvalid          ),
    .S00_AXI_AWREADY      (s0_awready          ),
    .S00_AXI_WDATA        (s0_wdata            ),
    .S00_AXI_WSTRB        (s0_wstrb            ),
    .S00_AXI_WLAST        (s0_wlast            ),
    .S00_AXI_WVALID       (s0_wvalid           ),
    .S00_AXI_WREADY       (s0_wready           ),
    .S00_AXI_BID          (s0_bid[3:0]         ),
    .S00_AXI_BRESP        (s0_bresp            ),
    .S00_AXI_BVALID       (s0_bvalid           ),
    .S00_AXI_BREADY       (s0_bready           ),
    .S00_AXI_ARID         (s0_arid[3:0]        ),
    .S00_AXI_ARADDR       (s0_araddr           ),
    .S00_AXI_ARLEN        ({4'b0,s0_arlen}     ),
    .S00_AXI_ARSIZE       (s0_arsize           ),
    .S00_AXI_ARBURST      (s0_arburst          ),
    .S00_AXI_ARLOCK       (s0_arlock[0:0]      ),
    .S00_AXI_ARCACHE      (s0_arcache          ),
    .S00_AXI_ARPROT       (s0_arprot           ),
    .S00_AXI_ARQOS        (4'b0                ),
    .S00_AXI_ARVALID      (s0_arvalid          ),
    .S00_AXI_ARREADY      (s0_arready          ),
    .S00_AXI_RID          (s0_rid[3:0]         ),
    .S00_AXI_RDATA        (s0_rdata            ),
    .S00_AXI_RRESP        (s0_rresp            ),
    .S00_AXI_RLAST        (s0_rlast            ),
    .S00_AXI_RVALID       (s0_rvalid           ),
    .S00_AXI_RREADY       (s0_rready           ),

    .S01_AXI_ARESET_OUT_N (                    ),
    .S01_AXI_ACLK         (aclk                ),
    .S01_AXI_AWID         (mac_m_awid[3:0]     ),
    .S01_AXI_AWADDR       (mac_m_awaddr        ),
    .S01_AXI_AWLEN        ({4'b0,mac_m_awlen}  ),
    .S01_AXI_AWSIZE       (mac_m_awsize        ),
    .S01_AXI_AWBURST      (mac_m_awburst       ),
    .S01_AXI_AWLOCK       (mac_m_awlock[0:0]   ),
    .S01_AXI_AWCACHE      (mac_m_awcache       ),
    .S01_AXI_AWPROT       (mac_m_awprot        ),
    .S01_AXI_AWQOS        (4'b0                ),
    .S01_AXI_AWVALID      (mac_m_awvalid       ),
    .S01_AXI_AWREADY      (mac_m_awready       ),
    .S01_AXI_WDATA        (mac_m_wdata         ),
    .S01_AXI_WSTRB        (mac_m_wstrb         ),
    .S01_AXI_WLAST        (mac_m_wlast         ),
    .S01_AXI_WVALID       (mac_m_wvalid        ),
    .S01_AXI_WREADY       (mac_m_wready        ),
    .S01_AXI_BID          (mac_m_bid[3:0]      ),
    .S01_AXI_BRESP        (mac_m_bresp         ),
    .S01_AXI_BVALID       (mac_m_bvalid        ),
    .S01_AXI_BREADY       (mac_m_bready        ),
    .S01_AXI_ARID         (mac_m_arid[3:0]     ),
    .S01_AXI_ARADDR       (mac_m_araddr        ),
    .S01_AXI_ARLEN        ({4'b0,mac_m_arlen}  ),
    .S01_AXI_ARSIZE       (mac_m_arsize        ),
    .S01_AXI_ARBURST      (mac_m_arburst       ),
    .S01_AXI_ARLOCK       (mac_m_arlock[0:0]   ),
    .S01_AXI_ARCACHE      (mac_m_arcache       ),
    .S01_AXI_ARPROT       (mac_m_arprot        ),
    .S01_AXI_ARQOS        (4'b0                ),
    .S01_AXI_ARVALID      (mac_m_arvalid       ),
    .S01_AXI_ARREADY      (mac_m_arready       ),
    .S01_AXI_RID          (mac_m_rid[3:0]      ),
    .S01_AXI_RDATA        (mac_m_rdata         ),
    .S01_AXI_RRESP        (mac_m_rresp         ),
    .S01_AXI_RLAST        (mac_m_rlast         ),
    .S01_AXI_RVALID       (mac_m_rvalid        ),
    .S01_AXI_RREADY       (mac_m_rready        ),

    .S02_AXI_ARESET_OUT_N (                    ),
    .S02_AXI_ACLK         (aclk                ),
    .S02_AXI_AWID         (dma0_awid           ),
    .S02_AXI_AWADDR       (dma0_awaddr         ),
    .S02_AXI_AWLEN        ({4'd0,dma0_awlen}   ),
    .S02_AXI_AWSIZE       (dma0_awsize         ),
    .S02_AXI_AWBURST      (dma0_awburst        ),
    .S02_AXI_AWLOCK       (dma0_awlock[0:0]    ),
    .S02_AXI_AWCACHE      (dma0_awcache        ),
    .S02_AXI_AWPROT       (dma0_awprot         ),
    .S02_AXI_AWQOS        (4'b0                ),
    .S02_AXI_AWVALID      (dma0_awvalid        ),
    .S02_AXI_AWREADY      (dma0_awready        ),
    .S02_AXI_WDATA        (dma0_wdata          ),
    .S02_AXI_WSTRB        (dma0_wstrb          ),
    .S02_AXI_WLAST        (dma0_wlast          ),
    .S02_AXI_WVALID       (dma0_wvalid         ),
    .S02_AXI_WREADY       (dma0_wready         ),
    .S02_AXI_BID          (dma0_bid            ),
    .S02_AXI_BRESP        (dma0_bresp          ),
    .S02_AXI_BVALID       (dma0_bvalid         ),
    .S02_AXI_BREADY       (dma0_bready         ),
    .S02_AXI_ARID         (dma0_arid           ),
    .S02_AXI_ARADDR       (dma0_araddr         ),
    .S02_AXI_ARLEN        ({4'd0,dma0_arlen}   ),
    .S02_AXI_ARSIZE       (dma0_arsize         ),
    .S02_AXI_ARBURST      (dma0_arburst        ),
    .S02_AXI_ARLOCK       (dma0_arlock[0:0]    ),
    .S02_AXI_ARCACHE      (dma0_arcache        ),
    .S02_AXI_ARPROT       (dma0_arprot         ),
    .S02_AXI_ARQOS        (4'b0                ),
    .S02_AXI_ARVALID      (dma0_arvalid        ),
    .S02_AXI_ARREADY      (dma0_arready        ),
    .S02_AXI_RID          (dma0_rid            ),
    .S02_AXI_RDATA        (dma0_rdata          ),
    .S02_AXI_RRESP        (dma0_rresp          ),
    .S02_AXI_RLAST        (dma0_rlast          ),
    .S02_AXI_RVALID       (dma0_rvalid         ),
    .S02_AXI_RREADY       (dma0_rready         ),

    .S03_AXI_ARESET_OUT_N (                    ),
    .S03_AXI_ACLK         (aclk                ),
    .S03_AXI_AWID         (mem_loop_awid           ),
    .S03_AXI_AWADDR       (mem_loop_awaddr         ),
    .S03_AXI_AWLEN  ({4'd0,mem_loop_awlen}   ),
    .S03_AXI_AWSIZE       (mem_loop_awsize         ),
    .S03_AXI_AWBURST      (mem_loop_awburst        ),
    .S03_AXI_AWLOCK       (mem_loop_awlock[0:0]    ),
    .S03_AXI_AWCACHE      (mem_loop_awcache        ),
    .S03_AXI_AWPROT       (mem_loop_awprot         ),
    .S03_AXI_AWVALID      (mem_loop_awvalid        ),
    .S03_AXI_AWREADY      (mem_loop_awready        ),
    .S03_AXI_WDATA        (mem_loop_wdata          ),
    .S03_AXI_WSTRB        (mem_loop_wstrb          ),
    .S03_AXI_WLAST        (mem_loop_wlast          ),
    .S03_AXI_WVALID       (mem_loop_wvalid         ),
    .S03_AXI_WREADY       (mem_loop_wready         ),
    .S03_AXI_BID          (mem_loop_bid            ),
    .S03_AXI_BRESP        (mem_loop_bresp          ),
    .S03_AXI_BVALID       (mem_loop_bvalid         ),
    .S03_AXI_BREADY       (mem_loop_bready         ),
    .S03_AXI_ARID         (mem_loop_arid           ),
    .S03_AXI_ARADDR       (mem_loop_araddr         ),
    .S03_AXI_ARLEN  ({4'd0,mem_loop_arlen}   ),
    .S03_AXI_ARSIZE       (mem_loop_arsize         ),
    .S03_AXI_ARBURST      (mem_loop_arburst        ),
    .S03_AXI_ARLOCK       (mem_loop_arlock[0:0]    ),
    .S03_AXI_ARCACHE      (mem_loop_arcache        ),
    .S03_AXI_ARPROT       (mem_loop_arprot         ),
    .S03_AXI_ARVALID      (mem_loop_arvalid        ),
    .S03_AXI_ARREADY      (mem_loop_arready        ),
    .S03_AXI_RID          (mem_loop_rid            ),
    .S03_AXI_RDATA        (mem_loop_rdata          ),
    .S03_AXI_RRESP        (mem_loop_rresp          ),
    .S03_AXI_RLAST        (mem_loop_rlast          ),
    .S03_AXI_RVALID       (mem_loop_rvalid         ),
    .S03_AXI_RREADY       (mem_loop_rready         ),
    .S03_AXI_ARQOS        (4'b0                ),
    .S03_AXI_AWQOS        (4'b0                ),

    .S04_AXI_ARESET_OUT_N (                    ),
    .S04_AXI_ACLK         (clk_100                ),
    .S04_AXI_AWID         (4'b0                    ),
    .S04_AXI_AWADDR       (tft_100M_awaddr         ),
    .S04_AXI_AWLEN        (tft_100M_awlen          ),
    .S04_AXI_AWSIZE       (tft_100M_awsize         ),
    .S04_AXI_AWBURST      (tft_100M_awburst        ),
    .S04_AXI_AWLOCK       (tft_100M_awlock         ),
    .S04_AXI_AWCACHE      (tft_100M_awcache        ),
    .S04_AXI_AWPROT       (tft_100M_awprot         ),
    .S04_AXI_AWVALID      (tft_100M_awvalid        ),
    .S04_AXI_AWREADY      (tft_100M_awready        ),
    .S04_AXI_WDATA        (tft_100M_wdata          ),
    .S04_AXI_WSTRB        (tft_100M_wstrb          ),
    .S04_AXI_WLAST        (tft_100M_wlast          ),
    .S04_AXI_WVALID       (tft_100M_wvalid         ),
    .S04_AXI_WREADY       (tft_100M_wready         ),
    .S04_AXI_BID          (4'b0                    ),
    .S04_AXI_BRESP        (tft_100M_bresp          ),
    .S04_AXI_BVALID       (tft_100M_bvalid         ),
    .S04_AXI_BREADY       (tft_100M_bready         ),
    .S04_AXI_ARID         (4'b0                    ),
    .S04_AXI_ARADDR       (tft_100M_araddr         ),
    .S04_AXI_ARLEN        (tft_100M_arlen          ),
    .S04_AXI_ARSIZE       (tft_100M_arsize         ),
    .S04_AXI_ARBURST      (tft_100M_arburst        ),
    .S04_AXI_ARLOCK       (tft_100M_arlock         ),
    .S04_AXI_ARCACHE      (tft_100M_arcache        ),
    .S04_AXI_ARPROT       (tft_100M_arprot         ),
    .S04_AXI_ARVALID      (tft_100M_arvalid        ),
    .S04_AXI_ARREADY      (tft_100M_arready        ),
    .S04_AXI_RID          (4'b0                    ),
    .S04_AXI_RDATA        (tft_100M_rdata          ),
    .S04_AXI_RRESP        (tft_100M_rresp          ),
    .S04_AXI_RLAST        (tft_100M_rlast          ),
    .S04_AXI_RVALID       (tft_100M_rvalid         ),
    .S04_AXI_RREADY       (tft_100M_rready         ),
    .S04_AXI_ARQOS        (4'b0                    ),
    .S04_AXI_AWQOS        (4'b0                    ),

    .S05_AXI_ARESET_OUT_N (                         ),
    .S05_AXI_ACLK         (clk_100                  ),
    .S05_AXI_AWID         (4'b0                     ),
    .S05_AXI_ARID         (4'b0                     ),
    .S05_AXI_BID          (4'b0                     ),
    .S05_AXI_RID          (4'b0                     ),
    .S05_AXI_AWADDR       (fb_wr_video_AWADDR       ),
    .S05_AXI_AWLEN        (fb_wr_video_AWLEN        ),
    .S05_AXI_AWSIZE       (fb_wr_video_AWSIZE       ),
    .S05_AXI_AWBURST      (fb_wr_video_AWBURST      ),
    .S05_AXI_AWLOCK       (fb_wr_video_AWLOCK       ),
    .S05_AXI_AWCACHE      (fb_wr_video_AWCACHE      ),
    .S05_AXI_AWPROT       (fb_wr_video_AWPROT       ),
    .S05_AXI_AWVALID      (fb_wr_video_AWVALID      ),
    .S05_AXI_AWREADY      (fb_wr_video_AWREADY      ),
    .S05_AXI_WDATA        (fb_wr_video_WDATA        ),
    .S05_AXI_WSTRB        (fb_wr_video_WSTRB        ),
    .S05_AXI_WLAST        (fb_wr_video_WLAST        ),
    .S05_AXI_WVALID       (fb_wr_video_WVALID       ),
    .S05_AXI_WREADY       (fb_wr_video_WREADY       ),
    .S05_AXI_BRESP        (fb_wr_video_BRESP        ),
    .S05_AXI_BVALID       (fb_wr_video_BVALID       ),
    .S05_AXI_BREADY       (fb_wr_video_BREADY       ),
    .S05_AXI_ARADDR       (fb_wr_video_ARADDR       ),
    .S05_AXI_ARLEN        (fb_wr_video_ARLEN        ),
    .S05_AXI_ARSIZE       (fb_wr_video_ARSIZE       ),
    .S05_AXI_ARBURST      (fb_wr_video_ARBURST      ),
    .S05_AXI_ARLOCK       (fb_wr_video_ARLOCK       ),
    .S05_AXI_ARCACHE      (fb_wr_video_ARCACHE      ),
    .S05_AXI_ARPROT       (fb_wr_video_ARPROT       ),
    .S05_AXI_ARVALID      (fb_wr_video_ARVALID      ),
    .S05_AXI_ARREADY      (fb_wr_video_ARREADY      ),
    .S05_AXI_RDATA        (fb_wr_video_RDATA        ),
    .S05_AXI_RRESP        (fb_wr_video_RRESP        ),
    .S05_AXI_RLAST        (fb_wr_video_RLAST        ),
    .S05_AXI_RVALID       (fb_wr_video_RVALID       ),
    .S05_AXI_RREADY       (fb_wr_video_RREADY       ),
    .S05_AXI_ARQOS        (fb_wr_video_ARQOS        ),
    .S05_AXI_AWQOS        (fb_wr_video_ARQOS        ),

    .S06_AXI_ARESET_OUT_N (                         ),
    .S06_AXI_ACLK         (clk_100                  ),
    .S06_AXI_AWID         (4'b0                     ),
    .S06_AXI_ARID         (4'b0                     ),
    .S06_AXI_BID          (4'b0                     ),
    .S06_AXI_RID          (4'b0                     ),
    .S06_AXI_AWADDR       (fb_rd_video_AWADDR       ),
    .S06_AXI_AWLEN        (fb_rd_video_AWLEN        ),
    .S06_AXI_AWSIZE       (fb_rd_video_AWSIZE       ),
    .S06_AXI_AWBURST      (fb_rd_video_AWBURST      ),
    .S06_AXI_AWLOCK       (fb_rd_video_AWLOCK       ),
    .S06_AXI_AWCACHE      (fb_rd_video_AWCACHE      ),
    .S06_AXI_AWPROT       (fb_rd_video_AWPROT       ),
    .S06_AXI_AWVALID      (fb_rd_video_AWVALID      ),
    .S06_AXI_AWREADY      (fb_rd_video_AWREADY      ),
    .S06_AXI_WDATA        (fb_rd_video_WDATA        ),
    .S06_AXI_WSTRB        (fb_rd_video_WSTRB        ),
    .S06_AXI_WLAST        (fb_rd_video_WLAST        ),
    .S06_AXI_WVALID       (fb_rd_video_WVALID       ),
    .S06_AXI_WREADY       (fb_rd_video_WREADY       ),
    .S06_AXI_BRESP        (fb_rd_video_BRESP        ),
    .S06_AXI_BVALID       (fb_rd_video_BVALID       ),
    .S06_AXI_BREADY       (fb_rd_video_BREADY       ),
    .S06_AXI_ARADDR       (fb_rd_video_ARADDR       ),
    .S06_AXI_ARLEN        (fb_rd_video_ARLEN        ),
    .S06_AXI_ARSIZE       (fb_rd_video_ARSIZE       ),
    .S06_AXI_ARBURST      (fb_rd_video_ARBURST      ),
    .S06_AXI_ARLOCK       (fb_rd_video_ARLOCK       ),
    .S06_AXI_ARCACHE      (fb_rd_video_ARCACHE      ),
    .S06_AXI_ARPROT       (fb_rd_video_ARPROT       ),
    .S06_AXI_ARVALID      (fb_rd_video_ARVALID      ),
    .S06_AXI_ARREADY      (fb_rd_video_ARREADY      ),
    .S06_AXI_RDATA        (fb_rd_video_RDATA        ),
    .S06_AXI_RRESP        (fb_rd_video_RRESP        ),
    .S06_AXI_RLAST        (fb_rd_video_RLAST        ),
    .S06_AXI_RVALID       (fb_rd_video_RVALID       ),
    .S06_AXI_RREADY       (fb_rd_video_RREADY       ),
    .S06_AXI_ARQOS        (fb_rd_video_ARQOS        ),
    .S06_AXI_AWQOS        (fb_rd_video_ARQOS        ),


    .M00_AXI_ARESET_OUT_N (ddr_aresetn         ),
    .M00_AXI_ACLK         (c1_clk0             ),
    .M00_AXI_AWID         (mig_awid            ),
    .M00_AXI_AWADDR       (mig_awaddr          ),
    .M00_AXI_AWLEN        ({mig_awlen}         ),
    .M00_AXI_AWSIZE       (mig_awsize          ),
    .M00_AXI_AWBURST      (mig_awburst         ),
    .M00_AXI_AWLOCK       (mig_awlock[0:0]     ),
    .M00_AXI_AWCACHE      (mig_awcache         ),
    .M00_AXI_AWPROT       (mig_awprot          ),
    .M00_AXI_AWQOS        (                    ),
    .M00_AXI_AWVALID      (mig_awvalid         ),
    .M00_AXI_AWREADY      (mig_awready         ),
    .M00_AXI_WDATA        (mig_wdata           ),
    .M00_AXI_WSTRB        (mig_wstrb           ),
    .M00_AXI_WLAST        (mig_wlast           ),
    .M00_AXI_WVALID       (mig_wvalid          ),
    .M00_AXI_WREADY       (mig_wready          ),
    .M00_AXI_BID          (mig_bid             ),
    .M00_AXI_BRESP        (mig_bresp           ),
    .M00_AXI_BVALID       (mig_bvalid          ),
    .M00_AXI_BREADY       (mig_bready          ),
    .M00_AXI_ARID         (mig_arid            ),
    .M00_AXI_ARADDR       (mig_araddr          ),
    .M00_AXI_ARLEN        ({mig_arlen}         ),
    .M00_AXI_ARSIZE       (mig_arsize          ),
    .M00_AXI_ARBURST      (mig_arburst         ),
    .M00_AXI_ARLOCK       (mig_arlock[0:0]     ),
    .M00_AXI_ARCACHE      (mig_arcache         ),
    .M00_AXI_ARPROT       (mig_arprot          ),
    .M00_AXI_ARQOS        (                    ),
    .M00_AXI_ARVALID      (mig_arvalid         ),
    .M00_AXI_ARREADY      (mig_arready         ),
    .M00_AXI_RID          (mig_rid             ),
    .M00_AXI_RDATA        (mig_rdata           ),
    .M00_AXI_RRESP        (mig_rresp           ),
    .M00_AXI_RLAST        (mig_rlast           ),
    .M00_AXI_RVALID       (mig_rvalid          ),
    .M00_AXI_RREADY       (mig_rready          )
);
//ddr3 controller
mig_axi_32 mig_axi (
    // Inouts
    .ddr3_dq             (ddr3_dq         ),
    .ddr3_dqs_p          (ddr3_dqs_p      ),    // for X16 parts
    .ddr3_dqs_n          (ddr3_dqs_n      ),  // for X16 parts
    // Outputs
    .ddr3_addr           (ddr3_addr       ),
    .ddr3_ba             (ddr3_ba         ),
    .ddr3_ras_n          (ddr3_ras_n      ),
    .ddr3_cas_n          (ddr3_cas_n      ),
    .ddr3_we_n           (ddr3_we_n       ),
    .ddr3_reset_n        (ddr3_reset_n    ),
    .ddr3_ck_p           (ddr3_ck_p       ),
    .ddr3_ck_n           (ddr3_ck_n       ),
    .ddr3_cke            (ddr3_cke        ),
    .ddr3_dm             (ddr3_dm         ),
    .ddr3_odt            (ddr3_odt        ),

	.ui_clk              (c1_clk0         ),
    .ui_clk_sync_rst     (c1_rst0         ),

    .sys_clk_i           (c1_sys_clk_i    ),
    .sys_rst             (clk_locked      ),
    .init_calib_complete (c1_calib_done   ),
    .clk_ref_i           (c1_clk_ref_i    ),
    .mmcm_locked         (                ),

	.app_sr_active       (                ),
    .app_ref_ack         (                ),
    .app_zq_ack          (                ),
    .app_sr_req          (1'b0            ),
    .app_ref_req         (1'b0            ),
    .app_zq_req          (1'b0            ),

    .aresetn             (ddr_aresetn     ),
    .s_axi_awid          (mig_awid        ),
    .s_axi_awaddr        (mig_awaddr[26:0]),
    .s_axi_awlen         ({mig_awlen}     ),
    .s_axi_awsize        (mig_awsize      ),
    .s_axi_awburst       (mig_awburst     ),
    .s_axi_awlock        (mig_awlock[0:0] ),
    .s_axi_awcache       (mig_awcache     ),
    .s_axi_awprot        (mig_awprot      ),
    .s_axi_awqos         (4'b0            ),
    .s_axi_awvalid       (mig_awvalid     ),
    .s_axi_awready       (mig_awready     ),
    .s_axi_wdata         (mig_wdata       ),
    .s_axi_wstrb         (mig_wstrb       ),
    .s_axi_wlast         (mig_wlast       ),
    .s_axi_wvalid        (mig_wvalid      ),
    .s_axi_wready        (mig_wready      ),
    .s_axi_bid           (mig_bid         ),
    .s_axi_bresp         (mig_bresp       ),
    .s_axi_bvalid        (mig_bvalid      ),
    .s_axi_bready        (mig_bready      ),
    .s_axi_arid          (mig_arid        ),
    .s_axi_araddr        (mig_araddr[26:0]),
    .s_axi_arlen         ({mig_arlen}     ),
    .s_axi_arsize        (mig_arsize      ),
    .s_axi_arburst       (mig_arburst     ),
    .s_axi_arlock        (mig_arlock[0:0] ),
    .s_axi_arcache       (mig_arcache     ),
    .s_axi_arprot        (mig_arprot      ),
    .s_axi_arqos         (4'b0            ),
    .s_axi_arvalid       (mig_arvalid     ),
    .s_axi_arready       (mig_arready     ),
    .s_axi_rid           (mig_rid         ),
    .s_axi_rdata         (mig_rdata       ),
    .s_axi_rresp         (mig_rresp       ),
    .s_axi_rlast         (mig_rlast       ),
    .s_axi_rvalid        (mig_rvalid      ),
    .s_axi_rready        (mig_rready      )
);

//DMA
dma_master DMA_MASTER0
(
.clk                (aclk                   ),
.rst_n		        (aresetn                ),
.awid               (dma0_awid              ),
.awaddr             (dma0_awaddr            ),
.awlen              (dma0_awlen             ),
.awsize             (dma0_awsize            ),
.awburst            (dma0_awburst           ),
.awlock             (dma0_awlock            ),
.awcache            (dma0_awcache           ),
.awprot             (dma0_awprot            ),
.awvalid            (dma0_awvalid           ),
.awready            (dma0_awready           ),
.wid                (dma0_wid               ),
.wdata              (dma0_wdata             ),
.wstrb              (dma0_wstrb             ),
.wlast              (dma0_wlast             ),
.wvalid             (dma0_wvalid            ),
.wready             (dma0_wready            ),
.bid                (dma0_bid               ),
.bresp              (dma0_bresp             ),
.bvalid             (dma0_bvalid            ),
.bready             (dma0_bready            ),
.arid               (dma0_arid              ),
.araddr             (dma0_araddr            ),
.arlen              (dma0_arlen             ),
.arsize             (dma0_arsize            ),
.arburst            (dma0_arburst           ),
.arlock             (dma0_arlock            ),
.arcache            (dma0_arcache           ),
.arprot             (dma0_arprot            ),
.arvalid            (dma0_arvalid           ),
.arready            (dma0_arready           ),
.rid                (dma0_rid               ),
.rdata              (dma0_rdata             ),
.rresp              (dma0_rresp             ),
.rlast              (dma0_rlast             ),
.rvalid             (dma0_rvalid            ),
.rready             (dma0_rready            ),

.dma_int            (dma_int                ),
.dma_req_in         (dma_req                ),
.dma_ack_out        (dma_ack                ),

.dma_gnt            (dma0_gnt               ),
.apb_rw             (apb_rw_dma0            ),
.apb_psel           (apb_psel_dma0          ),
.apb_valid_req      (apb_start_dma0	        ),
.apb_penable        (apb_penable_dma0       ),
.apb_addr           (apb_addr_dma0          ),
.apb_wdata          (apb_wdata_dma0         ),
.apb_rdata          (apb_rdata_dma0         ),

.order_addr_in      (order_addr_in          ),
.write_dma_end      (write_dma_end          ),
.finish_read_order  (finish_read_order      )
);

//AXI2APB
axi2apb_misc APB_DEV
(
.clk                (aclk               ),
.rst_n              (aresetn            ),

.axi_s_awid         (apb_s_awid         ),
.axi_s_awaddr       (apb_s_awaddr       ),
.axi_s_awlen        (apb_s_awlen        ),
.axi_s_awsize       (apb_s_awsize       ),
.axi_s_awburst      (apb_s_awburst      ),
.axi_s_awlock       (apb_s_awlock       ),
.axi_s_awcache      (apb_s_awcache      ),
.axi_s_awprot       (apb_s_awprot       ),
.axi_s_awvalid      (apb_s_awvalid      ),
.axi_s_awready      (apb_s_awready      ),
.axi_s_wid          (apb_s_wid          ),
.axi_s_wdata        (apb_s_wdata        ),
.axi_s_wstrb        (apb_s_wstrb        ),
.axi_s_wlast        (apb_s_wlast        ),
.axi_s_wvalid       (apb_s_wvalid       ),
.axi_s_wready       (apb_s_wready       ),
.axi_s_bid          (apb_s_bid          ),
.axi_s_bresp        (apb_s_bresp        ),
.axi_s_bvalid       (apb_s_bvalid       ),
.axi_s_bready       (apb_s_bready       ),
.axi_s_arid         (apb_s_arid         ),
.axi_s_araddr       (apb_s_araddr       ),
.axi_s_arlen        (apb_s_arlen        ),
.axi_s_arsize       (apb_s_arsize       ),
.axi_s_arburst      (apb_s_arburst      ),
.axi_s_arlock       (apb_s_arlock       ),
.axi_s_arcache      (apb_s_arcache      ),
.axi_s_arprot       (apb_s_arprot       ),
.axi_s_arvalid      (apb_s_arvalid      ),
.axi_s_arready      (apb_s_arready      ),
.axi_s_rid          (apb_s_rid          ),
.axi_s_rdata        (apb_s_rdata        ),
.axi_s_rresp        (apb_s_rresp        ),
.axi_s_rlast        (apb_s_rlast        ),
.axi_s_rvalid       (apb_s_rvalid       ),
.axi_s_rready       (apb_s_rready       ),

.apb_rw_dma         (apb_rw_dma0        ),
.apb_psel_dma       (apb_psel_dma0      ),
.apb_enab_dma       (apb_penable_dma0   ),
.apb_addr_dma       (apb_addr_dma0[19:0]),
.apb_valid_dma      (apb_start_dma0     ),
.apb_wdata_dma      (apb_wdata_dma0     ),
.apb_rdata_dma      (apb_rdata_dma0     ),
.apb_ready_dma      (                   ), //output, no use
.dma_grant          (dma0_gnt           ),

.dma_req_o          (dma_req            ),
.dma_ack_i          (dma_ack            ),

//UART0
.uart0_txd_i        (uart0_txd_i      ),
.uart0_txd_o        (uart0_txd_o      ),
.uart0_txd_oe       (uart0_txd_oe     ),
.uart0_rxd_i        (uart0_rxd_i      ),
.uart0_rxd_o        (uart0_rxd_o      ),
.uart0_rxd_oe       (uart0_rxd_oe     ),
.uart0_rts_o        (uart0_rts_o      ),
.uart0_dtr_o        (uart0_dtr_o      ),
.uart0_cts_i        (uart0_cts_i      ),
.uart0_dsr_i        (uart0_dsr_i      ),
.uart0_dcd_i        (uart0_dcd_i      ),
.uart0_ri_i         (uart0_ri_i       ),
.uart0_int          (uart0_int        ),

.nand_type          (2'h2             ),  //1Gbit
.nand_cle           (nand_cle         ),
.nand_ale           (nand_ale         ),
.nand_rdy           (nand_rdy         ),
.nand_rd            (nand_rd          ),
.nand_ce            (nand_ce          ),
.nand_wr            (nand_wr          ),
.nand_dat_i         (nand_dat_i       ),
.nand_dat_o         (nand_dat_o       ),
.nand_dat_oe        (nand_dat_oe      ),

.nand_int           (nand_int         )
);


main_xbar main_xbar (
    .aclk(aclk),                    // input  wire aclk
    .aresetn(interconnect_aresetn),              // input  wire aresetn

    .s_axi_awid   (m0_async_awid        ),
    .s_axi_awaddr (m0_async_awaddr      ),
    .s_axi_awlen  (m0_async_awlen       ),
    .s_axi_awsize (m0_async_awsize      ),
    .s_axi_awburst(m0_async_awburst     ),
    .s_axi_awlock (m0_async_awlock      ),
    .s_axi_awcache(m0_async_awcache     ),
    .s_axi_awprot (m0_async_awprot      ),
    .s_axi_awvalid(m0_async_awvalid     ),
    .s_axi_awready(m0_async_awready     ),
    .s_axi_wready (m0_async_wready      ),
    .s_axi_wid    (m0_async_wid         ),
    .s_axi_wdata  (m0_async_wdata       ),
    .s_axi_wstrb  (m0_async_wstrb       ),
    .s_axi_wlast  (m0_async_wlast       ),
    .s_axi_wvalid (m0_async_wvalid      ),
    .s_axi_bid    (m0_async_bid         ),
    .s_axi_bresp  (m0_async_bresp       ),
    .s_axi_bvalid (m0_async_bvalid      ),
    .s_axi_bready (m0_async_bready      ),
    .s_axi_arid   (m0_async_arid        ),
    .s_axi_araddr (m0_async_araddr      ),
    .s_axi_arlen  (m0_async_arlen       ),
    .s_axi_arsize (m0_async_arsize      ),
    .s_axi_arburst(m0_async_arburst     ),
    .s_axi_arlock (m0_async_arlock      ),
    .s_axi_arcache(m0_async_arcache     ),
    .s_axi_arprot (m0_async_arprot      ),
    .s_axi_arvalid(m0_async_arvalid     ),
    .s_axi_arready(m0_async_arready     ),
    .s_axi_rready (m0_async_rready      ),
    .s_axi_rid    (m0_async_rid         ),
    .s_axi_rdata  (m0_async_rdata       ),
    .s_axi_rresp  (m0_async_rresp       ),
    .s_axi_rlast  (m0_async_rlast       ),
    .s_axi_rvalid (m0_async_rvalid      ),

    .m_axi_awid           ({peripheral_awid   , s0_awid   }),
    .m_axi_awaddr         ({peripheral_awaddr , s0_awaddr }),
    .m_axi_awlen          ({peripheral_awlen  , s0_awlen  }),
    .m_axi_awsize         ({peripheral_awsize , s0_awsize }),
    .m_axi_awburst        ({peripheral_awburst, s0_awburst}),
    .m_axi_awlock         ({peripheral_awlock , s0_awlock }),
    .m_axi_awcache        ({peripheral_awcache, s0_awcache}),
    .m_axi_awprot         ({peripheral_awprot , s0_awprot }),
    .m_axi_awvalid        ({peripheral_awvalid, s0_awvalid}),
    .m_axi_awready        ({peripheral_awready, s0_awready}),
    .m_axi_wid            ({peripheral_wid    , s0_wid    }),
    .m_axi_wdata          ({peripheral_wdata  , s0_wdata  }),
    .m_axi_wstrb          ({peripheral_wstrb  , s0_wstrb  }),
    .m_axi_wlast          ({peripheral_wlast  , s0_wlast  }),
    .m_axi_wvalid         ({peripheral_wvalid , s0_wvalid }),
    .m_axi_wready         ({peripheral_wready , s0_wready }),
    .m_axi_bid            ({peripheral_bid    , s0_bid    }),
    .m_axi_bresp          ({peripheral_bresp  , s0_bresp  }),
    .m_axi_bvalid         ({peripheral_bvalid , s0_bvalid }),
    .m_axi_bready         ({peripheral_bready , s0_bready }),
    .m_axi_arid           ({peripheral_arid   , s0_arid   }),
    .m_axi_araddr         ({peripheral_araddr , s0_araddr }),
    .m_axi_arlen          ({peripheral_arlen  , s0_arlen  }),
    .m_axi_arsize         ({peripheral_arsize , s0_arsize }),
    .m_axi_arburst        ({peripheral_arburst, s0_arburst}),
    .m_axi_arlock         ({peripheral_arlock , s0_arlock }),
    .m_axi_arcache        ({peripheral_arcache, s0_arcache}),
    .m_axi_arprot         ({peripheral_arprot , s0_arprot }),
    .m_axi_arvalid        ({peripheral_arvalid, s0_arvalid}),
    .m_axi_arready        ({peripheral_arready, s0_arready}),
    .m_axi_rid            ({peripheral_rid    , s0_rid    }),
    .m_axi_rdata          ({peripheral_rdata  , s0_rdata  }),
    .m_axi_rresp          ({peripheral_rresp  , s0_rresp  }),
    .m_axi_rlast          ({peripheral_rlast  , s0_rlast  }),
    .m_axi_rvalid         ({peripheral_rvalid , s0_rvalid }),
    .m_axi_rready         ({peripheral_rready , s0_rready }),

    .m_axi_awqos  (),
    .m_axi_arqos  (),

    .s_axi_awqos  (4'b0),
    .s_axi_arqos  (4'b0)

);

wire [31 : 0] m_apb_paddr  ;
wire [1 : 0]  m_apb_psel   ;
wire          m_apb_penable;
wire          m_apb_pwrite ;
wire [31 : 0] m_apb_pwdata ;
wire [1 : 0]  m_apb_pready ;
wire [31 : 0] m_apb_prdata ;
wire [31 : 0] m_apb_prdata0;
wire [31 : 0] m_apb_prdata1;
wire [1 : 0]  m_apb_pslverr;
wire [2 : 0]  m_apb_pprot  ;
wire [3 : 0]  m_apb_pstrb  ;

assign m_apb_prdata = m_apb_psel[0] ? m_apb_prdata0 : (m_apb_psel[1] ? m_apb_prdata1 : 32'hdeadbeef);

axi_clock_converter_0 AXI_CLK_CONVERTER_APB (
    .s_axi_awid       (apb_connect_soc_clk_awid            ),
    .s_axi_awaddr     (apb_connect_soc_clk_awaddr          ),
    .s_axi_awlen      (apb_connect_soc_clk_awlen           ),
    .s_axi_awsize     (apb_connect_soc_clk_awsize          ),
    .s_axi_awburst    (apb_connect_soc_clk_awburst         ),
    .s_axi_awlock     (apb_connect_soc_clk_awlock          ),
    .s_axi_awcache    (apb_connect_soc_clk_awcache         ),
    .s_axi_awprot     (apb_connect_soc_clk_awprot          ),
    .s_axi_awvalid    (apb_connect_soc_clk_awvalid         ),
    .s_axi_awready    (apb_connect_soc_clk_awready         ),
    .s_axi_wid        (apb_connect_soc_clk_wid             ),
    .s_axi_wdata      (apb_connect_soc_clk_wdata           ),
    .s_axi_wstrb      (apb_connect_soc_clk_wstrb           ),
    .s_axi_wlast      (apb_connect_soc_clk_wlast           ),
    .s_axi_wvalid     (apb_connect_soc_clk_wvalid          ),
    .s_axi_wready     (apb_connect_soc_clk_wready          ),
    .s_axi_bid        (apb_connect_soc_clk_bid             ),
    .s_axi_bresp      (apb_connect_soc_clk_bresp           ),
    .s_axi_bvalid     (apb_connect_soc_clk_bvalid          ),
    .s_axi_bready     (apb_connect_soc_clk_bready          ),
    .s_axi_arid       (apb_connect_soc_clk_arid            ),
    .s_axi_araddr     (apb_connect_soc_clk_araddr          ),
    .s_axi_arlen      (apb_connect_soc_clk_arlen           ),
    .s_axi_arsize     (apb_connect_soc_clk_arsize          ),
    .s_axi_arburst    (apb_connect_soc_clk_arburst         ),
    .s_axi_arlock     (apb_connect_soc_clk_arlock          ),
    .s_axi_arcache    (apb_connect_soc_clk_arcache         ),
    .s_axi_arprot     (apb_connect_soc_clk_arprot          ),
    .s_axi_arvalid    (apb_connect_soc_clk_arvalid         ),
    .s_axi_arready    (apb_connect_soc_clk_arready         ),
    .s_axi_rid        (apb_connect_soc_clk_rid             ),
    .s_axi_rdata      (apb_connect_soc_clk_rdata           ),
    .s_axi_rresp      (apb_connect_soc_clk_rresp           ),
    .s_axi_rlast      (apb_connect_soc_clk_rlast           ),
    .s_axi_rvalid     (apb_connect_soc_clk_rvalid          ),
    .s_axi_rready     (apb_connect_soc_clk_rready          ),

    .s_axi_arqos      (4'b0               ),
    .s_axi_awqos      (4'b0               ),

    .s_axi_aclk	      (aclk            ),
    .s_axi_aresetn    (aresetn         ),

    .m_axi_awid       (apb_connect_awid      ),
    .m_axi_awaddr     (apb_connect_awaddr    ),
    .m_axi_awlen      (apb_connect_awlen     ),
    .m_axi_awsize     (apb_connect_awsize    ),
    .m_axi_awburst    (apb_connect_awburst   ),
    .m_axi_awlock     (apb_connect_awlock    ),
    .m_axi_awcache    (apb_connect_awcache   ),
    .m_axi_awprot     (apb_connect_awprot    ),
    .m_axi_awvalid    (apb_connect_awvalid   ),
    .m_axi_awready    (apb_connect_awready   ),
    .m_axi_wid        (apb_connect_wid       ),
    .m_axi_wdata      (apb_connect_wdata     ),
    .m_axi_wstrb      (apb_connect_wstrb     ),
    .m_axi_wlast      (apb_connect_wlast     ),
    .m_axi_wvalid     (apb_connect_wvalid    ),
    .m_axi_wready     (apb_connect_wready    ),
    .m_axi_bid        (apb_connect_bid       ),
    .m_axi_bresp      (apb_connect_bresp     ),
    .m_axi_bvalid     (apb_connect_bvalid    ),
    .m_axi_bready     (apb_connect_bready    ),
    .m_axi_arid       (apb_connect_arid      ),
    .m_axi_araddr     (apb_connect_araddr    ),
    .m_axi_arlen      (apb_connect_arlen     ),
    .m_axi_arsize     (apb_connect_arsize    ),
    .m_axi_arburst    (apb_connect_arburst   ),
    .m_axi_arlock     (apb_connect_arlock    ),
    .m_axi_arcache    (apb_connect_arcache   ),
    .m_axi_arprot     (apb_connect_arprot    ),
    .m_axi_arvalid    (apb_connect_arvalid   ),
    .m_axi_arready    (apb_connect_arready   ),
    .m_axi_rid        (apb_connect_rid       ),
    .m_axi_rdata      (apb_connect_rdata     ),
    .m_axi_rresp      (apb_connect_rresp     ),
    .m_axi_rlast      (apb_connect_rlast     ),
    .m_axi_rvalid     (apb_connect_rvalid    ),
    .m_axi_rready     (apb_connect_rready    ),

    .m_axi_arqos      (                   ),
    .m_axi_awqos      (                   ),

    .m_axi_aclk	      (clk_100               ),
    .m_axi_aresetn    (aresetn            )
);

axi_protocol_converter_0 apb_axi4lite_to_axi3 (
  .aclk(clk_100),                    // input  wire aclk
  .aresetn(aresetn),              // input  wire aresetn

  .s_axi_awaddr(apb_connect_awaddr),    // input  wire [31 : 0] s_axi_awaddr
  .s_axi_awlen(apb_connect_awlen),      // input  wire [3 : 0] s_axi_awlen
  .s_axi_awsize(apb_connect_awsize),    // input  wire [2 : 0] s_axi_awsize
  .s_axi_awburst(apb_connect_awburst),  // input  wire [1 : 0] s_axi_awburst
  .s_axi_awlock(apb_connect_awlock),    // input  wire [1 : 0] s_axi_awlock
  .s_axi_awcache(apb_connect_awcache),  // input  wire [3 : 0] s_axi_awcache
  .s_axi_awprot(apb_connect_awprot),    // input  wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(apb_connect_awvalid),  // input  wire s_axi_awvalid
  .s_axi_awready(apb_connect_awready),  // output wire s_axi_awready
  .s_axi_wdata(apb_connect_wdata),      // input  wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(apb_connect_wstrb),      // input  wire [3 : 0] s_axi_wstrb
  .s_axi_wlast(apb_connect_wlast),      // input  wire s_axi_wlast
  .s_axi_wvalid(apb_connect_wvalid),    // input  wire s_axi_wvalid
  .s_axi_wready(apb_connect_wready),    // output wire s_axi_wready
  .s_axi_bresp(apb_connect_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(apb_connect_bvalid),    // output wire s_axi_bvalid
  .s_axi_bready(apb_connect_bready),    // input  wire s_axi_bready
  .s_axi_araddr(apb_connect_araddr),    // input  wire [31 : 0] s_axi_araddr
  .s_axi_arlen(apb_connect_arlen),      // input  wire [3 : 0] s_axi_arlen
  .s_axi_arsize(apb_connect_arsize),    // input  wire [2 : 0] s_axi_arsize
  .s_axi_arburst(apb_connect_arburst),  // input  wire [1 : 0] s_axi_arburst
  .s_axi_arlock(apb_connect_arlock),    // input  wire [1 : 0] s_axi_arlock
  .s_axi_arcache(apb_connect_arcache),  // input  wire [3 : 0] s_axi_arcache
  .s_axi_arprot(apb_connect_arprot),    // input  wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(apb_connect_arvalid),  // input  wire s_axi_arvalid
  .s_axi_arready(apb_connect_arready),  // output wire s_axi_arready
  .s_axi_rdata(apb_connect_rdata),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(apb_connect_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(apb_connect_rlast),      // output wire s_axi_rlast
  .s_axi_rvalid(apb_connect_rvalid),    // output wire s_axi_rvalid
  .s_axi_rready(apb_connect_rready),    // input  wire s_axi_rready
  .m_axi_awaddr(apb_connect_axi4lite_awaddr),    // output wire [31 : 0] m_axi_awaddr
  .m_axi_awprot(apb_connect_axi4lite_awprot),    // output wire [2 : 0] m_axi_awprot
  .m_axi_awvalid(apb_connect_axi4lite_awvalid),  // output wire m_axi_awvalid
  .m_axi_awready(apb_connect_axi4lite_awready),  // input  wire m_axi_awready
  .m_axi_wdata(apb_connect_axi4lite_wdata),      // output wire [31 : 0] m_axi_wdata
  .m_axi_wstrb(apb_connect_axi4lite_wstrb),      // output wire [3 : 0] m_axi_wstrb
  .m_axi_wvalid(apb_connect_axi4lite_wvalid),    // output wire m_axi_wvalid
  .m_axi_wready(apb_connect_axi4lite_wready),    // input  wire m_axi_wready
  .m_axi_bresp(apb_connect_axi4lite_bresp),      // input  wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(apb_connect_axi4lite_bvalid),    // input  wire m_axi_bvalid
  .m_axi_bready(apb_connect_axi4lite_bready),    // output wire m_axi_bready
  .m_axi_araddr(apb_connect_axi4lite_araddr),    // output wire [31 : 0] m_axi_araddr
  .m_axi_arprot(apb_connect_axi4lite_arprot),    // output wire [2 : 0] m_axi_arprot
  .m_axi_arvalid(apb_connect_axi4lite_arvalid),  // output wire m_axi_arvalid
  .m_axi_arready(apb_connect_axi4lite_arready),  // input  wire m_axi_arready
  .m_axi_rdata(apb_connect_axi4lite_rdata),      // input  wire [31 : 0] m_axi_rdata
  .m_axi_rresp(apb_connect_axi4lite_rresp),      // input  wire [1 : 0] m_axi_rresp
  .m_axi_rvalid(apb_connect_axi4lite_rvalid),    // input  wire m_axi_rvalid
  .m_axi_rready(apb_connect_axi4lite_rready),    // output wire m_axi_rready

  .s_axi_awqos(4'b0),      // input  wire [3 : 0] s_axi_awqos
  .s_axi_arqos(4'b0)      // input  wire [3 : 0] s_axi_arqos

);

axi_apb_bridge_connect apb_bridge (
  .s_axi_aclk(clk_100),        // input  wire s_axi_aclk
  .s_axi_aresetn(aresetn),  // input  wire apb_connect_axi4lite_aresetn
  .s_axi_awaddr(apb_connect_axi4lite_awaddr),    // input  wire [31 : 0] s_axi_awaddr
  .s_axi_awprot(apb_connect_axi4lite_awprot),    // input  wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(apb_connect_axi4lite_awvalid),  // input  wire s_axi_awvalid
  .s_axi_awready(apb_connect_axi4lite_awready),  // output wire s_axi_awready
  .s_axi_wdata(apb_connect_axi4lite_wdata),      // input  wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(apb_connect_axi4lite_wstrb),      // input  wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(apb_connect_axi4lite_wvalid),    // input  wire s_axi_wvalid
  .s_axi_wready(apb_connect_axi4lite_wready),    // output wire s_axi_wready
  .s_axi_bresp(apb_connect_axi4lite_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(apb_connect_axi4lite_bvalid),    // output wire s_axi_bvalid
  .s_axi_bready(apb_connect_axi4lite_bready),    // input  wire s_axi_bready
  .s_axi_araddr(apb_connect_axi4lite_araddr),    // input  wire [31 : 0] s_axi_araddr
  .s_axi_arprot(apb_connect_axi4lite_arprot),    // input  wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(apb_connect_axi4lite_arvalid),  // input  wire s_axi_arvalid
  .s_axi_arready(apb_connect_axi4lite_arready),  // output wire s_axi_arready
  .s_axi_rdata(apb_connect_axi4lite_rdata),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(apb_connect_axi4lite_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(apb_connect_axi4lite_rvalid),    // output wire s_axi_rvalid
  .s_axi_rready(apb_connect_axi4lite_rready),    // input  wire s_axi_rready

  .m_apb_paddr(m_apb_paddr),         // output wire [31 : 0] m_apb_paddr
  .m_apb_psel(m_apb_psel),        // output wire [0 : 0] m_apb_psel
  .m_apb_penable(m_apb_penable),     // output wire m_apb_penable
  .m_apb_pwrite(m_apb_pwrite),       // output wire m_apb_pwrite
  .m_apb_pwdata(m_apb_pwdata),       // output wire [31 : 0] m_apb_pwdata
  .m_apb_pready(m_apb_pready),    // input  wire [0 : 0] m_apb_pready
  .m_apb_prdata(m_apb_prdata0),       // input  wire [31 : 0] m_apb_prdata
  .m_apb_prdata2(m_apb_prdata1),       // input  wire [31 : 0] m_apb_prdata
  .m_apb_pslverr(m_apb_pslverr),  // input  wire [0 : 0] m_apb_pslverr
  .m_apb_pprot(m_apb_pprot),         // output wire [2 : 0] m_apb_pprot
  .m_apb_pstrb(m_apb_pstrb)          // output wire [3 : 0] m_apb_pstrb
);


nt35510 lcd_controller (
  .nrst(aresetn),                  // input  wire nrst
  .clk(clk_100),                    // input  wire clk
  .APB_paddr(m_apb_paddr),        // input  wire [31 : 0] APB_paddr
  .APB_psel(m_apb_psel[0]),          // input  wire APB_psel
  .APB_penable(m_apb_penable),    // input  wire APB_penable
  .APB_pwrite(m_apb_pwrite),      // input  wire APB_pwrite
  .APB_pwdata(m_apb_pwdata),      // input  wire [31 : 0] APB_pwdata
  .APB_pready(m_apb_pready[0]),      // output wire APB_pready
  .APB_prdata(m_apb_prdata0),      // output wire [31 : 0] APB_prdata
  .APB_pslverr(m_apb_pslverr[0]),    // output wire APB_pslverr
  .LCD_nrst(LCD_nrst),          // output wire LCD_nrst
  .LCD_csel(LCD_csel),          // output wire LCD_csel
  .LCD_rs(LCD_rs),              // output wire LCD_rs
  .LCD_wr(LCD_wr),              // output wire LCD_wr
  .LCD_rd(LCD_rd),              // output wire LCD_rd
  .LCD_data_in(LCD_data_tri_i),    // input  wire [15 : 0] LCD_data_in
  .LCD_data_out(LCD_data_tri_o),  // output wire [15 : 0] LCD_data_out
  .LCD_data_z(LCD_data_tri_t)      // output wire [15 : 0] LCD_data_z
);

ps2 ps2 (
  .clk(clk_100),                     // input  wire clk
  .reset_n(aresetn),              // input  wire reset_n

  .paddr(m_apb_paddr[3:0]),                  // input  wire [3 : 0] paddr
  .penable(m_apb_penable),              // input  wire penable
  .psel(m_apb_psel[1]),                    // input  wire psel
  .byteenable(m_apb_pstrb),        // input  wire [3 : 0] byteenable
  .write(m_apb_pwrite),                  // input  wire write
  .writedata(m_apb_pwdata),          // input  wire [31 : 0] writedata
  .perr(m_apb_pslverr[1]),                    // output wire perr

  .PS2_CLK_i(PS2_clk_tri_i),          // input  wire PS2_CLK_i
  .PS2_CLK_o(PS2_clk_tri_o),          // output wire PS2_CLK_o
  .PS2_CLK_t(PS2_clk_tri_t),          // output wire PS2_CLK_t
  .PS2_DAT_i(PS2_dat_tri_i),          // input  wire PS2_DAT_i
  .PS2_DAT_o(PS2_dat_tri_o),          // output wire PS2_DAT_o
  .PS2_DAT_t(PS2_dat_tri_t),          // output wire PS2_DAT_t

  .irq(ps2_int),                      // output wire irq
  .readdata(m_apb_prdata1),            // output wire [31 : 0] readdata
  .waitrequest_n(m_apb_pready[1])   // output wire waitrequest_n
);

// AXI Lite Protocals

  // TFT
wire [3 : 0] tft_axi_lite_awaddr;
wire tft_axi_lite_awvalid;
wire tft_axi_lite_awready;
wire [31 : 0] tft_axi_lite_wdata;
wire [3 : 0] tft_axi_lite_wstrb;
wire tft_axi_lite_wvalid;
wire tft_axi_lite_wready;
wire [1 : 0] tft_axi_lite_bresp;
wire tft_axi_lite_bvalid;
wire tft_axi_lite_bready;
wire [3 : 0] tft_axi_lite_araddr;
wire tft_axi_lite_arvalid;
wire tft_axi_lite_arready;
wire [31 : 0] tft_axi_lite_rdata;
wire [1 : 0] tft_axi_lite_rresp;
wire tft_axi_lite_rvalid;
wire tft_axi_lite_rready;

  // FB WR
wire [6 : 0] fb_wr_axi4lite_AWADDR;
wire fb_wr_axi4lite_AWVALID       ;
wire fb_wr_axi4lite_AWREADY       ;
wire [31 : 0] fb_wr_axi4lite_WDATA;
wire [3 : 0] fb_wr_axi4lite_WSTRB ;
wire fb_wr_axi4lite_WVALID        ;
wire fb_wr_axi4lite_WREADY        ;
wire [1 : 0] fb_wr_axi4lite_BRESP ;
wire fb_wr_axi4lite_BVALID        ;
wire fb_wr_axi4lite_BREADY        ;
wire [6 : 0] fb_wr_axi4lite_ARADDR;
wire fb_wr_axi4lite_ARVALID       ;
wire fb_wr_axi4lite_ARREADY       ;
wire [31 : 0] fb_wr_axi4lite_RDATA;
wire [1 : 0] fb_wr_axi4lite_RRESP ;
wire fb_wr_axi4lite_RVALID        ;
wire fb_wr_axi4lite_RREADY        ;

  // FB RD
wire [6 : 0] fb_rd_axi4lite_AWADDR;
wire fb_rd_axi4lite_AWVALID       ;
wire fb_rd_axi4lite_AWREADY       ;
wire [31 : 0] fb_rd_axi4lite_WDATA;
wire [3 : 0] fb_rd_axi4lite_WSTRB ;
wire fb_rd_axi4lite_WVALID        ;
wire fb_rd_axi4lite_WREADY        ;
wire [1 : 0] fb_rd_axi4lite_BRESP ;
wire fb_rd_axi4lite_BVALID        ;
wire fb_rd_axi4lite_BREADY        ;
wire [6 : 0] fb_rd_axi4lite_ARADDR;
wire fb_rd_axi4lite_ARVALID       ;
wire fb_rd_axi4lite_ARREADY       ;
wire [31 : 0] fb_rd_axi4lite_RDATA;
wire [1 : 0] fb_rd_axi4lite_RRESP ;
wire fb_rd_axi4lite_RVALID        ;
wire fb_rd_axi4lite_RREADY        ;

// Videos interconnect
wire s_axis_video_TVALID;
wire s_axis_video_TREADY;
wire [23 : 0] s_axis_video_TDATA;
wire [2 : 0] s_axis_video_TKEEP;
wire [2 : 0] s_axis_video_TSTRB;
wire s_axis_video_TUSER;
wire s_axis_video_TLAST;
wire s_axis_video_TID;
wire s_axis_video_TDEST;
wire m_axis_video_TVALID;
wire m_axis_video_TREADY;
wire [23 : 0] m_axis_video_TDATA;
wire [2 : 0] m_axis_video_TKEEP;
wire [2 : 0] m_axis_video_TSTRB;
wire [0 : 0] m_axis_video_TUSER;
wire [0 : 0] m_axis_video_TLAST;
wire [0 : 0] m_axis_video_TID;
wire [0 : 0] m_axis_video_TDEST;

axi_clock_converter_0 AXI_CLK_CONVERTER_FB_WR (
    .s_axi_awid       (fb_write_slave_33M_awid            ),
    .s_axi_awaddr     (fb_write_slave_33M_awaddr          ),
    .s_axi_awlen      (fb_write_slave_33M_awlen           ),
    .s_axi_awsize     (fb_write_slave_33M_awsize          ),
    .s_axi_awburst    (fb_write_slave_33M_awburst         ),
    .s_axi_awlock     (fb_write_slave_33M_awlock          ),
    .s_axi_awcache    (fb_write_slave_33M_awcache         ),
    .s_axi_awprot     (fb_write_slave_33M_awprot          ),
    .s_axi_awvalid    (fb_write_slave_33M_awvalid         ),
    .s_axi_awready    (fb_write_slave_33M_awready         ),
    .s_axi_wid        (fb_write_slave_33M_wid             ),
    .s_axi_wdata      (fb_write_slave_33M_wdata           ),
    .s_axi_wstrb      (fb_write_slave_33M_wstrb           ),
    .s_axi_wlast      (fb_write_slave_33M_wlast           ),
    .s_axi_wvalid     (fb_write_slave_33M_wvalid          ),
    .s_axi_wready     (fb_write_slave_33M_wready          ),
    .s_axi_bid        (fb_write_slave_33M_bid             ),
    .s_axi_bresp      (fb_write_slave_33M_bresp           ),
    .s_axi_bvalid     (fb_write_slave_33M_bvalid          ),
    .s_axi_bready     (fb_write_slave_33M_bready          ),
    .s_axi_arid       (fb_write_slave_33M_arid            ),
    .s_axi_araddr     (fb_write_slave_33M_araddr          ),
    .s_axi_arlen      (fb_write_slave_33M_arlen           ),
    .s_axi_arsize     (fb_write_slave_33M_arsize          ),
    .s_axi_arburst    (fb_write_slave_33M_arburst         ),
    .s_axi_arlock     (fb_write_slave_33M_arlock          ),
    .s_axi_arcache    (fb_write_slave_33M_arcache         ),
    .s_axi_arprot     (fb_write_slave_33M_arprot          ),
    .s_axi_arvalid    (fb_write_slave_33M_arvalid         ),
    .s_axi_arready    (fb_write_slave_33M_arready         ),
    .s_axi_rid        (fb_write_slave_33M_rid             ),
    .s_axi_rdata      (fb_write_slave_33M_rdata           ),
    .s_axi_rresp      (fb_write_slave_33M_rresp           ),
    .s_axi_rlast      (fb_write_slave_33M_rlast           ),
    .s_axi_rvalid     (fb_write_slave_33M_rvalid          ),
    .s_axi_rready     (fb_write_slave_33M_rready          ),

    .s_axi_arqos      (4'b0               ),
    .s_axi_awqos      (4'b0               ),

    .s_axi_aclk	      (aclk            ),
    .s_axi_aresetn    (aresetn         ),

    // .m_axi_awid       (),
    // .m_axi_awaddr     (),
    // .m_axi_awlen      (),
    // .m_axi_awsize     (),
    // .m_axi_awburst    (),
    // .m_axi_awlock     (),
    // .m_axi_awcache    (),
    // .m_axi_awprot     (),
    // .m_axi_awvalid    (),
    // .m_axi_awready    (0),
    // .m_axi_wid        (),
    // .m_axi_wdata      (),
    // .m_axi_wstrb      (),
    // .m_axi_wlast      (),
    // .m_axi_wvalid     (),
    // .m_axi_wready     (0),
    // .m_axi_bid        (),
    // .m_axi_bresp      (),
    // .m_axi_bvalid     (0),
    // .m_axi_bready     (),
    // .m_axi_arid       (),
    // .m_axi_araddr     (),
    // .m_axi_arlen      (),
    // .m_axi_arsize     (),
    // .m_axi_arburst    (),
    // .m_axi_arlock     (),
    // .m_axi_arcache    (),
    // .m_axi_arprot     (),
    // .m_axi_arvalid    (),
    // .m_axi_arready    (0),
    // .m_axi_rid        (),
    // .m_axi_rdata      (),
    // .m_axi_rresp      (),
    // .m_axi_rlast      (),
    // .m_axi_rvalid     (0),
    // .m_axi_rready     (),

    .m_axi_awid       (fb_write_slave_100M_awid      ),
    .m_axi_awaddr     (fb_write_slave_100M_awaddr    ),
    .m_axi_awlen      (fb_write_slave_100M_awlen     ),
    .m_axi_awsize     (fb_write_slave_100M_awsize    ),
    .m_axi_awburst    (fb_write_slave_100M_awburst   ),
    .m_axi_awlock     (fb_write_slave_100M_awlock    ),
    .m_axi_awcache    (fb_write_slave_100M_awcache   ),
    .m_axi_awprot     (fb_write_slave_100M_awprot    ),
    .m_axi_awvalid    (fb_write_slave_100M_awvalid   ),
    .m_axi_awready    (fb_write_slave_100M_awready   ),
    .m_axi_wid        (fb_write_slave_100M_wid       ),
    .m_axi_wdata      (fb_write_slave_100M_wdata     ),
    .m_axi_wstrb      (fb_write_slave_100M_wstrb     ),
    .m_axi_wlast      (fb_write_slave_100M_wlast     ),
    .m_axi_wvalid     (fb_write_slave_100M_wvalid    ),
    .m_axi_wready     (fb_write_slave_100M_wready    ),
    .m_axi_bid        (fb_write_slave_100M_bid       ),
    .m_axi_bresp      (fb_write_slave_100M_bresp     ),
    .m_axi_bvalid     (fb_write_slave_100M_bvalid    ),
    .m_axi_bready     (fb_write_slave_100M_bready    ),
    .m_axi_arid       (fb_write_slave_100M_arid      ),
    .m_axi_araddr     (fb_write_slave_100M_araddr    ),
    .m_axi_arlen      (fb_write_slave_100M_arlen     ),
    .m_axi_arsize     (fb_write_slave_100M_arsize    ),
    .m_axi_arburst    (fb_write_slave_100M_arburst   ),
    .m_axi_arlock     (fb_write_slave_100M_arlock    ),
    .m_axi_arcache    (fb_write_slave_100M_arcache   ),
    .m_axi_arprot     (fb_write_slave_100M_arprot    ),
    .m_axi_arvalid    (fb_write_slave_100M_arvalid   ),
    .m_axi_arready    (fb_write_slave_100M_arready   ),
    .m_axi_rid        (fb_write_slave_100M_rid       ),
    .m_axi_rdata      (fb_write_slave_100M_rdata     ),
    .m_axi_rresp      (fb_write_slave_100M_rresp     ),
    .m_axi_rlast      (fb_write_slave_100M_rlast     ),
    .m_axi_rvalid     (fb_write_slave_100M_rvalid    ),
    .m_axi_rready     (fb_write_slave_100M_rready    ),

    .m_axi_arqos      (                   ),
    .m_axi_awqos      (                   ),

    .m_axi_aclk	      (clk_100               ),
    .m_axi_aresetn    (aresetn            )
);

axi_clock_converter_0 AXI_CLK_CONVERTER_FD_RD (
    .s_axi_awid       (fb_read_slave_33M_awid            ),
    .s_axi_awaddr     (fb_read_slave_33M_awaddr          ),
    .s_axi_awlen      (fb_read_slave_33M_awlen           ),
    .s_axi_awsize     (fb_read_slave_33M_awsize          ),
    .s_axi_awburst    (fb_read_slave_33M_awburst         ),
    .s_axi_awlock     (fb_read_slave_33M_awlock          ),
    .s_axi_awcache    (fb_read_slave_33M_awcache         ),
    .s_axi_awprot     (fb_read_slave_33M_awprot          ),
    .s_axi_awvalid    (fb_read_slave_33M_awvalid         ),
    .s_axi_awready    (fb_read_slave_33M_awready         ),
    .s_axi_wid        (fb_read_slave_33M_wid             ),
    .s_axi_wdata      (fb_read_slave_33M_wdata           ),
    .s_axi_wstrb      (fb_read_slave_33M_wstrb           ),
    .s_axi_wlast      (fb_read_slave_33M_wlast           ),
    .s_axi_wvalid     (fb_read_slave_33M_wvalid          ),
    .s_axi_wready     (fb_read_slave_33M_wready          ),
    .s_axi_bid        (fb_read_slave_33M_bid             ),
    .s_axi_bresp      (fb_read_slave_33M_bresp           ),
    .s_axi_bvalid     (fb_read_slave_33M_bvalid          ),
    .s_axi_bready     (fb_read_slave_33M_bready          ),
    .s_axi_arid       (fb_read_slave_33M_arid            ),
    .s_axi_araddr     (fb_read_slave_33M_araddr          ),
    .s_axi_arlen      (fb_read_slave_33M_arlen           ),
    .s_axi_arsize     (fb_read_slave_33M_arsize          ),
    .s_axi_arburst    (fb_read_slave_33M_arburst         ),
    .s_axi_arlock     (fb_read_slave_33M_arlock          ),
    .s_axi_arcache    (fb_read_slave_33M_arcache         ),
    .s_axi_arprot     (fb_read_slave_33M_arprot          ),
    .s_axi_arvalid    (fb_read_slave_33M_arvalid         ),
    .s_axi_arready    (fb_read_slave_33M_arready         ),
    .s_axi_rid        (fb_read_slave_33M_rid             ),
    .s_axi_rdata      (fb_read_slave_33M_rdata           ),
    .s_axi_rresp      (fb_read_slave_33M_rresp           ),
    .s_axi_rlast      (fb_read_slave_33M_rlast           ),
    .s_axi_rvalid     (fb_read_slave_33M_rvalid          ),
    .s_axi_rready     (fb_read_slave_33M_rready          ),

    .s_axi_arqos      (4'b0               ),
    .s_axi_awqos      (4'b0               ),

    .s_axi_aclk	      (aclk            ),
    .s_axi_aresetn    (aresetn         ),

    .m_axi_awid       (fb_read_slave_100M_awid      ),
    .m_axi_awaddr     (fb_read_slave_100M_awaddr    ),
    .m_axi_awlen      (fb_read_slave_100M_awlen     ),
    .m_axi_awsize     (fb_read_slave_100M_awsize    ),
    .m_axi_awburst    (fb_read_slave_100M_awburst   ),
    .m_axi_awlock     (fb_read_slave_100M_awlock    ),
    .m_axi_awcache    (fb_read_slave_100M_awcache   ),
    .m_axi_awprot     (fb_read_slave_100M_awprot    ),
    .m_axi_awvalid    (fb_read_slave_100M_awvalid   ),
    .m_axi_awready    (fb_read_slave_100M_awready   ),
    .m_axi_wid        (fb_read_slave_100M_wid       ),
    .m_axi_wdata      (fb_read_slave_100M_wdata     ),
    .m_axi_wstrb      (fb_read_slave_100M_wstrb     ),
    .m_axi_wlast      (fb_read_slave_100M_wlast     ),
    .m_axi_wvalid     (fb_read_slave_100M_wvalid    ),
    .m_axi_wready     (fb_read_slave_100M_wready    ),
    .m_axi_bid        (fb_read_slave_100M_bid       ),
    .m_axi_bresp      (fb_read_slave_100M_bresp     ),
    .m_axi_bvalid     (fb_read_slave_100M_bvalid    ),
    .m_axi_bready     (fb_read_slave_100M_bready    ),
    .m_axi_arid       (fb_read_slave_100M_arid      ),
    .m_axi_araddr     (fb_read_slave_100M_araddr    ),
    .m_axi_arlen      (fb_read_slave_100M_arlen     ),
    .m_axi_arsize     (fb_read_slave_100M_arsize    ),
    .m_axi_arburst    (fb_read_slave_100M_arburst   ),
    .m_axi_arlock     (fb_read_slave_100M_arlock    ),
    .m_axi_arcache    (fb_read_slave_100M_arcache   ),
    .m_axi_arprot     (fb_read_slave_100M_arprot    ),
    .m_axi_arvalid    (fb_read_slave_100M_arvalid   ),
    .m_axi_arready    (fb_read_slave_100M_arready   ),
    .m_axi_rid        (fb_read_slave_100M_rid       ),
    .m_axi_rdata      (fb_read_slave_100M_rdata     ),
    .m_axi_rresp      (fb_read_slave_100M_rresp     ),
    .m_axi_rlast      (fb_read_slave_100M_rlast     ),
    .m_axi_rvalid     (fb_read_slave_100M_rvalid    ),
    .m_axi_rready     (fb_read_slave_100M_rready    ),

    .m_axi_arqos      (                   ),
    .m_axi_awqos      (                   ),

    .m_axi_aclk	      (clk_100               ),
    .m_axi_aresetn    (aresetn            )
);

axi_clock_converter_0 AXI_CLK_CONVERTER_TFT (
    .s_axi_awid       (tft_slave_33M_awid            ),
    .s_axi_awaddr     (tft_slave_33M_awaddr          ),
    .s_axi_awlen      (tft_slave_33M_awlen           ),
    .s_axi_awsize     (tft_slave_33M_awsize          ),
    .s_axi_awburst    (tft_slave_33M_awburst         ),
    .s_axi_awlock     (tft_slave_33M_awlock          ),
    .s_axi_awcache    (tft_slave_33M_awcache         ),
    .s_axi_awprot     (tft_slave_33M_awprot          ),
    .s_axi_awvalid    (tft_slave_33M_awvalid         ),
    .s_axi_awready    (tft_slave_33M_awready         ),
    .s_axi_wid        (tft_slave_33M_wid             ),
    .s_axi_wdata      (tft_slave_33M_wdata           ),
    .s_axi_wstrb      (tft_slave_33M_wstrb           ),
    .s_axi_wlast      (tft_slave_33M_wlast           ),
    .s_axi_wvalid     (tft_slave_33M_wvalid          ),
    .s_axi_wready     (tft_slave_33M_wready          ),
    .s_axi_bid        (tft_slave_33M_bid             ),
    .s_axi_bresp      (tft_slave_33M_bresp           ),
    .s_axi_bvalid     (tft_slave_33M_bvalid          ),
    .s_axi_bready     (tft_slave_33M_bready          ),
    .s_axi_arid       (tft_slave_33M_arid            ),
    .s_axi_araddr     (tft_slave_33M_araddr          ),
    .s_axi_arlen      (tft_slave_33M_arlen           ),
    .s_axi_arsize     (tft_slave_33M_arsize          ),
    .s_axi_arburst    (tft_slave_33M_arburst         ),
    .s_axi_arlock     (tft_slave_33M_arlock          ),
    .s_axi_arcache    (tft_slave_33M_arcache         ),
    .s_axi_arprot     (tft_slave_33M_arprot          ),
    .s_axi_arvalid    (tft_slave_33M_arvalid         ),
    .s_axi_arready    (tft_slave_33M_arready         ),
    .s_axi_rid        (tft_slave_33M_rid             ),
    .s_axi_rdata      (tft_slave_33M_rdata           ),
    .s_axi_rresp      (tft_slave_33M_rresp           ),
    .s_axi_rlast      (tft_slave_33M_rlast           ),
    .s_axi_rvalid     (tft_slave_33M_rvalid          ),
    .s_axi_rready     (tft_slave_33M_rready          ),

    .s_axi_arqos      (4'b0               ),
    .s_axi_awqos      (4'b0               ),

    .s_axi_aclk	      (aclk            ),
    .s_axi_aresetn    (aresetn         ),

    .m_axi_awid       (tft_slave_100M_awid      ),
    .m_axi_awaddr     (tft_slave_100M_awaddr    ),
    .m_axi_awlen      (tft_slave_100M_awlen     ),
    .m_axi_awsize     (tft_slave_100M_awsize    ),
    .m_axi_awburst    (tft_slave_100M_awburst   ),
    .m_axi_awlock     (tft_slave_100M_awlock    ),
    .m_axi_awcache    (tft_slave_100M_awcache   ),
    .m_axi_awprot     (tft_slave_100M_awprot    ),
    .m_axi_awvalid    (tft_slave_100M_awvalid   ),
    .m_axi_awready    (tft_slave_100M_awready   ),
    .m_axi_wid        (tft_slave_100M_wid       ),
    .m_axi_wdata      (tft_slave_100M_wdata     ),
    .m_axi_wstrb      (tft_slave_100M_wstrb     ),
    .m_axi_wlast      (tft_slave_100M_wlast     ),
    .m_axi_wvalid     (tft_slave_100M_wvalid    ),
    .m_axi_wready     (tft_slave_100M_wready    ),
    .m_axi_bid        (tft_slave_100M_bid       ),
    .m_axi_bresp      (tft_slave_100M_bresp     ),
    .m_axi_bvalid     (tft_slave_100M_bvalid    ),
    .m_axi_bready     (tft_slave_100M_bready    ),
    .m_axi_arid       (tft_slave_100M_arid      ),
    .m_axi_araddr     (tft_slave_100M_araddr    ),
    .m_axi_arlen      (tft_slave_100M_arlen     ),
    .m_axi_arsize     (tft_slave_100M_arsize    ),
    .m_axi_arburst    (tft_slave_100M_arburst   ),
    .m_axi_arlock     (tft_slave_100M_arlock    ),
    .m_axi_arcache    (tft_slave_100M_arcache   ),
    .m_axi_arprot     (tft_slave_100M_arprot    ),
    .m_axi_arvalid    (tft_slave_100M_arvalid   ),
    .m_axi_arready    (tft_slave_100M_arready   ),
    .m_axi_rid        (tft_slave_100M_rid       ),
    .m_axi_rdata      (tft_slave_100M_rdata     ),
    .m_axi_rresp      (tft_slave_100M_rresp     ),
    .m_axi_rlast      (tft_slave_100M_rlast     ),
    .m_axi_rvalid     (tft_slave_100M_rvalid    ),
    .m_axi_rready     (tft_slave_100M_rready    ),

    .m_axi_arqos      (                   ),
    .m_axi_awqos      (                   ),

    .m_axi_aclk	      (clk_100               ),
    .m_axi_aresetn    (aresetn            )
);

axi_protocol_converter_0 fb_read_converter (
  .aclk(clk_100),                    // input  wire aclk
  .aresetn(aresetn),              // input  wire aresetn

  .s_axi_awaddr(fb_read_slave_100M_awaddr),    // input  wire [31 : 0] s_axi_awaddr
  .s_axi_awlen(fb_read_slave_100M_awlen),      // input  wire [3 : 0] s_axi_awlen
  .s_axi_awsize(fb_read_slave_100M_awsize),    // input  wire [2 : 0] s_axi_awsize
  .s_axi_awburst(fb_read_slave_100M_awburst),  // input  wire [1 : 0] s_axi_awburst
  .s_axi_awlock(fb_read_slave_100M_awlock),    // input  wire [1 : 0] s_axi_awlock
  .s_axi_awcache(fb_read_slave_100M_awcache),  // input  wire [3 : 0] s_axi_awcache
  .s_axi_awprot(fb_read_slave_100M_awprot),    // input  wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(fb_read_slave_100M_awvalid),  // input  wire s_axi_awvalid
  .s_axi_awready(fb_read_slave_100M_awready),  // output wire s_axi_awready
  .s_axi_wdata(fb_read_slave_100M_wdata),      // input  wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(fb_read_slave_100M_wstrb),      // input  wire [3 : 0] s_axi_wstrb
  .s_axi_wlast(fb_read_slave_100M_wlast),      // input  wire s_axi_wlast
  .s_axi_wvalid(fb_read_slave_100M_wvalid),    // input  wire s_axi_wvalid
  .s_axi_wready(fb_read_slave_100M_wready),    // output wire s_axi_wready
  .s_axi_bresp(fb_read_slave_100M_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(fb_read_slave_100M_bvalid),    // output wire s_axi_bvalid
  .s_axi_bready(fb_read_slave_100M_bready),    // input  wire s_axi_bready
  .s_axi_araddr(fb_read_slave_100M_araddr),    // input  wire [31 : 0] s_axi_araddr
  .s_axi_arlen(fb_read_slave_100M_arlen),      // input  wire [3 : 0] s_axi_arlen
  .s_axi_arsize(fb_read_slave_100M_arsize),    // input  wire [2 : 0] s_axi_arsize
  .s_axi_arburst(fb_read_slave_100M_arburst),  // input  wire [1 : 0] s_axi_arburst
  .s_axi_arlock(fb_read_slave_100M_arlock),    // input  wire [1 : 0] s_axi_arlock
  .s_axi_arcache(fb_read_slave_100M_arcache),  // input  wire [3 : 0] s_axi_arcache
  .s_axi_arprot(fb_read_slave_100M_arprot),    // input  wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(fb_read_slave_100M_arvalid),  // input  wire s_axi_arvalid
  .s_axi_arready(fb_read_slave_100M_arready),  // output wire s_axi_arready
  .s_axi_rdata(fb_read_slave_100M_rdata),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(fb_read_slave_100M_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(fb_read_slave_100M_rlast),      // output wire s_axi_rlast
  .s_axi_rvalid(fb_read_slave_100M_rvalid),    // output wire s_axi_rvalid
  .s_axi_rready(fb_read_slave_100M_rready),    // input  wire s_axi_rready


  .m_axi_awaddr(fb_rd_axi4lite_AWADDR),    // output wire [31 : 0] m_axi_awaddr
  .m_axi_awprot(),    // output wire [2 : 0] m_axi_awprot
  .m_axi_awvalid(fb_rd_axi4lite_AWVALID),  // output wire m_axi_awvalid
  .m_axi_awready(fb_rd_axi4lite_AWREADY),  // input  wire m_axi_awready
  .m_axi_wdata(fb_rd_axi4lite_WDATA),      // output wire [31 : 0] m_axi_wdata
  .m_axi_wstrb(fb_rd_axi4lite_WSTRB),      // output wire [3 : 0] m_axi_wstrb
  .m_axi_wvalid(fb_rd_axi4lite_WVALID),    // output wire m_axi_wvalid
  .m_axi_wready(fb_rd_axi4lite_WREADY),    // input  wire m_axi_wready
  .m_axi_bresp(fb_rd_axi4lite_BRESP),      // input  wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(fb_rd_axi4lite_BVALID),    // input  wire m_axi_bvalid
  .m_axi_bready(fb_rd_axi4lite_BREADY),    // output wire m_axi_bready
  .m_axi_araddr(fb_rd_axi4lite_ARADDR),    // output wire [31 : 0] m_axi_araddr
  .m_axi_arprot( ),    // output wire [2 : 0] m_axi_arprot
  .m_axi_arvalid(fb_rd_axi4lite_ARVALID),  // output wire m_axi_arvalid
  .m_axi_arready(fb_rd_axi4lite_ARREADY),  // input  wire m_axi_arready
  .m_axi_rdata(fb_rd_axi4lite_RDATA),      // input  wire [31 : 0] m_axi_rdata
  .m_axi_rresp(fb_rd_axi4lite_RRESP),      // input  wire [1 : 0] m_axi_rresp
  .m_axi_rvalid(fb_rd_axi4lite_RVALID),    // input  wire m_axi_rvalid
  .m_axi_rready(fb_rd_axi4lite_RREADY),    // output wire m_axi_rready

  .s_axi_awqos(4'b0),      // input  wire [3 : 0] s_axi_awqos
  .s_axi_arqos(4'b0)      // input  wire [3 : 0] s_axi_arqos
);

axi_protocol_converter_0 fb_write_converter (
  .aclk(clk_100),                    // input  wire aclk
  .aresetn(aresetn),              // input  wire aresetn

  .s_axi_awaddr(fb_write_slave_100M_awaddr),    // input  wire [31 : 0] s_axi_awaddr
  .s_axi_awlen(fb_write_slave_100M_awlen),      // input  wire [3 : 0] s_axi_awlen
  .s_axi_awsize(fb_write_slave_100M_awsize),    // input  wire [2 : 0] s_axi_awsize
  .s_axi_awburst(fb_write_slave_100M_awburst),  // input  wire [1 : 0] s_axi_awburst
  .s_axi_awlock(fb_write_slave_100M_awlock),    // input  wire [1 : 0] s_axi_awlock
  .s_axi_awcache(fb_write_slave_100M_awcache),  // input  wire [3 : 0] s_axi_awcache
  .s_axi_awprot(fb_write_slave_100M_awprot),    // input  wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(fb_write_slave_100M_awvalid),  // input  wire s_axi_awvalid
  .s_axi_awready(fb_write_slave_100M_awready),  // output wire s_axi_awready
  .s_axi_wdata(fb_write_slave_100M_wdata),      // input  wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(fb_write_slave_100M_wstrb),      // input  wire [3 : 0] s_axi_wstrb
  .s_axi_wlast(fb_write_slave_100M_wlast),      // input  wire s_axi_wlast
  .s_axi_wvalid(fb_write_slave_100M_wvalid),    // input  wire s_axi_wvalid
  .s_axi_wready(fb_write_slave_100M_wready),    // output wire s_axi_wready
  .s_axi_bresp(fb_write_slave_100M_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(fb_write_slave_100M_bvalid),    // output wire s_axi_bvalid
  .s_axi_bready(fb_write_slave_100M_bready),    // input  wire s_axi_bready
  .s_axi_araddr(fb_write_slave_100M_araddr),    // input  wire [31 : 0] s_axi_araddr
  .s_axi_arlen(fb_write_slave_100M_arlen),      // input  wire [3 : 0] s_axi_arlen
  .s_axi_arsize(fb_write_slave_100M_arsize),    // input  wire [2 : 0] s_axi_arsize
  .s_axi_arburst(fb_write_slave_100M_arburst),  // input  wire [1 : 0] s_axi_arburst
  .s_axi_arlock(fb_write_slave_100M_arlock),    // input  wire [1 : 0] s_axi_arlock
  .s_axi_arcache(fb_write_slave_100M_arcache),  // input  wire [3 : 0] s_axi_arcache
  .s_axi_arprot(fb_write_slave_100M_arprot),    // input  wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(fb_write_slave_100M_arvalid),  // input  wire s_axi_arvalid
  .s_axi_arready(fb_write_slave_100M_arready),  // output wire s_axi_arready
  .s_axi_rdata(fb_write_slave_100M_rdata),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(fb_write_slave_100M_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(fb_write_slave_100M_rlast),      // output wire s_axi_rlast
  .s_axi_rvalid(fb_write_slave_100M_rvalid),    // output wire s_axi_rvalid
  .s_axi_rready(fb_write_slave_100M_rready),    // input  wire s_axi_rready


  .m_axi_awaddr(fb_wr_axi4lite_AWADDR),    // output wire [31 : 0] m_axi_awaddr
  .m_axi_awprot(),    // output wire [2 : 0] m_axi_awprot
  .m_axi_awvalid(fb_wr_axi4lite_AWVALID),  // output wire m_axi_awvalid
  .m_axi_awready(fb_wr_axi4lite_AWREADY),  // input  wire m_axi_awready
  .m_axi_wdata(fb_wr_axi4lite_WDATA),      // output wire [31 : 0] m_axi_wdata
  .m_axi_wstrb(fb_wr_axi4lite_WSTRB),      // output wire [3 : 0] m_axi_wstrb
  .m_axi_wvalid(fb_wr_axi4lite_WVALID),    // output wire m_axi_wvalid
  .m_axi_wready(fb_wr_axi4lite_WREADY),    // input  wire m_axi_wready
  .m_axi_bresp(fb_wr_axi4lite_BRESP),      // input  wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(fb_wr_axi4lite_BVALID),    // input  wire m_axi_bvalid
  .m_axi_bready(fb_wr_axi4lite_BREADY),    // output wire m_axi_bready
  .m_axi_araddr(fb_wr_axi4lite_ARADDR),    // output wire [31 : 0] m_axi_araddr
  .m_axi_arprot( ),    // output wire [2 : 0] m_axi_arprot
  .m_axi_arvalid(fb_wr_axi4lite_ARVALID),  // output wire m_axi_arvalid
  .m_axi_arready(fb_wr_axi4lite_ARREADY),  // input  wire m_axi_arready
  .m_axi_rdata(fb_wr_axi4lite_RDATA),      // input  wire [31 : 0] m_axi_rdata
  .m_axi_rresp(fb_wr_axi4lite_RRESP),      // input  wire [1 : 0] m_axi_rresp
  .m_axi_rvalid(fb_wr_axi4lite_RVALID),    // input  wire m_axi_rvalid
  .m_axi_rready(fb_wr_axi4lite_RREADY),    // output wire m_axi_rready

  .s_axi_awqos(4'b0),      // input  wire [3 : 0] s_axi_awqos
  .s_axi_arqos(4'b0)      // input  wire [3 : 0] s_axi_arqos
);

axi_protocol_converter_0 tft_protocol_converter (
  .aclk(clk_100),                    // input  wire aclk
  .aresetn(aresetn),              // input  wire aresetn

  .s_axi_awaddr(tft_slave_100M_awaddr),    // input  wire [31 : 0] s_axi_awaddr
  .s_axi_awlen(tft_slave_100M_awlen),      // input  wire [3 : 0] s_axi_awlen
  .s_axi_awsize(tft_slave_100M_awsize),    // input  wire [2 : 0] s_axi_awsize
  .s_axi_awburst(tft_slave_100M_awburst),  // input  wire [1 : 0] s_axi_awburst
  .s_axi_awlock(tft_slave_100M_awlock),    // input  wire [1 : 0] s_axi_awlock
  .s_axi_awcache(tft_slave_100M_awcache),  // input  wire [3 : 0] s_axi_awcache
  .s_axi_awprot(tft_slave_100M_awprot),    // input  wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(tft_slave_100M_awvalid),  // input  wire s_axi_awvalid
  .s_axi_awready(tft_slave_100M_awready),  // output wire s_axi_awready
  .s_axi_wdata(tft_slave_100M_wdata),      // input  wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(tft_slave_100M_wstrb),      // input  wire [3 : 0] s_axi_wstrb
  .s_axi_wlast(tft_slave_100M_wlast),      // input  wire s_axi_wlast
  .s_axi_wvalid(tft_slave_100M_wvalid),    // input  wire s_axi_wvalid
  .s_axi_wready(tft_slave_100M_wready),    // output wire s_axi_wready
  .s_axi_bresp(tft_slave_100M_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(tft_slave_100M_bvalid),    // output wire s_axi_bvalid
  .s_axi_bready(tft_slave_100M_bready),    // input  wire s_axi_bready
  .s_axi_araddr(tft_slave_100M_araddr),    // input  wire [31 : 0] s_axi_araddr
  .s_axi_arlen(tft_slave_100M_arlen),      // input  wire [3 : 0] s_axi_arlen
  .s_axi_arsize(tft_slave_100M_arsize),    // input  wire [2 : 0] s_axi_arsize
  .s_axi_arburst(tft_slave_100M_arburst),  // input  wire [1 : 0] s_axi_arburst
  .s_axi_arlock(tft_slave_100M_arlock),    // input  wire [1 : 0] s_axi_arlock
  .s_axi_arcache(tft_slave_100M_arcache),  // input  wire [3 : 0] s_axi_arcache
  .s_axi_arprot(tft_slave_100M_arprot),    // input  wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(tft_slave_100M_arvalid),  // input  wire s_axi_arvalid
  .s_axi_arready(tft_slave_100M_arready),  // output wire s_axi_arready
  .s_axi_rdata(tft_slave_100M_rdata),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(tft_slave_100M_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(tft_slave_100M_rlast),      // output wire s_axi_rlast
  .s_axi_rvalid(tft_slave_100M_rvalid),    // output wire s_axi_rvalid
  .s_axi_rready(tft_slave_100M_rready),    // input  wire s_axi_rready


  .m_axi_awaddr(tft_axi_lite_awaddr),    // output wire [31 : 0] m_axi_awaddr
  .m_axi_awprot(),    // output wire [2 : 0] m_axi_awprot
  .m_axi_awvalid(tft_axi_lite_awvalid),  // output wire m_axi_awvalid
  .m_axi_awready(tft_axi_lite_awready),  // input  wire m_axi_awready
  .m_axi_wdata(tft_axi_lite_wdata),      // output wire [31 : 0] m_axi_wdata
  .m_axi_wstrb(tft_axi_lite_wstrb),      // output wire [3 : 0] m_axi_wstrb
  .m_axi_wvalid(tft_axi_lite_wvalid),    // output wire m_axi_wvalid
  .m_axi_wready(tft_axi_lite_wready),    // input  wire m_axi_wready
  .m_axi_bresp(tft_axi_lite_bresp),      // input  wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(tft_axi_lite_bvalid),    // input  wire m_axi_bvalid
  .m_axi_bready(tft_axi_lite_bready),    // output wire m_axi_bready
  .m_axi_araddr(tft_axi_lite_araddr),    // output wire [31 : 0] m_axi_araddr
  .m_axi_arprot( ),    // output wire [2 : 0] m_axi_arprot
  .m_axi_arvalid(tft_axi_lite_arvalid),  // output wire m_axi_arvalid
  .m_axi_arready(tft_axi_lite_arready),  // input  wire m_axi_arready
  .m_axi_rdata(tft_axi_lite_rdata),      // input  wire [31 : 0] m_axi_rdata
  .m_axi_rresp(tft_axi_lite_rresp),      // input  wire [1 : 0] m_axi_rresp
  .m_axi_rvalid(tft_axi_lite_rvalid),    // input  wire m_axi_rvalid
  .m_axi_rready(tft_axi_lite_rready),    // output wire m_axi_rready

  .s_axi_awqos(4'b0),      // input  wire [3 : 0] s_axi_awqos
  .s_axi_arqos(4'b0)      // input  wire [3 : 0] s_axi_arqos
);


v_frmbuf_wr_0 fb_write (
  .s_axi_CTRL_AWADDR(fb_wr_axi4lite_AWADDR),              // input  wire [6 : 0] s_axi_CTRL_AWADDR
  .s_axi_CTRL_AWVALID(fb_wr_axi4lite_AWVALID),            // input  wire s_axi_CTRL_AWVALID
  .s_axi_CTRL_AWREADY(fb_wr_axi4lite_AWREADY),            // output wire s_axi_CTRL_AWREADY
  .s_axi_CTRL_WDATA(fb_wr_axi4lite_WDATA),                // input  wire [31 : 0] s_axi_CTRL_WDATA
  .s_axi_CTRL_WSTRB(fb_wr_axi4lite_WSTRB),                // input  wire [3 : 0] s_axi_CTRL_WSTRB
  .s_axi_CTRL_WVALID(fb_wr_axi4lite_WVALID),              // input  wire s_axi_CTRL_WVALID
  .s_axi_CTRL_WREADY(fb_wr_axi4lite_WREADY),              // output wire s_axi_CTRL_WREADY
  .s_axi_CTRL_BRESP(fb_wr_axi4lite_BRESP),                // output wire [1 : 0] s_axi_CTRL_BRESP
  .s_axi_CTRL_BVALID(fb_wr_axi4lite_BVALID),              // output wire s_axi_CTRL_BVALID
  .s_axi_CTRL_BREADY(fb_wr_axi4lite_BREADY),              // input  wire s_axi_CTRL_BREADY
  .s_axi_CTRL_ARADDR(fb_wr_axi4lite_ARADDR),              // input  wire [6 : 0] s_axi_CTRL_ARADDR
  .s_axi_CTRL_ARVALID(fb_wr_axi4lite_ARVALID),            // input  wire s_axi_CTRL_ARVALID
  .s_axi_CTRL_ARREADY(fb_wr_axi4lite_ARREADY),            // output wire s_axi_CTRL_ARREADY
  .s_axi_CTRL_RDATA(fb_wr_axi4lite_RDATA),                // output wire [31 : 0] s_axi_CTRL_RDATA
  .s_axi_CTRL_RRESP(fb_wr_axi4lite_RRESP),                // output wire [1 : 0] s_axi_CTRL_RRESP
  .s_axi_CTRL_RVALID(fb_wr_axi4lite_RVALID),              // output wire s_axi_CTRL_RVALID
  .s_axi_CTRL_RREADY(fb_wr_axi4lite_RREADY),              // input  wire s_axi_CTRL_RREADY

  .ap_clk(clk_100),                                    // input  wire ap_clk
  .ap_rst_n(aresetn),                                // input  wire ap_rst_n
  .interrupt( ),                              // output wire interrupt


  .m_axi_mm_video_AWADDR(fb_wr_video_AWADDR),      // output wire [31 : 0] m_axi_mm_video_AWADDR
  .m_axi_mm_video_AWLEN(fb_wr_video_AWLEN),        // output wire [7 : 0] m_axi_mm_video_AWLEN
  .m_axi_mm_video_AWSIZE(fb_wr_video_AWSIZE),      // output wire [2 : 0] m_axi_mm_video_AWSIZE
  .m_axi_mm_video_AWBURST(fb_wr_video_AWBURST),    // output wire [1 : 0] m_axi_mm_video_AWBURST
  .m_axi_mm_video_AWLOCK(fb_wr_video_AWLOCK),      // output wire [1 : 0] m_axi_mm_video_AWLOCK
  .m_axi_mm_video_AWREGION(fb_wr_video_AWREGION),  // output wire [3 : 0] m_axi_mm_video_AWREGION
  .m_axi_mm_video_AWCACHE(fb_wr_video_AWCACHE),    // output wire [3 : 0] m_axi_mm_video_AWCACHE
  .m_axi_mm_video_AWPROT(fb_wr_video_AWPROT),      // output wire [2 : 0] m_axi_mm_video_AWPROT
  .m_axi_mm_video_AWQOS(fb_wr_video_AWQOS),        // output wire [3 : 0] m_axi_mm_video_AWQOS
  .m_axi_mm_video_AWVALID(fb_wr_video_AWVALID),    // output wire m_axi_mm_video_AWVALID
  .m_axi_mm_video_AWREADY(fb_wr_video_AWREADY),    // input  wire m_axi_mm_video_AWREADY
  .m_axi_mm_video_WDATA(fb_wr_video_WDATA),        // output wire [63 : 0] m_axi_mm_video_WDATA
  .m_axi_mm_video_WSTRB(fb_wr_video_WSTRB),        // output wire [7 : 0] m_axi_mm_video_WSTRB
  .m_axi_mm_video_WLAST(fb_wr_video_WLAST),        // output wire m_axi_mm_video_WLAST
  .m_axi_mm_video_WVALID(fb_wr_video_WVALID),      // output wire m_axi_mm_video_WVALID
  .m_axi_mm_video_WREADY(fb_wr_video_WREADY),      // input  wire m_axi_mm_video_WREADY
  .m_axi_mm_video_BRESP(fb_wr_video_BRESP),        // input  wire [1 : 0] m_axi_mm_video_BRESP
  .m_axi_mm_video_BVALID(fb_wr_video_BVALID),      // input  wire m_axi_mm_video_BVALID
  .m_axi_mm_video_BREADY(fb_wr_video_BREADY),      // output wire m_axi_mm_video_BREADY
  .m_axi_mm_video_ARADDR(fb_wr_video_ARADDR),      // output wire [31 : 0] m_axi_mm_video_ARADDR
  .m_axi_mm_video_ARLEN(fb_wr_video_ARLEN),        // output wire [7 : 0] m_axi_mm_video_ARLEN
  .m_axi_mm_video_ARSIZE(fb_wr_video_ARSIZE),      // output wire [2 : 0] m_axi_mm_video_ARSIZE
  .m_axi_mm_video_ARBURST(fb_wr_video_ARBURST),    // output wire [1 : 0] m_axi_mm_video_ARBURST
  .m_axi_mm_video_ARLOCK(fb_wr_video_ARLOCK),      // output wire [1 : 0] m_axi_mm_video_ARLOCK
  .m_axi_mm_video_ARREGION(fb_wr_video_ARREGION),  // output wire [3 : 0] m_axi_mm_video_ARREGION
  .m_axi_mm_video_ARCACHE(fb_wr_video_ARCACHE),    // output wire [3 : 0] m_axi_mm_video_ARCACHE
  .m_axi_mm_video_ARPROT(fb_wr_video_ARPROT),      // output wire [2 : 0] m_axi_mm_video_ARPROT
  .m_axi_mm_video_ARQOS(fb_wr_video_ARQOS),        // output wire [3 : 0] m_axi_mm_video_ARQOS
  .m_axi_mm_video_ARVALID(fb_wr_video_ARVALID),    // output wire m_axi_mm_video_ARVALID
  .m_axi_mm_video_ARREADY(fb_wr_video_ARREADY),    // input  wire m_axi_mm_video_ARREADY
  .m_axi_mm_video_RDATA(fb_wr_video_RDATA),        // input  wire [63 : 0] m_axi_mm_video_RDATA
  .m_axi_mm_video_RRESP(fb_wr_video_RRESP),        // input  wire [1 : 0] m_axi_mm_video_RRESP
  .m_axi_mm_video_RLAST(fb_wr_video_RLAST),        // input  wire m_axi_mm_video_RLAST
  .m_axi_mm_video_RVALID(fb_wr_video_RVALID),      // input  wire m_axi_mm_video_RVALID
  .m_axi_mm_video_RREADY(fb_wr_video_RREADY),      // output wire m_axi_mm_video_RREADY

  .s_axis_video_TVALID(s_axis_video_TVALID),          // input  wire s_axis_video_TVALID
  .s_axis_video_TREADY(s_axis_video_TREADY),          // output wire s_axis_video_TREADY
  .s_axis_video_TDATA(s_axis_video_TDATA),            // input  wire [23 : 0] s_axis_video_TDATA
  .s_axis_video_TKEEP(s_axis_video_TKEEP),            // input  wire [2 : 0] s_axis_video_TKEEP
  .s_axis_video_TSTRB(s_axis_video_TSTRB),            // input  wire [2 : 0] s_axis_video_TSTRB
  .s_axis_video_TUSER(s_axis_video_TUSER),            // input  wire s_axis_video_TUSER
  .s_axis_video_TLAST(s_axis_video_TLAST),            // input  wire s_axis_video_TLAST
  .s_axis_video_TID(s_axis_video_TID),                // input  wire s_axis_video_TID
  .s_axis_video_TDEST(s_axis_video_TDEST)             // input  wire s_axis_video_TDEST
);

v_frmbuf_rd_0 fb_read (
  .s_axi_CTRL_AWADDR(fb_rd_axi4lite_AWADDR),              // input  wire [6 : 0] s_axi_CTRL_AWADDR
  .s_axi_CTRL_AWVALID(fb_rd_axi4lite_AWVALID),            // input  wire s_axi_CTRL_AWVALID
  .s_axi_CTRL_AWREADY(fb_rd_axi4lite_AWREADY),            // output wire s_axi_CTRL_AWREADY
  .s_axi_CTRL_WDATA(fb_rd_axi4lite_WDATA),                // input  wire [31 : 0] s_axi_CTRL_WDATA
  .s_axi_CTRL_WSTRB(fb_rd_axi4lite_WSTRB),                // input  wire [3 : 0] s_axi_CTRL_WSTRB
  .s_axi_CTRL_WVALID(fb_rd_axi4lite_WVALID),              // input  wire s_axi_CTRL_WVALID
  .s_axi_CTRL_WREADY(fb_rd_axi4lite_WREADY),              // output wire s_axi_CTRL_WREADY
  .s_axi_CTRL_BRESP(fb_rd_axi4lite_BRESP),                // output wire [1 : 0] s_axi_CTRL_BRESP
  .s_axi_CTRL_BVALID(fb_rd_axi4lite_BVALID),              // output wire s_axi_CTRL_BVALID
  .s_axi_CTRL_BREADY(fb_rd_axi4lite_BREADY),              // input  wire s_axi_CTRL_BREADY
  .s_axi_CTRL_ARADDR(fb_rd_axi4lite_ARADDR),              // input  wire [6 : 0] s_axi_CTRL_ARADDR
  .s_axi_CTRL_ARVALID(fb_rd_axi4lite_ARVALID),            // input  wire s_axi_CTRL_ARVALID
  .s_axi_CTRL_ARREADY(fb_rd_axi4lite_ARREADY),            // output wire s_axi_CTRL_ARREADY
  .s_axi_CTRL_RDATA(fb_rd_axi4lite_RDATA),                // output wire [31 : 0] s_axi_CTRL_RDATA
  .s_axi_CTRL_RRESP(fb_rd_axi4lite_RRESP),                // output wire [1 : 0] s_axi_CTRL_RRESP
  .s_axi_CTRL_RVALID(fb_rd_axi4lite_RVALID),              // output wire s_axi_CTRL_RVALID
  .s_axi_CTRL_RREADY(fb_rd_axi4lite_RREADY),              // input  wire s_axi_CTRL_RREADY

  .ap_clk(clk_100),                                    // input  wire ap_clk
  .ap_rst_n(aresetn),                                // input  wire ap_rst_n
  .interrupt( ),                              // output wire interrupt

  .m_axi_mm_video_AWADDR(fb_rd_video_AWADDR),      // output wire [31 : 0] m_axi_mm_video_AWADDR
  .m_axi_mm_video_AWLEN(fb_rd_video_AWLEN),        // output wire [7 : 0] m_axi_mm_video_AWLEN
  .m_axi_mm_video_AWSIZE(fb_rd_video_AWSIZE),      // output wire [2 : 0] m_axi_mm_video_AWSIZE
  .m_axi_mm_video_AWBURST(fb_rd_video_AWBURST),    // output wire [1 : 0] m_axi_mm_video_AWBURST
  .m_axi_mm_video_AWLOCK(fb_rd_video_AWLOCK),      // output wire [1 : 0] m_axi_mm_video_AWLOCK
  .m_axi_mm_video_AWREGION(fb_rd_video_AWREGION),  // output wire [3 : 0] m_axi_mm_video_AWREGION
  .m_axi_mm_video_AWCACHE(fb_rd_video_AWCACHE),    // output wire [3 : 0] m_axi_mm_video_AWCACHE
  .m_axi_mm_video_AWPROT(fb_rd_video_AWPROT),      // output wire [2 : 0] m_axi_mm_video_AWPROT
  .m_axi_mm_video_AWQOS(fb_rd_video_AWQOS),        // output wire [3 : 0] m_axi_mm_video_AWQOS
  .m_axi_mm_video_AWVALID(fb_rd_video_AWVALID),    // output wire m_axi_mm_video_AWVALID
  .m_axi_mm_video_AWREADY(fb_rd_video_AWREADY),    // input  wire m_axi_mm_video_AWREADY
  .m_axi_mm_video_WDATA(fb_rd_video_WDATA),        // output wire [63 : 0] m_axi_mm_video_WDATA
  .m_axi_mm_video_WSTRB(fb_rd_video_WSTRB),        // output wire [7 : 0] m_axi_mm_video_WSTRB
  .m_axi_mm_video_WLAST(fb_rd_video_WLAST),        // output wire m_axi_mm_video_WLAST
  .m_axi_mm_video_WVALID(fb_rd_video_WVALID),      // output wire m_axi_mm_video_WVALID
  .m_axi_mm_video_WREADY(fb_rd_video_WREADY),      // input  wire m_axi_mm_video_WREADY
  .m_axi_mm_video_BRESP(fb_rd_video_BRESP),        // input  wire [1 : 0] m_axi_mm_video_BRESP
  .m_axi_mm_video_BVALID(fb_rd_video_BVALID),      // input  wire m_axi_mm_video_BVALID
  .m_axi_mm_video_BREADY(fb_rd_video_BREADY),      // output wire m_axi_mm_video_BREADY
  .m_axi_mm_video_ARADDR(fb_rd_video_ARADDR),      // output wire [31 : 0] m_axi_mm_video_ARADDR
  .m_axi_mm_video_ARLEN(fb_rd_video_ARLEN),        // output wire [7 : 0] m_axi_mm_video_ARLEN
  .m_axi_mm_video_ARSIZE(fb_rd_video_ARSIZE),      // output wire [2 : 0] m_axi_mm_video_ARSIZE
  .m_axi_mm_video_ARBURST(fb_rd_video_ARBURST),    // output wire [1 : 0] m_axi_mm_video_ARBURST
  .m_axi_mm_video_ARLOCK(fb_rd_video_ARLOCK),      // output wire [1 : 0] m_axi_mm_video_ARLOCK
  .m_axi_mm_video_ARREGION(fb_rd_video_ARREGION),  // output wire [3 : 0] m_axi_mm_video_ARREGION
  .m_axi_mm_video_ARCACHE(fb_rd_video_ARCACHE),    // output wire [3 : 0] m_axi_mm_video_ARCACHE
  .m_axi_mm_video_ARPROT(fb_rd_video_ARPROT),      // output wire [2 : 0] m_axi_mm_video_ARPROT
  .m_axi_mm_video_ARQOS(fb_rd_video_ARQOS),        // output wire [3 : 0] m_axi_mm_video_ARQOS
  .m_axi_mm_video_ARVALID(fb_rd_video_ARVALID),    // output wire m_axi_mm_video_ARVALID
  .m_axi_mm_video_ARREADY(fb_rd_video_ARREADY),    // input  wire m_axi_mm_video_ARREADY
  .m_axi_mm_video_RDATA(fb_rd_video_RDATA),        // input  wire [63 : 0] m_axi_mm_video_RDATA
  .m_axi_mm_video_RRESP(fb_rd_video_RRESP),        // input  wire [1 : 0] m_axi_mm_video_RRESP
  .m_axi_mm_video_RLAST(fb_rd_video_RLAST),        // input  wire m_axi_mm_video_RLAST
  .m_axi_mm_video_RVALID(fb_rd_video_RVALID),      // input  wire m_axi_mm_video_RVALID
  .m_axi_mm_video_RREADY(fb_rd_video_RREADY),      // output wire m_axi_mm_video_RREADY

  .m_axis_video_TVALID(m_axis_video_TVALID),          // output wire m_axis_video_TVALID
  .m_axis_video_TREADY(m_axis_video_TREADY),          // input  wire m_axis_video_TREADY
  .m_axis_video_TDATA(m_axis_video_TDATA),            // output wire [23 : 0] m_axis_video_TDATA
  .m_axis_video_TKEEP(m_axis_video_TKEEP),            // output wire [2 : 0] m_axis_video_TKEEP
  .m_axis_video_TSTRB(m_axis_video_TSTRB),            // output wire [2 : 0] m_axis_video_TSTRB
  .m_axis_video_TUSER(m_axis_video_TUSER),            // output wire [0 : 0] m_axis_video_TUSER
  .m_axis_video_TLAST(m_axis_video_TLAST),            // output wire [0 : 0] m_axis_video_TLAST
  .m_axis_video_TID(m_axis_video_TID),                // output wire [0 : 0] m_axis_video_TID
  .m_axis_video_TDEST(m_axis_video_TDEST)             // output wire [0 : 0] m_axis_video_TDEST
);

axi_tft_0 tft (
  .s_axi_aclk(clk_100),        // input  wire s_axi_aclk
  .s_axi_aresetn(aresetn),  // input  wire s_axi_aresetn

  .m_axi_aclk(clk_100),        // input  wire m_axi_aclk
  .m_axi_aresetn(aresetn),  // input  wire m_axi_aresetn

  .md_error(),            // output wire md_error
  .ip2intc_irpt(),    // output wire ip2intc_irpt

  .m_axi_arready(tft_100M_arready),  // input  wire m_axi_arready
  .m_axi_arvalid(tft_100M_arvalid),  // output wire m_axi_arvalid
  .m_axi_araddr(tft_100M_araddr),    // output wire [31 : 0] m_axi_araddr
  .m_axi_arlen(tft_100M_arlen),      // output wire [7 : 0] m_axi_arlen
  .m_axi_arsize(tft_100M_arsize),    // output wire [2 : 0] m_axi_arsize
  .m_axi_arburst(tft_100M_arburst),  // output wire [1 : 0] m_axi_arburst
  .m_axi_arprot(tft_100M_arprot),    // output wire [2 : 0] m_axi_arprot
  .m_axi_arcache(tft_100M_arcache),  // output wire [3 : 0] m_axi_arcache
  .m_axi_rready(tft_100M_rready),    // output wire m_axi_rready
  .m_axi_rvalid(tft_100M_rvalid),    // input  wire m_axi_rvalid
  .m_axi_rdata(tft_100M_rdata),      // input  wire [31 : 0] m_axi_rdata
  .m_axi_rresp(tft_100M_rresp),      // input  wire [1 : 0] m_axi_rresp
  .m_axi_rlast(tft_100M_rlast),      // input  wire m_axi_rlast
  .m_axi_awready(tft_100M_awready),  // input  wire m_axi_awready
  .m_axi_awvalid(tft_100M_awvalid),  // output wire m_axi_awvalid
  .m_axi_awaddr(tft_100M_awaddr),    // output wire [31 : 0] m_axi_awaddr
  .m_axi_awlen(tft_100M_awlen),      // output wire [7 : 0] m_axi_awlen
  .m_axi_awsize(tft_100M_awsize),    // output wire [2 : 0] m_axi_awsize
  .m_axi_awburst(tft_100M_awburst),  // output wire [1 : 0] m_axi_awburst
  .m_axi_awprot(tft_100M_awprot),    // output wire [2 : 0] m_axi_awprot
  .m_axi_awcache(tft_100M_awcache),  // output wire [3 : 0] m_axi_awcache
  .m_axi_wready(tft_100M_wready),    // input  wire m_axi_wready
  .m_axi_wvalid(tft_100M_wvalid),    // output wire m_axi_wvalid
  .m_axi_wdata(tft_100M_wdata),      // output wire [31 : 0] m_axi_wdata
  .m_axi_wstrb(tft_100M_wstrb),      // output wire [3 : 0] m_axi_wstrb
  .m_axi_wlast(tft_100M_wlast),      // output wire m_axi_wlast
  .m_axi_bready(tft_100M_bready),    // output wire m_axi_bready
  .m_axi_bvalid(tft_100M_bvalid),    // input  wire m_axi_bvalid
  .m_axi_bresp(tft_100M_bresp),      // input  wire [1 : 0] m_axi_bresp

  .s_axi_awaddr(tft_axi_lite_awaddr),    // input  wire [3 : 0] s_axi_awaddr
  .s_axi_awvalid(tft_axi_lite_awvalid),  // input  wire s_axi_awvalid
  .s_axi_awready(tft_axi_lite_awready),  // output wire s_axi_awready
  .s_axi_wdata(tft_axi_lite_wdata),      // input  wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(tft_axi_lite_wstrb),      // input  wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(tft_axi_lite_wvalid),    // input  wire s_axi_wvalid
  .s_axi_wready(tft_axi_lite_wready),    // output wire s_axi_wready
  .s_axi_bresp(tft_axi_lite_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(tft_axi_lite_bvalid),    // output wire s_axi_bvalid
  .s_axi_bready(tft_axi_lite_bready),    // input  wire s_axi_bready
  .s_axi_araddr(tft_axi_lite_araddr),    // input  wire [3 : 0] s_axi_araddr
  .s_axi_arvalid(tft_axi_lite_arvalid),  // input  wire s_axi_arvalid
  .s_axi_arready(tft_axi_lite_arready),  // output wire s_axi_arready
  .s_axi_rdata(tft_axi_lite_rdata),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(tft_axi_lite_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(tft_axi_lite_rvalid),    // output wire s_axi_rvalid
  .s_axi_rready(tft_axi_lite_rready),    // input  wire s_axi_rready

  .sys_tft_clk(clk_25),      // input  wire sys_tft_clk
  .tft_hsync(VGA_hsync),          // output wire tft_hsync
  .tft_vsync(VGA_vsync),          // output wire tft_vsync
  .tft_de( ),                // output wire tft_de
  .tft_dps( ),              // output wire tft_dps
  .tft_vga_clk( ),      // output wire tft_vga_clk
  .tft_vga_r(VGA_red),          // output wire [5 : 0] tft_vga_r
  .tft_vga_g(VGA_green),          // output wire [5 : 0] tft_vga_g
  .tft_vga_b(VGA_blue)           // output wire [5 : 0] tft_vga_b
);

stream_ctl_0 stream_ctl (
  .s_axis_video_TREADY(m_axis_video_TREADY),  // output wire s_axis_video_TREADY
  .m_axis_video_TVALID(s_axis_video_TVALID),  // output wire m_axis_video_TVALID
  .m_axis_video_TDATA(s_axis_video_TDATA),    // output wire [23 : 0] m_axis_video_TDATA
  .m_axis_video_TKEEP(s_axis_video_TKEEP),    // output wire [2 : 0] m_axis_video_TKEEP
  .m_axis_video_TSTRB(s_axis_video_TSTRB),    // output wire [2 : 0] m_axis_video_TSTRB
  .m_axis_video_TUSER(s_axis_video_TUSER),    // output wire [0 : 0] m_axis_video_TUSER
  .m_axis_video_TLAST(s_axis_video_TLAST),    // output wire [0 : 0] m_axis_video_TLAST
  .m_axis_video_TID(s_axis_video_TID),        // output wire [0 : 0] m_axis_video_TID
  .m_axis_video_TDEST(s_axis_video_TDEST),    // output wire [0 : 0] m_axis_video_TDEST

  .aclk(clk_100),                                // input wire aclk
  .aresetn(aresetn),                          // input wire aresetn

  .ctl_reg1(vga_reg),                         // input wire [31 : 0] ctl_reg1
  .s_axis_video_TVALID(m_axis_video_TVALID),  // input wire s_axis_video_TVALID
  .s_axis_video_TDATA(m_axis_video_TDATA),    // input wire [23 : 0] s_axis_video_TDATA
  .s_axis_video_TKEEP(m_axis_video_TKEEP),    // input wire [2 : 0] s_axis_video_TKEEP
  .s_axis_video_TSTRB(m_axis_video_TSTRB),    // input wire [2 : 0] s_axis_video_TSTRB
  .s_axis_video_TUSER(m_axis_video_TUSER),    // input wire s_axis_video_TUSER
  .s_axis_video_TLAST(m_axis_video_TLAST),    // input wire s_axis_video_TLAST
  .s_axis_video_TID(m_axis_video_TID),        // input wire s_axis_video_TID
  .s_axis_video_TDEST(m_axis_video_TDEST),    // input wire s_axis_video_TDEST
  .m_axis_video_TREADY(s_axis_video_TREADY)   // input wire m_axis_video_TREADY
);

proc_sys_reset_0 main_reset (
  .slowest_sync_clk(aclk),          // input wire slowest_sync_clk
  .ext_reset_in(1'b1),                  // input wire ext_reset_in
  .aux_reset_in(c1_calib_done),                  // input wire aux_reset_in
  .mb_debug_sys_rst(1'b0),          // input wire mb_debug_sys_rst
  .dcm_locked(clk_locked),                      // input wire dcm_locked
  .mb_reset(cpu_reset_p),                          // output wire mb_reset
  .bus_struct_reset( ),          // output wire [0 : 0] bus_struct_reset
  .peripheral_reset( ),          // output wire [0 : 0] peripheral_reset
  .interconnect_aresetn(interconnect_aresetn),  // output wire [0 : 0] interconnect_aresetn
  .peripheral_aresetn(aresetn)       // output wire [0 : 0] peripheral_aresetn
);

endmodule
