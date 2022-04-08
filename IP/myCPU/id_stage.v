`include "mycpu.h"

module id_stage(
    input                               clk           ,
    input                               reset         ,
    //allowin
    input                               es_allowin    ,
    output                              ds_allowin    ,
    //from fs
    input                               fs_to_ds_valid,
    input  [`FS_TO_DS_BUS_WD -1:0]      fs_to_ds_bus  ,
    //from es forward path
    input  [`ES_TO_DS_FORWARD_BUS -1:0] es_to_ds_forward_bus,
    input  [`MS_TO_DS_FORWARD_BUS -1:0] ms_to_ds_forward_bus,
    //to es
    output                              ds_to_es_valid,
    output [`DS_TO_ES_BUS_WD -1:0]      ds_to_es_bus  ,
    //to fs
    output [`BR_BUS_WD       -1:0]      br_bus        ,
    //exception
    input                               excp_flush    ,
    input                               ertn_flush    ,
    input                               refetch_flush ,
    input                               icacop_flush  ,
    //idle
    input                               idle_flush    ,
    //tlb ins
    input                               es_tlb_inst_stall,
    input                               ms_tlb_inst_stall,
    input                               ws_tlb_inst_stall,
    //interrupt
    input                               has_int       ,
    //csr
    output [13:0]                       rd_csr_addr   ,
    input  [31:0]                       rd_csr_data   ,
    input  [ 1:0]                       csr_plv       ,
    //timer 64
    input  [63:0]                       timer_64      ,
    input  [31:0]                       csr_tid       ,
    //llbit
    input                               ds_llbit      ,
    //every stage valid sign
    input                               es_to_ds_valid,
    input                               ms_to_ds_valid,
    input                               ws_to_ds_valid,
    //from axi
    input                               write_buffer_empty,
    //to btb
    output                              btb_operate_en    ,
    output                              btb_pop_ras       ,
    output                              btb_push_ras      ,
    output                              btb_add_entry     ,
    output                              btb_delete_entry  ,
    output                              btb_pre_error     ,
    output                              btb_pre_right     ,
    output                              btb_target_error  ,
    output                              btb_right_orien   ,
    output [31:0]                       btb_right_target  ,    
    output [31:0]                       btb_operate_pc    ,
    output [ 4:0]                       btb_operate_index ,
    //to rf: for write back
    input  [`WS_TO_RF_BUS_WD -1:0]      ws_to_rf_bus      ,
    // difftest
    output [31:0]                       rf_to_diff [31:0]
);

reg         ds_valid   ;
wire        ds_ready_go;

reg  [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus_r;

wire [31:0] ds_inst;
wire [31:0] ds_pc  ;
wire [ 3:0] ds_excp_num;
wire        ds_excp;
wire        ds_icache_miss;
wire        ds_btb_taken;
wire        ds_btb_en;
wire [ 4:0] ds_btb_index;
wire [31:0] ds_btb_target;

assign {ds_btb_target,  //108:77
        ds_btb_index,   //76:72
        ds_btb_taken,   //71:71
        ds_btb_en,      //70:70
        ds_icache_miss, //69:69
        ds_excp,        //68:68
        ds_excp_num,    //67:64
        ds_inst,        //63:32
        ds_pc           //31:0
       } = fs_to_ds_bus_r;

wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;
assign {rf_we   ,  //37:37
        rf_waddr,  //36:32
        rf_wdata   //31:0
       } = ws_to_rf_bus;

//wire        idle_stall;
wire        br_taken;
wire [31:0] br_target;
wire        btb_pre_error_flush;
wire [31:0] btb_pre_error_flush_target;

//wire        jirl_br;
wire [13:0] alu_op;
wire [ 3:0] mul_div_op;
wire        mul_div_sign;
wire        src1_is_pc;
wire        src2_is_imm;
wire        src2_is_4;
wire        load_op;
wire        res_from_csr;
wire        csr_mask;
wire        mem_b_size;
wire        mem_h_size;
wire        mem_sign_exted;
wire        dst_is_r1;
wire        dst_is_rj;
wire        gr_we;
wire        store_op;
wire        csr_we;
wire        src_reg_is_rd;
wire [1: 0] mem_size;
wire [4: 0] dest;
wire [31:0] rj_value;
wire [31:0] rkd_value;
wire [31:0] ds_imm;

wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 4:0] op_19_15;
wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;
wire [11:0] i12;
wire [13:0] i14;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;
wire [13:0] csr_idx;

wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [ 3:0] op_21_20_d;
wire [31:0] op_19_15_d;
wire [31:0] rd_d;
wire [31:0] rj_d;
wire [31:0] rk_d;
  
wire inst_add_w; 
wire inst_sub_w;  
wire inst_slt;    
wire inst_sltu;   
wire inst_nor;    
wire inst_and;    
wire inst_or;     
wire inst_xor;     
wire inst_lu12i_w;
wire inst_addi_w;
wire inst_slti;
wire inst_sltui;
wire inst_pcaddi;
wire inst_pcaddu12i;
wire inst_andn;
wire inst_orn;
wire inst_andi;
wire inst_ori;
wire inst_xori;
wire inst_mul_w;
wire inst_mulh_w;
wire inst_mulh_wu;
wire inst_div_w;
wire inst_mod_w;
wire inst_div_wu;
wire inst_mod_wu;

wire inst_slli_w;  
wire inst_srli_w;  
wire inst_srai_w;  
wire inst_sll_w;
wire inst_srl_w;
wire inst_sra_w;

wire inst_jirl;   
wire inst_b;      
wire inst_bl;     
wire inst_beq;    
wire inst_bne; 
wire inst_blt;
wire inst_bge;
wire inst_bltu;
wire inst_bgeu;

wire inst_ll_w;
wire inst_sc_w;
wire inst_ld_b;
wire inst_ld_bu;
wire inst_ld_h;
wire inst_ld_hu;
wire inst_ld_w;
wire inst_st_b;
wire inst_st_h;
wire inst_st_w;

wire inst_syscall;
wire inst_break;
wire inst_csrrd;
wire inst_csrwr;
wire inst_csrxchg;
wire inst_ertn;

wire inst_rdcntid_w;
wire inst_rdcntvl_w;
wire inst_rdcntvh_w;
wire inst_idle;

wire inst_tlbsrch;
wire inst_tlbrd;
wire inst_tlbwr;
wire inst_tlbfill;
wire inst_invtlb;

wire inst_cacop;
wire inst_preld;
wire inst_dbar;
wire inst_ibar;

wire need_ui5;
wire need_si12;
wire need_ui12;
wire need_si14_pc;
wire need_si16_pc;
wire need_si20;
wire need_si20_pc;
wire need_si26_pc;

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;

wire        pipeline_no_empty;
wire        dbar_stall;
wire        ibar_stall;

wire        rj_eq_rd;
wire        rj_lt_rd_sign;
wire        rj_lt_rd_unsign;

wire        ms_forward_enable;
wire [ 4:0] ms_forward_reg;
wire [31:0] ms_forward_data;
wire        ms_dep_need_stall;
wire        es_dep_need_stall;
wire        es_forward_enable;
wire [ 4:0] es_forward_reg;
wire [31:0] es_forward_data;
wire        rf1_forward_stall;
wire        rf2_forward_stall;

wire        excp;
wire [ 8:0] excp_num;
wire        inst_valid;
wire        excp_ine;
wire        excp_ipe;
wire [31:0] csr_data;
wire        refetch;
wire        flush_sign;

wire        fs_excp;

wire        kernel_inst;

wire [31:0] rdcnt_result;
wire        rdcnt_en;

reg         branch_slot_cancel;

wire        tlb_inst_stall;

wire        br_inst;

reg         br_jirl;

wire        br_need_reg_data;
wire        br_to_btb;

wire        inst_need_rj;
wire        inst_need_rkd;

wire [31:0] rj_value_forward_es;
wire [31:0] rkd_value_forward_es;

assign br_bus       = {btb_pre_error_flush,           //32:32
                       btb_pre_error_flush_target     //31:0
                      };

assign ds_to_es_bus = {inst_csr_rstat_en,  // 349:349 for difftest
                       inst_st_en       ,  // 348:341 for difftest
                       inst_ld_en       ,  // 340:333 for difftest
                       (inst_rdcntvl_w | inst_rdcntvh_w | inst_rdcntid_w), //332:332  for difftest
                       timer_64      ,  //331:268  for difftest
                       ds_inst       ,  //267:236  for difftest
                       inst_idle     ,  //235:235
                       btb_pre_error_flush, //234:234
                       br_to_btb     ,  //233:233
                       ds_icache_miss,  //232:232
                       br_inst       ,  //231:231
                       inst_preld    ,  //230:230
                       inst_cacop    ,  //229:229
                       mem_sign_exted,  //228:228
                       inst_invtlb   ,  //227:227
                       inst_tlbrd    ,  //226:226
                       refetch       ,  //225:225
                       inst_tlbfill  ,  //224:224
                       inst_tlbwr    ,  //223:223
                       inst_tlbsrch  ,  //222:222
                       inst_sc_w     ,  //221:221
                       inst_ll_w     ,  //220:220
                       excp_num      ,  //219:211
                       csr_mask      ,  //210:210
                       csr_we        ,  //209:209
                       csr_idx       ,  //208:195
                       res_from_csr  ,  //194:194
                       csr_data      ,  //193:162
                       inst_ertn     ,  //161:161
                       excp          ,  //160:160
                       mem_size      ,  //159:158
                       mul_div_op    ,  //157:154
                       mul_div_sign  ,  //153:153
                       alu_op        ,  //152:139
                       load_op       ,  //138:138 bug2 load_op
                       src1_is_pc    ,  //137:137
                       src2_is_imm   ,  //136:136
                       src2_is_4     ,  //135:135
                       gr_we         ,  //134:134
                       store_op      ,  //133:133
                       dest          ,  //132:128
                       ds_imm        ,  //127:96
                       rj_value      ,  //95 :64
                       rkd_value     ,  //63 :32
                       ds_pc            //31 :0
                      };

assign flush_sign = excp_flush || ertn_flush || refetch_flush || icacop_flush || idle_flush;

assign fs_excp = fs_to_ds_bus[68];

//wait inst will stall at ds.
assign ds_ready_go    = !(rf2_forward_stall || rf1_forward_stall/*|| idle_stall*/ || tlb_inst_stall || ibar_stall || dbar_stall) || excp;
assign ds_allowin     = !ds_valid || ds_ready_go && es_allowin;
assign ds_to_es_valid = ds_valid && ds_ready_go;
always @(posedge clk) begin   //bug1 no reset; branch no delay slot
    if (reset || flush_sign) begin
        ds_valid <= 1'b0;
    end
    else begin 
        if (ds_allowin) begin   //bug2 ??
            if ((btb_pre_error_flush && es_allowin) || branch_slot_cancel) begin
                ds_valid <= 1'b0;
            end
            else begin
                ds_valid <= fs_to_ds_valid;
            end
        end
    end

    if (fs_to_ds_valid && ds_allowin) begin
        fs_to_ds_bus_r <= fs_to_ds_bus;
    end
end

assign op_31_26  = ds_inst[31:26];
assign op_25_22  = ds_inst[25:22];
assign op_21_20  = ds_inst[21:20];
assign op_19_15  = ds_inst[19:15];

assign rd   = ds_inst[ 4: 0];
assign rj   = ds_inst[ 9: 5];
assign rk   = ds_inst[14:10];

assign i12  = ds_inst[21:10];
assign i14  = ds_inst[23:10];
assign i20  = ds_inst[24: 5];
assign i16  = ds_inst[25:10];
assign i26  = {ds_inst[ 9: 0], ds_inst[25:10]};

assign csr_idx = ds_inst[23:10];

decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

decoder_5_32 u_dec4(.in(rd  ), .out(rd_d  ));
decoder_5_32 u_dec5(.in(rj  ), .out(rj_d  ));
decoder_5_32 u_dec6(.in(rk  ), .out(rk_d  ));

assign inst_add_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or         = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_orn        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0c];
assign inst_andn       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0d];
assign inst_sll_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0e];
assign inst_srl_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];
assign inst_sra_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];
assign inst_mul_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18];
assign inst_mulh_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h19];
assign inst_mulh_wu    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h1a];
assign inst_div_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h00];
assign inst_mod_w      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h01];
assign inst_div_wu     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h02];
assign inst_mod_wu     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h03];
assign inst_break      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h14];
assign inst_syscall    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h16];
assign inst_slli_w     = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w     = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w     = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_idle       = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
assign inst_invtlb     = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h13];
assign inst_dbar       = op_31_26_d[6'h0e] & op_25_22_d[4'h1] & op_21_20_d[2'h3] & op_19_15_d[5'h04];
assign inst_ibar       = op_31_26_d[6'h0e] & op_25_22_d[4'h1] & op_21_20_d[2'h3] & op_19_15_d[5'h05];
assign inst_slti       = op_31_26_d[6'h00] & op_25_22_d[4'h8];
assign inst_sltui      = op_31_26_d[6'h00] & op_25_22_d[4'h9];
assign inst_addi_w     = op_31_26_d[6'h00] & op_25_22_d[4'ha];
assign inst_andi       = op_31_26_d[6'h00] & op_25_22_d[4'hd];
assign inst_ori        = op_31_26_d[6'h00] & op_25_22_d[4'he];
assign inst_xori       = op_31_26_d[6'h00] & op_25_22_d[4'hf];
assign inst_ld_b       = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
assign inst_ld_h       = op_31_26_d[6'h0a] & op_25_22_d[4'h1];
assign inst_ld_w       = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_st_b       = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
assign inst_st_h       = op_31_26_d[6'h0a] & op_25_22_d[4'h5];
assign inst_st_w       = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
assign inst_ld_bu      = op_31_26_d[6'h0a] & op_25_22_d[4'h8];
assign inst_ld_hu      = op_31_26_d[6'h0a] & op_25_22_d[4'h9];
assign inst_cacop      = op_31_26_d[6'h01] & op_25_22_d[4'h8];
assign inst_preld      = op_31_26_d[6'h0a] & op_25_22_d[4'hb];
assign inst_jirl       = op_31_26_d[6'h13];
assign inst_b          = op_31_26_d[6'h14];
assign inst_bl         = op_31_26_d[6'h15];
assign inst_beq        = op_31_26_d[6'h16];
assign inst_bne        = op_31_26_d[6'h17];
assign inst_blt        = op_31_26_d[6'h18];
assign inst_bge        = op_31_26_d[6'h19];
assign inst_bltu       = op_31_26_d[6'h1a];
assign inst_bgeu       = op_31_26_d[6'h1b];
assign inst_lu12i_w    = op_31_26_d[6'h05] & ~ds_inst[25];
assign inst_pcaddi     = op_31_26_d[6'h06] & ~ds_inst[25];
assign inst_pcaddu12i  = op_31_26_d[6'h07] & ~ds_inst[25];
assign inst_csrxchg    = op_31_26_d[6'h01] & ~ds_inst[25] & ~ds_inst[24] & (~rj_d[5'h00] & ~rj_d[5'h01]);  //rj != 0,1
assign inst_ll_w       = op_31_26_d[6'h08] & ~ds_inst[25] & ~ds_inst[24];
assign inst_sc_w       = op_31_26_d[6'h08] & ~ds_inst[25] &  ds_inst[24];
assign inst_csrrd      = op_31_26_d[6'h01] & ~ds_inst[25] & ~ds_inst[24] & rj_d[5'h00];
assign inst_csrwr      = op_31_26_d[6'h01] & ~ds_inst[25] & ~ds_inst[24] & rj_d[5'h01];
assign inst_rdcntid_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & rk_d[5'h18] & rd_d[5'h00];
assign inst_rdcntvl_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & rk_d[5'h18] & rj_d[5'h00] & !rd_d[5'h00];
assign inst_rdcntvh_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & rk_d[5'h19] & rj_d[5'h00];
assign inst_ertn       = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0e] & rj_d[5'h00] & rd_d[5'h00];
assign inst_tlbsrch    = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0a] & rj_d[5'h00] & rd_d[5'h00];
assign inst_tlbrd      = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0b] & rj_d[5'h00] & rd_d[5'h00];
assign inst_tlbwr      = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0c] & rj_d[5'h00] & rd_d[5'h00];
assign inst_tlbfill    = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0d] & rj_d[5'h00] & rd_d[5'h00];


assign alu_op[ 0] = inst_add_w    | 
                    inst_addi_w   | 
                    inst_ld_b     |
                    inst_ld_h     |
                    inst_ld_w     |
                    inst_st_b     |
                    inst_st_h     | 
                    inst_st_w     |
                    inst_ld_bu    |
                    inst_ld_hu    | 
                    inst_ll_w     |
                    inst_sc_w     |
                    inst_jirl     | 
                    inst_bl       |
                    inst_pcaddi   |
                    inst_pcaddu12i|
                    inst_cacop    |
                    inst_preld    ;

assign alu_op[ 1] = inst_sub_w;
assign alu_op[ 2] = inst_slt   | inst_slti;
assign alu_op[ 3] = inst_sltu  | inst_sltui;
assign alu_op[ 4] = inst_and   | inst_andi;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or    | inst_ori;
assign alu_op[ 7] = inst_xor   | inst_xori;
assign alu_op[ 8] = inst_sll_w | inst_slli_w;
assign alu_op[ 9] = inst_srl_w | inst_srli_w;
assign alu_op[10] = inst_sra_w | inst_srai_w;
assign alu_op[11] = inst_lu12i_w;
assign alu_op[12] = inst_andn;
assign alu_op[13] = inst_orn;

assign mul_div_op[ 0] = inst_mul_w;
assign mul_div_op[ 1] = inst_mulh_w | inst_mulh_wu;
assign mul_div_op[ 2] = inst_div_w  | inst_div_wu;
assign mul_div_op[ 3] = inst_mod_w  | inst_mod_wu;

assign mul_div_sign  =  inst_mul_w | inst_mulh_w | inst_div_w | inst_mod_w;

assign need_ui5      =  inst_slli_w | inst_srli_w | inst_srai_w;
assign need_si12     =  inst_addi_w |
                        inst_ld_b   |
                        inst_ld_h   |
                        inst_ld_w   |
                        inst_st_b   |
                        inst_st_h   | 
                        inst_st_w   |
                        inst_ld_bu  |
                        inst_ld_hu  | 
                        inst_slti   | 
                        inst_sltui  |
                        inst_cacop  |
                        inst_preld  ;

assign need_ui12     =  inst_andi | inst_ori | inst_xori;
assign need_si14_pc  =  inst_ll_w | inst_sc_w;
assign need_si16_pc  =  inst_jirl |
                        inst_beq  | 
                        inst_bne  | 
                        inst_blt  | 
                        inst_bge  | 
                        inst_bltu | 
                        inst_bgeu;

assign need_si20     =  inst_lu12i_w | inst_pcaddu12i;
assign need_si20_pc  =  inst_pcaddi;
assign need_si26_pc  =  inst_b | inst_bl;

assign ds_imm = ({32{need_ui5    }} & {27'b0, rk}               ) |
                ({32{need_si12   }} & {{20{i12[11]}}, i12}      ) |
                ({32{need_ui12   }} & {20'b0, i12}              ) |
                ({32{need_si14_pc}} & {{16{i14[13]}}, i14, 2'b0}) |
                ({32{need_si16_pc}} & {{14{i16[15]}}, i16, 2'b0}) |
                ({32{need_si20   }} & {i20, 12'b0}              ) |
                ({32{need_si20_pc}} & {{10{i20[19]}}, i20, 2'b0}) |
                ({32{need_si26_pc}} & {{ 4{i26[25]}}, i26, 2'b0}) ;

assign src_reg_is_rd = inst_beq    | 
                       inst_bne    | 
                       inst_blt    | 
                       inst_bltu   | 
                       inst_bge    | 
                       inst_bgeu   |
                       inst_st_b   |
                       inst_st_h   |
                       inst_st_w   |
                       inst_sc_w   |
                       inst_csrwr  |
                       inst_csrxchg;

assign src1_is_pc    = inst_jirl | inst_bl | inst_pcaddi | inst_pcaddu12i;

assign src2_is_imm   = inst_slli_w    |
                       inst_srli_w    |
                       inst_srai_w    |
                       inst_addi_w    |
                       inst_slti      |
                       inst_sltui     |
                       inst_andi      |
                       inst_ori       |
                       inst_xori      |
                       inst_pcaddi    |
                       inst_pcaddu12i |
                       inst_ld_b      |
                       inst_ld_h      |
                       inst_ld_w      |
                       inst_ld_bu     |
                       inst_ld_hu     |
                       inst_st_b      |
                       inst_st_h      |
                       inst_st_w      |
                       inst_ll_w      |
                       inst_sc_w      |
                       inst_lu12i_w   |
                       inst_cacop     |
                       inst_preld     ;

assign src2_is_4     = inst_jirl | inst_bl;

assign load_op       = inst_ld_b | inst_ld_h | inst_ld_w | inst_ld_bu | inst_ld_hu | inst_ll_w;
assign mem_b_size    = inst_ld_b | inst_ld_bu | inst_st_b;
assign mem_h_size    = inst_ld_h | inst_ld_hu | inst_st_h;
assign mem_sign_exted= inst_ld_b | inst_ld_h;
assign dst_is_r1     = inst_bl;
assign gr_we         = ~inst_st_b    & 
                       ~inst_st_h    & 
                       ~inst_st_w    & 
                       ~inst_beq     & 
                       ~inst_bne     & 
                       ~inst_blt     & 
                       ~inst_bge     &
                       ~inst_bltu    &
                       ~inst_bgeu    &
                       ~inst_b       &
                       ~inst_syscall &
                       ~inst_tlbsrch &
                       ~inst_tlbrd   &
                       ~inst_tlbwr   &
                       ~inst_tlbfill &
                       ~inst_invtlb  &
                       ~inst_cacop   &
                       ~inst_preld   &      
                       ~inst_dbar    &      
                       ~inst_ibar    ;

assign store_op      = inst_st_b | inst_st_h | inst_st_w | (inst_sc_w & ds_llbit);

assign dest          = (dst_is_r1) ? 5'd1 :
                       (dst_is_rj) ? rj   : rd;

assign dst_is_rj     = inst_rdcntid_w;

assign {rdcnt_en, rdcnt_result} = ({33{inst_rdcntvl_w}} & {1'b1, timer_64[31: 0]}) |
                                  ({33{inst_rdcntvh_w}} & {1'b1, timer_64[63:32]}) |
                                  ({33{inst_rdcntid_w}} & {1'b1, csr_tid}); 

assign csr_data      = rdcnt_en  ? rdcnt_result      : 
                       inst_sc_w ? {31'b0, ds_llbit} : rd_csr_data;                      
                                                                        
assign res_from_csr  = inst_csrrd | inst_csrwr | inst_csrxchg | inst_rdcntid_w | inst_rdcntvh_w | inst_rdcntvl_w | inst_sc_w;
assign csr_we        = inst_csrwr | inst_csrxchg;
assign csr_mask      = inst_csrxchg;

assign mem_size  = {mem_h_size, mem_b_size};

assign inst_need_rj = inst_add_w   |
                      inst_sub_w   |
                      inst_addi_w  |
                      inst_slt     |
                      inst_sltu    |
                      inst_slti    |
                      inst_sltui   |
                      inst_and     |
                      inst_or      |
                      inst_nor     |
                      inst_xor     |
                      inst_andi    |
                      inst_ori     |
                      inst_xori    |
                      inst_mul_w   |
                      inst_mulh_w  |
                      inst_mulh_wu |
                      inst_div_w   |
                      inst_div_wu  |
                      inst_mod_w   |
                      inst_mod_wu  |
                      inst_sll_w   |
                      inst_srl_w   |
                      inst_sra_w   |
                      inst_slli_w  |
                      inst_srli_w  |
                      inst_srai_w  |
                      inst_beq     |
                      inst_bne     |
                      inst_blt     |
                      inst_bltu    |
                      inst_bge     |
                      inst_bgeu    |
                      inst_jirl    |
                      inst_ld_b    |
                      inst_ld_bu   |
                      inst_ld_h    |
                      inst_ld_hu   |
                      inst_ld_w    |
                      inst_st_b    |
                      inst_st_h    |
                      inst_st_w    |
                      inst_preld   |
                      inst_ll_w    |
                      inst_sc_w    |
                      inst_csrxchg |
                      inst_cacop   |
                      inst_invtlb  ;
                      
assign inst_need_rkd = inst_add_w   |
                       inst_sub_w   |
                       inst_slt     |
                       inst_sltu    |
                       inst_and     |
                       inst_or      |
                       inst_nor     |
                       inst_xor     |
                       inst_mul_w   |
                       inst_mulh_w  |
                       inst_mulh_wu |
                       inst_div_w   |
                       inst_div_wu  |
                       inst_mod_w   |
                       inst_mod_wu  |
                       inst_sll_w   |
                       inst_srl_w   |
                       inst_sra_w   |
                       inst_beq     |
                       inst_bne     |
                       inst_blt     |
                       inst_bltu    |
                       inst_bge     |
                       inst_bgeu    |
                       inst_st_b    |
                       inst_st_h    |
                       inst_st_w    |
                       inst_sc_w    |
                       inst_csrwr   |
                       inst_csrxchg |
                       inst_invtlb  ;


assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd : rk;
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata ),
    .rf_o   (rf_to_diff)
    );

assign {es_dep_need_stall,
        es_forward_enable, 
        es_forward_reg   ,
        es_forward_data
       } = es_to_ds_forward_bus;

assign {ms_dep_need_stall,
        ms_forward_enable, 
        ms_forward_reg   ,
        ms_forward_data
       } = ms_to_ds_forward_bus;

//exe stage first forward
assign {rf1_forward_stall, rj_value, rj_value_forward_es} = ((rf_raddr1 == es_forward_reg) && es_forward_enable && inst_need_rj) ? {es_dep_need_stall, es_forward_data, es_forward_data} :
                                                            ((rf_raddr1 == ms_forward_reg) && ms_forward_enable && inst_need_rj) ? {ms_dep_need_stall || br_need_reg_data, ms_forward_data, rf_rdata1} :
                                                                                                                                   {1'b0, rf_rdata1, rf_rdata1}; 

assign {rf2_forward_stall, rkd_value, rkd_value_forward_es} = ((rf_raddr2 == es_forward_reg) && es_forward_enable && inst_need_rkd) ? {es_dep_need_stall, es_forward_data, es_forward_data} :
                                                              ((rf_raddr2 == ms_forward_reg) && ms_forward_enable && inst_need_rkd) ? {ms_dep_need_stall || br_need_reg_data, ms_forward_data, rf_rdata2} :
                                                                                                                                      {1'b0, rf_rdata2, rf_rdata2};

assign rj_eq_rd        = (rj_value_forward_es == rkd_value_forward_es);
assign rj_lt_rd_unsign = (rj_value_forward_es < rkd_value_forward_es);   //operate "<" has nice timing
assign rj_lt_rd_sign   = (rj_value_forward_es[31] && ~rkd_value_forward_es[31]) ? 1'b1 :
                         (~rj_value_forward_es[31] && rkd_value_forward_es[31]) ? 1'b0 : rj_lt_rd_unsign;                         
                                                            
assign br_taken  = (   inst_beq  &&  rj_eq_rd
                    || inst_bne  && !rj_eq_rd
                    || inst_blt  &&  rj_lt_rd_sign
                    || inst_bge  && !rj_lt_rd_sign
                    || inst_bltu &&  rj_lt_rd_unsign
                    || inst_bgeu && !rj_lt_rd_unsign
                    || inst_jirl
                    || inst_bl
                    || inst_b
                    ) && ds_valid && !ds_excp; 

assign br_inst = br_need_reg_data || inst_bl || inst_b;

assign br_to_btb = inst_beq   ||
                   inst_bne   ||
                   inst_blt   ||
                   inst_bge   ||
                   inst_bltu  ||
                   inst_bgeu  ||
                   inst_bl    ||
                   inst_b     || 
                   inst_jirl;

assign br_need_reg_data = inst_beq   ||
                          inst_bne   ||
                          inst_blt   ||
                          inst_bge   ||
                          inst_bltu  ||
                          inst_bgeu  ||
                          inst_jirl;

assign br_target = ({32{inst_beq || inst_bne || inst_bl || inst_b || 
                    inst_blt || inst_bge || inst_bltu || inst_bgeu}} & (ds_pc + ds_imm   ))            |
                   ({32{inst_jirl}}                                  & (rj_value_forward_es + ds_imm)) ;

//assign idle_stall = inst_idle & ds_valid & !has_int;

assign excp     = excp_ipe | inst_syscall | inst_break | ds_excp | excp_ine | has_int;
assign excp_num = {excp_ipe, excp_ine, inst_break, inst_syscall, ds_excp_num, has_int};

assign rd_csr_addr = csr_idx;

//when cache operate icache, will refetch inst after this inst.
assign refetch = (inst_tlbwr || inst_tlbfill || inst_tlbrd || inst_invtlb || inst_ertn || inst_ibar) && ds_valid;  //this inst will change addr trans 

assign tlb_inst_stall = es_tlb_inst_stall || ms_tlb_inst_stall || ws_tlb_inst_stall;

assign inst_valid = inst_add_w     |
                    inst_sub_w     |
                    inst_slt       |
                    inst_sltu      |
                    inst_nor       |
                    inst_and       |
                    inst_or        |
                    inst_xor       |
                    inst_sll_w     |
                    inst_srl_w     |
                    inst_sra_w     |
                    inst_mul_w     |
                    inst_mulh_w    |
                    inst_mulh_wu   |
                    inst_div_w     |
                    inst_mod_w     |
                    inst_div_wu    |
                    inst_mod_wu    |
                    inst_break     |
                    inst_syscall   |
                    inst_slli_w    |
                    inst_srli_w    |
                    inst_srai_w    |
                    inst_idle      |
                    inst_slti      |
                    inst_sltui     |
                    inst_addi_w    |
                    inst_andi      |
                    inst_ori       |
                    inst_xori      |
                    inst_ld_b      |
                    inst_ld_h      |
                    inst_ld_w      |
                    inst_st_b      |
                    inst_st_h      |
                    inst_st_w      |
                    inst_ld_bu     |
                    inst_ld_hu     |
                    inst_ll_w      |
                    inst_sc_w      |
                    inst_jirl      |
                    inst_b         |
                    inst_bl        |
                    inst_beq       |
                    inst_bne       |
                    inst_blt       |
                    inst_bge       |
                    inst_bltu      |
                    inst_bgeu      |
                    inst_lu12i_w   |
                    inst_pcaddu12i |
                    inst_csrrd     |
                    inst_csrwr     |
                    inst_csrxchg   |
                    inst_rdcntid_w |
                    inst_rdcntvh_w |
                    inst_rdcntvl_w |
                    inst_ertn      |
                    inst_cacop     |
                    inst_preld     |
                    inst_dbar      |
                    inst_ibar      |
                    inst_tlbsrch   |
                    inst_tlbrd     |
                    inst_tlbwr     |
                    inst_tlbfill   |
                    (inst_invtlb && (rd == 5'd0 || 
                                     rd == 5'd1 || 
                                     rd == 5'd2 || 
                                     rd == 5'd3 || 
                                     rd == 5'd4 ||
                                     rd == 5'd5 || 
                                     rd == 5'd6 ));  //invtlb valid op

assign excp_ine = ~inst_valid;

assign kernel_inst = inst_csrrd    |
                     inst_csrwr    |
                     inst_csrxchg  |
                     inst_cacop    |
                     inst_tlbsrch  |
                     inst_tlbrd    |
                     inst_tlbwr    |
                     inst_tlbfill  |
                     inst_invtlb   |
                     inst_ertn     |
                     inst_idle     ;

assign excp_ipe = kernel_inst && (csr_plv == 2'b11);

//branch slot cancel, need wait next valid inst after branch
//only valid br_taken sign can generate slot_cancel.
always @(posedge clk) begin
    if (reset || flush_sign) begin
    //flush signal need flush this buffer
        branch_slot_cancel <= 1'b0;
    end
    else if (btb_pre_error_flush && es_allowin && !fs_to_ds_valid) begin
        branch_slot_cancel <= 1'b1;
    end
    else if (branch_slot_cancel && fs_to_ds_valid) begin
        branch_slot_cancel <= 1'b0;
    end
end

assign btb_operate_en    = ds_valid && ds_allowin && !ds_excp;
assign btb_operate_pc    = ds_pc;
assign btb_pop_ras       = inst_jirl; 
assign btb_push_ras      = inst_bl;
assign btb_add_entry     = br_to_btb && !ds_btb_en && br_taken;
assign btb_delete_entry  = !br_to_btb && ds_btb_en;
assign btb_pre_error     = br_to_btb && ds_btb_en && (ds_btb_taken ^ br_taken);
assign btb_target_error  = br_to_btb && ds_btb_en && (ds_btb_taken && br_taken) && (ds_btb_target != br_target);
assign btb_pre_right     = br_to_btb && ds_btb_en && !(ds_btb_taken ^ br_taken);
assign btb_right_orien   = br_taken;
assign btb_right_target  = br_target;
assign btb_operate_index = ds_btb_index;

assign btb_pre_error_flush = (btb_add_entry || btb_delete_entry || btb_pre_error || btb_target_error) && ds_valid && ds_ready_go && !ds_excp;
assign btb_pre_error_flush_target = br_taken ? br_target : ds_pc + 32'h4;

//ibar dbar
assign pipeline_no_empty = es_to_ds_valid || ms_to_ds_valid || ws_to_ds_valid || !write_buffer_empty;
assign dbar_stall = inst_dbar && pipeline_no_empty;
assign ibar_stall = inst_ibar && pipeline_no_empty;

// difftest
wire [7:0]  inst_ld_en;
wire [7:0]  inst_st_en;
wire        inst_csr_rstat_en;

// ll ldw ldhu ldh ldbu ldb
assign inst_ld_en = {2'b0, inst_ll_w, inst_ld_w, inst_ld_hu, inst_ld_h, inst_ld_bu, inst_ld_b};
// sc(llbit = 1) stw sth stb
assign inst_st_en = {4'b0, ds_llbit && inst_sc_w, inst_st_w, inst_st_h, inst_st_b};
assign inst_csr_rstat_en = (inst_csrrd || inst_csrwr || inst_csrxchg) && (csr_idx == 14'd5);


endmodule
