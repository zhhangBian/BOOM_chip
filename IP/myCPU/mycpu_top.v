module core_top(
    input           aclk,
    input           aresetn,
    input    [ 7:0] intrpt, 
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
    output   [ 3:0] wid,
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

    output [31:0] debug0_wb_pc,
    output [ 3:0] debug0_wb_rf_wen,
    output [ 4:0] debug0_wb_rf_wnum,
    output [31:0] debug0_wb_rf_wdata,
    output [31:0] debug0_wb_inst
);
reg         reset;
always @(posedge aclk) reset <= ~aresetn; 

wire         ds_allowin;
wire         es_allowin;
wire         ms_allowin;
wire         ws_allowin;
wire         fs_to_ds_valid;
wire         ds_to_es_valid;
wire         es_to_ms_valid;
wire         ms_to_ws_valid;
wire [31:0]  fs_csr_eentry;
wire [31:0]  fs_csr_era;
wire [31:0]  ws_csr_era;
wire [ 8:0]  ws_csr_esubcode;
wire [ 5:0]  ws_csr_ecode;
wire [63:0]  ds_timer_64;
wire [31:0]  ds_csr_tid;
wire [13:0]  rd_csr_addr;
wire [31:0]  rd_csr_data;
wire [13:0]  wr_csr_addr;
wire [31:0]  wr_csr_data;
wire [31:0]  ws_bad_va;
wire         ws_va_error;
wire         ds_llbit;
wire         ws_llbit;
wire         ws_llbit_set;
wire         has_int;
wire         csr_wr_en;
wire         excp_flush; 
wire         ertn_flush;
wire         icacop_flush;
wire         idle_flush;
wire         es_div_enable;
wire         es_mul_div_sign;
wire [31:0]  es_rj_value;
wire [31:0]  es_rkd_value;
wire         div_complete;
wire [31:0]  div_result;
wire [31:0]  mod_result;
wire [63:0]  mul_result;
wire [ 9:0]  csr_asid;
wire [ 4:0]  rand_index;
wire [31:0]  tlbw_tlbehi;
wire [31:0]  tlbw_tlbelo0;
wire [31:0]  tlbw_tlbelo1;
wire [31:0]  tlbw_r_tlbidx;
wire [ 5:0]  tlbw_ecode;
wire         tlbrd_en;
wire [31:0]  tlbr_tlbehi;
wire [31:0]  tlbr_tlbelo0;
wire [31:0]  tlbr_tlbelo1;
wire [31:0]  tlbr_tlbidx;
wire [ 9:0]  tlbr_asid;
wire         invtlb_en;
wire [ 9:0]  invtlb_asid;
wire [18:0]  invtlb_vpn;
wire [ 4:0]  invtlb_op;
wire [18:0]  csr_vppn;
wire         inst_tlb_found;
wire         inst_tlb_v;
wire         inst_tlb_d;
wire [ 1:0]  inst_tlb_mat;
wire [ 1:0]  inst_tlb_plv;
wire         data_tlb_found;
wire [ 4:0]  data_tlb_index;
wire         data_tlb_v;
wire         data_tlb_d;
wire [ 1:0]  data_tlb_mat;
wire [ 1:0]  data_tlb_plv;
wire         tlbsrch_en;
wire         tlbfill_en;
wire         tlbwr_en;
wire         refetch_flush;
wire         tlbsrch_found;
wire [ 4:0]  tlbsrch_index;
wire         ms_wr_tlbehi;
wire         ms_flush;
wire         excp_tlbrefill;
wire [31:0]  csr_tlbrentry;
wire         csr_pg;
wire         csr_da;
wire [31:0]  csr_dmw0;
wire [31:0]  csr_dmw1;
wire [ 1:0]  csr_plv;
wire [ 1:0]  csr_datf;
wire [ 1:0]  csr_datm;
wire         inst_addr_trans_en;
wire         data_addr_trans_en;
wire         cacop_op_mode_di;
wire         excp_tlb;
wire [18:0]  excp_tlb_vppn;
wire         icacop_op_en;
wire         dcacop_op_en;
wire [ 1:0]  cacop_op_mode;
wire         icache_unbusy;
wire         dcache_unbusy;
wire [31:0]  fetch_pc;
wire         fetch_en;
wire [31:0]  btb_ret_pc;
wire         btb_taken;
wire         btb_en;
wire [ 4:0]  btb_index;
wire         btb_add_entry;    
wire         btb_pop_ras;
wire         btb_push_ras;
wire         btb_operate_en;
wire         btb_delete_entry; 
wire         btb_pre_error;  
wire         btb_pre_right;  
wire         btb_target_error; 
wire         btb_right_orien;  
wire [31:0]  btb_right_target;
wire [31:0]  btb_operate_pc;   
wire [ 4:0]  btb_operate_index;
wire         es_tlb_inst_stall;
wire         ms_tlb_inst_stall;
wire         ws_tlb_inst_stall;
wire         data_fetch;
wire [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus;
wire [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus;
wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus;
wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus;
wire [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus;
wire [`BR_BUS_WD       -1:0] br_bus;
wire [`ES_TO_DS_FORWARD_BUS -1:0] es_to_ds_forward_bus;
wire [`MS_TO_DS_FORWARD_BUS -1:0] ms_to_ds_forward_bus; 

wire [31:0]  inst_vaddr;
wire         inst_valid;
wire         inst_op;
wire [ 7:0]  inst_index;
wire [19:0]  inst_tag;
wire [ 3:0]  inst_offset;
wire [ 3:0]  inst_wstrb;
wire [31:0]  inst_wdata;
wire         inst_addr_ok;  
wire         inst_data_ok;  
wire [31:0]  inst_rdata;    
wire         inst_rd_req;   
wire [ 2:0]  inst_rd_type;  
wire [31:0]  inst_rd_addr;  
wire         inst_rd_rdy;   
wire         inst_ret_valid;
wire         inst_ret_last; 
wire [31:0]  inst_ret_data; 
wire         inst_wr_req;   
wire [ 2:0]  inst_wr_type;  
wire [31:0]  inst_wr_addr;  
wire [ 3:0]  inst_wr_wstrb; 
wire [127:0] inst_wr_data;  
wire         inst_wr_rdy;  
wire         inst_uncache_en;
wire         inst_tlb_excp_cancel_req;
wire         inst_dmw0_en;
wire         inst_dmw1_en;
wire [31:0]  data_vaddr; 
wire         data_valid;
wire         data_op;
wire [ 2:0]  data_size;
wire [ 7:0]  data_index;
wire [19:0]  data_tag;
wire [ 3:0]  data_offset;
wire [ 3:0]  data_wstrb;
wire [31:0]  data_wdata;
wire         data_addr_ok;  
wire         data_data_ok;  
wire [31:0]  data_rdata;    
wire         data_rd_req;   
wire [ 2:0]  data_rd_type;  
wire [31:0]  data_rd_addr;  
wire         data_rd_rdy;   
wire         data_ret_valid;
wire         data_ret_last; 
wire [31:0]  data_ret_data; 
wire         data_wr_req;   
wire [ 2:0]  data_wr_type;  
wire [31:0]  data_wr_addr;  
wire [ 3:0]  data_wr_wstrb; 
wire [127:0] data_wr_data;  
wire         data_wr_rdy; 
wire         data_uncache_en;  
wire         data_dmw0_en;
wire         data_dmw1_en;
wire         data_tlb_excp_cancel_req;

wire         es_to_ds_valid;
wire         ms_to_ds_valid;
wire         ws_to_ds_valid;
wire         write_buffer_empty;
wire [ 4:0]  preld_hint;
wire         preld_en;

wire         commit_inst;
wire         br_inst;
wire         icache_miss;
wire         dcache_miss;
wire         mem_inst;
wire         br_pre;
wire         br_pre_error;
wire         fs_icache_miss;
wire         ms_dcache_miss;
wire         disable_cache;

wire [ 8:0]  interrupt;
assign interrupt = intrpt;

// IF stage
if_stage if_stage(
    .clk             (aclk           ),
    .reset           (reset          ),
    //allowin
    .ds_allowin      (ds_allowin     ),
    //brbus
    .br_bus          (br_bus         ),
    //outputs
    .fs_to_ds_valid  (fs_to_ds_valid ),
    .fs_to_ds_bus    (fs_to_ds_bus   ),
    //exception
    .excp_flush        (excp_flush     ),
    .ertn_flush        (ertn_flush     ),
    .refetch_flush     (refetch_flush  ),
    .icacop_flush      (icacop_flush   ),
    .ws_pc             (ws_csr_era     ),
    .csr_eentry        (fs_csr_eentry  ),
    .csr_era           (fs_csr_era     ),
    .excp_tlbrefill    (excp_tlbrefill ),
    .csr_tlbrentry     (csr_tlbrentry  ),
    .has_int           (has_int        ), 
    //idle
    .idle_flush        (idle_flush     ),
    // inst cache interface
    .inst_valid        (inst_valid       ),
    .inst_op           (inst_op          ),
    .inst_addr         (inst_vaddr       ),
    .inst_wstrb        (inst_wstrb       ),
    .inst_wdata        (inst_wdata       ),
    .inst_addr_ok      (inst_addr_ok     ),
    .inst_data_ok      (inst_data_ok     ),
    .icache_miss       (fs_icache_miss   ),
    .inst_rdata        (inst_rdata       ),
    .inst_uncache_en   (inst_uncache_en  ),
    .tlb_excp_cancel_req (inst_tlb_excp_cancel_req),
    //from csr
    .csr_pg            (csr_pg           ),
    .csr_da            (csr_da           ),
    .csr_dmw0          (csr_dmw0         ),
    .csr_dmw1          (csr_dmw1         ),
    .csr_plv           (csr_plv          ),
    .csr_datf          (csr_datf         ),
    .disable_cache     (disable_cache    ),
    //to btb
    .fetch_pc          (fetch_pc         ),
    .fetch_en          (fetch_en         ),
    .btb_ret_pc        (btb_ret_pc       ),  
    .btb_taken         (btb_taken        ),
    .btb_en            (btb_en           ),
    .btb_index         (btb_index        ),  
    //to addr trans
    .inst_addr_trans_en(inst_addr_trans_en),
    .dmw0_en           (inst_dmw0_en     ),
    .dmw1_en           (inst_dmw1_en     ),
    //tlb
    .inst_tlb_found    (inst_tlb_found   ),
    .inst_tlb_v        (inst_tlb_v       ),
    .inst_tlb_d        (inst_tlb_d       ),
    .inst_tlb_mat      (inst_tlb_mat     ),
    .inst_tlb_plv      (inst_tlb_plv     )
);
// ID stage
id_stage id_stage(
    .clk                  (aclk                ),
    .reset                (reset               ),
    //allowin
    .es_allowin           (es_allowin          ),
    .ds_allowin           (ds_allowin          ),
    //from fs
    .fs_to_ds_valid       (fs_to_ds_valid      ),
    .fs_to_ds_bus         (fs_to_ds_bus        ),
    //from ds forward path 
    .es_to_ds_forward_bus (es_to_ds_forward_bus),
    .ms_to_ds_forward_bus (ms_to_ds_forward_bus),
    //to es
    .ds_to_es_valid       (ds_to_es_valid      ),
    .ds_to_es_bus         (ds_to_es_bus        ),
    //to fs
    .br_bus               (br_bus              ),
    //exception
    .excp_flush           (excp_flush          ),
    .ertn_flush           (ertn_flush          ),
    .refetch_flush        (refetch_flush       ),
    .icacop_flush         (icacop_flush        ),
    //idle
    .idle_flush           (idle_flush          ),
    //tlb ins 
    .es_tlb_inst_stall    (es_tlb_inst_stall   ),
    .ms_tlb_inst_stall    (ms_tlb_inst_stall   ),
    .ws_tlb_inst_stall    (ws_tlb_inst_stall   ),
    //interrupt
    .has_int              (has_int             ),
    //csr
    .rd_csr_addr          (rd_csr_addr         ),
    .rd_csr_data          (rd_csr_data         ),
    .csr_plv              (csr_plv             ),
    //timer 64
    .timer_64             (ds_timer_64         ),
    .csr_tid              (ds_csr_tid          ),
    //llbit 
    .ds_llbit             (ds_llbit            ),
    //every stage valid sign
    .es_to_ds_valid       (es_to_ds_valid      ),
    .ms_to_ds_valid       (ms_to_ds_valid      ),
    .ws_to_ds_valid       (ws_to_ds_valid      ),
    //from axi 
    .write_buffer_empty   (write_buffer_empty  ),
    //to btb
    .btb_operate_en       (btb_operate_en      ),
    .btb_pop_ras          (btb_pop_ras         ),
    .btb_push_ras         (btb_push_ras        ),
    .btb_add_entry        (btb_add_entry       ),
    .btb_delete_entry     (btb_delete_entry    ),    
    .btb_pre_error        (btb_pre_error       ),
    .btb_pre_right        (btb_pre_right       ),
    .btb_target_error     (btb_target_error    ),    
    .btb_right_orien      (btb_right_orien     ),
    .btb_right_target     (btb_right_target    ),
    .btb_operate_pc       (btb_operate_pc      ),
    .btb_operate_index    (btb_operate_index   ),
    //to rf: for write back
    .ws_to_rf_bus         (ws_to_rf_bus        ),
    .rf_to_diff           (regs                )
);
// EXE stage
exe_stage exe_stage(
    .clk                  (aclk                ),
    .reset                (reset               ),
    //allowin
    .ms_allowin           (ms_allowin          ),
    .es_allowin           (es_allowin          ),
    //from ds
    .ds_to_es_valid       (ds_to_es_valid      ),
    .ds_to_es_bus         (ds_to_es_bus        ),
    //to ms
    .es_to_ms_valid       (es_to_ms_valid      ),
    .es_to_ms_bus         (es_to_ms_bus        ),
    //to ds forward path
    .es_to_ds_forward_bus (es_to_ds_forward_bus),
    .es_to_ds_valid       (es_to_ds_valid      ), 
    //div_mul
    .es_div_enable        (es_div_enable       ),
    .es_mul_div_sign      (es_mul_div_sign     ),
    .es_rj_value          (es_rj_value         ),
    .es_rkd_value         (es_rkd_value        ),
    .div_complete         (div_complete        ),
    //exception
    .excp_flush           (excp_flush          ),
    .ertn_flush           (ertn_flush          ),
    .refetch_flush        (refetch_flush       ),
    .icacop_flush         (icacop_flush        ),
    //idle
    .idle_flush           (idle_flush          ),
    //tlb/cache ins
    .tlb_inst_stall       (es_tlb_inst_stall   ),
    //cache ins
    .icacop_op_en         (icacop_op_en        ),
    .dcacop_op_en         (dcacop_op_en        ),
    .cacop_op_mode        (cacop_op_mode       ),
    //from icache
    .icache_unbusy        (icache_unbusy       ),
    //preld ins
    .preld_hint           (preld_hint          ),
    .preld_en             (preld_en            ),
    // data cache interface
    .data_valid           (data_valid          ),  
    .data_op              (data_op             ), 
    .data_size            (data_size           ),
    .data_wstrb           (data_wstrb          ), 
    .data_wdata           (data_wdata          ), 
    .data_addr_ok         (data_addr_ok        ),
    //from csr
    .csr_vppn             (csr_vppn            ),
    //to addr trans
    .data_addr            (data_vaddr          ), 
    .data_fetch           (data_fetch          ),
    //from ms 
    .ms_wr_tlbehi         (ms_wr_tlbehi        ),
    .ms_flush             (ms_flush            )
);

div u_div(
    .div_clk         (aclk           ),
    .reset           (reset          ),
    .div             (es_div_enable  ),
    .div_signed      (es_mul_div_sign),
    .x               (es_rj_value    ),
    .y               (es_rkd_value   ),
    .s               (div_result     ),
    .r               (mod_result     ),
    .complete        (div_complete   )
    );

mul u_mul(
    .mul_clk         (aclk           ),
    .reset           (reset          ),
    .mul_signed      (es_mul_div_sign),
    .x               (es_rj_value    ),
    .y               (es_rkd_value   ),
    .result          (mul_result     )
    );

// MEM stage
mem_stage mem_stage(
    .clk                  (aclk                ),
    .reset                (reset               ),
    //allowin
    .ws_allowin           (ws_allowin          ),
    .ms_allowin           (ms_allowin          ),
    //from es
    .es_to_ms_valid       (es_to_ms_valid      ),
    .es_to_ms_bus         (es_to_ms_bus        ),
    //to ws
    .ms_to_ws_valid       (ms_to_ws_valid      ),
    .ms_to_ws_bus         (ms_to_ws_bus        ),
    //to ds forward path
    .ms_to_ds_forward_bus (ms_to_ds_forward_bus),
    .ms_to_ds_valid       (ms_to_ds_valid      ),
    //div mul
    .div_result           (div_result          ),
    .mod_result           (mod_result          ),
    .mul_result           (mul_result          ),
    //exception
    .excp_flush           (excp_flush          ),
    .ertn_flush           (ertn_flush          ),
    .refetch_flush        (refetch_flush       ),
    .icacop_flush         (icacop_flush        ),
    //idle
    .idle_flush           (idle_flush          ),
    //tlb ins 
    .tlb_inst_stall       (ms_tlb_inst_stall   ),
    //to es
    .ms_wr_tlbehi         (ms_wr_tlbehi        ),
    .ms_flush             (ms_flush            ),
    //from cache
    .data_data_ok         (data_data_ok        ),
    .dcache_miss          (ms_dcache_miss      ),
    .data_rdata           (data_rdata          ),
    //to cache
    .data_uncache_en      (data_uncache_en     ),
    .tlb_excp_cancel_req  (data_tlb_excp_cancel_req),
    //from csr
    .csr_pg               (csr_pg              ),
    .csr_da               (csr_da              ),
    .csr_dmw0             (csr_dmw0            ),
    .csr_dmw1             (csr_dmw1            ),
    .csr_plv              (csr_plv             ),
    .csr_datm             (csr_datm            ),
    .disable_cache        (disable_cache       ),
    //from addr trans for difftest
    .data_index_diff      (data_index          ),
    .data_tag_diff        (data_tag            ),
    .data_offset_diff     (data_offset         ),
    //to addr trans 
    .data_addr_trans_en   (data_addr_trans_en  ),
    .dmw0_en              (data_dmw0_en        ),
    .dmw1_en              (data_dmw1_en        ),
    .cacop_op_mode_di     (cacop_op_mode_di    ),
    //tlb 
    .data_tlb_found       (data_tlb_found      ),
    .data_tlb_index       (data_tlb_index      ),
    .data_tlb_v           (data_tlb_v          ),
    .data_tlb_d           (data_tlb_d          ),
    .data_tlb_mat         (data_tlb_mat        ),
    .data_tlb_plv         (data_tlb_plv        )
);
// WB stage
wb_stage wb_stage(
    .clk               (aclk             ),
    .reset             (reset            ),
    //allowin
    .ws_allowin        (ws_allowin       ),
    //from ms
    .ms_to_ws_valid    (ms_to_ws_valid   ),
    .ms_to_ws_bus      (ms_to_ws_bus     ),
    //to rf: for write back
    .ws_to_rf_bus      (ws_to_rf_bus     ),
    //to ds
    .ws_to_ds_valid    (ws_to_ds_valid   ),
    //exception
    .csr_era           (ws_csr_era       ),
    .csr_esubcode      (ws_csr_esubcode  ),
    .csr_ecode         (ws_csr_ecode     ),
    .excp_flush        (excp_flush       ),     
    .ertn_flush        (ertn_flush       ),
    .refetch_flush     (refetch_flush    ),
    .icacop_flush      (icacop_flush     ),
    .csr_wr_en         (csr_wr_en        ),
    .wr_csr_addr       (wr_csr_addr      ),
    .wr_csr_data       (wr_csr_data      ),
    .va_error          (ws_va_error      ),
    .bad_va            (ws_bad_va        ),
    .excp_tlbrefill    (excp_tlbrefill   ),
    .excp_tlb          (excp_tlb         ),
    .excp_tlb_vppn     (excp_tlb_vppn    ),
    //idle
    .idle_flush        (idle_flush       ),
    //llbit
    .ws_llbit_set      (ws_llbit_set     ),
    .ws_llbit          (ws_llbit         ),
    //tlb ins
    .tlb_inst_stall    (ws_tlb_inst_stall),
    .tlbsrch_en        (tlbsrch_en       ),
    .tlbsrch_found     (tlbsrch_found    ),
    .tlbsrch_index     (tlbsrch_index    ),
    .tlbfill_en        (tlbfill_en       ),
    .tlbwr_en          (tlbwr_en         ),
    .tlbrd_en          (tlbrd_en         ),
    .invtlb_en         (invtlb_en        ),
    .invtlb_asid       (invtlb_asid      ),
    .invtlb_vpn        (invtlb_vpn       ),
    .invtlb_op         (invtlb_op        ),
    //to perf_counter
    .real_valid        (commit_inst      ),
    .real_br_inst      (br_inst          ),
    .real_icache_miss  (icache_miss      ),
    .real_dcache_miss  (dcache_miss      ),
    .real_mem_inst     (mem_inst         ),
    .real_br_pre       (br_pre           ),
    .real_br_pre_error (br_pre_error     ),
    //trace debug interface
    .debug_wb_pc       (debug0_wb_pc      ),
    .debug_wb_rf_wen   (debug0_wb_rf_wen  ),
    .debug_wb_rf_wnum  (debug0_wb_rf_wnum ),
    .debug_wb_rf_wdata (debug0_wb_rf_wdata),
    .debug_wb_inst     (debug0_wb_inst    ),

    .ws_valid_diff      (ws_valid_diff     ),
    .ws_cnt_inst_diff   (cnt_inst_diff     ),
    .ws_timer_64_diff   (timer_64_diff     ),
    .ws_inst_ld_en_diff (inst_ld_en_diff   ),
    .ws_ld_paddr_diff   (ld_paddr_diff     ),
    .ws_ld_vaddr_diff   (ld_vaddr_diff     ),
    .ws_inst_st_en_diff (inst_st_en_diff   ),
    .ws_st_paddr_diff   (st_paddr_diff     ),
    .ws_st_vaddr_diff   (st_vaddr_diff     ),
    .ws_st_data_diff    (st_data_diff      ),
    .ws_csr_rstat_en_diff (csr_rstat_en_diff    ),
    .ws_csr_data_diff   (csr_data_diff     )
);

csr u_csr(
    .clk            (aclk           ),
    .reset          (reset          ),
    //from to ds
    .rd_addr        (rd_csr_addr    ),
    .rd_data        (rd_csr_data    ),
    //timer 64
    .timer_64_out   (ds_timer_64    ),
    .tid_out        (ds_csr_tid     ),
    //from ws
    .csr_wr_en      (csr_wr_en      ),
    .wr_addr        (wr_csr_addr    ),
    .wr_data        (wr_csr_data    ),
    //interrupt
    .interrupt      (interrupt      ),
    .has_int        (has_int        ),
    //from ws
    .excp_flush     (excp_flush     ),
    .ertn_flush     (ertn_flush     ),
    .era_in         (ws_csr_era     ),
    .esubcode_in    (ws_csr_esubcode),
    .ecode_in       (ws_csr_ecode   ),
    .va_error_in    (ws_va_error    ),
    .bad_va_in      (ws_bad_va      ),
    .tlbsrch_en     (tlbsrch_en     ),
    .tlbsrch_found  (tlbsrch_found  ),
    .tlbsrch_index  (tlbsrch_index  ),
    .excp_tlbrefill (excp_tlbrefill ),
    .excp_tlb       (excp_tlb       ),
    .excp_tlb_vppn  (excp_tlb_vppn  ),
    //from ws llbit
    .llbit_in       (ws_llbit       ),
    .llbit_set_in   (ws_llbit_set   ),
    //to es
    .llbit_out      (ds_llbit       ),
    .vppn_out       (csr_vppn       ),
    //to fs
    .eentry_out     (fs_csr_eentry  ),
    .era_out        (fs_csr_era     ),
    .tlbrentry_out  (csr_tlbrentry  ),
    .disable_cache_out (disable_cache),
    //to addr trans
    .asid_out       (csr_asid        ),
    .rand_index     (rand_index      ),
    .tlbehi_out     (tlbw_tlbehi     ),
    .tlbelo0_out    (tlbw_tlbelo0    ),
    .tlbelo1_out    (tlbw_tlbelo1    ),
    .tlbidx_out     (tlbw_r_tlbidx   ),
    .pg_out         (csr_pg          ),
    .da_out         (csr_da          ),
    .dmw0_out       (csr_dmw0        ),
    .dmw1_out       (csr_dmw1        ),
    .datf_out       (csr_datf        ),
    .datm_out       (csr_datm        ), 
    .ecode_out      (tlbw_ecode      ),
    //from addr trans
    .tlbrd_en       (tlbrd_en        ),
    .tlbehi_in      (tlbr_tlbehi     ),
    .tlbelo0_in     (tlbr_tlbelo0    ),
    .tlbelo1_in     (tlbr_tlbelo1    ),
    .tlbidx_in      (tlbr_tlbidx     ),
    .asid_in        (tlbr_asid       ),
    //general use
    .plv_out        (csr_plv         ),
    //difftest
    .csr_crmd_diff      (csr_crmd_diff_0    ),
    .csr_prmd_diff      (csr_prmd_diff_0    ),
    .csr_ectl_diff      (csr_ectl_diff_0    ),
    .csr_estat_diff     (csr_estat_diff_0   ),
    .csr_era_diff       (csr_era_diff_0     ),
    .csr_badv_diff      (csr_badv_diff_0    ),
    .csr_eentry_diff    (csr_eentry_diff_0  ),
    .csr_tlbidx_diff    (csr_tlbidx_diff_0  ),
    .csr_tlbehi_diff    (csr_tlbehi_diff_0  ),
    .csr_tlbelo0_diff   (csr_tlbelo0_diff_0 ),
    .csr_tlbelo1_diff   (csr_tlbelo1_diff_0 ),
    .csr_asid_diff      (csr_asid_diff_0    ),
    .csr_save0_diff     (csr_save0_diff_0   ),
    .csr_save1_diff     (csr_save1_diff_0   ),
    .csr_save2_diff     (csr_save2_diff_0   ),
    .csr_save3_diff     (csr_save3_diff_0   ),
    .csr_tid_diff       (csr_tid_diff_0     ),
    .csr_tcfg_diff      (csr_tcfg_diff_0    ),
    .csr_tval_diff      (csr_tval_diff_0    ),
    .csr_ticlr_diff     (csr_ticlr_diff_0   ),
    .csr_llbctl_diff    (csr_llbctl_diff_0  ),
    .csr_tlbrentry_diff (csr_tlbrentry_diff_0),
    .csr_dmw0_diff      (csr_dmw0_diff_0    ),
    .csr_dmw1_diff      (csr_dmw1_diff_0    ),
    .csr_pgdl_diff      (csr_pgdl_diff_0    ),
    .csr_pgdh_diff      (csr_pgdh_diff_0    )
);

axi_bridge axi_bridge(
    .clk            (aclk           ),
    .reset          (reset          ),

    .arid           (arid           ),
    .araddr         (araddr         ),
    .arlen          (arlen          ),
    .arsize         (arsize         ),
    .arburst        (arburst        ),
    .arlock         (arlock         ),
    .arcache        (arcache        ),
    .arprot         (arprot         ),
    .arvalid        (arvalid        ),    
    .arready        (arready        ),
                            
    .rid            (rid            ),
    .rdata          (rdata          ),
    .rresp          (rresp          ),
    .rlast          (rlast          ),
    .rvalid         (rvalid         ),
    .rready         (rready         ),
                                    
    .awid           (awid           ),
    .awaddr         (awaddr         ),
    .awlen          (awlen          ),
    .awsize         (awsize         ),
    .awburst        (awburst        ),
    .awlock         (awlock         ),
    .awcache        (awcache        ),
    .awprot         (awprot         ), 
    .awvalid        (awvalid        ),
    .awready        (awready        ),
                                    
    .wid            (wid            ),
    .wdata          (wdata          ),
    .wstrb          (wstrb          ),
    .wlast          (wlast          ),
    .wvalid         (wvalid         ),
    .wready         (wready         ),
                                     
    .bid            (bid            ),
    .bresp          (bresp          ), 
    .bvalid         (bvalid         ),
    .bready         (bready         ),
                                       
    .inst_rd_req    (inst_rd_req    ),  
    .inst_rd_type   (inst_rd_type   ), 
    .inst_rd_addr   (inst_rd_addr   ),
    .inst_rd_rdy    (inst_rd_rdy    ),
    .inst_ret_valid (inst_ret_valid ),
    .inst_ret_last  (inst_ret_last  ),
    .inst_ret_data  (inst_ret_data  ),
    .inst_wr_req    (inst_wr_req    ),
    .inst_wr_type   (inst_wr_type   ),
    .inst_wr_addr   (inst_wr_addr   ),
    .inst_wr_wstrb  (inst_wr_wstrb  ),
    .inst_wr_data   (inst_wr_data   ),
    .inst_wr_rdy    (inst_wr_rdy    ),


    .data_rd_req    (data_rd_req    ),  
    .data_rd_type   (data_rd_type   ), 
    .data_rd_addr   (data_rd_addr   ),
    .data_rd_rdy    (data_rd_rdy    ),
    .data_ret_valid (data_ret_valid ),
    .data_ret_last  (data_ret_last  ),
    .data_ret_data  (data_ret_data  ),
    .data_wr_req    (data_wr_req    ),
    .data_wr_type   (data_wr_type   ),
    .data_wr_addr   (data_wr_addr   ),
    .data_wr_wstrb  (data_wr_wstrb  ),
    .data_wr_data   (data_wr_data   ),
    .data_wr_rdy    (data_wr_rdy    ),
    .write_buffer_empty (write_buffer_empty)
);

addr_trans addr_trans(
    .clk            (aclk           ),
    .asid           (csr_asid       ),
    //trans mode 
    .inst_addr_trans_en (inst_addr_trans_en),
    .data_addr_trans_en (data_addr_trans_en),
    //inst addr trans
    .inst_fetch     (fetch_en       ),
    .inst_vaddr     (inst_vaddr     ),
    .inst_dmw0_en   (inst_dmw0_en   ),
    .inst_dmw1_en   (inst_dmw1_en   ),
    .inst_index     (inst_index     ),
    .inst_tag       (inst_tag       ),
    .inst_offset    (inst_offset    ),
    .inst_tlb_found (inst_tlb_found ),
    .inst_tlb_v     (inst_tlb_v     ),
    .inst_tlb_d     (inst_tlb_d     ),
    .inst_tlb_mat   (inst_tlb_mat   ),
    .inst_tlb_plv   (inst_tlb_plv   ),
    //data addr trans 
    .data_fetch     (data_fetch     ),
    .data_vaddr     (data_vaddr     ),
    .data_dmw0_en   (data_dmw0_en   ),
    .data_dmw1_en   (data_dmw1_en   ),
    .cacop_op_mode_di (cacop_op_mode_di),
    .data_index     (data_index     ),
    .data_tag       (data_tag       ),
    .data_offset    (data_offset    ),
    .data_tlb_found (data_tlb_found ),
    .data_tlb_index (data_tlb_index ),
    .data_tlb_v     (data_tlb_v     ),
    .data_tlb_d     (data_tlb_d     ),
    .data_tlb_mat   (data_tlb_mat   ),
    .data_tlb_plv   (data_tlb_plv   ),
    //tlbwr tlbfill tlb write 
    .tlbfill_en     (tlbfill_en     ),
    .tlbwr_en       (tlbwr_en       ),
    .rand_index     (rand_index     ),
    .tlbehi_in      (tlbw_tlbehi    ),
    .tlbelo0_in     (tlbw_tlbelo0   ),
    .tlbelo1_in     (tlbw_tlbelo1   ),
    .tlbidx_in      (tlbw_r_tlbidx  ),
    .ecode_in       (tlbw_ecode     ),
    //tlbp tlb read
    .tlbehi_out     (tlbr_tlbehi    ),
    .tlbelo0_out    (tlbr_tlbelo0   ),
    .tlbelo1_out    (tlbr_tlbelo1   ),
    .tlbidx_out     (tlbr_tlbidx    ),
    .asid_out       (tlbr_asid      ),
    //invtlb 
    .invtlb_en      (invtlb_en      ),
    .invtlb_asid    (invtlb_asid    ),
    .invtlb_vpn     (invtlb_vpn     ),
    .invtlb_op      (invtlb_op      ),
    //from csr
    .csr_dmw0       (csr_dmw0       ),
    .csr_dmw1       (csr_dmw1       ),
    .csr_da         (csr_da         ),
    .csr_pg         (csr_pg         )
);

icache icache( 
    .clk            (aclk           ),
    .reset          (reset          ),
//to from cpu
    .valid          (inst_valid     ),
    .op             (inst_op        ),     
    .index          (inst_index     ),
    .tag            (inst_tag       ),
    .offset         (inst_offset    ),
    .wstrb          (inst_wstrb     ),
    .wdata          (inst_wdata     ),
    .addr_ok        (inst_addr_ok   ),
    .data_ok        (inst_data_ok   ),
    .rdata          (inst_rdata     ),
    .uncache_en     (inst_uncache_en),
    .icacop_op_en   (icacop_op_en   ),
    .cacop_op_mode  (cacop_op_mode  ),
    .cacop_op_addr_index  (data_index              ),
    .cacop_op_addr_tag    (data_tag                ),
    .cacop_op_addr_offset (data_offset             ),
    .icache_unbusy        (icache_unbusy           ),
    .tlb_excp_cancel_req  (inst_tlb_excp_cancel_req),
//to from axi 
    .rd_req         (inst_rd_req    ), 
    .rd_type        (inst_rd_type   ), 
    .rd_addr        (inst_rd_addr   ), 
    .rd_rdy         (inst_rd_rdy    ), 
    .ret_valid      (inst_ret_valid ),    
    .ret_last       (inst_ret_last  ), 
    .ret_data       (inst_ret_data  ), 
    .wr_req         (inst_wr_req    ), 
    .wr_type        (inst_wr_type   ), 
    .wr_addr        (inst_wr_addr   ), 
    .wr_wstrb       (inst_wr_wstrb  ), 
    .wr_data        (inst_wr_data   ), 
    .wr_rdy         (inst_wr_rdy    ),
    .cache_miss     (fs_icache_miss )
);

dcache dcache( 
    .clk            (aclk           ),
    .reset          (reset          ),
//to from cpu
    .valid          (data_valid     ),
    .op             (data_op        ),  
    .size           (data_size      ),   
    .index          (data_index     ),
    .tag            (data_tag       ),
    .offset         (data_offset    ),
    .wstrb          (data_wstrb     ),
    .wdata          (data_wdata     ),
    .addr_ok        (data_addr_ok   ),
    .data_ok        (data_data_ok   ),
    .rdata          (data_rdata     ),
    .uncache_en     (data_uncache_en),
    .dcacop_op_en   (dcacop_op_en   ),
    .cacop_op_mode  (cacop_op_mode  ),
    .preld_hint     (preld_hint     ),
    .preld_en       (preld_en       ),
    .tlb_excp_cancel_req (data_tlb_excp_cancel_req),
//to from axi 
    .rd_req         (data_rd_req    ), 
    .rd_type        (data_rd_type   ), 
    .rd_addr        (data_rd_addr   ), 
    .rd_rdy         (data_rd_rdy    ), 
    .ret_valid      (data_ret_valid ),    
    .ret_last       (data_ret_last  ), 
    .ret_data       (data_ret_data  ), 
    .wr_req         (data_wr_req    ), 
    .wr_type        (data_wr_type   ), 
    .wr_addr        (data_wr_addr   ), 
    .wr_wstrb       (data_wr_wstrb  ), 
    .wr_data        (data_wr_data   ), 
    .wr_rdy         (data_wr_rdy    ),
    .cache_miss     (ms_dcache_miss )
);

btb btb( 
    .clk            (aclk             ),
    .reset          (reset            ),
    //from/to if
    .fetch_pc       (fetch_pc         ),
    .fetch_en       (fetch_en         ),
    .ret_pc         (btb_ret_pc       ), 
    .taken          (btb_taken        ),
    .ret_en         (btb_en           ),
    .ret_index      (btb_index        ),
    //from id
    .operate_en     (btb_operate_en   ),
    .operate_pc     (btb_operate_pc   ),    
    .operate_index  (btb_operate_index),
    .pop_ras        (btb_pop_ras      ),
    .push_ras       (btb_push_ras     ),
    .add_entry      (btb_add_entry    ),    
    .delete_entry   (btb_delete_entry ),
    .pre_error      (btb_pre_error    ),
    .pre_right      (btb_pre_right    ),
    .target_error   (btb_target_error ),
    .right_orien    (btb_right_orien  ),
    .right_target   (btb_right_target )
);

perf_counter perf_counter(
    .clk            (aclk           ),
    .reset          (reset          ),
    .dcache_miss    (dcache_miss    ),
    .icache_miss    (icache_miss    ),
    .commit_inst    (commit_inst    ),
    .br_inst        (br_inst        ),
    .mem_inst       (mem_inst       ),
    .br_pre         (br_pre         ),
    .br_pre_error   (br_pre_error   )
);

// difftest
// from wb_stage
wire            ws_valid_diff       ;
wire            cnt_inst_diff       ;
wire    [63:0]  timer_64_diff       ;
wire    [ 7:0]  inst_ld_en_diff     ;
wire    [31:0]  ld_paddr_diff       ;
wire    [31:0]  ld_vaddr_diff       ;
wire    [ 7:0]  inst_st_en_diff     ;
wire    [31:0]  st_paddr_diff       ;
wire    [31:0]  st_vaddr_diff       ;
wire    [31:0]  st_data_diff        ;
wire            csr_rstat_en_diff   ;
wire    [31:0]  csr_data_diff       ;

wire inst_valid_diff = ws_valid_diff;
reg             cmt_valid           ;
reg             cmt_cnt_inst        ;
reg     [63:0]  cmt_timer_64        ;
reg     [ 7:0]  cmt_inst_ld_en      ;
reg     [31:0]  cmt_ld_paddr        ;
reg     [31:0]  cmt_ld_vaddr        ;
reg     [ 7:0]  cmt_inst_st_en      ;
reg     [31:0]  cmt_st_paddr        ;
reg     [31:0]  cmt_st_vaddr        ;
reg     [31:0]  cmt_st_data         ;
reg             cmt_csr_rstat_en    ;
reg     [31:0]  cmt_csr_data        ;

reg             cmt_wen             ;
reg     [ 7:0]  cmt_wdest           ;
reg     [31:0]  cmt_wdata           ;
reg     [31:0]  cmt_pc              ;
reg     [31:0]  cmt_inst            ;

reg             cmt_excp_flush      ;
reg             cmt_ertn            ;
reg     [5:0]   cmt_csr_ecode       ;
reg             cmt_tlbfill_en      ;
reg     [4:0]   cmt_rand_index      ;

// to difftest debug
reg             trap                ;
reg     [ 7:0]  trap_code           ;
reg     [63:0]  cycleCnt            ;
reg     [63:0]  instrCnt            ;

// from regfile
wire    [31:0]  regs[31:0]          ;

// from csr
wire    [31:0]  csr_crmd_diff_0     ;
wire    [31:0]  csr_prmd_diff_0     ;
wire    [31:0]  csr_ectl_diff_0     ;
wire    [31:0]  csr_estat_diff_0    ;
wire    [31:0]  csr_era_diff_0      ;
wire    [31:0]  csr_badv_diff_0     ;
wire	[31:0]  csr_eentry_diff_0   ;
wire 	[31:0]  csr_tlbidx_diff_0   ;
wire 	[31:0]  csr_tlbehi_diff_0   ;
wire 	[31:0]  csr_tlbelo0_diff_0  ;
wire 	[31:0]  csr_tlbelo1_diff_0  ;
wire 	[31:0]  csr_asid_diff_0     ;
wire 	[31:0]  csr_save0_diff_0    ;
wire 	[31:0]  csr_save1_diff_0    ;
wire 	[31:0]  csr_save2_diff_0    ;
wire 	[31:0]  csr_save3_diff_0    ;
wire 	[31:0]  csr_tid_diff_0      ;
wire 	[31:0]  csr_tcfg_diff_0     ;
wire 	[31:0]  csr_tval_diff_0     ;
wire 	[31:0]  csr_ticlr_diff_0    ;
wire 	[31:0]  csr_llbctl_diff_0   ;
wire 	[31:0]  csr_tlbrentry_diff_0;
wire 	[31:0]  csr_dmw0_diff_0     ;
wire 	[31:0]  csr_dmw1_diff_0     ;
wire 	[31:0]  csr_pgdl_diff_0     ;
wire 	[31:0]  csr_pgdh_diff_0     ;

always @(posedge aclk) begin
    if (reset) begin
        {cmt_valid, cmt_cnt_inst, cmt_timer_64, cmt_inst_ld_en, cmt_ld_paddr, cmt_ld_vaddr, cmt_inst_st_en, cmt_st_paddr, cmt_st_vaddr, cmt_st_data, cmt_csr_rstat_en, cmt_csr_data} <= 0;
        {cmt_wen, cmt_wdest, cmt_wdata, cmt_pc, cmt_inst} <= 0;
        {trap, trap_code, cycleCnt, instrCnt} <= 0;
    end else if (~trap) begin
        cmt_valid       <= inst_valid_diff          ;
        cmt_cnt_inst    <= cnt_inst_diff            ;
        cmt_timer_64    <= timer_64_diff            ;
        cmt_inst_ld_en  <= inst_ld_en_diff          ;
        cmt_ld_paddr    <= ld_paddr_diff            ;
        cmt_ld_vaddr    <= ld_vaddr_diff            ;
        cmt_inst_st_en  <= inst_st_en_diff          ;
        cmt_st_paddr    <= st_paddr_diff            ;
        cmt_st_vaddr    <= st_vaddr_diff            ;
        cmt_st_data     <= st_data_diff             ;
        cmt_csr_rstat_en<= csr_rstat_en_diff        ;
        cmt_csr_data    <= csr_data_diff            ;

        cmt_wen     <=  debug0_wb_rf_wen            ;
        cmt_wdest   <=  {3'd0, debug0_wb_rf_wnum}   ;
        cmt_wdata   <=  debug0_wb_rf_wdata          ;
        cmt_pc      <=  debug0_wb_pc                ;
        cmt_inst    <=  debug0_wb_inst              ;

        cmt_excp_flush  <= excp_flush               ;
        cmt_ertn        <= ertn_flush               ;
        cmt_csr_ecode   <= ws_csr_ecode             ;
        cmt_tlbfill_en  <= tlbfill_en               ;
        cmt_rand_index  <= rand_index               ;

        trap            <= 0                        ;
        trap_code       <= regs[10][7:0]            ;
        cycleCnt        <= cycleCnt + 1             ;
        instrCnt        <= instrCnt + inst_valid_diff;
    end
end

DifftestInstrCommit DifftestInstrCommit(
    .clock              (aclk           ),
    .coreid             (0              ),
    .index              (0              ),
    .valid              (cmt_valid      ),
    .pc                 (cmt_pc         ),
    .instr              (cmt_inst       ),
    .skip               (0              ),
    .is_TLBFILL         (cmt_tlbfill_en ),
    .TLBFILL_index      (cmt_rand_index ),
    .is_CNTinst         (cmt_cnt_inst   ),
    .timer_64_value     (cmt_timer_64   ),
    .wen                (cmt_wen        ),
    .wdest              (cmt_wdest      ),
    .wdata              (cmt_wdata      ),
    .csr_rstat          (cmt_csr_rstat_en),
    .csr_data           (cmt_csr_data   )
);

DifftestExcpEvent DifftestExcpEvent(
    .clock              (aclk           ),
    .coreid             (0              ),
    .excp_valid         (cmt_excp_flush ),
    .eret               (cmt_ertn       ),
    .intrNo             (csr_estat_diff_0[12:2]),
    .cause              (cmt_csr_ecode  ),
    .exceptionPC        (cmt_pc         ),
    .exceptionInst      (cmt_inst       )
);

DifftestTrapEvent DifftestTrapEvent(
    .clock              (aclk           ),
    .coreid             (0              ),
    .valid              (trap           ),
    .code               (trap_code      ),
    .pc                 (cmt_pc         ),
    .cycleCnt           (cycleCnt       ),
    .instrCnt           (instrCnt       )
);

DifftestStoreEvent DifftestStoreEvent(
    .clock              (aclk           ),
    .coreid             (0              ),
    .index              (0              ),
    .valid              (cmt_inst_st_en ),
    .storePAddr         (cmt_st_paddr   ),
    .storeVAddr         (cmt_st_vaddr   ),
    .storeData          (cmt_st_data    )
);

DifftestLoadEvent DifftestLoadEvent(
    .clock              (aclk           ),
    .coreid             (0              ),
    .index              (0              ),
    .valid              (cmt_inst_ld_en ),
    .paddr              (cmt_ld_paddr   ),
    .vaddr              (cmt_ld_vaddr   )
);

DifftestCSRRegState DifftestCSRRegState(
    .clock              (aclk               ),
    .coreid             (0                  ),
    .crmd               (csr_crmd_diff_0    ),
    .prmd               (csr_prmd_diff_0    ),
    .euen               (0                  ),
    .ecfg               (csr_ectl_diff_0    ),
    .estat              (csr_estat_diff_0   ),
    .era                (csr_era_diff_0     ),
    .badv               (csr_badv_diff_0    ),
    .eentry             (csr_eentry_diff_0  ),
    .tlbidx             (csr_tlbidx_diff_0  ),
    .tlbehi             (csr_tlbehi_diff_0  ),
    .tlbelo0            (csr_tlbelo0_diff_0 ),
    .tlbelo1            (csr_tlbelo1_diff_0 ),
    .asid               (csr_asid_diff_0    ),
    .pgdl               (csr_pgdl_diff_0    ),
    .pgdh               (csr_pgdh_diff_0    ),
    .save0              (csr_save0_diff_0   ),
    .save1              (csr_save1_diff_0   ),
    .save2              (csr_save2_diff_0   ),
    .save3              (csr_save3_diff_0   ),
    .tid                (csr_tid_diff_0     ),
    .tcfg               (csr_tcfg_diff_0    ),
    .tval               (csr_tval_diff_0    ),
    .ticlr              (csr_ticlr_diff_0   ),
    .llbctl             (csr_llbctl_diff_0  ),
    .tlbrentry          (csr_tlbrentry_diff_0),
    .dmw0               (csr_dmw0_diff_0    ),
    .dmw1               (csr_dmw1_diff_0    )
);

DifftestGRegState DifftestGRegState(
    .clock              (aclk       ),
    .coreid             (0          ),
    .gpr_0              (0          ),
    .gpr_1              (regs[1]    ),
    .gpr_2              (regs[2]    ),
    .gpr_3              (regs[3]    ),
    .gpr_4              (regs[4]    ),
    .gpr_5              (regs[5]    ),
    .gpr_6              (regs[6]    ),
    .gpr_7              (regs[7]    ),
    .gpr_8              (regs[8]    ),
    .gpr_9              (regs[9]    ),
    .gpr_10             (regs[10]   ),
    .gpr_11             (regs[11]   ),
    .gpr_12             (regs[12]   ),
    .gpr_13             (regs[13]   ),
    .gpr_14             (regs[14]   ),
    .gpr_15             (regs[15]   ),
    .gpr_16             (regs[16]   ),
    .gpr_17             (regs[17]   ),
    .gpr_18             (regs[18]   ),
    .gpr_19             (regs[19]   ),
    .gpr_20             (regs[20]   ),
    .gpr_21             (regs[21]   ),
    .gpr_22             (regs[22]   ),
    .gpr_23             (regs[23]   ),
    .gpr_24             (regs[24]   ),
    .gpr_25             (regs[25]   ),
    .gpr_26             (regs[26]   ),
    .gpr_27             (regs[27]   ),
    .gpr_28             (regs[28]   ),
    .gpr_29             (regs[29]   ),
    .gpr_30             (regs[30]   ),
    .gpr_31             (regs[31]   )
);

endmodule
