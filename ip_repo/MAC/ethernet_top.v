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

module ethernet_top
(
    hclk,
    hrst_,      
    mawid_o    ,
    mawaddr_o  ,
    mawlen_o   ,
    mawsize_o  ,
    mawburst_o ,
    mawlock_o  ,
    mawcache_o ,
    mawprot_o  ,
    mawvalid_o ,
    mawready_i ,
    mwid_o     ,
    mwdata_o   ,
    mwstrb_o   ,
    mwlast_o   ,
    mwvalid_o  ,
    mwready_i  ,
    mbid_i     ,
    mbresp_i   ,
    mbvalid_i  ,
    mbready_o  ,
    marid_o    ,
    maraddr_o  ,
    marlen_o   ,
    marsize_o  ,
    marburst_o ,
    marlock_o  ,
    marcache_o ,
    marprot_o  ,
    marvalid_o ,
    marready_i ,
    mrid_i     ,
    mrdata_i   ,
    mrresp_i   ,
    mrlast_i   ,
    mrvalid_i  ,
    mrready_o  ,
    sawid_i    ,
    sawaddr_i  ,
    sawlen_i   ,
    sawsize_i  ,
    sawburst_i ,
    sawlock_i  ,
    sawcache_i ,
    sawprot_i  ,
    sawvalid_i ,
    sawready_o ,   
    swid_i     ,
    swdata_i   ,
    swstrb_i   ,
    swlast_i   ,
    swvalid_i  ,
    swready_o  ,
    sbid_o     ,
    sbresp_o   ,
    sbvalid_o  ,
    sbready_i  ,
    sarid_i    ,
    saraddr_i  ,
    sarlen_i   ,
    sarsize_i  ,
    sarburst_i ,
    sarlock_i  ,
    sarcache_i ,
    sarprot_i  ,
    sarvalid_i ,
    sarready_o ,
    srid_o     ,
    srdata_o   ,
    srresp_o   ,
    srlast_o   ,
    srvalid_o  ,
    srready_i  ,                 

    interrupt_0,
 
    mtxclk_0,     
    mtxen_0,      
    mtxd_0,       
    mtxerr_0,
    mrxclk_0,      
    mrxdv_0,     
    mrxd_0,        
    mrxerr_0,
    mcoll_0,
    mcrs_0,
    mdc_0,
    md_i_0,
    md_o_0,       
    md_oe_0
);

input   hclk;
input   hrst_;      

  output  [  3:0] mawid_o              ;
  output  [ 31:0] mawaddr_o            ;
  output  [  3:0] mawlen_o             ;
  output  [  2:0] mawsize_o            ;
  output  [  1:0] mawburst_o           ;
  output  [  1:0] mawlock_o            ;
  output  [  3:0] mawcache_o           ;
  output  [  2:0] mawprot_o            ;
  output          mawvalid_o           ;
  input           mawready_i           ;
  output  [  3:0] mwid_o               ;
  output  [ 31:0] mwdata_o             ;
  output  [  3:0] mwstrb_o             ;
  output          mwlast_o             ;
  output          mwvalid_o            ;
  input           mwready_i            ;
  input   [  3:0] mbid_i               ;
  input   [  1:0] mbresp_i             ;
  input           mbvalid_i            ;
  output          mbready_o            ;
  output  [  3:0] marid_o              ;
  output  [ 31:0] maraddr_o            ;
  output  [  3:0] marlen_o             ;
  output  [  2:0] marsize_o            ;
  output  [  1:0] marburst_o           ;
  output  [  1:0] marlock_o            ;
  output  [  3:0] marcache_o           ;
  output  [  2:0] marprot_o            ;
  output          marvalid_o           ;
  input           marready_i           ;
  input   [  3:0] mrid_i               ;
  input   [ 31:0] mrdata_i             ;
  input   [  1:0] mrresp_i             ;
  input           mrlast_i             ;
  input           mrvalid_i            ;
  output          mrready_o            ;                 

  input   [  3:0]   sawid_i              ;
  input   [ 31:0]   sawaddr_i            ;
  input   [  3:0]   sawlen_i             ;
  input   [  2:0]   sawsize_i            ;
  input   [  1:0]   sawburst_i           ;
  input   [  1:0]   sawlock_i            ;
  input   [  3:0]   sawcache_i           ;
  input   [  2:0]   sawprot_i            ;
  input             sawvalid_i           ;
  output            sawready_o           ;
  input   [  3:0]   swid_i               ;
  input   [ 31:0]   swdata_i             ;
  input   [  3:0]   swstrb_i             ;
  input             swlast_i             ;
  input             swvalid_i            ;
  output            swready_o            ;
  output  [  3:0]   sbid_o               ;
  output  [  1:0]   sbresp_o             ;
  output            sbvalid_o            ;
  input             sbready_i            ;
  input   [  3:0]   sarid_i              ;
  input   [ 31:0]   saraddr_i            ;
  input   [  3:0]   sarlen_i             ;
  input   [  2:0]   sarsize_i            ;
  input   [  1:0]   sarburst_i           ;
  input   [  1:0]   sarlock_i            ;
  input   [  3:0]   sarcache_i           ;
  input   [  2:0]   sarprot_i            ;
  input             sarvalid_i           ;
  output            sarready_o           ;
  output  [  3:0]   srid_o               ;
  output  [ 31:0]   srdata_o             ;
  output  [  1:0]   srresp_o             ;
  output            srlast_o             ;
  output            srvalid_o            ;
  input             srready_i            ;      

// (* MARK_DEBUG = "TRUE" *) wire [3:0] mawid_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [31:0] mawaddr_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] mawlen_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [2:0] mawsize_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [1:0] mawburst_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [1:0] mawlock_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] mawcache_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [2:0] mawprot_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] mawvalid_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] mawready_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] mwid_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [31:0] mwdata_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] mwstrb_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] mwlast_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] mwvalid_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] mwready_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] mbid_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [1:0] mbresp_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] mbvalid_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] mbready_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] marid_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [31:0] maraddr_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] marlen_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [2:0] marsize_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [1:0] marburst_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [1:0] marlock_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] marcache_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [2:0] marprot_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] marvalid_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] marready_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] mrid_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [31:0] mrdata_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [1:0] mrresp_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] mrlast_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] mrvalid_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] mrready_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] sawid_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [31:0] sawaddr_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] sawlen_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [2:0] sawsize_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [1:0] sawburst_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [1:0] sawlock_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] sawcache_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [2:0] sawprot_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] sawvalid_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] sawready_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] swid_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [31:0] swdata_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] swstrb_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] swlast_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] swvalid_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] swready_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] sbid_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [1:0] sbresp_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] sbvalid_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] sbready_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] sarid_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [31:0] saraddr_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] sarlen_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [2:0] sarsize_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [1:0] sarburst_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [1:0] sarlock_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] sarcache_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [2:0] sarprot_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] sarvalid_i_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] sarready_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [3:0] srid_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [31:0] srdata_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [1:0] srresp_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] srlast_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] srvalid_o_ila;
// (* MARK_DEBUG = "TRUE" *) wire [0:0] srready_i_ila;

// assign mawid_o_ila = mawid_o;
// assign mawaddr_o_ila = mawaddr_o;
// assign mawlen_o_ila = mawlen_o;
// assign mawsize_o_ila = mawsize_o;
// assign mawburst_o_ila = mawburst_o;
// assign mawlock_o_ila = mawlock_o;
// assign mawcache_o_ila = mawcache_o;
// assign mawprot_o_ila = mawprot_o;
// assign mawvalid_o_ila = mawvalid_o;
// assign mawready_i_ila = mawready_i;
// assign mwid_o_ila = mwid_o;
// assign mwdata_o_ila = mwdata_o;
// assign mwstrb_o_ila = mwstrb_o;
// assign mwlast_o_ila = mwlast_o;
// assign mwvalid_o_ila = mwvalid_o;
// assign mwready_i_ila = mwready_i;
// assign mbid_i_ila = mbid_i;
// assign mbresp_i_ila = mbresp_i;
// assign mbvalid_i_ila = mbvalid_i;
// assign mbready_o_ila = mbready_o;
// assign marid_o_ila = marid_o;
// assign maraddr_o_ila = maraddr_o;
// assign marlen_o_ila = marlen_o;
// assign marsize_o_ila = marsize_o;
// assign marburst_o_ila = marburst_o;
// assign marlock_o_ila = marlock_o;
// assign marcache_o_ila = marcache_o;
// assign marprot_o_ila = marprot_o;
// assign marvalid_o_ila = marvalid_o;
// assign marready_i_ila = marready_i;
// assign mrid_i_ila = mrid_i;
// assign mrdata_i_ila = mrdata_i;
// assign mrresp_i_ila = mrresp_i;
// assign mrlast_i_ila = mrlast_i;
// assign mrvalid_i_ila = mrvalid_i;
// assign mrready_o_ila = mrready_o;
// assign sawid_i_ila = sawid_i;
// assign sawaddr_i_ila = sawaddr_i;
// assign sawlen_i_ila = sawlen_i;
// assign sawsize_i_ila = sawsize_i;
// assign sawburst_i_ila = sawburst_i;
// assign sawlock_i_ila = sawlock_i;
// assign sawcache_i_ila = sawcache_i;
// assign sawprot_i_ila = sawprot_i;
// assign sawvalid_i_ila = sawvalid_i;
// assign sawready_o_ila = sawready_o;
// assign swid_i_ila = swid_i;
// assign swdata_i_ila = swdata_i;
// assign swstrb_i_ila = swstrb_i;
// assign swlast_i_ila = swlast_i;
// assign swvalid_i_ila = swvalid_i;
// assign swready_o_ila = swready_o;
// assign sbid_o_ila = sbid_o;
// assign sbresp_o_ila = sbresp_o;
// assign sbvalid_o_ila = sbvalid_o;
// assign sbready_i_ila = sbready_i;
// assign sarid_i_ila = sarid_i;
// assign saraddr_i_ila = saraddr_i;
// assign sarlen_i_ila = sarlen_i;
// assign sarsize_i_ila = sarsize_i;
// assign sarburst_i_ila = sarburst_i;
// assign sarlock_i_ila = sarlock_i;
// assign sarcache_i_ila = sarcache_i;
// assign sarprot_i_ila = sarprot_i;
// assign sarvalid_i_ila = sarvalid_i;
// assign sarready_o_ila = sarready_o;
// assign srid_o_ila = srid_o;
// assign srdata_o_ila = srdata_o;
// assign srresp_o_ila = srresp_o;
// assign srlast_o_ila = srlast_o;
// assign srvalid_o_ila = srvalid_o;
// assign srready_i_ila = srready_i;

// ila_0 ila(
// .clk(hclk),
// .probe0(mawid_o_ila[3:0]),
// .probe1(mawaddr_o_ila[31:0]),
// .probe2(mawlen_o_ila[3:0]),
// .probe3(mawsize_o_ila[2:0]),
// .probe4(mawburst_o_ila[1:0]),
// .probe5(mawlock_o_ila[1:0]),
// .probe6(mawcache_o_ila[3:0]),
// .probe7(mawprot_o_ila[2:0]),
// .probe8(mawvalid_o_ila[0:0]),
// .probe9(mawready_i_ila[0:0]),
// .probe10(mwid_o_ila[3:0]),
// .probe11(mwdata_o_ila[31:0]),
// .probe12(mwstrb_o_ila[3:0]),
// .probe13(mwlast_o_ila[0:0]),
// .probe14(mwvalid_o_ila[0:0]),
// .probe15(mwready_i_ila[0:0]),
// .probe16(mbid_i_ila[3:0]),
// .probe17(mbresp_i_ila[1:0]),
// .probe18(mbvalid_i_ila[0:0]),
// .probe19(mbready_o_ila[0:0]),
// .probe20(marid_o_ila[3:0]),
// .probe21(maraddr_o_ila[31:0]),
// .probe22(marlen_o_ila[3:0]),
// .probe23(marsize_o_ila[2:0]),
// .probe24(marburst_o_ila[1:0]),
// .probe25(marlock_o_ila[1:0]),
// .probe26(marcache_o_ila[3:0]),
// .probe27(marprot_o_ila[2:0]),
// .probe28(marvalid_o_ila[0:0]),
// .probe29(marready_i_ila[0:0]),
// .probe30(mrid_i_ila[3:0]),
// .probe31(mrdata_i_ila[31:0]),
// .probe32(mrresp_i_ila[1:0]),
// .probe33(mrlast_i_ila[0:0]),
// .probe34(mrvalid_i_ila[0:0]),
// .probe35(mrready_o_ila[0:0]),
// .probe36(sawid_i_ila[3:0]),
// .probe37(sawaddr_i_ila[31:0]),
// .probe38(sawlen_i_ila[3:0]),
// .probe39(sawsize_i_ila[2:0]),
// .probe40(sawburst_i_ila[1:0]),
// .probe41(sawlock_i_ila[1:0]),
// .probe42(sawcache_i_ila[3:0]),
// .probe43(sawprot_i_ila[2:0]),
// .probe44(sawvalid_i_ila[0:0]),
// .probe45(sawready_o_ila[0:0]),
// .probe46(swid_i_ila[3:0]),
// .probe47(swdata_i_ila[31:0]),
// .probe48(swstrb_i_ila[3:0]),
// .probe49(swlast_i_ila[0:0]),
// .probe50(swvalid_i_ila[0:0]),
// .probe51(swready_o_ila[0:0]),
// .probe52(sbid_o_ila[3:0]),
// .probe53(sbresp_o_ila[1:0]),
// .probe54(sbvalid_o_ila[0:0]),
// .probe55(sbready_i_ila[0:0]),
// .probe56(sarid_i_ila[3:0]),
// .probe57(saraddr_i_ila[31:0]),
// .probe58(sarlen_i_ila[3:0]),
// .probe59(sarsize_i_ila[2:0]),
// .probe60(sarburst_i_ila[1:0]),
// .probe61(sarlock_i_ila[1:0]),
// .probe62(sarcache_i_ila[3:0]),
// .probe63(sarprot_i_ila[2:0]),
// .probe64(sarvalid_i_ila[0:0]),
// .probe65(sarready_o_ila[0:0]),
// .probe66(srid_o_ila[3:0]),
// .probe67(srdata_o_ila[31:0]),
// .probe68(srresp_o_ila[1:0]),
// .probe69(srlast_o_ila[0:0]),
// .probe70(srvalid_o_ila[0:0]),
// .probe71(srready_i_ila[0:0])
// );

input           mtxclk_0;  
output  [3:0]   mtxd_0;    
output          mtxen_0;   
output          mtxerr_0;  

input           mrxclk_0;  
input   [3:0]   mrxd_0;    
input           mrxdv_0;   
input           mrxerr_0;  

input           mcoll_0;   
input           mcrs_0;    

input           md_i_0;      
output          mdc_0;     
output          md_o_0;      
output          md_oe_0;    

output          interrupt_0;


`define  MAHBDATAWIDTH 32
`define  TFIFODEPTH 9
`define  RFIFODEPTH 9
`define  ADDRDEPTH  6

wire    [`MAHBDATAWIDTH - 1:0] trdata_0;  
wire    twe_0;
wire    [`TFIFODEPTH - 1:0] twaddr_0;
wire    [`TFIFODEPTH - 1:0] traddr_0;
wire    [`MAHBDATAWIDTH - 1:0] twdata_0;

wire    [`MAHBDATAWIDTH - 1:0] rrdata_0; 
wire    rwe_0;
wire    [`RFIFODEPTH - 1:0] rwaddr_0;
wire    [`RFIFODEPTH - 1:0] rraddr_0;
wire    [`MAHBDATAWIDTH - 1:0] rwdata_0;    


mac_top u_mac_top_0
(
    .hclk(hclk),       
    .hrst_(hrst_),      

    .mawid_o      (mawid_o    ),
    .mawaddr_o    (mawaddr_o  ),
    .mawlen_o     (mawlen_o   ),
    .mawsize_o    (mawsize_o  ),
    .mawburst_o   (mawburst_o ),
    .mawlock_o    (mawlock_o  ),
    .mawcache_o   (mawcache_o ),
    .mawprot_o    (mawprot_o  ),
    .mawvalid_o   (mawvalid_o ),
    .mawready_i   (mawready_i ),
    .mwid_o       (mwid_o     ),
    .mwdata_o     (mwdata_o   ),
    .mwstrb_o     (mwstrb_o   ),
    .mwlast_o     (mwlast_o   ),
    .mwvalid_o    (mwvalid_o  ),
    .mwready_i    (mwready_i  ),
    .mbid_i       (mbid_i     ),
    .mbresp_i     (mbresp_i   ),
    .mbvalid_i    (mbvalid_i  ),
    .mbready_o    (mbready_o  ),
    .marid_o      (marid_o    ),
    .maraddr_o    (maraddr_o  ),
    .marlen_o     (marlen_o   ),
    .marsize_o    (marsize_o  ),
    .marburst_o   (marburst_o ),
    .marlock_o    (marlock_o  ),
    .marcache_o   (marcache_o ),
    .marprot_o    (marprot_o  ),
    .marvalid_o   (marvalid_o ),
    .marready_i   (marready_i ),
    .mrid_i       (mrid_i     ),
    .mrdata_i     (mrdata_i   ),
    .mrresp_i     (mrresp_i   ),
    .mrlast_i     (mrlast_i   ),
    .mrvalid_i    (mrvalid_i  ),
    .mrready_o    (mrready_o  ),
    .sawid_i       (sawid_i    ),
    .sawaddr_i     (sawaddr_i  ),
    .sawlen_i      (sawlen_i   ),
    .sawsize_i     (sawsize_i  ),
    .sawburst_i    (sawburst_i ),
    .sawlock_i     (sawlock_i  ),
    .sawcache_i    (sawcache_i ),
    .sawprot_i     (sawprot_i  ),
    .sawvalid_i    (sawvalid_i ),
    .sawready_o    (sawready_o ),   
    .swid_i        (swid_i     ),
    .swdata_i      (swdata_i   ),
    .swstrb_i      (swstrb_i   ),
    .swlast_i      (swlast_i   ),
    .swvalid_i     (swvalid_i  ),
    .swready_o     (swready_o  ),
    .sbid_o        (sbid_o     ),
    .sbresp_o      (sbresp_o   ),
    .sbvalid_o     (sbvalid_o  ),
    .sbready_i     (sbready_i  ),
    .sarid_i       (sarid_i    ),
    .saraddr_i     (saraddr_i  ),
    .sarlen_i      (sarlen_i   ),
    .sarsize_i     (sarsize_i  ),
    .sarburst_i    (sarburst_i ),
    .sarlock_i     (sarlock_i  ),
    .sarcache_i    (sarcache_i ),
    .sarprot_i     (sarprot_i  ),
    .sarvalid_i    (sarvalid_i ),
    .sarready_o    (sarready_o ),
    .srid_o        (srid_o     ),
    .srdata_o      (srdata_o   ),
    .srresp_o      (srresp_o   ),
    .srlast_o      (srlast_o   ),
    .srvalid_o     (srvalid_o  ),
    .srready_i     (srready_i  ),                 

    .interrupt(interrupt_0),
 
    .mtxclk(mtxclk_0),      .mtxen(mtxen_0),       .mtxd(mtxd_0),        .mtxerr(mtxerr_0),
    .mrxclk(mrxclk_0),      .mrxdv(mrxdv_0),       .mrxd(mrxd_0),        .mrxerr(mrxerr_0),
    .mcoll(mcoll_0),       .mcrs(mcrs_0),
    .mdc(mdc_0),         .md_i(md_i_0),        .md_o(md_o_0),        .md_oe(md_oe_0),

    .trdata(trdata_0),
    .twe(twe_0),
    .twaddr(twaddr_0),
    .traddr(traddr_0),
    .twdata(twdata_0),

    .rrdata(rrdata_0),
    .rwe(rwe_0),
    .rwaddr(rwaddr_0),
    .rraddr(rraddr_0),
    .rwdata(rwdata_0)
); 

wire [31:0] douta_nc;
dpram_512x32 dpram_512x32_tx(
  .clka     (hclk    ),
  .ena      (twe_0   ),
  .wea      (twe_0   ),
  .addra    (twaddr_0),
  .dina     (twdata_0),
  .clkb     (mtxclk_0),
  .addrb    (traddr_0),
  .doutb    (trdata_0)
);

wire [31:0] doutb_nc;
dpram_512x32 dpram_512x32_rx(
  .clka     (mrxclk_0),
  .ena      (rwe_0   ),
  .wea      (rwe_0   ),
  .addra    (rwaddr_0),
  .dina     (rwdata_0),
  .clkb     (hclk    ),
  .addrb    (rraddr_0),
  .doutb    (rrdata_0)
);

endmodule

