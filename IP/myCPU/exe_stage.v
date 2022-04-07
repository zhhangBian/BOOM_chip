`include "mycpu.h" 
`include "csr.h"

module exe_stage(
    input                               clk                 ,
    input                               reset               ,
    //allowin
    input                               ms_allowin          ,
    output                              es_allowin          ,
    //from ds
    input                               ds_to_es_valid      ,
    input  [`DS_TO_ES_BUS_WD -1:0]      ds_to_es_bus        ,
    //to ms
    output                              es_to_ms_valid      ,
    output [`ES_TO_MS_BUS_WD -1:0]      es_to_ms_bus        ,
    //to ds forward path
    output [`ES_TO_DS_FORWARD_BUS -1:0] es_to_ds_forward_bus,
    output                              es_to_ds_valid      ,
    //div_mul
    output        es_div_enable   ,
    output        es_mul_div_sign ,
    output [31:0] es_rj_value     ,
    output [31:0] es_rkd_value    ,
    input         div_complete    ,
    //exception
    input         excp_flush      ,
    input         ertn_flush      ,
    input         refetch_flush   ,
    input         icacop_flush    ,
    //idle
    input         idle_flush      ,
    //tlb/cache ins 
    output        tlb_inst_stall  ,
    //cache ins
    output        icacop_op_en    ,
    output        dcacop_op_en    ,
    output [ 1:0] cacop_op_mode   ,
    //from icache
    input         icache_unbusy   ,
    //preld ins
    output [ 4:0] preld_hint      ,
    output        preld_en        ,
    // data cache interface
    output        data_valid      ,
    output        data_op         ,
    output [ 2:0] data_size       ,
    output [ 3:0] data_wstrb      ,
    output [31:0] data_wdata      ,
    input         data_addr_ok    ,
    //from csr 
    input  [18:0] csr_vppn          ,
    //to addr trans
    output [31:0] data_addr         ,
    output        data_fetch        ,
    //from ms
    input         ms_wr_tlbehi      ,
    input         ms_flush          
);

reg         es_valid      ;
wire        es_ready_go   ;

wire [31:0] error_va      ;

reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;
wire [13:0] es_alu_op      ;
wire        es_src1_is_pc  ;
wire        es_src2_is_imm ; 
wire        es_src2_is_4   ;
wire        es_gr_we       ;
wire        es_store_op    ;
wire [ 4:0] es_dest        ;
wire [31:0] es_imm         ;
wire [31:0] es_pc          ;
wire [ 3:0] es_mul_div_op  ;
wire [ 1:0] es_mem_size    ;
wire [31:0] es_csr_data    ;
wire [13:0] es_csr_idx     ;
wire [31:0] es_csr_result  ;
wire [31:0] csr_mask_result;
wire        es_res_from_csr;
wire        es_csr_we      ;
wire        es_csr_mask    ;
wire        es_excp        ;
wire        excp           ;
wire [ 8:0] es_excp_num    ;
wire [ 9:0] excp_num       ;
wire        es_ertn        ;
wire        es_mul_enable  ;
wire        div_stall      ;
wire        es_ll_w        ;
wire        es_sc_w        ;
wire        es_tlbsrch     ;
wire        es_tlbwr       ;
wire        es_tlbfill     ;
wire        es_tlbrd       ;
wire        es_refetch     ;
wire        es_invtlb      ;
wire [ 9:0] es_invtlb_asid ;
wire [18:0] es_invtlb_vpn  ;
wire        es_cacop       ;
wire        es_preld       ;
wire        es_br_inst     ;
wire        es_icache_miss ;
wire        es_idle        ;

wire        es_load_op     ;

wire        dep_need_stall ;
wire        forward_enable ;
wire        dest_zero      ;

wire        excp_ale       ;

wire        es_flush_sign  ;
wire [ 3:0] wr_byte_en     ;

wire        access_mem      ;
wire        es_mem_sign_exted;
wire [ 1:0] sram_addr_low2bit;

wire        tlbsrch_stall  ;

wire [31:0] pv_addr        ;

wire [ 4:0] cacop_op        ;

wire        dcache_req_or_inst_en;

wire        icacop_inst      ;
wire        icacop_inst_stall;
wire        dcacop_inst      ;
wire        preld_inst       ;

wire        es_br_pre_error  ;
wire        es_br_pre        ;

assign {es_csr_rstat_en  ,  //349:349  for difftest
        es_inst_st_en    ,  //348:341  for difftest
        es_inst_ld_en    ,  //340:333  for difftst
        es_cnt_inst      ,  //332:332  for difftest
        es_timer_64      ,  //331:268  for difftest
        es_inst          ,  //236:267  for difftest
        es_idle          ,  //235:235
        es_br_pre_error  ,  //234:234
        es_br_pre        ,  //233:233
        es_icache_miss   ,  //232:232
        es_br_inst       ,  //231:231
        es_preld         ,  //230:230
        es_cacop         ,  //229:229
        es_mem_sign_exted,  //228:228
        es_invtlb        ,  //227:227
        es_tlbrd         ,  //226:226
        es_refetch       ,  //225:225
        es_tlbfill       ,  //224:224
        es_tlbwr         ,  //223:223
        es_tlbsrch       ,  //222:222
        es_sc_w          ,  //221:221
        es_ll_w          ,  //220:220
        es_excp_num      ,  //219:211
        es_csr_mask      ,  //210:210
        es_csr_we        ,  //209:209
        es_csr_idx       ,  //208:195
        es_res_from_csr  ,  //194:194
        es_csr_data      ,  //193:162
        es_ertn          ,  //161:161
        es_excp          ,  //160:160
        es_mem_size      ,  //159:158
        es_mul_div_op    ,  //157:154
        es_mul_div_sign  ,  //153:153
        es_alu_op        ,  //152:139
        es_load_op       ,  //138:138
        es_src1_is_pc    ,  //137:137
        es_src2_is_imm   ,  //136:136
        es_src2_is_4     ,  //135:135
        es_gr_we         ,  //134:134
        es_store_op      ,  //133:133
        es_dest          ,  //132:128
        es_imm           ,  //127:96
        es_rj_value      ,  //95 :64
        es_rkd_value     ,  //63 :32
        es_pc               //31 :0
       } = ds_to_es_bus_r;

wire [31:0] es_alu_src1   ;
wire [31:0] es_alu_src2   ;
wire [31:0] es_alu_result ;
wire [31:0] exe_result    ;

assign es_to_ms_bus = {es_csr_data      ,  //424:393  for difftest
                       es_csr_rstat_en  ,  //392:392  for difftest
                       data_wdata       ,  //391:360  for difftest
                       es_inst_st_en    ,  //359:352  for difftest
                       data_addr        ,  //351:320  for difftest
                       es_inst_ld_en    ,  //319:312  for difftest
                       es_cnt_inst      ,  //311:311  for difftest
                       es_timer_64      ,  //310:247  for difftest
                       es_inst          ,  //246:215  for difftest
                       error_va         ,  //214:183
                       es_idle          ,  //182:182
                       es_cacop         ,  //181:181
                       preld_inst       ,  //180:180
                       es_br_pre_error  ,  //179:179
                       es_br_pre        ,  //178:178
                       es_icache_miss   ,  //177:177
                       es_br_inst       ,  //176:176
                       icacop_op_en     ,  //175:175
                       es_mem_sign_exted,  //174:174  //only add this, not used. 
                       es_invtlb_vpn    ,  //173:155
                       es_invtlb_asid   ,  //154:145
                       es_invtlb        ,  //144:144
                       es_tlbrd         ,  //143:143
                       es_refetch       ,  //142:142
                       es_tlbfill       ,  //141:141
                       es_tlbwr         ,  //140:140
                       es_tlbsrch       ,  //139:139
                       es_store_op      ,  //138:138
                       es_sc_w          ,  //137:137
                       es_ll_w          ,  //136:136
                       excp_num         ,  //135:126
                       es_csr_we        ,  //125:125
                       es_csr_idx       ,  //124:111
                       es_csr_result    ,  //110:79
                       es_ertn          ,  //78:78
                       excp             ,  //77:77
                       es_mem_size      ,  //76:75
                       es_mul_div_op    ,  //74:71
                       es_load_op       ,  //70:70
                       es_gr_we         ,  //69:69
                       es_dest          ,  //68:64
                       exe_result       ,  //63:32
                       es_pc               //31:0
                      };

assign es_to_ds_valid = es_valid;

assign access_mem = es_load_op || es_store_op;

assign es_flush_sign  = excp_flush || ertn_flush || refetch_flush || icacop_flush || idle_flush;

assign icacop_inst_stall = icacop_op_en && !icache_unbusy;

assign es_ready_go    = (!div_stall && ((dcache_req_or_inst_en && data_addr_ok) || !(access_mem || dcacop_inst || preld_inst)) && !tlbsrch_stall && !icacop_inst_stall) || excp;
assign es_allowin     = !es_valid || es_ready_go && ms_allowin;
assign es_to_ms_valid =  es_valid && es_ready_go;
always @(posedge clk) begin
    if (reset || es_flush_sign) begin     
        es_valid <= 1'b0;
    end
    else if (es_allowin) begin 
        es_valid <= ds_to_es_valid;
    end

    if (ds_to_es_valid && es_allowin) begin
        ds_to_es_bus_r <= ds_to_es_bus;
    end
end

assign es_alu_src1 = es_src1_is_pc ? es_pc : es_rj_value;
                                      
assign es_alu_src2 = (es_src2_is_imm) ? es_imm : 
                     (es_src2_is_4)   ? 32'd4  : es_rkd_value;

assign es_div_enable = (es_mul_div_op[2] | es_mul_div_op[3]) & es_valid;
assign es_mul_enable = es_mul_div_op[0] | es_mul_div_op[1];

assign div_stall     = es_div_enable & ~div_complete;

alu u_alu(
    .alu_op     (es_alu_op    ),
    .alu_src1   (es_alu_src1  ),  //bug3 es_alu_src2
    .alu_src2   (es_alu_src2  ),
    .alu_result (es_alu_result)
    );

assign exe_result     = es_res_from_csr ? es_csr_data : es_alu_result;

//forward path
assign dest_zero            = (es_dest == 5'b0); 
assign forward_enable       = es_gr_we & ~dest_zero & es_valid;
assign dep_need_stall       = es_load_op | es_div_enable | es_mul_enable;
assign es_to_ds_forward_bus = {dep_need_stall ,  //38:38
                               forward_enable ,  //37:37
                               es_dest        ,  //36:32
                               exe_result         //31:0
                              };

assign tlb_inst_stall = (es_tlbsrch || es_tlbrd) && es_valid;

//csr mask
assign csr_mask_result = (es_rj_value & es_rkd_value) | (~es_rj_value & es_csr_data);
assign es_csr_result   = es_csr_mask ? csr_mask_result : es_rkd_value;

assign error_va        = pv_addr;

//exception
assign excp_ale        = access_mem & ((es_mem_size[0] &  1'b0)                                  | 
                                       (es_mem_size[1] &  es_alu_result[0])                      | 
                                       (!es_mem_size   & (es_alu_result[0] | es_alu_result[1]))) ;
                                
assign excp            = es_excp || excp_ale;
assign excp_num        = {excp_ale, es_excp_num};

assign sram_addr_low2bit = {es_alu_result[1], es_alu_result[0]};

//mem_size[0] byte size   [1] halfword size
assign dcache_req_or_inst_en = es_valid && !excp && ms_allowin && !es_flush_sign && !ms_flush;

assign data_valid = access_mem && dcache_req_or_inst_en;
assign data_op    = es_store_op && !es_cacop && !es_preld;
assign data_wstrb = wr_byte_en;

assign data_addr = es_tlbsrch ? {csr_vppn, 13'b0} : pv_addr;

wire [3:0] es_stb_wen = { sram_addr_low2bit==2'b11  ,
                          sram_addr_low2bit==2'b10  ,
                          sram_addr_low2bit==2'b01  ,
                          sram_addr_low2bit==2'b00} ;

wire [3:0] es_sth_wen = { sram_addr_low2bit==2'b10  ,
                          sram_addr_low2bit==2'b10  ,
                          sram_addr_low2bit==2'b00  ,
                          sram_addr_low2bit==2'b00} ;

wire [31:0] es_stb_cont = { {8{es_stb_wen[3]}} & es_rkd_value[7:0] ,
                            {8{es_stb_wen[2]}} & es_rkd_value[7:0] ,
                            {8{es_stb_wen[1]}} & es_rkd_value[7:0] ,
                            {8{es_stb_wen[0]}} & es_rkd_value[7:0]};

wire [31:0] es_sth_cont = { {16{es_sth_wen[3]}} & es_rkd_value[15:0] ,
                            {16{es_sth_wen[0]}} & es_rkd_value[15:0]};

assign {wr_byte_en, data_size}  = ({7{es_mem_size[0]}} & {es_stb_wen, 3'b00}) |
                                  ({7{es_mem_size[1]}} & {es_sth_wen, 3'b01}) |
                                  ({7{!es_mem_size  }} & {4'b1111   , 3'b10}) ;

//assign data_wdata = es_rkd_value; 
assign data_wdata = ({32{es_mem_size[0]}} & es_stb_cont ) |
                    ({32{es_mem_size[1]}} & es_sth_cont ) |
                    ({32{!es_mem_size  }} & es_rkd_value) ; 

assign tlbsrch_stall = es_tlbsrch && ms_wr_tlbehi;

//invtlb 
assign es_invtlb_asid = es_rj_value[9:0];
assign es_invtlb_vpn  = es_rkd_value[31:13];

assign pv_addr = es_alu_result;

//cache ins
assign cacop_op         = es_dest;
assign icacop_inst      = es_cacop && (cacop_op[2:0] == 3'b0);
assign icacop_op_en     = icacop_inst && dcache_req_or_inst_en;
assign dcacop_inst      = es_cacop && (cacop_op[2:0] == 3'b1);
assign dcacop_op_en     = dcacop_inst && dcache_req_or_inst_en;
assign cacop_op_mode    = cacop_op[4:3];

//preld ins
assign preld_hint = es_dest;
assign preld_inst = es_preld && ((preld_hint == 5'd0) || (preld_hint == 5'd8))/* && !data_uncache_en*/; //preld must have bug
assign preld_en   = preld_inst && dcache_req_or_inst_en; 

assign data_fetch = (data_valid || es_cacop|| preld_en) && data_addr_ok || es_tlbsrch;

// difftest
wire [31:0] es_inst         ;
wire [63:0] es_timer_64     ;
wire        es_cnt_inst     ;
wire [ 7:0] es_inst_ld_en   ;
wire [ 7:0] es_inst_st_en   ;
wire        es_csr_rstat_en ;

endmodule
