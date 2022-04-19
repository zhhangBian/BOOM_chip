`include "mycpu.h"
`include "csr.h"

module csr(
    input                           clk          ,
    input                           reset        ,
    //from to ds 
    input  [13:0]                   rd_addr      ,
    output [31:0]                   rd_data      ,
    //timer 64
    output [63:0]                   timer_64_out ,
    output [31:0]                   tid_out      ,
    //from ws
    input                           csr_wr_en    ,
    input  [13:0]                   wr_addr      ,
    input  [31:0]                   wr_data      ,
    //interrupt
    input  [ 8:0]                   interrupt    ,
    output                          has_int      ,
    //from ws
    input                           excp_flush   ,
    input                           ertn_flush   ,
    input  [31:0]                   era_in       ,
    input  [ 8:0]                   esubcode_in  ,
    input  [ 5:0]                   ecode_in     ,
    input                           va_error_in  ,
    input  [31:0]                   bad_va_in    ,
    input                           tlbsrch_en    ,
    input                           tlbsrch_found ,
    input  [ 4:0]                   tlbsrch_index ,
    input                           excp_tlbrefill,
    input                           excp_tlb     ,
    input  [18:0]                   excp_tlb_vppn,
    //from ws llbit
    input                           llbit_in     ,
    input                           llbit_set_in ,
    //to es
    output                          llbit_out    ,
    output [18:0]                   vppn_out     ,
    //to fs
    output [31:0]                   eentry_out   ,
    output [31:0]                   era_out      ,
    output [31:0]                   tlbrentry_out,
    output                          disable_cache_out,
    //to addr trans
    output [ 9:0]                   asid_out     ,
    output [ 4:0]                   rand_index   ,
    output [31:0]                   tlbehi_out   ,
    output [31:0]                   tlbelo0_out  ,
    output [31:0]                   tlbelo1_out  ,
    output [31:0]                   tlbidx_out   ,
    output                          pg_out       ,
    output                          da_out       ,
    output [31:0]                   dmw0_out     ,
    output [31:0]                   dmw1_out     ,
    output [ 1:0]                   datf_out     ,
    output [ 1:0]                   datm_out     ,
    output [ 5:0]                   ecode_out    ,
    //from addr trans 
    input                           tlbrd_en     ,
    input  [31:0]                   tlbehi_in    ,
    input  [31:0]                   tlbelo0_in   ,
    input  [31:0]                   tlbelo1_in   ,
    input  [31:0]                   tlbidx_in    ,
    input  [ 9:0]                   asid_in      ,
    //general use
    output [ 1:0]                   plv_out      ,
    // csr regs for diff
    output [31:0]                   csr_crmd_diff,
    output [31:0]                   csr_prmd_diff,
    output [31:0]                   csr_ectl_diff,
    output [31:0]                   csr_estat_diff,
    output [31:0]                   csr_era_diff,
    output [31:0]                   csr_badv_diff,
    output [31:0]                   csr_eentry_diff,
    output [31:0]                   csr_tlbidx_diff,
    output [31:0]                   csr_tlbehi_diff,
    output [31:0]                   csr_tlbelo0_diff,
    output [31:0]                   csr_tlbelo1_diff,
    output [31:0]                   csr_asid_diff,
    output [31:0]                   csr_save0_diff,
    output [31:0]                   csr_save1_diff,
    output [31:0]                   csr_save2_diff,
    output [31:0]                   csr_save3_diff,
    output [31:0]                   csr_tid_diff,
    output [31:0]                   csr_tcfg_diff,
    output [31:0]                   csr_tval_diff,
    output [31:0]                   csr_ticlr_diff,
    output [31:0]                   csr_llbctl_diff,
    output [31:0]                   csr_tlbrentry_diff,
    output [31:0]                   csr_dmw0_diff,
    output [31:0]                   csr_dmw1_diff,
    output [31:0]                   csr_pgdl_diff,
    output [31:0]                   csr_pgdh_diff
);

localparam CRMD  = 14'h0;
localparam PRMD  = 14'h1;
localparam ECTL  = 14'h4;
localparam ESTAT = 14'h5;
localparam ERA   = 14'h6;
localparam BADV  = 14'h7;
localparam EENTRY = 14'hc;
localparam TLBIDX= 14'h10;
localparam TLBEHI= 14'h11;
localparam TLBELO0=14'h12;
localparam TLBELO1=14'h13;
localparam ASID  = 14'h18;
localparam PGDL  = 14'h19;
localparam PGDH  = 14'h1a;
localparam PGD   = 14'h1b;
localparam CPUID = 14'h20;
localparam SAVE0 = 14'h30;
localparam SAVE1 = 14'h31;
localparam SAVE2 = 14'h32;
localparam SAVE3 = 14'h33;
localparam TID   = 14'h40;
localparam TCFG  = 14'h41;
localparam TVAL  = 14'h42;
localparam CNTC  = 14'h43;
localparam TICLR = 14'h44;
localparam LLBCTL= 14'h60;
localparam TLBRENTRY = 14'h88;
localparam DMW0  = 14'h180;
localparam DMW1  = 14'h181;
localparam BRK = 14'h100;
localparam DISABLE_CACHE = 14'h101;

wire crmd_wen   = csr_wr_en & (wr_addr == CRMD);
wire prmd_wen   = csr_wr_en & (wr_addr == PRMD);
wire ectl_wen   = csr_wr_en & (wr_addr == ECTL);
wire estat_wen  = csr_wr_en & (wr_addr == ESTAT);
wire era_wen    = csr_wr_en & (wr_addr == ERA);
wire badv_wen   = csr_wr_en & (wr_addr == BADV);
wire eentry_wen = csr_wr_en & (wr_addr == EENTRY);
wire tlbidx_wen = csr_wr_en & (wr_addr == TLBIDX);
wire tlbehi_wen = csr_wr_en & (wr_addr == TLBEHI);
wire tlbelo0_wen= csr_wr_en & (wr_addr == TLBELO0);
wire tlbelo1_wen= csr_wr_en & (wr_addr == TLBELO1);
wire asid_wen   = csr_wr_en & (wr_addr == ASID);
wire pgdl_wen   = csr_wr_en & (wr_addr == PGDL);
wire pgdh_wen   = csr_wr_en & (wr_addr == PGDH);
wire pgd_wen    = csr_wr_en & (wr_addr == PGD);
wire cpuid_wen  = csr_wr_en & (wr_addr == CPUID);
wire save0_wen  = csr_wr_en & (wr_addr == SAVE0);
wire save1_wen  = csr_wr_en & (wr_addr == SAVE1);
wire save2_wen  = csr_wr_en & (wr_addr == SAVE2);
wire save3_wen  = csr_wr_en & (wr_addr == SAVE3);
wire tid_wen    = csr_wr_en & (wr_addr == TID);
wire tcfg_wen   = csr_wr_en & (wr_addr == TCFG);
wire tval_wen   = csr_wr_en & (wr_addr == TVAL);
wire cntc_wen   = csr_wr_en & (wr_addr == CNTC);
wire ticlr_wen  = csr_wr_en & (wr_addr == TICLR);
wire llbctl_wen = csr_wr_en & (wr_addr == LLBCTL);
wire tlbrentry_wen = csr_wr_en & (wr_addr == TLBRENTRY);
wire DMW0_wen   = csr_wr_en & (wr_addr == DMW0);
wire DMW1_wen   = csr_wr_en & (wr_addr == DMW1);
wire BRK_wen    = csr_wr_en & (wr_addr == BRK);
wire disable_cache_wen = csr_wr_en & (wr_addr == DISABLE_CACHE);

reg [31:0] csr_crmd;
reg [31:0] csr_prmd;
reg [31:0] csr_ectl;
reg [31:0] csr_estat;
reg [31:0] csr_era;
reg [31:0] csr_badv;
reg [31:0] csr_eentry;
reg [31:0] csr_tlbidx;
reg [31:0] csr_tlbehi;
reg [31:0] csr_tlbelo0;
reg [31:0] csr_tlbelo1;
reg [31:0] csr_asid;
reg [31:0] csr_cpuid;
reg [31:0] csr_save0;
reg [31:0] csr_save1;
reg [31:0] csr_save2;
reg [31:0] csr_save3;
reg [31:0] csr_tid;
reg [31:0] csr_tcfg;
reg [31:0] csr_tval;
reg [31:0] csr_cntc;
reg [31:0] csr_ticlr;
reg [31:0] csr_llbctl;
reg [31:0] csr_tlbrentry;
reg [31:0] csr_dmw0;
reg [31:0] csr_dmw1;
reg [31:0] csr_pgdl;
reg [31:0] csr_pgdh;
reg [31:0] csr_brk;
reg [31:0] csr_disable_cache;

wire [31:0] csr_pgd;

reg        timer_en;
reg [63:0] timer_64;

reg        llbit;

wire tlbrd_valid_wr_en;
wire tlbrd_invalid_wr_en;

wire eret_tlbrefill_excp;

wire no_forward;

assign csr_pgd = csr_badv[31] ? csr_pgdh : csr_pgdl;

assign eret_tlbrefill_excp = csr_estat[`ECODE] == 6'h3f;

assign tlbrd_valid_wr_en   = tlbrd_en && !tlbidx_in[`NE];
assign tlbrd_invalid_wr_en = tlbrd_en &&  tlbidx_in[`NE];

assign has_int = ((csr_ectl[`LIE] & csr_estat[`IS]) != 13'b0) & csr_crmd[`IE];

assign eentry_out   = csr_eentry;
assign era_out      = csr_era;
assign timer_64_out = timer_64 + {{32{csr_cntc[31]}}, csr_cntc};
assign tid_out      = csr_tid;
assign llbit_out    = llbit;
assign asid_out     = csr_asid[`TLB_ASID];
assign vppn_out     = (csr_wr_en && wr_addr == TLBEHI) ? wr_data[`VPPN] : csr_tlbehi[`VPPN];
assign tlbehi_out   = csr_tlbehi;
assign tlbelo0_out  = csr_tlbelo0;
assign tlbelo1_out  = csr_tlbelo1;
assign tlbidx_out   = csr_tlbidx;
assign rand_index   = timer_64[4:0];
assign disable_cache_out = csr_disable_cache[0];

//forward to if stage
assign no_forward   = !excp_tlbrefill && !(eret_tlbrefill_excp && ertn_flush) && !crmd_wen;

assign pg_out       = excp_tlbrefill & 1'b0                      |
                      (eret_tlbrefill_excp && ertn_flush) & 1'b1 |
                      crmd_wen       & wr_data[`PG]              |
                      no_forward     & csr_crmd[`PG];

assign da_out       = excp_tlbrefill & 1'b1                      |
                      (eret_tlbrefill_excp && ertn_flush) & 1'b0 |
                      crmd_wen       & wr_data[`DA]              |
                      no_forward     & csr_crmd[`DA];

assign dmw0_out     = DMW0_wen ? wr_data : csr_dmw0;
assign dmw1_out     = DMW1_wen ? wr_data : csr_dmw1;

assign plv_out      = {2{excp_flush}} & 2'b0            |
                      {2{ertn_flush}} & csr_prmd[`PPLV] |
                      {2{crmd_wen  }} & wr_data[`PLV]   |
                      {2{!excp_flush && !ertn_flush && !crmd_wen}} & csr_crmd[`PLV];

assign tlbrentry_out= csr_tlbrentry;
assign datf_out     = csr_crmd[`DATF];
assign datm_out     = csr_crmd[`DATM];

assign ecode_out    = csr_estat[`ECODE];

assign rd_data = {32{rd_addr == CRMD  }}  & csr_crmd    |
                 {32{rd_addr == PRMD  }}  & csr_prmd    |
                 {32{rd_addr == ECTL  }}  & csr_ectl    |
                 {32{rd_addr == ESTAT }}  & csr_estat   |
                 {32{rd_addr == ERA   }}  & csr_era	    |
                 {32{rd_addr == BADV  }}  & csr_badv    |
                 {32{rd_addr == EENTRY}}  & csr_eentry  |
                 {32{rd_addr == TLBIDX}}  & csr_tlbidx  |
                 {32{rd_addr == TLBEHI}}  & csr_tlbehi  |
                 {32{rd_addr == TLBELO0}} & csr_tlbelo0 |
                 {32{rd_addr == TLBELO1}} & csr_tlbelo1 |
                 {32{rd_addr == ASID  }}  & csr_asid    |
                 {32{rd_addr == PGDL  }}  & csr_pgdl    |
                 {32{rd_addr == PGDH  }}  & csr_pgdh    |
                 {32{rd_addr == PGD   }}  & csr_pgd     |
                 {32{rd_addr == CPUID }}  & csr_cpuid   |
                 {32{rd_addr == SAVE0 }}  & csr_save0   |
                 {32{rd_addr == SAVE1 }}  & csr_save1   |
                 {32{rd_addr == SAVE2 }}  & csr_save2   |
                 {32{rd_addr == SAVE3 }}  & csr_save3   |
                 {32{rd_addr == TID   }}  & csr_tid     |
                 {32{rd_addr == TCFG  }}  & csr_tcfg    |
                 {32{rd_addr == CNTC  }}  & csr_cntc    |
                 {32{rd_addr == TICLR }}  & csr_ticlr   |
                 {32{rd_addr == LLBCTL}}  & {csr_llbctl[31:1], llbit} |
                 {32{rd_addr == TVAL  }}  & csr_tval    |
                 {32{rd_addr == TLBRENTRY}} & csr_tlbrentry   |
                 {32{rd_addr == DMW0}}    & csr_dmw0    |
                 {32{rd_addr == DMW1}}    & csr_dmw1    ;

//crmd
always @(posedge clk) begin
    if (reset) begin
        csr_crmd[ `PLV] <=  2'b0;
        csr_crmd[  `IE] <=  1'b0;
        csr_crmd[  `DA] <=  1'b1;
        csr_crmd[  `PG] <=  1'b0;
        csr_crmd[`DATF] <=  2'b0;
        csr_crmd[`DATM] <=  2'b0;
        csr_crmd[31: 9] <= 23'b0;
    end
    else if (excp_flush) begin
        csr_crmd[ `PLV] <=  2'b0;
        csr_crmd[  `IE] <=  1'b0;
    if (excp_tlbrefill) begin
        csr_crmd [`DA] <= 1'b1;
        csr_crmd [`PG] <= 1'b0;
    end
    end
    else if (ertn_flush) begin
        csr_crmd[ `PLV] <= csr_prmd[`PPLV];
        csr_crmd[  `IE] <= csr_prmd[`PIE ];
        if (eret_tlbrefill_excp) begin
            csr_crmd[`DA] <= 1'b0;
            csr_crmd[`PG] <= 1'b1;
        end
    end 
    else if (crmd_wen) begin
        csr_crmd[ `PLV] <= wr_data[ `PLV];
        csr_crmd[  `IE] <= wr_data[	 `IE];
        csr_crmd[  `DA] <= wr_data[	 `DA];
        csr_crmd[  `PG] <= wr_data[  `PG];
        csr_crmd[`DATF] <= wr_data[`DATF];
        csr_crmd[`DATM] <= wr_data[`DATM];
    end
end

//prmd
always @(posedge clk) begin
    if (reset) begin
        csr_prmd[31:3] <= 29'b0;
    end
    else if (excp_flush) begin
        csr_prmd[`PPLV] <= csr_crmd[`PLV];
        csr_prmd[ `PIE] <= csr_crmd[`IE ];
    end
    else if (prmd_wen) begin
        csr_prmd[`PPLV] <= wr_data[`PPLV];
        csr_prmd[ `PIE] <= wr_data[ `PIE];
    end
end

//ectl
always @(posedge clk) begin
    if (reset) begin
        csr_ectl <= 32'b0;
    end
    else if (ectl_wen) begin
        csr_ectl[ `LIE] <= wr_data[ `LIE];
    end
end

//estat
always @(posedge clk) begin
    if (reset) begin
        csr_estat[ 1: 0] <= 2'b0; 
        csr_estat[15:13] <= 3'b0;
        csr_estat[31]    <= 1'b0;
        
        timer_en <= 1'b0;
    end
    else begin
        if (ticlr_wen && wr_data[`CLR]) begin
            csr_estat[11] <= 1'b0;
        end
        else if (tcfg_wen) begin
            timer_en <= wr_data[`EN];
        end
        else if (timer_en && (csr_tval == 32'b0)) begin
            csr_estat[11] <= 1'b1;
            timer_en      <= csr_tcfg[`PERIODIC];
        end
        csr_estat[10:2] <= interrupt;
        if (excp_flush) begin
            csr_estat[   `ECODE] <= ecode_in;
            csr_estat[`ESUBCODE] <= esubcode_in;
        end
        else if (estat_wen) begin
            csr_estat[      1:0] <= wr_data[      1:0];
        end
    end
end

//era
always @(posedge clk) begin
    if (excp_flush) begin
        csr_era <= era_in;
    end
    else if (era_wen) begin
        csr_era <= wr_data;
    end
end

//badv
always @(posedge clk) begin
    if (badv_wen) begin
        csr_badv <= wr_data;
    end
    else if (va_error_in) begin
        csr_badv <= bad_va_in;
    end
end

//eentry
always @(posedge clk) begin
    if (reset) begin
        csr_eentry[5:0] <= 6'b0;
    end
    else if (eentry_wen) begin
        csr_eentry[31:6] <= wr_data[31:6];
    end
end

//tlbidx
always @(posedge clk) begin
    if (reset) begin
        csr_tlbidx[23: 5] <= 19'b0;
        csr_tlbidx[30]    <= 1'b0;
    end
    else if (tlbidx_wen) begin
        csr_tlbidx[`INDEX] <= wr_data[`INDEX];
        csr_tlbidx[`PS]    <= wr_data[`PS];
        csr_tlbidx[`NE]    <= wr_data[`NE];
    end
    else if (tlbsrch_en) begin
        if (tlbsrch_found) begin
            csr_tlbidx[`INDEX] <= tlbsrch_index;
            csr_tlbidx[`NE]    <= 1'b0;
        end
        else begin
            csr_tlbidx[`NE] <= 1'b1;
        end
    end
    else if (tlbrd_valid_wr_en) begin
        csr_tlbidx[`PS] <= tlbidx_in[`PS];
        csr_tlbidx[`NE] <= tlbidx_in[`NE];
    end
    else if (tlbrd_invalid_wr_en) begin
        csr_tlbidx[`PS] <= 6'b0;
        csr_tlbidx[`NE] <= tlbidx_in[`NE];
    end
end

//tlbehi
always @(posedge clk) begin
    if (reset) begin
        csr_tlbehi[12:0] <= 13'b0;
    end
    else if (tlbehi_wen) begin
        csr_tlbehi[`VPPN] <= wr_data[`VPPN];
    end
    else if (tlbrd_valid_wr_en) begin
        csr_tlbehi[`VPPN] <= tlbehi_in[`VPPN];
    end
    else if (tlbrd_invalid_wr_en) begin
        csr_tlbehi[`VPPN] <= 19'b0;
    end
    else if (excp_tlb) begin
        csr_tlbehi[`VPPN] <= excp_tlb_vppn;
    end
end

//tlbelo0
always @(posedge clk) begin
    if (reset) begin
        csr_tlbelo0[7] <= 1'b0;
    end
    else if (tlbelo0_wen) begin
        csr_tlbelo0[`TLB_V]   <= wr_data[`TLB_V];
        csr_tlbelo0[`TLB_D]   <= wr_data[`TLB_D];
        csr_tlbelo0[`TLB_PLV] <= wr_data[`TLB_PLV];
        csr_tlbelo0[`TLB_MAT] <= wr_data[`TLB_MAT];
        csr_tlbelo0[`TLB_G]   <= wr_data[`TLB_G];
        csr_tlbelo0[`TLB_PPN] <= wr_data[`TLB_PPN];
    end
    else if (tlbrd_valid_wr_en) begin
        csr_tlbelo0[`TLB_V]   <= tlbelo0_in[`TLB_V];
        csr_tlbelo0[`TLB_D]   <= tlbelo0_in[`TLB_D];
        csr_tlbelo0[`TLB_PLV] <= tlbelo0_in[`TLB_PLV];
        csr_tlbelo0[`TLB_MAT] <= tlbelo0_in[`TLB_MAT];
        csr_tlbelo0[`TLB_G]   <= tlbelo0_in[`TLB_G];
        csr_tlbelo0[`TLB_PPN] <= tlbelo0_in[`TLB_PPN];
    end
    else if (tlbrd_invalid_wr_en) begin
        csr_tlbelo0[`TLB_V]   <= 1'b0;
        csr_tlbelo0[`TLB_D]   <= 1'b0;
        csr_tlbelo0[`TLB_PLV] <= 2'b0;
        csr_tlbelo0[`TLB_MAT] <= 2'b0;
        csr_tlbelo0[`TLB_G]   <= 1'b0;
        csr_tlbelo0[`TLB_PPN] <= 24'b0;
    end
end

//tlbelo1
always @(posedge clk) begin
    if (reset) begin
        csr_tlbelo1[7] <= 1'b0;
    end
    else if (tlbelo1_wen) begin
        csr_tlbelo1[`TLB_V]   <= wr_data[`TLB_V];
        csr_tlbelo1[`TLB_D]   <= wr_data[`TLB_D];
        csr_tlbelo1[`TLB_PLV] <= wr_data[`TLB_PLV];
        csr_tlbelo1[`TLB_MAT] <= wr_data[`TLB_MAT];
        csr_tlbelo1[`TLB_G]   <= wr_data[`TLB_G];
        csr_tlbelo1[`TLB_PPN] <= wr_data[`TLB_PPN];
    end
    else if (tlbrd_valid_wr_en) begin
        csr_tlbelo1[`TLB_V]   <= tlbelo1_in[`TLB_V];
        csr_tlbelo1[`TLB_D]   <= tlbelo1_in[`TLB_D];
        csr_tlbelo1[`TLB_PLV] <= tlbelo1_in[`TLB_PLV];
        csr_tlbelo1[`TLB_MAT] <= tlbelo1_in[`TLB_MAT];
        csr_tlbelo1[`TLB_G]   <= tlbelo1_in[`TLB_G];
        csr_tlbelo1[`TLB_PPN] <= tlbelo1_in[`TLB_PPN];
    end
    else if (tlbrd_invalid_wr_en) begin
        csr_tlbelo1[`TLB_V]   <= 1'b0;
        csr_tlbelo1[`TLB_D]   <= 1'b0;
        csr_tlbelo1[`TLB_PLV] <= 2'b0;
        csr_tlbelo1[`TLB_MAT] <= 2'b0;
        csr_tlbelo1[`TLB_G]   <= 1'b0;
        csr_tlbelo1[`TLB_PPN] <= 24'b0;
    end
end

//asid
always @(posedge clk) begin
    if (reset) begin
        csr_asid[31:10] <= 22'h280; //ASIDBITS = 10
    end
    else if (asid_wen) begin
        csr_asid[`TLB_ASID] <= wr_data[`TLB_ASID];
    end
    else if (tlbrd_valid_wr_en) begin
        csr_asid[`TLB_ASID] <= asid_in;
    end
    else if (tlbrd_invalid_wr_en) begin
        csr_asid[`TLB_ASID] <= 10'b0;
    end
end

//TLBRENTRY
always @(posedge clk) begin
    if (reset) begin
        csr_tlbrentry[5:0] <= 6'b0;
    end
    else if (tlbrentry_wen) begin
        csr_tlbrentry[`TLBRENTRY_PA] <= wr_data[`TLBRENTRY_PA];
    end
end

//dmw0
always @(posedge clk) begin
    if (reset) begin
        csr_dmw0[ 2:1] <= 2'b0;
        csr_dmw0[24:6] <= 19'b0;
        csr_dmw0[28]   <= 1'b0;
    end
    else if (DMW0_wen) begin
        csr_dmw0[`PLV0]    <= wr_data[`PLV0];
        csr_dmw0[`PLV3]    <= wr_data[`PLV3];
        csr_dmw0[`DMW_MAT] <= wr_data[`DMW_MAT];
        csr_dmw0[`PSEG]    <= wr_data[`PSEG];
        csr_dmw0[`VSEG]    <= wr_data[`VSEG];
    end
end

//dmw1
always @(posedge clk) begin
    if (reset) begin
        csr_dmw1[ 2:1] <= 2'b0;
        csr_dmw1[24:6] <= 19'b0;
        csr_dmw1[28]   <= 1'b0;
    end
    else if (DMW1_wen) begin
        csr_dmw1[`PLV0]    <= wr_data[`PLV0];
        csr_dmw1[`PLV3]    <= wr_data[`PLV3];
        csr_dmw1[`DMW_MAT] <= wr_data[`DMW_MAT];
        csr_dmw1[`PSEG]    <= wr_data[`PSEG];
        csr_dmw1[`VSEG]    <= wr_data[`VSEG];
    end
end

//cpuid
always @(posedge clk) begin
    if (reset) begin
        csr_cpuid <= 32'b0;
    end 
end

//save0
always @(posedge clk) begin
    if (save0_wen) begin
        csr_save0 <= wr_data;
    end 
end

//save1
always @(posedge clk) begin
    if (save1_wen) begin
        csr_save1 <= wr_data;
    end 
end

//save2
always @(posedge clk) begin
    if (save2_wen) begin
        csr_save2 <= wr_data;
    end 
end

//save3
always @(posedge clk) begin
    if (save3_wen) begin
        csr_save3 <= wr_data;
    end 
end

//tid
always @(posedge clk) begin
    if (reset) begin
        csr_tid <= 32'b0;
    end
    else if (tid_wen) begin
        csr_tid <= wr_data;
    end
end

//tcfg
always @(posedge clk) begin
    if (reset) begin
        csr_tcfg[`EN] <= 1'b0;
    end
    else if (tcfg_wen) begin
        csr_tcfg[      `EN] <= wr_data[      `EN];
        csr_tcfg[`PERIODIC] <= wr_data[`PERIODIC];
        csr_tcfg[ `INITVAL] <= wr_data[ `INITVAL];
    end
end

//cntc
always @(posedge clk) begin
    if (reset) begin
        csr_cntc <= 32'b0;
    end
    else if (cntc_wen) begin
        csr_cntc <= wr_data;
    end
end

//tval
always @(posedge clk) begin
    if (tcfg_wen) begin
        csr_tval <= {wr_data[ `INITVAL], 2'b0};
    end
    else if (timer_en) begin
        if (csr_tval != 32'b0) begin
            csr_tval <= csr_tval - 32'b1;
        end
        else if (csr_tval == 32'b0) begin
            csr_tval <= csr_tcfg[`PERIODIC] ? {csr_tcfg[`INITVAL], 2'b0} : 32'hffffffff;
        end
    end
end

//ticlr
always @(posedge clk) begin
    if (reset) begin
        csr_ticlr <= 32'b0;
    end
end

//llbctl
always @(posedge clk) begin
    if (reset) begin
        csr_llbctl[`KLO] <= 1'b0;
        csr_llbctl[31:3] <= 29'b0;
        llbit <= 1'b0;
    end 
    else if (ertn_flush) begin
        if (csr_llbctl[`KLO]) begin
            csr_llbctl[`KLO] <= 1'b0;
        end
        else begin
            llbit <= 1'b0;
        end
    end
    else if (llbctl_wen) begin 
        csr_llbctl[  `KLO] <= wr_data[  `KLO];
        if (wr_data[`WCLLB] == 1'b1) begin
            llbit <= 1'b0;
        end
    end
    else if (llbit_set_in) begin
        llbit <= llbit_in;
    end
end

//timer_64
always @(posedge clk) begin
    if (reset) begin
        timer_64 <= 64'b0;
    end
    else begin
        timer_64 <= timer_64 + 1'b1;
    end
end

//pgdl
always @(posedge clk) begin
    if (pgdl_wen) begin
        csr_pgdl[`BASE] <= wr_data[`BASE];
    end
end

//pgdh
always @(posedge clk) begin
    if (pgdh_wen) begin
        csr_pgdh[`BASE] <= wr_data[`BASE];
    end
end

//use for break in chipscope in software
always @(posedge clk) begin
    if (reset) begin
        csr_brk <= 32'b0;
    end
    if (BRK_wen) begin
        csr_brk <= wr_data;
    end
end

//use for disable cache or enable cache
always @(posedge clk) begin
    if (reset) begin
        csr_disable_cache <= 32'b0;
    end
    if (disable_cache_wen) begin
        csr_disable_cache <= wr_data;
    end
end

// difftest
assign csr_crmd_diff        = csr_crmd;
assign csr_prmd_diff        = csr_prmd;
assign csr_ectl_diff        = csr_ectl;
assign csr_estat_diff       = csr_estat;
assign csr_era_diff         = csr_era;
assign csr_badv_diff        = csr_badv;
assign csr_eentry_diff      = csr_eentry;
assign csr_tlbidx_diff      = csr_tlbidx;
assign csr_tlbehi_diff      = csr_tlbehi;
assign csr_tlbelo0_diff     = csr_tlbelo0;
assign csr_tlbelo1_diff     = csr_tlbelo1;
assign csr_asid_diff        = csr_asid;
assign csr_save0_diff       = csr_save0;
assign csr_save1_diff       = csr_save1;
assign csr_save2_diff       = csr_save2;
assign csr_save3_diff       = csr_save3;
assign csr_tid_diff         = csr_tid;
assign csr_tcfg_diff        = csr_tcfg;
assign csr_tval_diff        = csr_tval;
assign csr_ticlr_diff       = csr_ticlr;
assign csr_llbctl_diff      = {csr_llbctl[31:1], llbit};
assign csr_tlbrentry_diff   = csr_tlbrentry;
assign csr_dmw0_diff        = csr_dmw0;
assign csr_dmw1_diff        = csr_dmw1;
assign csr_pgdl_diff        = csr_pgdl;
assign csr_pgdh_diff        = csr_pgdh;

endmodule
