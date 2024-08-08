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

module axi2apb_bridge(
clk,
rst_n,
axi_s_awid,
axi_s_awaddr,
axi_s_awlen,
axi_s_awsize,
axi_s_awburst,
axi_s_awlock,
axi_s_awcache,
axi_s_awprot,
axi_s_awvalid,
axi_s_awready,
axi_s_wid,
axi_s_wdata,
axi_s_wstrb,
axi_s_wlast,
axi_s_wvalid,
axi_s_wready,
axi_s_bid,
axi_s_bresp,
axi_s_bvalid,
axi_s_bready,
axi_s_arid,
axi_s_araddr,
axi_s_arlen,
axi_s_arsize,
axi_s_arburst,
axi_s_arlock,
axi_s_arcache,
axi_s_arprot,
axi_s_arvalid,
axi_s_arready,
axi_s_rid,
axi_s_rdata,
axi_s_rresp,
axi_s_rlast,
axi_s_rvalid,
axi_s_rready,

apb_valid_cpu,
cpu_grant,
apb_word_trans,
apb_high_24b_rd,
apb_high_24b_wr,
apb_clk,
apb_reset_n,
reg_psel,
reg_enable,
reg_rw,
reg_addr,
reg_datai,
reg_ready_1,
reg_datao
);
parameter L_ADDR_APB = 20;

input                   clk;
input                   rst_n;

input  [`LID         -1 :0] axi_s_awid;
input  [`Lawaddr     -1 :0] axi_s_awaddr;
input  [`Lawlen      -1 :0] axi_s_awlen;
input  [`Lawsize     -1 :0] axi_s_awsize;
input  [`Lawburst    -1 :0] axi_s_awburst;
input  [`Lawlock     -1 :0] axi_s_awlock;
input  [`Lawcache    -1 :0] axi_s_awcache;
input  [`Lawprot     -1 :0] axi_s_awprot;
input                       axi_s_awvalid;
output                      axi_s_awready;
input  [`LID         -1 :0] axi_s_wid;
input  [`Lwdata      -1 :0] axi_s_wdata;
input  [`Lwstrb      -1 :0] axi_s_wstrb;
input                       axi_s_wlast;
input                       axi_s_wvalid;
output                      axi_s_wready;
output [`LID         -1 :0] axi_s_bid;
output [`Lbresp      -1 :0] axi_s_bresp;
output                      axi_s_bvalid;
input                       axi_s_bready;
input  [`LID         -1 :0] axi_s_arid;
input  [`Laraddr     -1 :0] axi_s_araddr;
input  [`Larlen      -1 :0] axi_s_arlen;
input  [`Larsize     -1 :0] axi_s_arsize;
input  [`Larburst    -1 :0] axi_s_arburst;
input  [`Larlock     -1 :0] axi_s_arlock;
input  [`Larcache    -1 :0] axi_s_arcache;
input  [`Larprot     -1 :0] axi_s_arprot;
input                       axi_s_arvalid;
output                      axi_s_arready;
output [`LID         -1 :0] axi_s_rid;
output [`Lrdata      -1 :0] axi_s_rdata;
output [`Lrresp      -1 :0] axi_s_rresp;
output                      axi_s_rlast;
output                      axi_s_rvalid;
input                       axi_s_rready;
input                   apb_word_trans;
input                   cpu_grant;
output                  apb_valid_cpu;
input  [23:0]           apb_high_24b_rd;
output [23:0]           apb_high_24b_wr;
output                  apb_clk;
output                  apb_reset_n;
output                  reg_psel;
output                  reg_enable;
output                  reg_rw;
output[L_ADDR_APB-1:0]  reg_addr;
output[7:0]           	reg_datai;
input [7:0]           	reg_datao;
input                   reg_ready_1;

wire    csr_rw_send_axi_rsp_done;
wire    reg_ready;

parameter CSR_RW_SM_IDLE         = 4'b0001,
          CSR_RW_SM_GET_AXI_ADDR = 4'b0010,
          CSR_RW_SM_SEND_AXI_RSP = 4'b1000;

reg reg_psel;
reg reg_enable;
reg axi_s_sel_rd;
reg axi_s_sel_wr;
reg[3:0] csr_rw_sm;
reg[3:0] csr_rw_sm_nxt;
reg[L_ADDR_APB-1:0] axi_s_req_addr;
reg[`LID-1:0] axi_s_w_id;
reg[`LID-1:0] axi_s_r_id;
reg[23:0]     apb_high_24b_wr;

assign	apb_clk     = clk;
assign	apb_reset_n = rst_n;
assign  reg_rw      = axi_s_sel_wr; 
assign  reg_addr    = axi_s_req_addr;  
assign  reg_ready   = reg_enable & reg_ready_1; 
assign  apb_valid_cpu = axi_s_sel_wr | axi_s_sel_rd | axi_s_awvalid | axi_s_arvalid;
reg axi_s_rlast;
reg axi_s_rvalid;
reg axi_s_wready;
reg axi_s_awready; 
reg axi_s_arready; 

reg [3:0]axi_s_rstrb;
reg [3:0]apb_s_wstrb;
reg [31:0]reg_datai_32;
reg [31:0]reg_datao_32;
reg [2:0] rd_count;
reg [2:0] apb_rd_size;
reg [2:0] apb_wr_size;
reg [7:0] reg_datai;
reg axi_s_bvalid;

always@(posedge clk) 
begin
    if(!rst_n)
    begin
        reg_datai_32    <= 32'h0;
        reg_datao_32    <= 32'h0;
        axi_s_req_addr  <= 20'h0;
        apb_s_wstrb     <= 4'b0;
        axi_s_rstrb     <= 4'b0;
        axi_s_wready    <= 1'b0;
        reg_enable      <= 1'b0;
        reg_psel        <= 1'b0;
        rd_count        <= 3'b0;
        apb_rd_size     <= 3'b0;
        apb_wr_size     <= 3'b0;
        axi_s_rlast     <= 1'b0;
        axi_s_rvalid    <= 1'b0;
        reg_datai       <= 8'b0; 
        axi_s_awready   <= 1'b0;
        axi_s_arready   <= 1'b0;
        axi_s_bvalid    <= 1'b0; 
        axi_s_sel_wr    <= 1'b0;
        axi_s_sel_rd    <= 1'b0;
        axi_s_w_id      <= 'h0;
        axi_s_r_id      <= 'h0; 
        apb_high_24b_wr <= 24'h0;
    end
    else begin
        if(axi_s_awvalid & ~axi_s_bvalid & ~axi_s_sel_rd & (csr_rw_sm == CSR_RW_SM_IDLE) &cpu_grant) begin
                axi_s_req_addr  <= axi_s_awaddr[L_ADDR_APB-1:0];
                axi_s_awready   <= 1'b1;
                axi_s_sel_wr    <= 1'b1;
                apb_wr_size     <= axi_s_awsize;
        end 
        else if(axi_s_sel_wr) begin
            axi_s_awready   <= 1'b0; 
            if(axi_s_wvalid && ~axi_s_wready) begin
          `ifdef AXI128
          axi_s_req_addr <= (axi_s_wstrb[15:0]==16'h0002)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h1):
                            (axi_s_wstrb[15:0]==16'h0004)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h2):
                            (axi_s_wstrb[15:0]==16'h0008)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h3):
                            (axi_s_wstrb[15:0]==16'h0010)&&(axi_s_req_addr[  2]==1'h0)? (axi_s_req_addr + 4'h4):
                            (axi_s_wstrb[15:0]==16'h0020)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h5):
                            (axi_s_wstrb[15:0]==16'h0040)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h6):
                            (axi_s_wstrb[15:0]==16'h0080)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h7):
                            (axi_s_wstrb[15:0]==16'h0100)&&(axi_s_req_addr[  3]==1'h0)? (axi_s_req_addr + 4'h8):
                            (axi_s_wstrb[15:0]==16'h0200)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h9):
                            (axi_s_wstrb[15:0]==16'h0400)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'ha):
                            (axi_s_wstrb[15:0]==16'h0800)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'hb):
                            (axi_s_wstrb[15:0]==16'h1000)&&(axi_s_req_addr[  2]==1'h0)? (axi_s_req_addr + 4'hc):
                            (axi_s_wstrb[15:0]==16'h2000)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'hd):
                            (axi_s_wstrb[15:0]==16'h4000)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'he):
                            (axi_s_wstrb[15:0]==16'h8000)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'hf):
                            (axi_s_wstrb[15:0]==16'h0006)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h1):
                            (axi_s_wstrb[15:0]==16'h000c)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h2):
                            (axi_s_wstrb[15:0]==16'h0018)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h3):
                            (axi_s_wstrb[15:0]==16'h0030)&&(axi_s_req_addr[  2]==1'h0)? (axi_s_req_addr + 4'h4):
                            (axi_s_wstrb[15:0]==16'h0060)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h5):
                            (axi_s_wstrb[15:0]==16'h00c0)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h6):
                            (axi_s_wstrb[15:0]==16'h0180)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h7):
                            (axi_s_wstrb[15:0]==16'h0300)&&(axi_s_req_addr[  3]==1'h0)? (axi_s_req_addr + 4'h8):
                            (axi_s_wstrb[15:0]==16'h0600)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h9):
                            (axi_s_wstrb[15:0]==16'h0c00)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'ha):
                            (axi_s_wstrb[15:0]==16'h1800)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'hb):
                            (axi_s_wstrb[15:0]==16'h3000)&&(axi_s_req_addr[  2]==1'h0)? (axi_s_req_addr + 4'hc):
                            (axi_s_wstrb[15:0]==16'h6000)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'hd):
                            (axi_s_wstrb[15:0]==16'hc000)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'he):
                            (axi_s_wstrb[15:0]==16'h001e)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h1):
                            (axi_s_wstrb[15:0]==16'h003c)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h2):
                            (axi_s_wstrb[15:0]==16'h0078)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h3):
                            (axi_s_wstrb[15:0]==16'h00f0)&&(axi_s_req_addr[  2]==1'h0)? (axi_s_req_addr + 4'h4):
                            (axi_s_wstrb[15:0]==16'h01e0)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h5):
                            (axi_s_wstrb[15:0]==16'h03c0)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h6):
                            (axi_s_wstrb[15:0]==16'h0780)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h7):
                            (axi_s_wstrb[15:0]==16'h0f00)&&(axi_s_req_addr[  3]==1'h0)? (axi_s_req_addr + 4'h8):
                            (axi_s_wstrb[15:0]==16'h1e00)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h9):
                            (axi_s_wstrb[15:0]==16'h3c00)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'ha):
                            (axi_s_wstrb[15:0]==16'h7800)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'hb):
                            (axi_s_wstrb[15:0]==16'hf000)&&(axi_s_req_addr[  2]==1'h0)? (axi_s_req_addr + 4'hc):
                            (axi_s_wstrb[15:0]==16'h01fe)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h1):
                            (axi_s_wstrb[15:0]==16'h03fc)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h2):
                            (axi_s_wstrb[15:0]==16'h07f8)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h3):
                            (axi_s_wstrb[15:0]==16'h0ff0)&&(axi_s_req_addr[  2]==1'h0)? (axi_s_req_addr + 4'h4):
                            (axi_s_wstrb[15:0]==16'h1fe0)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h5):
                            (axi_s_wstrb[15:0]==16'h3fc0)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h6):
                            (axi_s_wstrb[15:0]==16'h7f80)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 4'h7):
                            (axi_s_wstrb[15:0]==16'hff00)&&(axi_s_req_addr[  3]==1'h0)? (axi_s_req_addr + 4'h8): axi_s_req_addr ;
          `elsif AXI64
          axi_s_req_addr <= (axi_s_wstrb[7:0]==8'h02)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h1):
                            (axi_s_wstrb[7:0]==8'h04)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h2):
                            (axi_s_wstrb[7:0]==8'h08)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h3):
                            (axi_s_wstrb[7:0]==8'h10)&&(axi_s_req_addr[  2]==1'h0)? (axi_s_req_addr + 2'h4):
                            (axi_s_wstrb[7:0]==8'h20)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h5):
                            (axi_s_wstrb[7:0]==8'h40)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h6):
                            (axi_s_wstrb[7:0]==8'h80)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h7):
                            (axi_s_wstrb[7:0]==8'h06)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h1): 
                            (axi_s_wstrb[7:0]==8'h0c)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h2): 
                            (axi_s_wstrb[7:0]==8'h18)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h3):
                            (axi_s_wstrb[7:0]==8'h30)&&(axi_s_req_addr[  2]==1'h0)? (axi_s_req_addr + 2'h4):
                            (axi_s_wstrb[7:0]==8'h60)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h5):
                            (axi_s_wstrb[7:0]==8'hc0)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h6):
                            (axi_s_wstrb[7:0]==8'h1e)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h1):
                            (axi_s_wstrb[7:0]==8'h3c)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h2):
                            (axi_s_wstrb[7:0]==8'h78)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h3):
                            (axi_s_wstrb[7:0]==8'hf0)&&(axi_s_req_addr[  2]==1'h0)? (axi_s_req_addr + 2'h4): axi_s_req_addr ; 
          `else
          axi_s_req_addr <= (axi_s_wstrb[3:0]==4'h2)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h1):
                            (axi_s_wstrb[3:0]==4'h4)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h2):
                            (axi_s_wstrb[3:0]==4'h8)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h3): 
                            (axi_s_wstrb[3:0]==4'h6)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h1): 
                            (axi_s_wstrb[3:0]==4'hc)&&(axi_s_req_addr[1:0]==2'h0)? (axi_s_req_addr + 2'h2): axi_s_req_addr ; 
          `endif
                
                axi_s_wready    <= 1'b1;
                reg_psel        <= 1'b0;
                reg_enable      <= 1'b0;
                axi_s_w_id      <= axi_s_wid;
                `ifdef AXI128
                case({axi_s_req_addr[3:0]})
                  4'b0000: begin apb_s_wstrb <= axi_s_wstrb[ 3: 0];              reg_datai_32 <=axi_s_wdata[ 31:  0];                   end
                  4'b0001: begin apb_s_wstrb <= axi_s_wstrb[ 4: 1];              reg_datai_32 <=axi_s_wdata[ 39:  8];                   end 
                  4'b0010: begin apb_s_wstrb <= axi_s_wstrb[ 5: 2];              reg_datai_32 <=axi_s_wdata[ 47: 16];                   end 
                  4'b0011: begin apb_s_wstrb <= axi_s_wstrb[ 6: 3];              reg_datai_32 <=axi_s_wdata[ 55: 24];                   end
                  4'b0100: begin apb_s_wstrb <= axi_s_wstrb[ 7: 4];              reg_datai_32 <=axi_s_wdata[ 63: 32];                   end
                  4'b0101: begin apb_s_wstrb <= axi_s_wstrb[ 8: 5];              reg_datai_32 <=axi_s_wdata[ 71: 40];                   end
                  4'b0110: begin apb_s_wstrb <= axi_s_wstrb[ 9: 6];              reg_datai_32 <=axi_s_wdata[ 79: 48];                   end
                  4'b0111: begin apb_s_wstrb <= axi_s_wstrb[10: 7];              reg_datai_32 <=axi_s_wdata[ 87: 56];                   end
                  4'b1000: begin apb_s_wstrb <= axi_s_wstrb[11: 8];              reg_datai_32 <=axi_s_wdata[ 95: 64];                   end
                  4'b1001: begin apb_s_wstrb <= axi_s_wstrb[12: 9];              reg_datai_32 <=axi_s_wdata[103: 72];                   end
                  4'b1010: begin apb_s_wstrb <= axi_s_wstrb[13:10];              reg_datai_32 <=axi_s_wdata[111: 80];                   end
                  4'b1011: begin apb_s_wstrb <= axi_s_wstrb[14:11];              reg_datai_32 <=axi_s_wdata[119: 88];                   end
                  4'b1100: begin apb_s_wstrb <= axi_s_wstrb[15:12];              reg_datai_32 <=axi_s_wdata[127: 96];                   end
                  4'b1101: begin apb_s_wstrb <= {1'b0, axi_s_wstrb[15:13]};      reg_datai_32 <={ 8'b0, axi_s_wdata[127:104]};          end
                  4'b1110: begin apb_s_wstrb <= {2'b0, axi_s_wstrb[15:14]};      reg_datai_32 <={16'b0, axi_s_wdata[127:112]};          end
                  4'b1111: begin apb_s_wstrb <= {3'b0, axi_s_wstrb[   15]};      reg_datai_32 <={24'b0, axi_s_wdata[127:120]};          end
                  default:      begin apb_s_wstrb <= 4'b0;                     reg_datai_32 <=32'h0; end
                endcase
                `elsif AXI64
                case({axi_s_req_addr[2:0]})
                  3'b000: begin apb_s_wstrb <= axi_s_wstrb[3:0];               reg_datai_32 <=axi_s_wdata[31: 0];                   end
                  3'b001: begin apb_s_wstrb <= axi_s_wstrb[4:1];               reg_datai_32 <=axi_s_wdata[39: 8];                   end 
                  3'b010: begin apb_s_wstrb <= axi_s_wstrb[5:2];               reg_datai_32 <=axi_s_wdata[47:16];                   end 
                  3'b011: begin apb_s_wstrb <= axi_s_wstrb[6:3];               reg_datai_32 <=axi_s_wdata[55:24];                   end
                  3'b100: begin apb_s_wstrb <= axi_s_wstrb[7:4];               reg_datai_32 <=axi_s_wdata[63:32];                   end
                  3'b101: begin apb_s_wstrb <= {1'b0, axi_s_wstrb[7:5]};       reg_datai_32 <={8 'b0, axi_s_wdata[63:40]};          end
                  3'b110: begin apb_s_wstrb <= {2'b0, axi_s_wstrb[7:6]};       reg_datai_32 <={16'b0, axi_s_wdata[63:48]};          end
                  3'b111: begin apb_s_wstrb <= {3'b0, axi_s_wstrb[  7]};       reg_datai_32 <={24'b0, axi_s_wdata[63:56]};          end
                  default:      begin apb_s_wstrb <= 4'b0;                     reg_datai_32 <=32'h0; end
                endcase
                `else
                case({axi_s_req_addr[1:0]})
                  2'b00: begin apb_s_wstrb <= axi_s_wstrb[3:0];        reg_datai_32 <=axi_s_wdata[31:0];   end 
                  2'b01: begin apb_s_wstrb <= {1'b0,axi_s_wstrb[3:1]}; reg_datai_32 <={8'h0,axi_s_wdata[31:8]};   end
                  2'b10: begin apb_s_wstrb <= {2'b0,axi_s_wstrb[3:2]}; reg_datai_32 <={16'b0,axi_s_wdata[31:16]};  end
                  2'b11: begin apb_s_wstrb <= {3'b0,axi_s_wstrb[3]};   reg_datai_32 <={24'b0,axi_s_wdata[31:24]};  end
                  default:     begin apb_s_wstrb <= 4'b0;               reg_datai_32 <=32'h0;  end 
                endcase
                `endif
            end
            else if((~reg_psel) && (apb_s_wstrb!=4'h0) ) begin
                reg_psel        <= 1'b1;
                reg_enable      <= 1'b0;
                reg_datai       <= (apb_s_wstrb == 4'h1) ? reg_datai_32[7:0]:
                                   (apb_s_wstrb == 4'h2) ? reg_datai_32[15:8]:
                                   (apb_s_wstrb == 4'h6) ? reg_datai_32[15:8]:
                                   (apb_s_wstrb == 4'h4) ? reg_datai_32[23:16]:
                                   (apb_s_wstrb == 4'h8) ? reg_datai_32[31:24]: reg_datai_32[7:0];
                apb_high_24b_wr <= reg_datai_32[31:8];
                if(axi_s_bready) axi_s_bvalid    <= 1'b0;
            end
            else if(apb_word_trans & apb_s_wstrb==4'hf ) begin
                if(~reg_ready)begin
                    reg_psel    <= 1'b1;
                    reg_enable  <= 1'b1;
                end
                else begin
                    reg_psel        <= 1'b0;
                    reg_enable      <= 1'b0;
                    axi_s_sel_wr    <= 1'b0;
                    axi_s_bvalid    <= 1'b1;
                    apb_s_wstrb     <= 4'b0;
                end
                    reg_datai       <= reg_datai_32[7:0];
                    apb_high_24b_wr <= reg_datai_32[31:8];
                    axi_s_wready    <= 1'b0;
            end
            else if(apb_s_wstrb[0]) begin
                if(~reg_ready)begin
                    reg_psel    <= 1'b1;
                    reg_enable  <= 1'b1;
                    reg_datai   <= reg_datai_32[7:0];
                end
                else begin
                    if(apb_s_wstrb[3:1] ==3'b0)
                    begin
                        reg_psel    <= 1'b0;
                        axi_s_sel_wr<= 1'b0;
                        axi_s_bvalid    <= 1'b1;
                    end
                    else
                        reg_psel    <= 1'b1;
                    reg_enable      <= 1'b0;
                    apb_s_wstrb[0]  <= 1'b0;
                    axi_s_req_addr  <= axi_s_req_addr  +1'b1;
                    reg_datai       <= reg_datai_32[15:8];
                end
                    axi_s_wready    <= 1'b0;
            end
            else if (apb_s_wstrb[1]) begin
                if(~reg_ready)begin
                    reg_psel <= 1'b1;
                    reg_enable <= 1'b1;
                end
                else begin
                    if(apb_s_wstrb[3:2] ==2'b0)
                    begin
                        reg_psel <= 1'b0;
                        axi_s_sel_wr <= 1'b0;
                        axi_s_bvalid    <= 1'b1;
                    end
                    else
                        reg_psel <= 1'b1;
                    reg_enable <= 1'b0;
                    apb_s_wstrb[1]  <= 1'b0;
                    axi_s_req_addr  <= axi_s_req_addr  +1'b1;
                    reg_datai       <= reg_datai_32[23:16];
                end
                    axi_s_wready    <= 1'b0;
            end
            else if (apb_s_wstrb[2]) begin
                if(~reg_ready)begin
                    reg_psel <= 1'b1;
                    reg_enable <= 1'b1;
                end
                else begin
                    if(apb_s_wstrb[3] ==1'b0)
                    begin
                        reg_psel <= 1'b0;
                        axi_s_sel_wr <= 1'b0;
                        axi_s_bvalid    <= 1'b1;
                    end
                    else
                        reg_psel <= 1'b1;
                    reg_enable <= 1'b0;
                    apb_s_wstrb[2]  <= 1'b0;
                    axi_s_req_addr  <= axi_s_req_addr  +1'b1;
                    reg_datai       <= reg_datai_32[31:24];
                end
                    axi_s_wready    <= 1'b0;
            end
            else if (apb_s_wstrb[3]) begin
                if(~reg_ready)begin
                    reg_psel    <= 1'b1;
                    reg_enable  <= 1'b1;
                end
                else begin
                    reg_psel        <= 1'b0;
                    reg_enable      <= 1'b0;
                    axi_s_sel_wr    <= 1'b0;
                    axi_s_bvalid    <= 1'b1;
                    apb_s_wstrb[3]  <= 1'b0;
                end
                    axi_s_wready    <= 1'b0;
            end
            else begin
                reg_psel        <= 1'b0;
                reg_enable      <= 1'b0;
                reg_datai       <= 8'h0;
                apb_s_wstrb     <= 4'h0;
                axi_s_wready    <= 1'b0; 
                if(csr_rw_sm == CSR_RW_SM_IDLE) axi_s_sel_wr  <= 1'b0;
            end
        end
        else if(axi_s_arvalid & ~axi_s_arready & ~axi_s_bvalid  & (csr_rw_sm == CSR_RW_SM_IDLE)&cpu_grant) 
        begin
                reg_enable      <= 1'b0;
                reg_psel        <= 1'b1;
                axi_s_arready   <= 1'b1;
                axi_s_sel_rd    <= 1'b1;
                axi_s_r_id      <= axi_s_arid;
                apb_rd_size     <= axi_s_arsize;
                axi_s_req_addr  <= axi_s_araddr[L_ADDR_APB-1:0];
                axi_s_rstrb     <= axi_s_araddr[3:0];
                if(axi_s_arsize==3'b010)
                    rd_count<= 3'h4;
                else if(axi_s_arsize==3'b01)
                    rd_count<= 3'h2;
                else if(axi_s_arsize==3'b0)    
                    rd_count<= 3'h1;
        end
        else if(axi_s_sel_rd)
        begin
           axi_s_arready   <= 1'b0; 
           if(apb_word_trans)
           begin
                if(reg_ready)
                begin
                    reg_psel        <= rd_count==3'b10;
                    reg_enable      <= 1'b0;
                    rd_count        <= rd_count-3'b1;
                    axi_s_rlast     <= apb_rd_size==3'h2|rd_count==2'b1;
                    axi_s_rvalid    <= apb_rd_size==3'h2|rd_count==2'b1;
                    axi_s_sel_rd    <= rd_count==3'b10;
                    reg_datao_32    <= {apb_high_24b_rd,reg_datao};
                end
                else begin
                    reg_psel        <= 1'b1;
                    reg_enable      <= 1'b1;
                end
           end
           else if(rd_count==3'h4)
           begin
                if(reg_ready)
                begin
                    reg_psel            <= 1'b1;
                    reg_enable          <= 1'b0;
                    rd_count            <= rd_count-3'h1;
                    reg_datao_32[7:0]   <= reg_datao;
                    axi_s_req_addr      <= axi_s_req_addr  +1'b1;
                end
                else begin
                    reg_psel            <= 1'b1;
                    reg_enable          <= 1'b1;
                end
           end
           else if(rd_count==3'h3)
           begin
                if(reg_ready)
                begin
                    reg_psel            <= 1'b1;
                    reg_enable          <= 1'b0;
                    rd_count            <= rd_count-3'h1;
                    reg_datao_32[15:8]  <= reg_datao;
                    axi_s_req_addr      <= axi_s_req_addr  +1'b1;
                end
                else begin
                    reg_psel            <= 1'b1;
                    reg_enable          <= 1'b1;
                end
           end
           else if(rd_count==3'h2)
           begin
                if(reg_ready)
                begin
                    reg_psel        <= 1'b1;
                    reg_enable      <= 1'b0;
                    rd_count        <= rd_count-3'h1;
                    axi_s_req_addr  <= axi_s_req_addr  +1'b1;
                    if(apb_rd_size==3'h2 )
                        reg_datao_32[23:16]  <= reg_datao;
                    else if(apb_rd_size==3'h1)
                        reg_datao_32[7:0]   <= reg_datao;
                end
                else begin
                    reg_psel        <= 1'b1;
                    reg_enable      <= 1'b1;
                end
           end
           else if(rd_count==3'h1)
           begin
                if(reg_ready)
                begin
                    reg_psel        <= 1'b0;
                    reg_enable      <= 1'b0;
                    axi_s_rlast     <= 1'b1;
                    axi_s_rvalid    <= 1'b1;
                    axi_s_sel_rd    <= 1'b0;
                    if(apb_rd_size==3'h2 )
                        reg_datao_32[31:24]     <= reg_datao;
                    else if(apb_rd_size==3'h1)
                        reg_datao_32[15:8]     <= reg_datao;
                    else if(apb_rd_size==3'h0)
                        reg_datao_32[7:0]       <= reg_datao;
                end 
                else begin
                    reg_psel        <= 1'b1;
                    reg_enable      <= 1'b1;
                end
           end// end if(rd_count)
           else begin
                    axi_s_arready   <= 1'b0; 
                    axi_s_rlast     <= 1'b1;
                    axi_s_rvalid    <= 1'b1;
                    reg_psel        <= 1'b0;
                    reg_enable      <= 1'b0; 
                    if(axi_s_rvalid && axi_s_rready)
                    begin
                        reg_datao_32    <= 32'h0;
                        axi_s_rlast     <= 1'b0;
                        axi_s_rvalid    <= 1'b0;
                    end
                    if(csr_rw_sm == CSR_RW_SM_IDLE) axi_s_sel_rd    <= 1'b0;
                    if(axi_s_bready) axi_s_bvalid    <= 1'b0;
           end
        end//end if(axi_s_sel_rd)
        else begin
                    reg_psel        <= 1'b0;
                    reg_enable      <= 1'b0;
                    axi_s_sel_wr    <= 1'b0;
                    axi_s_sel_rd    <= 1'b0;
                    axi_s_wready    <= 1'b0;
                    axi_s_arready   <= 1'b0; 
                    axi_s_req_addr  <= 32'h0;
                    reg_datai_32    <= 32'h0;
                    if(axi_s_bready) axi_s_bvalid    <= 1'b0;
                    if(axi_s_rvalid && axi_s_rready)
                    begin
                        reg_datao_32    <= 32'h0;
                        axi_s_rlast     <= 1'b0;
                        axi_s_rvalid    <= 1'b0;
                    end
        end
    end//end if(rst_n) 
end//end always

assign csr_rw_send_axi_rsp_done = csr_rw_sm == CSR_RW_SM_SEND_AXI_RSP && axi_s_rlast && axi_s_rready || axi_s_bvalid && axi_s_bready;

assign axi_s_bid = axi_s_w_id; 
assign axi_s_rid = axi_s_r_id;
assign axi_s_bresp = 2'b00;
assign axi_s_rresp = 2'b00;
`ifdef AXI128
assign axi_s_rdata=  ( axi_s_rstrb      == 4'h0) ? {96'b0, reg_datao_32            } :
                     ( axi_s_rstrb      == 4'h1) ? {88'b0, reg_datao_32,  8'b0     } :
                     ( axi_s_rstrb      == 4'h2) ? {80'b0, reg_datao_32, 16'b0     } :
                     ( axi_s_rstrb      == 4'h3) ? {72'b0, reg_datao_32, 24'b0     } :
                     ( axi_s_rstrb      == 4'h4) ? {64'b0, reg_datao_32, 32'b0     } :
                     ( axi_s_rstrb      == 4'h5) ? {56'b0, reg_datao_32, 40'b0     } :
                     ( axi_s_rstrb      == 4'h6) ? {48'b0, reg_datao_32, 48'b0     } :
                     ( axi_s_rstrb      == 4'h7) ? {40'b0, reg_datao_32, 56'b0     } :
                     ( axi_s_rstrb      == 4'h8) ? {32'b0, reg_datao_32, 64'b0     } :
                     ( axi_s_rstrb      == 4'h9) ? {24'b0, reg_datao_32, 72'b0     } :
                     ( axi_s_rstrb      == 4'ha) ? {16'b0, reg_datao_32, 80'b0     } :
                     ( axi_s_rstrb      == 4'hb) ? { 8'b0, reg_datao_32, 88'b0     } :
                     ( axi_s_rstrb      == 4'hc) ? {reg_datao_32, 96'b0            } :
                     ( axi_s_rstrb      == 4'hd) ? {reg_datao_32[23:0], 104'b0     } :
                     ( axi_s_rstrb      == 4'he) ? {reg_datao_32[15:0], 112'b0     } :
                     ( axi_s_rstrb      == 4'hf) ? {reg_datao_32[ 7:0], 120'b0     } : 128'h0;

`elsif AXI64
assign axi_s_rdata=  ( axi_s_rstrb[2:0] == 3'h0) ? {32'b0, reg_datao_32            } :
                     ( axi_s_rstrb[2:0] == 3'h1) ? {24'b0, reg_datao_32,  8'b0     } :
                     ( axi_s_rstrb[2:0] == 3'h2) ? {16'b0, reg_datao_32, 16'b0     } :
                     ( axi_s_rstrb[2:0] == 3'h3) ? { 8'b0, reg_datao_32, 24'b0     } :
                     ( axi_s_rstrb[2:0] == 3'h4) ? {reg_datao_32, 32'b0            } :
                     ( axi_s_rstrb[2:0] == 3'h5) ? {reg_datao_32[23:0], 40'b0      } :
                     ( axi_s_rstrb[2:0] == 3'h6) ? {reg_datao_32[15:0], 48'b0      } :
                     ( axi_s_rstrb[2:0] == 3'h7) ? {reg_datao_32[ 7:0], 56'b0      } : 64'h0;
`else
assign axi_s_rdata=  ( axi_s_rstrb[1:0] == 2'h0) ? {      reg_datao_32      } :
                     ( axi_s_rstrb[1:0] == 2'h1) ? {reg_datao_32[23:0], 8'h0} :
                     ( axi_s_rstrb[1:0] == 2'h2) ? {reg_datao_32[15:0],16'h0} :
                     ( axi_s_rstrb[1:0] == 2'h3) ? {reg_datao_32[7:0], 24'h0} : 32'h0;
`endif
always@(csr_rw_sm or axi_s_awvalid or axi_s_arvalid or axi_s_sel_rd or axi_s_sel_wr or 
        axi_s_wready or csr_rw_send_axi_rsp_done or cpu_grant) begin
  case(csr_rw_sm) 
    CSR_RW_SM_IDLE:         
      if((axi_s_awvalid || axi_s_arvalid)&&~(axi_s_sel_wr||axi_s_sel_rd)&cpu_grant)
        csr_rw_sm_nxt = CSR_RW_SM_GET_AXI_ADDR;
      else
        csr_rw_sm_nxt = CSR_RW_SM_IDLE;
    CSR_RW_SM_GET_AXI_ADDR: 
      if(axi_s_sel_wr)
        csr_rw_sm_nxt = CSR_RW_SM_SEND_AXI_RSP; 
      else if(axi_s_sel_rd)
        csr_rw_sm_nxt = CSR_RW_SM_SEND_AXI_RSP;
      else
        csr_rw_sm_nxt = CSR_RW_SM_GET_AXI_ADDR;
    CSR_RW_SM_SEND_AXI_RSP:
      if(csr_rw_send_axi_rsp_done)
        csr_rw_sm_nxt = CSR_RW_SM_IDLE; 
      else
        csr_rw_sm_nxt = CSR_RW_SM_SEND_AXI_RSP; 
    default:
        csr_rw_sm_nxt = CSR_RW_SM_IDLE; 
  endcase
end

always@(posedge clk) begin
  if(!rst_n)
    csr_rw_sm <= CSR_RW_SM_IDLE;
  else
    csr_rw_sm <= csr_rw_sm_nxt;
end

endmodule

