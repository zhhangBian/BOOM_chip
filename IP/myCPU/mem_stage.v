`include "mycpu.h"
`include "csr.h"

module mem_stage(
    input                              clk           ,
    input                              reset         ,
    //allowin
    input                              ws_allowin    ,
    output                             ms_allowin    ,
    //from es
    input                              es_to_ms_valid,
    input  [`ES_TO_MS_BUS_WD -1:0]     es_to_ms_bus  ,
    //to ws
    output                             ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0]     ms_to_ws_bus  ,
    //to ds forward path 
    output [`MS_TO_DS_FORWARD_BUS-1:0] ms_to_ds_forward_bus,
    output                             ms_to_ds_valid,
    //div mul
    input  [31:0]     div_result    ,
    input  [31:0]     mod_result    ,
    input  [63:0]     mul_result    ,
    //exception
    input             excp_flush    ,
    input             ertn_flush    ,
    input             refetch_flush ,
    input             icacop_flush  ,
    //idle
    input             idle_flush    ,
    //tlb ins
    output            tlb_inst_stall,
    //to es 
    output            ms_wr_tlbehi  ,
    output            ms_flush      ,
    //from cache
    input             data_data_ok   ,
    input             dcache_miss    ,
    input  [31:0]     data_rdata     ,
    //to cache
    output            data_uncache_en,
    output            tlb_excp_cancel_req,
    //from csr 
    input             csr_pg         ,
    input             csr_da         ,
    input  [31:0]     csr_dmw0       ,
    input  [31:0]     csr_dmw1       ,
    input  [ 1:0]     csr_plv        ,
    input  [ 1:0]     csr_datm       ,
    input             disable_cache  ,
    // from addr trans for difftest
    input  [ 7:0]     data_index_diff   ,
    input  [19:0]     data_tag_diff     ,
    input  [ 3:0]     data_offset_diff  ,
    //to addr trans 
    output            data_addr_trans_en,   
    output            dmw0_en           ,
    output            dmw1_en           ,
    output            cacop_op_mode_di  ,   
    //tlb 
    input             data_tlb_found ,
    input  [ 4:0]     data_tlb_index ,
    input             data_tlb_v     ,
    input             data_tlb_d     ,
    input  [ 1:0]     data_tlb_mat   ,
    input  [ 1:0]     data_tlb_plv   
);

reg         ms_valid;
wire        ms_ready_go;

wire        dep_need_stall;
reg [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus_r;
wire [ 3:0] ms_mul_div_op;
wire [ 1:0] sram_addr_low2bit;
wire [ 1:0] ms_mem_size;
wire        ms_load_op;
wire        ms_gr_we;
wire [ 4:0] ms_dest;
wire [31:0] ms_exe_result;
wire [31:0] ms_pc;
wire        ms_excp;
wire [ 9:0] ms_excp_num;
wire        ms_ertn;
wire [31:0] ms_csr_result;
wire [13:0] ms_csr_idx;
wire        ms_csr_we;
wire        ms_ll_w;
wire        ms_sc_w;
wire        ms_store_op;
wire        ms_tlbsrch;
wire        ms_tlbfill;
wire        ms_tlbwr;
wire        ms_tlbrd;
wire        ms_refetch;
wire        ms_invtlb;
wire [ 9:0] ms_invtlb_asid;
wire [18:0] ms_invtlb_vpn;
wire        ms_mem_sign_exted;
wire        ms_icacop_op_en;
wire        ms_br_inst;
wire        ms_icache_miss;
wire        ms_br_pre;
wire        ms_br_pre_error;
wire        ms_preld_inst;
wire        ms_cacop;
wire        ms_idle;
wire [31:0] ms_error_va;

assign {ms_csr_data      ,  //424:393  for difftest
        ms_csr_rstat_en  ,  //392:392  for difftest
        ms_st_data       ,  //391:360  for difftest
        ms_inst_st_en    ,  //359:352  for difftest
        ms_ld_vaddr      ,  //351:320  for difftest
        ms_inst_ld_en    ,  //319:312  for difftest
        ms_cnt_inst      ,  //311:311  for difftest
        ms_timer_64      ,  //310:247  for difftest
        ms_inst          ,  //246:215  for difftest
        ms_error_va      ,  //214:183
        ms_idle          ,  //182:182
        ms_cacop         ,  //181:181
        ms_preld_inst    ,  //180:180
        ms_br_pre_error  ,  //179:179
        ms_br_pre        ,  //178:178
        ms_icache_miss   ,  //177:177
        ms_br_inst       ,  //176:176
        ms_icacop_op_en  ,  //175:175
        ms_mem_sign_exted,  //174:174
        ms_invtlb_vpn    ,  //173:155
        ms_invtlb_asid   ,  //154:145
        ms_invtlb        ,  //144:144
        ms_tlbrd         ,  //143:143
        ms_refetch       ,  //142:142
        ms_tlbfill       ,  //141:141
        ms_tlbwr         ,  //140:140
        ms_tlbsrch       ,  //139:139
        ms_store_op      ,  //138:138
        ms_sc_w          ,  //137:137
        ms_ll_w          ,  //136:136
        ms_excp_num      ,  //135:126
        ms_csr_we        ,  //125:125
        ms_csr_idx       ,  //124:111
        ms_csr_result    ,  //110:79
        ms_ertn          ,  //78:78
        ms_excp          ,  //77:77
        ms_mem_size      ,  //76:75
        ms_mul_div_op    ,  //74:71
        ms_load_op       ,  //70:70
        ms_gr_we         ,  //69:69
        ms_dest          ,  //68:64
        ms_exe_result    ,  //63:32
        ms_pc               //31:0
       } = es_to_ms_bus_r;

wire [31:0] mem_result;
wire [31:0] ms_final_result;
wire        flush_sign;

wire [31:0] ms_rdata;
reg  [31:0] data_rd_buff;
reg         data_buff_enable;

wire        access_mem;

wire [ 4:0] cacop_op;
wire [ 1:0] cacop_op_mode;

wire        forward_enable;
wire        dest_zero;

wire [15:0] excp_num;
wire        excp;

wire        excp_adem;
wire        excp_tlbr;
wire        excp_pil ;
wire        excp_pis ;
wire        excp_pme ;
wire        excp_ppi ; 

wire        da_mode  ;
wire        pg_mode  ;

assign ms_to_ws_bus = {ms_csr_data    ,  //459:428 for difftest
                       ms_csr_rstat_en,  //427:427 for difftest
                       ms_st_data     ,  //426:395 for difftest
                       ms_inst_st_en  ,  //394:387 for difftest
                       ms_ld_vaddr    ,  //386:355 for difftest
                       ms_ld_paddr    ,  //354:323 for difftest
                       ms_inst_ld_en  ,  //322:315 for difftest
                       ms_cnt_inst    ,  //314:314 for difftest
                       ms_timer_64    ,  //313:250 for difftest
                       ms_inst        ,  //249:218 for difftest
                       ms_idle        ,  //217:217
                       ms_br_pre_error,  //216:216
                       ms_br_pre      ,  //215:215
                       dcache_miss    ,  //214:214
                       access_mem     ,  //213:213
                       ms_icache_miss ,  //212:212
                       ms_br_inst     ,  //211:211
                       ms_icacop_op_en,  //210:210
                       ms_invtlb_vpn  ,  //209:191
                       ms_invtlb_asid ,  //190:181
                       ms_invtlb      ,  //180:180
                       ms_tlbrd       ,  //179:179
                       ms_refetch     ,  //178:178
                       ms_tlbfill     ,  //177:177
                       ms_tlbwr       ,  //176:176
                       data_tlb_index ,  //175:171
                       data_tlb_found ,  //170:170
                       ms_tlbsrch     ,  //169:169
                       ms_error_va    ,  //168:137
                       ms_sc_w        ,  //136:136
                       ms_ll_w        ,  //135:135
                       excp_num       ,  //134:119
                       ms_csr_we      ,  //118:118
                       ms_csr_idx     ,  //117:104
                       ms_csr_result  ,  //103:72
                       ms_ertn        ,  //71:71
                       excp           ,  //70:70
                       ms_gr_we       ,  //69:69
                       ms_dest        ,  //68:64
                       ms_final_result,  //63:32
                       ms_pc             //31:0
                      };

assign ms_to_ds_valid = ms_valid;

//cache inst need wait data_data_ok signal
assign ms_ready_go    = (data_data_ok || data_buff_enable) || !access_mem || excp;
assign ms_allowin     = !ms_valid || ms_ready_go && ws_allowin;
assign ms_to_ws_valid = ms_valid && ms_ready_go;
always @(posedge clk) begin
    if (reset || flush_sign) begin
        ms_valid <= 1'b0;
    end
    else if (ms_allowin) begin
        ms_valid <= es_to_ms_valid;
    end

    if (es_to_ms_valid && ms_allowin) begin
        es_to_ms_bus_r <= es_to_ms_bus;
    end
end                            

assign access_mem = ms_store_op || ms_load_op;

assign flush_sign = excp_flush || ertn_flush || refetch_flush || icacop_flush || idle_flush;

assign ms_rdata = data_buff_enable ? data_rd_buff : data_rdata;

assign sram_addr_low2bit = {ms_exe_result[1], ms_exe_result[0]};

wire [7:0] mem_byteLoaded = ({8{sram_addr_low2bit==2'b00}} & ms_rdata[ 7: 0]) |
                            ({8{sram_addr_low2bit==2'b01}} & ms_rdata[15: 8]) |
                            ({8{sram_addr_low2bit==2'b10}} & ms_rdata[23:16]) |
                            ({8{sram_addr_low2bit==2'b11}} & ms_rdata[31:24]) ; 
                                                            

wire [15:0] mem_halfLoaded = ({16{sram_addr_low2bit==2'b00}} & ms_rdata[15: 0]) |
                             ({16{sram_addr_low2bit==2'b10}} & ms_rdata[31:16]) ;

assign mem_result = ({32{ms_mem_size[0] &&  ms_mem_sign_exted}} & {{24{mem_byteLoaded[ 7]}}, mem_byteLoaded}) |
                    ({32{ms_mem_size[0] && ~ms_mem_sign_exted}} & { 24'b0                  , mem_byteLoaded}) |
                    ({32{ms_mem_size[1] &&  ms_mem_sign_exted}} & {{16{mem_halfLoaded[15]}}, mem_halfLoaded}) |
                    ({32{ms_mem_size[1] && ~ms_mem_sign_exted}} & { 16'b0                  , mem_halfLoaded}) |
                    ({32{!ms_mem_size}}                         &   ms_rdata                                  ) ;

assign ms_final_result = ({32{ms_load_op      }} & mem_result       )  |
                         ({32{ms_mul_div_op[0]}} & mul_result[31:0] )  |
                         ({32{ms_mul_div_op[1]}} & mul_result[63:32])  |
                         ({32{ms_mul_div_op[2]}} & div_result       )  |
                         ({32{ms_mul_div_op[3]}} & mod_result       )  |
                         ({32{!ms_mul_div_op && !ms_load_op}} & ms_exe_result);

assign dest_zero            = (ms_dest == 5'b0);
assign forward_enable       = ms_gr_we & ~dest_zero & ms_valid;
assign dep_need_stall       = ms_load_op && !ms_to_ws_valid;
assign ms_to_ds_forward_bus = {dep_need_stall,  //38:38
                               forward_enable,  //37:37
                               ms_dest       ,  //36:32
                               ms_final_result  //31:0
                              };

//addr trans
assign pg_mode = !csr_da && csr_pg;
//uncache judgement
assign da_mode =  csr_da && !csr_pg;

assign data_addr_trans_en = pg_mode && !dmw0_en && !dmw1_en && !cacop_op_mode_di;

//addr dmw trans
assign dmw0_en = ((csr_dmw0[`PLV0] && csr_plv == 2'd0) || (csr_dmw0[`PLV3] && csr_plv == 2'd3)) && (ms_error_va[31:29] == csr_dmw0[`VSEG]);
assign dmw1_en = ((csr_dmw1[`PLV0] && csr_plv == 2'd0) || (csr_dmw1[`PLV3] && csr_plv == 2'd3)) && (ms_error_va[31:29] == csr_dmw1[`VSEG]);

assign excp = excp_tlbr || excp_pil || excp_pis || excp_ppi || excp_pme || excp_adem || ms_excp;
assign excp_num = {excp_pil, excp_pis, excp_ppi, excp_pme, excp_tlbr, excp_adem, ms_excp_num};

//tlb exception //preld should not generate these excp
assign excp_tlbr = (access_mem || ms_cacop) && !data_tlb_found && data_addr_trans_en;
assign excp_pil  = (ms_load_op || ms_cacop) && !data_tlb_v && data_addr_trans_en;  //cache will generate pil exception??
assign excp_pis  = ms_store_op && !data_tlb_v && data_addr_trans_en;
assign excp_ppi  = access_mem && data_tlb_v && (csr_plv > data_tlb_plv) && data_addr_trans_en;
assign excp_pme  = ms_store_op && data_tlb_v && (csr_plv <= data_tlb_plv) && !data_tlb_d && data_addr_trans_en;

assign excp_adem = access_mem && ms_error_va[31] && (csr_plv == 2'd3) && data_addr_trans_en;

assign tlb_excp_cancel_req = excp_tlbr || excp_pil || excp_pis || excp_ppi || excp_pme || excp_adem;

assign data_uncache_en = (da_mode && (csr_datm == 2'b0))                 || 
                         (dmw0_en && (csr_dmw0[`DMW_MAT] == 2'b0))       ||
                         (dmw1_en && (csr_dmw1[`DMW_MAT] == 2'b0))       ||
                         (data_addr_trans_en && (data_tlb_mat == 2'b0))  ||
                         disable_cache;

assign ms_flush = (excp | ms_ertn | (ms_csr_we | (ms_ll_w | ms_sc_w) & !excp) | ms_refetch | ms_idle) & ms_valid;

assign tlb_inst_stall = (ms_tlbsrch || ms_tlbrd) && ms_valid;

always @(posedge clk) begin
   if (reset || (ms_ready_go && ws_allowin) || flush_sign) begin
       data_rd_buff <= 32'b0;
       data_buff_enable <= 1'b0;
   end
   else if (data_data_ok && !ws_allowin) begin
       data_rd_buff <= data_rdata;
       data_buff_enable <= 1'b1;
   end
end

assign ms_wr_tlbehi = ms_csr_we && (ms_csr_idx == 14'h11) && ms_valid; //stall es tlbsrch

assign cacop_op = ms_dest;
assign cacop_op_mode    = cacop_op[4:3];
assign cacop_op_mode_di = ms_cacop && ((cacop_op_mode == 2'b0) || (cacop_op_mode == 2'b1));

// difftest
wire        ms_cnt_inst     ;
wire [63:0] ms_timer_64     ;
wire [31:0] ms_inst         ;
wire [ 7:0] ms_inst_ld_en   ;
wire [31:0] ms_ld_paddr     ;
wire [31:0] ms_ld_vaddr     ;
wire [ 7:0] ms_inst_st_en   ;
wire [31:0] ms_st_data      ;
wire        ms_csr_rstat_en ;
wire [31:0] ms_csr_data     ;

reg  [ 7:0] tmp_data_index  ;
reg  [ 3:0] tmp_data_offset ;
always @(posedge clk) begin
    tmp_data_index  <= data_index_diff;
    tmp_data_offset <= data_offset_diff;
end

assign ms_ld_paddr = {data_tag_diff, tmp_data_index, tmp_data_offset};

endmodule
