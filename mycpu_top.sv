`include "a_defines.svh"

// 我们是双提交
`define CPU_2CMT

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

    //debug TODO: chiplab only. However, chiplab can be modified (doge)
`ifdef _VERILATOR
    input           break_point,
    input           infor_flag,
    input  [ 4:0]   reg_num,
    output          ws_valid,
    output [31:0]   rf_rdata,
`endif

`ifdef _VERILATOR
    // chiplab 的接口
    output [31:0] debug0_wb_pc,
    output      debug0_wb_rf_wen,
    output [ 4:0] debug0_wb_rf_wnum,
    output [31:0] debug0_wb_rf_wdata
    // ,output [31:0] debug0_wb_inst
`ifdef CPU_2CMT
    // 我们是双提交
    ,output [31:0] debug1_wb_pc,
    output      debug1_wb_rf_wen,
    output [ 4:0] debug1_wb_rf_wnum,
    output [31:0] debug1_wb_rf_wdata
`endif
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

parameter int CDB_COUNT = 2;
parameter int WKUP_COUNT = 2;

wire clk;
wire rst_n;

assign clk = aclk;
assign rst_n = aresetn;

logic flush; // wire, 全局 flush 信号
logic stall;
csr_t csr;

/*============================== Branch Predicting ==============================*/

handshake_if #(b_f_pkg_t) b_fifo_handshake();
correct_info_t [1:0] correct_infos;

logic [31:0] redir_addr;

bpu bpu_inst(
    .clk(clk),
    .rst_n(rst_n),
    .flush_i(flush),
    .redir_addr_i(redir_addr),

    .correct_infos_i(correct_infos),
    .sender(b_fifo_handshake.sender)
);

handshake_if #(b_f_pkg_t) fifo_f_handshake();

// 实际上是一个 skidbuf
fifo #(
    .DEPTH(2),
    .BYPASS(1),
    .T(b_f_pkg_t)
) b_f_fifo (
    .clk(clk),
    .rst_n(rst_n & ~flush),
    .receiver(b_fifo_handshake.receiver),
    .sender(fifo_f_handshake.sender)
);

/*============================== Inst Fetch ==============================*/

handshake_if #(f_d_pkg_t) f_fifo_handshake();

commit_icache_req_t commit_icache_req;
logic   [1:0]   icache_cacop_flush;
tlb_exception_t icache_cacop_tlb_exc;
logic   [31:0]  icache_cacop_bvaddr;
logic   commit_icache_valid;
logic   icache_commit_ready;
logic   icache_commit_valid;

tlb_write_req_t tlb_update_pkg;

logic icache_axi_addr_valid;
logic [31:0] icache_axi_addr;
logic [7:0] icache_axi_len;
logic axi_icache_ready;
logic axi_icache_valid;
logic [31:0] axi_icache_data;

icache # (
    .WAY_NUM(2), // default
    .WORD_SIZE(64), // default
    .DATA_DEPTH(128), // default
    .BLOCK_SIZE(4 * 64) // default
) icache_inst (
    .clk(clk),
    .rst_n(rst_n),
    .flush_i(flush),
    // CSR
    .csr_i(csr),
    // cpu 侧信号
    .fetch_icache_receiver(fifo_f_handshake.receiver),
    .icache_decoder_sender(f_fifo_handshake.sender),

    .addr_valid_o(icache_axi_addr_valid),
    .addr_o(icache_axi_addr),
    .data_len_o(icache_axi_len),
    .axi_resp_ready_i(axi_icache_ready),
    .axi_data_valid_i(axi_icache_valid),
    .axi_data_i(axi_icache_data),

    .commit_icache_req(commit_icache_req), // commit维护cache时的请求
    .icache_cacop_flush_o(icache_cacop_flush),
    .icache_cacop_tlb_exc(icache_cacop_tlb_exc),
    .icache_cacop_bvaddr(icache_cacop_bvaddr),
    .commit_req_valid_i(commit_icache_valid), // commit发维护请求需要读（cacop op为2的时候）的时候
    .commit_resp_ready_o(icache_commit_ready), // 状态处理完毕，即为NORMAL状态时
    .commit_resp_valid_o(icache_commit_valid), // cache向提交级反馈结果
    .tlb_write_req_i(tlb_update_pkg)
);

/*============================== Decoder ==============================*/

handshake_if #(.T(f_d_pkg_t)) fifo_d_handshake();

// decode 前的队列
fifo #(
    .DEPTH(`D_BEFORE_QUEUE_DEPTH),
    .BYPASS(0), // 不允许 bypass ，因为这个 fifo 也充当了 d 级的流水寄存器。
    .T(f_d_pkg_t)
) f_d_fifo (
    .clk(clk),
    .rst_n(rst_n & !flush),
    .receiver(f_fifo_handshake.receiver),
    .sender(fifo_d_handshake.sender)
);

handshake_if #(.T(d_r_pkg_t)) d_fifo_handshake();

// decoder 是纯组合逻辑的，其流水寄存器是前面的FIFO
decoder decoder_inst(
    .receiver(fifo_d_handshake.receiver),
    .sender(d_fifo_handshake.sender)
);

handshake_if #(.T(d_r_pkg_t)) fifo_r_handshake();

// decoder 后的队列

fifo #(
    .DEPTH(`D_AFTER_QUEUE_DEPTH),
    .BYPASS(0), // 不允许 BYPASS ，充当前后端之间的流水寄存器
    .T(d_r_pkg_t)
) d_r_fifo (
    .clk(clk),
    .rst_n(rst_n & !flush),
    .receiver(d_fifo_handshake.receiver),
    .sender(fifo_r_handshake.sender)
);

/*============================== Rename ==============================*/

handshake_if #(.T(r_p_pkg_t)) r_p_handshake();

logic [1:0] c_retire; // 这个是c级的retire信号，含义是：要提交指令且该指令要写ARF，写ARF信息在infos里面
retire_pkg_t [1:0] c_retire_infos;
logic [1:0] commit_arf_we;
logic [1:0][31:0] commit_arf_data;
logic [1:0][4:0] commit_arf_areg;
logic [1:0][5:0] commit_arf_preg;
logic [1:0]      commit_arf_check;

assign c_retire = commit_arf_we;
for(genvar i = 0; i < 2; i += 1) begin
    always_comb begin
        c_retire_infos[i].w_valid = commit_arf_we[i];
        c_retire_infos[i].arf_id = commit_arf_areg[i];
        c_retire_infos[i].rob_id = commit_arf_preg[i]; // TODO
        c_retire_infos[i].data = commit_arf_data[i];
        c_retire_infos[i].w_check = commit_arf_check[i];
    end
end

logic [1:0] retire_request;
rename # () rename (
    .clk(clk),
    .rst_n(rst_n),
    .c_flush_i(flush),

    .d_r_receiver(fifo_r_handshake.receiver),
    .r_p_sender(r_p_handshake.sender),

    .c_retire_i(retire_request),
    .c_retire_info_i(c_retire_infos)
);

handshake_if #(.T(p_i_pkg_t)) p_alu_handshake_0();
handshake_if #(.T(p_i_pkg_t)) p_alu_handshake_1();
handshake_if #(.T(p_i_pkg_t)) p_lsu_handshake();
handshake_if #(.T(p_i_pkg_t)) p_mdu_handshake();

// dispatch 和 rob 交互信息
dispatch_rob_pkg_t dispatch_rob_pkg [1:0];
rob_dispatch_pkg_t rob_dispatch_pkg [1:0];
cdb_dispatch_pkg_t cdb_dispatch_pkg [1:0];

dispatch # () p_dispatch(
    .clk(clk),
    .rst_n(rst_n),
    .flush_i(flush),

    .cdb_dispatch_i(cdb_dispatch_pkg), // cdb信号转发进来
    .rob_dispatch_i(rob_dispatch_pkg), // 从rob读的数据

    .dispatch_rob_o(dispatch_rob_pkg), // 写入rob的信息，和要读的rob_id

    .r_p_receiver(r_p_handshake.receiver),

    .p_alu_sender_0(p_alu_handshake_0.sender),
    .p_alu_sender_1(p_alu_handshake_1.sender),
    .p_lsu_sender(p_lsu_handshake.sender),
    .p_mdu_sender(p_mdu_handshake.sender)
);

// TODO 将接口信号拆分为握手信号和传输数据
logic [1:0][31:0] cdb_data;
logic [1:0][5 :0] cdb_reg_id;
logic [1:0]       cdb_valid;

// TODO 增加receiver接口
handshake_if #(.T(cdb_info_t)) fu_cdb  [3 : 0] ();
handshake_if #(.T(cdb_info_t)) fu_fifo [3 : 0] ();
cdb_info_t fu_cdb_data [3 : 0];
for (genvar i = 0; i < 4; i++) begin
    assign fu_fifo[i].data = fu_cdb_data[i];
end

logic [WKUP_COUNT - 1 : 0][31:0] wkup_data;
logic [WKUP_COUNT - 1 : 0][5 :0] wkup_reg_id;
logic [WKUP_COUNT - 1 : 0]       wkup_valid;

alu_iq #(
    .CDB_COUNT(CDB_COUNT),
    .WKUP_COUNT(WKUP_COUNT)
) i_alu_iq_0 (
    .clk(clk),
    .rst_n(rst_n),
    .flush(flush),

    .choose(p_alu_handshake_0.data.inst_choose & {2{p_alu_handshake_0.ready}} & {2{p_alu_handshake_0.valid}}), /* 2024/07/24 fix*/ 
    .p_di_c(p_alu_handshake_0.data.di), //两条指令各自的译码信息  TODO
    .p_data_c(p_alu_handshake_0.data.data), //从P级传入的两条指令各自的两个data数值
    .p_reg_id_c(p_alu_handshake_0.data.preg), // 从P级传入的两条指令各自的两个rob_id(源寄存器数据的物理寄存器编号)
    .other_ready(p_alu_handshake_0.valid),
    .p_valid_c(p_alu_handshake_0.data.data_valid),   
    
    .entry_ready_o(p_alu_handshake_0.ready), // ready信号

    .cdb_data_i(cdb_data), // cdb传入的数据
    .cdb_reg_id_i(cdb_reg_id), // cdb传入的物理寄存器编号
    .cdb_valid_i(cdb_valid), // cdb要写寄存器

    .wkup_data_i(wkup_data),
    .wkup_reg_id_i(wkup_reg_id),
    .wkup_valid_i(wkup_valid),

    .wkup_data_o(wkup_data[0]),
    .wkup_reg_id_o(wkup_reg_id[0]),
    .wkup_valid_o(wkup_valid[0]),

    .result_o(fu_cdb_data[0]),
    .fifo_ready(fu_fifo[0].ready),
    .excute_valid_o(fu_fifo[0].valid)
);

fifo # (
    .BYPASS(0),
    .T(cdb_info_t)
) alu_iq_fifo_0 (
    .clk(clk),
    .rst_n(rst_n & !flush),
    .receiver(fu_fifo[0].receiver),
    .sender(fu_cdb[0].sender)
);

alu_iq #(
    .CDB_COUNT(CDB_COUNT),
    .WKUP_COUNT(WKUP_COUNT)
) i_alu_iq_1 (
    .clk(clk),
    .rst_n(rst_n),
    .flush(flush),

    .choose(p_alu_handshake_1.data.inst_choose & {2{p_alu_handshake_1.ready}} & {2{p_alu_handshake_1.valid}}), /* 2024/07/24 fix*/
    .p_di_c(p_alu_handshake_1.data.di),
    .p_data_c(p_alu_handshake_1.data.data),
    .p_reg_id_c(p_alu_handshake_1.data.preg),
    .other_ready(p_alu_handshake_1.valid),
    .p_valid_c(p_alu_handshake_1.data.data_valid),

    .entry_ready_o(p_alu_handshake_1.ready),

    .cdb_data_i(cdb_data),
    .cdb_reg_id_i(cdb_reg_id),
    .cdb_valid_i(cdb_valid),

    .wkup_data_i(wkup_data),
    .wkup_reg_id_i(wkup_reg_id),
    .wkup_valid_i(wkup_valid),

    .wkup_data_o(wkup_data[1]),
    .wkup_reg_id_o(wkup_reg_id[1]),
    .wkup_valid_o(wkup_valid[1]),

    .result_o(fu_cdb_data[1]),
    .fifo_ready(fu_fifo[1].ready),
    .excute_valid_o(fu_fifo[1].valid)
);

// handshake_if #(.T(cdb_info_t)) alu_1_cdb();

fifo # (
    .BYPASS(0),
    .T(cdb_info_t)
) alu_iq_fifo_1 (
    .clk(clk),
    .rst_n(rst_n & !flush),
    .receiver(fu_fifo[1].receiver),
    .sender(fu_cdb[1].sender)
);

handshake_if #(.T(iq_lsu_pkg_t)) cpu_lsu_if();
handshake_if #(.T(lsu_iq_pkg_t)) lsu_cpu_if();

lsu_iq # (
    .CDB_COUNT(CDB_COUNT),
    .WKUP_COUNT(WKUP_COUNT)
) i_lsu_iq (
    .clk(clk),
    .rst_n(rst_n),
    .flush(flush),

    .choose(p_lsu_handshake.data.inst_choose & {2{p_lsu_handshake.ready}} & {2{p_lsu_handshake.valid}}), /* 2024/07/24 fix*/
    .p_di_i(p_lsu_handshake.data.di),
    .p_data_i(p_lsu_handshake.data.data),
    .p_reg_id_i(p_lsu_handshake.data.preg),
    .p_valid_i(p_lsu_handshake.data.data_valid),
    .other_ready(p_lsu_handshake.valid),

    .entry_ready_o(p_lsu_handshake.ready),

    .cdb_data_i(cdb_data),
    .cdb_reg_id_i(cdb_reg_id),
    .cdb_valid_i(cdb_valid),

    .wkup_data_i(wkup_data),
    .wkup_reg_id_i(wkup_reg_id),
    .wkup_valid_i(wkup_valid),

    .iq_lsu_valid_o(cpu_lsu_if.valid),
    .iq_lsu_ready_i(cpu_lsu_if.ready),
    .iq_lsu_req_o(cpu_lsu_if.data),

    .lsu_iq_valid_i(lsu_cpu_if.valid),
    .lsu_iq_ready_o(lsu_cpu_if.ready),
    .lsu_iq_resp_i(lsu_cpu_if.data),

    .result_o(fu_cdb_data[2]),
    .fifo_ready(fu_fifo[2].ready),
    .entry_valid_o(fu_fifo[2].valid)
);

// handshake_if #(.T(cdb_info_t)) lsu_cdb();

fifo # (
    .BYPASS(0),
    .T(cdb_info_t)
) lsu_iq_fifo (
    .clk(clk),
    .rst_n(rst_n & !flush),
    .receiver(fu_fifo[2].receiver),
    .sender(fu_cdb[2].sender)
);

mdu_iq # (
    .CDB_COUNT(CDB_COUNT),
    .WKUP_COUNT(WKUP_COUNT)
) i_mdu_iq (
    .clk(clk),
    .rst_n(rst_n),
    .flush(flush),

    .choose(p_mdu_handshake.data.inst_choose & {2{p_mdu_handshake.ready}} & {2{p_mdu_handshake.valid}}), /* 2024/07/24 fix*/
    .p_di_i(p_mdu_handshake.data.di),
    .p_data_i(p_mdu_handshake.data.data),
    .p_reg_id_i(p_mdu_handshake.data.preg),
    .p_valid_i(p_mdu_handshake.data.data_valid),
    .other_ready(p_mdu_handshake.valid),

    .entry_ready_o(p_mdu_handshake.ready),

    .cdb_data_i(cdb_data),
    .cdb_reg_id_i(cdb_reg_id),
    .cdb_valid_i(cdb_valid),

    .wkup_data_i(wkup_data),
    .wkup_reg_id_i(wkup_reg_id),
    .wkup_valid_i(wkup_valid),

    .result_o(fu_cdb_data[3]),
    .fifo_ready(fu_fifo[3].ready),
    .entry_valid_o(fu_fifo[3].valid)
);

// handshake_if #(.T(cdb_info_t)) mdu_cdb();

fifo # (
    .BYPASS(0),
    .T(cdb_info_t)
) mdu_iq_fifo (
    .clk(clk),
    .rst_n(rst_n & !flush),
    .receiver(fu_fifo[3].receiver),
    .sender(fu_cdb[3].sender)
);

cdb_info_t [1:0] cdb_infos;

cdb #(
    .PORT_COUNT(4)
) cdb (
    .clk(clk),
    .rst_n(rst_n),
    .flush(flush),

    .fifo_handshake(fu_cdb),
    .cdb_data_o(cdb_infos)
);

cdb_rob_pkg_t cdb_rob_pkgs [1:0];
always_comb begin
    for (integer i = 0; i < 2; i++) begin
        cdb_data[i]               =  cdb_infos[i].w_data;
        cdb_reg_id[i]             =  cdb_infos[i].rob_id;
        cdb_valid[i]              =  cdb_infos[i].w_reg;

        cdb_dispatch_pkg[i].w_preg =  cdb_infos[i].rob_id;
        cdb_dispatch_pkg[i].w_data =  cdb_infos[i].w_data;
        cdb_dispatch_pkg[i].w_reg  =  cdb_infos[i].w_reg;
        // cdb_dispatch_pkg[i].w_mem  =  /* TODO */
        cdb_dispatch_pkg[i].w_valid=  cdb_infos[i].r_valid;           

        cdb_rob_pkgs[i].s_data    =  cdb_infos[i].s_data;
        cdb_rob_pkgs[i].w_preg    =  cdb_infos[i].rob_id;
        cdb_rob_pkgs[i].w_data    =  cdb_infos[i].w_data;
        cdb_rob_pkgs[i].w_valid   =  cdb_infos[i].r_valid;
        cdb_rob_pkgs[i].ctrl      =  cdb_infos[i].ctrl/* TODO */; 
        cdb_rob_pkgs[i].lsu_info  =  cdb_infos[i].lsu_info; 
    end
end

rob_commit_pkg_t commit_infos [1:0];
logic [1:0] rob_commit_valid;
logic [1:0] commit_request;

rob # () rob (
    .clk(clk),
    .rst_n(rst_n),
    .flush_i(flush),

    .dispatch_info_i(dispatch_rob_pkg),
    .cdb_info_i(cdb_rob_pkgs),

    .rob_dispatch_o(rob_dispatch_pkg),
    .commit_req(commit_request),
    .commit_info_o(commit_infos),
    .commit_valid(rob_commit_valid)
);

/* 2024/07/24 fix*/
// handshake_if #(.T(commit_cache_req_t)) commit_cache_if();
// handshake_if #(.T(cache_commit_resp_t)) cache_commit_if();

commit_cache_req_t commit_cache_req;
cache_commit_resp_t cache_commit_resp;

commit_axi_req_t commit_axi_req;
axi_commit_resp_t axi_commit_resp;
logic commit_axi_arvalid;
logic axi_commit_arready;
logic axi_commit_rvalid;
logic axi_commit_last;
logic commit_axi_awvalid;
logic axi_commit_awready;
logic commit_axi_wvalid;
logic commit_axi_wlast;
logic axi_commit_wready;

word_t commit_debug_pc [1:0];

commit # () commit(
    .clk(clk),
    .rst_n(rst_n),
    .flush(flush),
    // 给Dcache使用
    .stall_o(stall),

    .hard_is_i(
    `ifdef _VERILATOR
        intrpt
    `endif
    `ifdef _FPGA
        ext_int
    `endif
    ),

    .rob_commit_valid_i(rob_commit_valid),
    .rob_commit_i(commit_infos),

    .commit_request_o(commit_request),
    .retire_request_o(retire_request),

    .commit_cache_req_o(commit_cache_req),
    .cache_commit_resp_i(cache_commit_resp),

    .commit_axi_arvalid_o(commit_axi_arvalid),
    .axi_commit_arready_i(axi_commit_arready),
    .axi_commit_rvalid_i(axi_commit_rvalid),
    .axi_commit_last_i(axi_commit_last),
    .commit_axi_awvalid_o(commit_axi_awvalid),
    .axi_commit_awready_i(axi_commit_awready), /* 2024/07/24 fix axi_commit_arready -> axi_commit_awready*/
    .commit_axi_wvalid_o(commit_axi_wvalid),
    .commit_axi_wlast_o(commit_axi_wlast),
    .axi_commit_wready_i(axi_commit_wready),

    .commit_axi_req_o(commit_axi_req),
    .axi_commit_resp_i(axi_commit_resp),

    .commit_debug_pc_o(commit_debug_pc),
    .commit_arf_we_o(commit_arf_we),
    .commit_arf_data_o(commit_arf_data),
    .commit_arf_areg_o(commit_arf_areg),
    .commit_arf_preg_o(commit_arf_preg), // TODO: recheck
    .commit_arf_check_o(commit_arf_check),

    .correct_info_o(correct_infos),
    .redir_addr_o(redir_addr),
    
    .csr_o(csr),
    .tlb_write_req_o(tlb_update_pkg),

    .commit_icache_req_o(commit_icache_req),
    .icache_cacop_flush_i(icache_cacop_flush),
    .icache_cacop_tlb_exc_i(icache_cacop_tlb_exc),
    .icache_cacop_bvaddr_i(icache_cacop_bvaddr),
    .commit_icache_valid_o(commit_icache_valid),
    .icache_commit_ready_i(icache_commit_ready),
    .icache_commit_valid_i(icache_commit_valid)
);

`ifdef _VERILATOR
assign debug0_wb_pc = commit_debug_pc[0];
assign debug0_wb_rf_wen = commit_arf_we[0];
assign debug0_wb_rf_wnum = commit_arf_areg[0];
assign debug0_wb_rf_wdata = commit_arf_data[0];

`ifdef CPU_2CMT
assign debug1_wb_pc = commit_debug_pc[1];
assign debug1_wb_rf_wen = commit_arf_we[1];
assign debug1_wb_rf_wnum = commit_arf_areg[1];
assign debug1_wb_rf_wdata = commit_arf_data[1];
`endif
`endif

`ifdef _FPGA
assign debug_wb_pc = commit_debug_pc[0];
assign debug_wb_rf_we = {4{commit_arf_we[0]}};
assign debug_wb_rf_wnum = commit_arf_areg[0];
assign debug_wb_rf_wdata = commit_arf_data[0];
`endif

//我要一个硬中断
dcache # () dcache(
    .clk(clk),
    .rst_n(rst_n),
    .flush_i(flush),
    .stall_i(stall),

    .csr_i(csr),
    .cpu_lsu_receiver(cpu_lsu_if.receiver),
    .lsu_cpu_sender(lsu_cpu_if.sender),

    .commit_cache_req(commit_cache_req), /* 2024/07/24 fix interface to struct*/
    .cache_commit_resp(cache_commit_resp), /* 2024/07/24 fix interface to struct*/

    .tlb_write_req_i(tlb_update_pkg)
);

/*============================== 2x1 AXI Bridge ==============================*/
logic [10:0] rubblish_wire;
assign wid = '0;
axi_convert # (
    .S_COUNT(2), // 连接两个cache, == 2
    .M_COUNT(1), // 连接总线，== 1
    .DATA_WIDTH(32), // 数据位宽 官方包是 32 位，需要使用 burst 传输
    .ADDR_WIDTH(32), // 地址位宽， 32 位
    .S_ID_WIDTH(4), // 官方包是 4 
    .M_ID_WIDTH(4), /* 2024/07/24 fix */
    .M_ADDR_WIDTH(32'd32), // ICACHE和DCACHE的数据位宽应该都是32位？TODO: 取决于物理地址宽度
    .M_CONNECT_WRITE(2'b01) // TODO: 设置成仅 DCache 侧可写
) axi_crossbar_2x1_inst (
    .clk(aclk),
    .rst_n(aresetn), // TODO: recheck
    /*
     * AXI slave interfaces
     */
    .s_axi_awid('0),
    .s_axi_awaddr({icache_axi_addr, commit_axi_req.waddr}),
    .s_axi_awlen({icache_axi_len - 8'b1, commit_axi_req.wlen - 8'b1}),
    .s_axi_awsize({3'b010,3'b010}),
    .s_axi_awburst({2'b01,2'b01}),
    .s_axi_awlock('0),
    .s_axi_awcache('0),
    .s_axi_awprot('0),
    .s_axi_awqos('0),
    .s_axi_awuser('0),
    .s_axi_awvalid({1'b0,commit_axi_awvalid}),
    .s_axi_awready({rubblish_wire[0],axi_commit_awready}),
    .s_axi_wdata({32'b0, commit_axi_req.wdata}),
    .s_axi_wstrb({4'b0, commit_axi_req.strb}),
    .s_axi_wlast({'0, commit_axi_wlast}),
    .s_axi_wuser('0),
    .s_axi_wvalid({1'b0,commit_axi_wvalid}),
    .s_axi_wready({rubblish_wire[1], axi_commit_wready}),
    .s_axi_bready('1),
    .s_axi_arid({4'b0001, 4'b0000}),
    .s_axi_araddr({icache_axi_addr, commit_axi_req.raddr}), /*2024/07/24 fix waddr -> raddr*/
    .s_axi_arlen({icache_axi_len - 8'b1, commit_axi_req.rlen - 8'b1}), /*2024/07/24 fix wlen -> rlen*/
    .s_axi_arsize({3'b010,3'b010}),
    .s_axi_arburst({2'b01,2'b01}),
    .s_axi_arlock('0),
    .s_axi_arcache('0),
    .s_axi_arprot('0),
    .s_axi_arqos('0),
    .s_axi_aruser('0),
    .s_axi_arvalid({icache_axi_addr_valid, commit_axi_arvalid}),
    .s_axi_arready({axi_icache_ready, axi_commit_arready}),
    .s_axi_rid(),
    .s_axi_rdata({axi_icache_data, axi_commit_resp.rdata}),
    .s_axi_rresp(),
    .s_axi_rlast(axi_commit_last),
    .s_axi_ruser(),
    .s_axi_rvalid({axi_icache_valid, axi_commit_rvalid}),
    .s_axi_rready('1),

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
    .m_axi_awregion(/*TODO: 悬空, 但是顶层模块不会用到*/),
    .m_axi_awuser(/*TODO: 悬空，在默认参数下不会使用到这个信号*/),
    .m_axi_awvalid(awvalid),
    .m_axi_awready(awready),
    .m_axi_wdata(/*TODO*/ wdata),
    .m_axi_wstrb(wstrb),
    .m_axi_wlast(wlast),
    .m_axi_wuser(),
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
    .m_axi_arburst(arburst),
    .m_axi_arlock(arlock),
    .m_axi_arcache(arcache),
    .m_axi_arprot(arprot),
    .m_axi_arqos(/*TODO: 悬空*/),
    .m_axi_arregion(/*TODO: 悬空, 顶层模块没有 region 信息*/),
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

/* 不出bug
____________________████████████████__________████████████
__________________██░░░░░░░░░░░░░░░░████__████░░░░░░░░░░░░██
________________██░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░██
______________██░░░░░░░░░░░░░░██████░░░░░░██░░░░░░░░░░░░░░░░░░██
______________██░░░░░░░░██████░░░░░░██████░░██░░░░░░████████░░██
____________██░░░░░░████░░░░░░░░░░░░░░░░██████░░████░░░░░░░░████
__________██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░██████
________██░░░░░░░░░░░░░░░░░░░░░░░░░░████████████░░░░░░░░░░████████░░░░██
________██░░░░░░░░░░░░░░░░░░██████████░░░░░░████████░░░░████░░░░████░░░░██
______████░░░░░░░░░░░░░░██████░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░██████
____██░░░░░░░░░░░░░░░░░░░░░░░░░░░░██████████████████░░░░██████████████████
__██░░░░░░░░░░░░░░░░░░░░██████████__████████______████████__██████████______██
__██░░░░░░░░░░░░░░░░░░░░██____________██__██████____██__________██████__██______██
██░░░░░░░░░░░░░░░░░░░░░░░░██______████████__████████________████__████████████
░░░░░░░░░░░░░░░░░░░░░░░░░░██████████████████░░░░░░████████████████░░░░░░██
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░░░██
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████░░░░░░░░██░░░░░░░░░░░░████
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████░░░░░░░░░░░░░░██████████████
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░██
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
░░░░░░░░░░░░░░░░░░░░░░██████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░████
░░░░░░░░░░░░░░░░░░░░██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██████████████████████████████▒▒▒▒██
░░░░░░░░░░░░░░░░░░██▒▒▒▒██████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
░░░░░░░░░░░░░░░░░░██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██████████████████████████████████          没有bug对吧
░░░░░░░░░░░░░░░░░░░░████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████████████████████████████████████
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████
▓▓████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████
▓▓▓▓▓▓██████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
▓▓▓▓▓▓▓▓▓▓▓▓██████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████████████████▓▓▓▓██
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██
*/
