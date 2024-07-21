`include "a_defines.svh"

function cache_tag_t get_cache_tag(
    input logic [31:0] addr,
    input logic v,
    input logic d
);
    cache_tag_t cache_tag;
    cache_tag.tag = addr[31:20];
    cache_tag.v = v;
    cache_tag.d = d;

    return cache_tag;
endfunction

function logic [31:0] get_data_mask(
    input logic [31:0] data,
    input logic [3:0] mask
);
    logic [31:0] data_mask;

    assign data_mask[7:0]   = mask[0] ? data[7:0]   : '0;
    assign data_mask[15:8]  = mask[1] ? data[15:8]  : '0;
    assign data_mask[23:16] = mask[2] ? data[23:16] : '0;
    assign data_mask[31:24] = mask[3] ? data[31:24] : '0;

    return data_mask;
endfunction

function logic [1:0] get_way_choose(
    input logic hit
);
    return hit ? 2'b10 : 2'b01;
endfunction

module commit #(
    parameter int CACHE_BLOCK_NUM = 4;
    parameter int CPU_ID = 0;
) (
    input   logic   clk,
    input   logic   rst_n,
    // 唯一一处flush的输出
    output  logic   flush,
    output  logic   stall_o,

    // 可能没用
    input   logic   [1:0]   rob_commit_valid_i,
    input   rob_commit_pkg_t [1:0]  rob_commit_i,

    // 给ROB的输出信号，确定提交相关指令
    output  logic   commit_ready_o,
    output  logic   [1:0]   commit_request_o,

    // commit与DCache的接口
    output  commit_cache_req_t  commit_cache_req_o,
    input   cache_commit_resp_t cache_commit_resp_i,
    //input   tag.    cache_commit_tag_i,     // TODO：返回了tag的信息
    // commit与cache的握手信号
    input   logic   commit_cache_ready_i,
    output  logic   commit_cache_valid_o,
    input   logic   cache_commit_valid_i,
    output  logic   cache_commit_ready_o,

    // commit与AXI的接口
    // 接口好多啊
    output  commit_axi_req_t    commit_axi_req_o,
    input   axi_commit_resp_t   axi_commit_resp_i,
    // 按照axi-crossbar的逻辑设计
    output  logic   commit_axi_ready_o,
    output  logic   commit_axi_valid_o,
    output  logic   commit_axi_last_o,
    input   logic   axi_commit_valid_i,
    input   logic   axi_commit_ready_i,

    // commit与ARF的接口
    output  logic   [1:0]   commit_arf_we_o,
    output  word_t  [1:0]   commit_arf_data_o,
    output  word_t  [1:0]   commit_arf_areg_o,

    // commit与BPU的接口
    output  correct_info_t [1:0]    correct_info_o,

    //commit与两个外部tlb/mmu的接口
    output  csr_t            csr_o,
    output  tlb_write_req_t  tlb_write_req_o,

    // commit与ICache的握手信号
    output  commit_icache_req_t     commit_icache_req_o,
    // ICache返回TLB异常
    input   tlb_exception_t         icache_commit_tlb_exp_i,
    // 2'b01 tlb_exc, 2'b10 tag_miss, other normal
    input   logic [1:0]             icache_commit_tlb_miss_i,
    output  logic   commit_icache_ready_o,
    output  logic   commit_icache_valid_o,
    input   logic   icache_commit_ready_i,
    input   logic   icache_commit_valid_i
);

// ------------------------------------------------------------------
// 处理指令提交逻辑
// 是否将整个提交阻塞
logic stall, stall_q;
assign stall_o = stall;
assign commit_ready_o = ~stall;
assign commit_icache_ready_o = commit_ready_o;

assign commit_cache_ready = '1;

logic [31:0] commit_data, commit_data_q;
assign commit_data_o = commit_data_q;

// 维护一个提交级的时钟
logic [5:0] timer_64, timer_64_q;

// 正常情况都不需要进入状态机，直接提交即可
// 特殊处理
// - cache没有命中（在LSU中判断）：进入状态机
// - 分支预测失败
// - 写csr指令
// - 异常处理
// - tlb维护指令
// - is_uncached指令
// - cache维护指令
// - dbar,ibar
// 特殊处理均只允许单条提交
//TODO : 最后提交的逻辑，ibar（不实现）,cacop的异常没有处理
always_comb begin
    commit_request_o[0] = rob_commit_valid_i[0] & commit_ready_o;

    commit_request_o[1] = rob_commit_valid_i[0] &
                          rob_commit_valid_i[1] &
                          ~rob_commit_i[0].first_commit &
                          ~rob_commit_i[1].first_commit &
                          commit_ready_o;
end

// 处理对ARF的接口
always_comb begin
    commit_arf_we_o = '0;
    commit_arf_data_o = '0;
    commit_arf_areg_o = '0;

    if(~stall) begin
        commit_arf_we_o[1] = commit_request_o[1] & rob_commit_i[1].w_reg;
        commit_arf_data_o[1] = rob_commit_i[1].w_data;
        commit_arf_areg_o[1] = rob_commit_i[1].w_areg;
    end
//上面这个提交不太对TODO

    if(is_csr_fix[0]) begin
        commit_arf_we_o[0]   = rob_commit_valid_i[0] & !cur_exception;
        commit_arf_data_o[0] = commit_csr_data_o;
        commit_arf_areg_o[0] = rob_commit_i[0].w_areg;
    end
    if (rdcnt_en[0]) begin
        commit_arf_we_o[0]   = rob_commit_valid_i[0] & !cur_exception;
        commit_arf_data_o[0] = rdcnt_data_o;
        commit_arf_areg_o[0] = rob_commit_i[0].w_areg;
    end
    //csr指令和rdcnt指令的提交，已完成

    else if(ls_fsm_q == S_NORMAL) begin
        commit_arf_we_o[0]   = commit_request_o[0] & rob_commit_i[0].w_reg;
        commit_arf_data_o[0] = rob_commit_i[0].w_data;
        commit_arf_areg_o[0] = rob_commit_i[0].w_areg;
    end
    else if(ls_fsm_q == S_UNCACHED) begin
        if(axi_commit_valid_i) begin
            commit_arf_we_o[0]   = |rob_commit_q.lsu_info.rmask;
            commit_arf_data_o[0] = axi_commit_resp_i.data;
            commit_arf_areg_o[0] = rob_commit_q.w_areg;
        end
    end
    // 其余情况均不提交
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 代表相应的指令属性
logic [1:0] is_lsu_write, is_lsu_read, is_lsu;
logic [1:0] is_uncached;    // 指令为Uncached指令
logic [1:0] is_csr_fix;     // 指令为CSR特权指令
logic [1:0] is_cache_fix;   // 指令为Cache维护指令
logic [1:0] is_tlb_fix;     // 指令为TLB维护指令
logic [1:0] cache_commit_hit; // 此周期输入到cache的地址没有命中
logic [1:0] cache_commit_dirty;
logic [1:0] is_ll;
logic [1:0] is_sc;

// 与DCache的一级流水交互
lsu_iq_pkg_t [1:0] lsu_info;
assign lsu_info[0] = rob_commit_i[0].lsu_info;
assign lsu_info[1] = rob_commit_i[1].lsu_info;

commit_cache_req_t commit_cache_req, commit_cache_req_q;
assign commit_cache_req_o = commit_cache_req;

commit_axi_req_t commit_axi_req_q, commit_axi_req;
assign commit_axi_req_o = commit_axi_req;

commit_icache_req_t commit_icache_req_q, commit_icache_req;
assign commit_icache_req_o = commit_icache_req;

// 判断指令类型
for(integer i = 0; i < 2; i += 1) begin
    always_comb begin
        // 处理后续的竞争逻辑
        is_lsu_write[i] = |lsu_info[i].strb;
        is_lsu_read[i]  = |lsu_info[i].rmask;

        is_lsu[i]       = is_lsu_write[i] | is_lsu_read[i];
        is_uncached[i]  = lsu_info[i].is_uncached;
        is_csr_fix[i]   = rob_commit_i[i].is_csr_fix;
        is_cache_fix[i] = rob_commit_i[i].is_cache_fix;
        is_tlb_fix[i]   = rob_commit_i[i].is_tlb_fix;

        cache_commit_hit[i] = lsu_info[i].hit;
        cache_commit_dirty[i] = lsu_info[i].dirty;

        is_ll[i]        = rob_commit_i[i].is_ll;
        is_sc[i]        = rob_commit_i[i].is_sc;
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 处理全局flush信息
TODO
always_comb begin
    // 只要不是现在提交，就刷
    // 此种情况包含了Cache，CSR和TLB维护的情况
    if(~(commit_request_o[0]) && ls_fsm_q == S_NORMAL) begin
        flush = '1;
    end
    else if(is_dbar || is_ibar) begin
        flush = '1;
    end
    else if((ls_fsm_q == S_ICACHE) && icache_commit_valid_i) begin
        flush = '1;
    end
    else if(|is_lsu) begin
        if(ls_fsm_q == S_NORMAL) begin
            if(!cache_commit_hit) begin
                flush = '1;
            end
            else if(is_uncached[0]) begin
                flush = '1;
            end
            else begin
                flush = '0;
            end
        end
        else begin
            flush = '0;
        end
    end
    else begin
        flush = '0;
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 处理分支预测信息
// 分支预测是否正确：按照第一条错误的分支指令来
// 认为分支指令只能单挑提交
word_t [1:0] pc;
word_t [1:0] pc_add_4;
word_t [1:0] next_pc;
word_t [1:0] real_target;

predict_info_t [1:0] predict_info;
assign predict_info[0] = rob_commit_i[0].predict_info;
assign predict_info[1] = rob_commit_i[1].predict_info;

logic [1:0] predict_branch;

branch_info_t [1:0] branch_info;
assign branch_info[0] = rob_commit_i[0].branch_info;
assign branch_info[1] = rob_commit_i[1].branch_info;

logic [1:0] is_branch;
logic [1:0] taken;

// 异常PC入口
logic [31:0] exp_pc;
assign exp_pc = cur_tlbr_exception ? csr_q.tlbrentry : csr_q.eentry ;

// 计算实际跳转的PC
for(integer i = 0; i < 2; i += 1) begin
    always_comb begin
        next_pc[i] = rob_commit_i[i].pc + 4;
        predict_branch[i] = predict_info[i].taken;

        case (branch_info[i].br_type)
            // 比较结果由ALU进行计算
            BR_B:
            BR_NORMAL: begin
                real_target = rob_commit_i[i].pc + rob_commit_i[i].data_imm;
                if (rob_commit_i[i].w_data == 1) begin
                    next_pc[i] = real_target; // TODO: check
                end
            end
            BR_CALL: begin
                real_target = rob_commit_i[i].data_imm;
                next_pc[i] = rob_commit_i[i].data_imm;
            end
            BR_RET: begin
                real_target = rob_commit_i[i].data_imm + rob_commit_i[i].data_rj;
                next_pc[i] = real_target; // TODO: check
            end
        endcase
    end
end

// 计算分支预测是否正确
for(integer i = 0; i < 2; i += 1) begin
    always_comb begin
        is_branch[i] = branch_info[i].is_branch;
        taken[i] = ((branch_info[i].br_type != BR_NORMAL) ||
                    (rob_commit_i[i].w_data == 1));
    end
end

for(integer i = 0; i < 2; i += 1) begin
    always_comb begin
        correct_info_o[i].pc = rob_commit_i[i].pc;
        correct_info_o[i].redir_addr = cur_exception ? exp_pc : //异常入口
                                       (rob_commit_i[0].ertn_en) : csr_q.era : //异常返回
                                       (flush & ~is_uncached) ? rob_commit_i[i].pc ://重新执行当前pc
                                       next_pc[i];//刷掉流水，执行下一条（pc + 4)
        //前面的跳转只允许所提交的第0条指令的重定位，分支预测失败？TODO
        correct_info_o[i].target_miss = (predict_info[i].target_pc != real_target[i]);
        corrext_info_o[i].type_miss = (predict_info[i].br_type != branch_info[i].br_type);

        correct_info_o[i].taken = taken[i];
        correct_info_o[i].is_branch = branch_info[i].is_branch;
        correct_info_o[i].branch_type = branch_info[i].br_type;

        correct_info_o[i].update = (predict_info[i].need_update) |
                                   (predict_branch[i]) |
                                   (is_branch[i]);
        correct_info_o[i].target_pc = real_target[i] : 

        correct_info_o[i].history = predict_info[i].history;
        correct_info_o[i].scnt = predict_info[i].scnt;
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 维护提交级的计时器
always_ff @(posedge clk) begin
    if(!rst_n) begin
        timer_64_q <= '0;
    end
    else begin
        timer_64_q <= timer_64_q + 64'b1;
    end
end

always_comb begin
    timer_64 = timer_64_q;
end

//rdcnt命令
logic [31:0] rdcnt_data_o;

always_comb begin
    rdcnt_data_o = '0;
    if (rob_commit_i[0].rdcntvl_en) begin
        rdcnt_data_o = timer_64_q[31:0];
    end
    else if (rob_commit_i[0].rdcntvh_en) begin
        rdcnt_data_o = timer_64_q[63:32];
    end
    else if (rob_commit_i[0].rdcntid_en) begin
        rdcnt_data_o = csr_q.tid;
    end
end

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 异常处理
//识别rob_commit_i[0]这一条指令是不是有异常，如果有，修改csr

//都不是寄存器
logic cur_exception;       //提交的第0条是不是异常指令
logic cur_tlbr_exception;  //提交的第0条指令的异常是不是tlbr异常，用于判断异常入口，上面信号为1才有意义
csr_t csr_exception_update;//周期结束时候写入csr_q

//中断识别
wire [12:0] int_vec = csr_q.estat[`_ESTAT_IS] & csr_q.ecfg[`_ECFG_LIE];
wire int_excep      = csr_q.crmd[`_CRMD_IE] && |int_vec;

//取指异常 TODO 判断的信号从fetch来，要求fetch如果有例外要传一个fetch_exception
wire fetch_excp    = rob_commit_valid_i[0] & rob_commit_i[0].fetch_exception;

//译码异常 下面的信号来自decoder TODO
wire syscall_excp  = rob_commit_valid_i[0] & rob_commit_i[0].syscall_inst;
wire break_excp    = rob_commit_valid_i[0] & rob_commit_i[0].break_inst;
wire ine_excp      = rob_commit_valid_i[0] & rob_commit_i[0].decode_err;
wire priv_excp     = rob_commit_valid_i[0] & rob_commit_i[0].priv_inst && (csr_q.crmd[`_CRMD_PLV] == 3);

//执行异常 TODO 访存级别如果有地址不对齐错误或者tlb错要传execute_exception信号
wire execute_excp  = rob_commit_valid_i[0] & rob_commit_i[0].execute_exception;

wire [6:0] exception = {int_excep, fetch_excp, syscall_excp, break_excp, ine_excp, priv_excp, execute_excp};

always_comb begin
    /*所有例外都要处理的东西，默认处理，如果没有例外在defalut里面改回去*/
    cur_exception = 1'b1;
    cur_tlbr_exception = 1'b0;//tlbr

    csr_exception_update = csr_q;

    csr_exception_update.prmd[`_PRMD_PPLV] = csr_q.crmd[`_CRMD_PLV];
    csr_exception_update.prmd[`_PRMD_PIE]  = csr_q.crmd[`_CRMD_IE];
    csr_exception_update.crmd[`_CRMD_PLV]  = '0;
    csr_exception_update.crmd[`_CRMD_IE]   = '0;
    /*对应文档的1，进入核心态和关中断*/
    csr_exception_update.era               = rob_commit_i[0].pc;
    /*对应2，TODO:要pc，好像没有*/

    //例外的仲裁部分，取最优先的例外将例外号存入csr，对应文档的例外操作3
    //部分操作包含4和5，即存badv和vppn的部分
    unique casez (exception)
        7'b1??????: begin
            csr_exception_update.estat[`_ESTAT_ECODE]    = `_ECODE_INT;
            csr_exception_update.estat[`_ESTAT_ESUBCODE] = '0;
        end /*中断*/

        7'b01?????: begin
            csr_exception_update.estat[`_ESTAT_ECODE]    = rob_commit_i[0].exc_code;
            csr_exception_update.estat[`_ESTAT_ESUBCODE] = '0;
            csr_exception_update.badv                    = rob_commit_i[0].pc; //存badv
            if (rob_commit_i[0].exc_code != `_ECODE_ADEF) begin
                csr_exception_update.tlbehi[`_TLBEHI_VPPN] = rob_commit_i[0].pc[31:13];        //tlb例外存vppn
            end
            if (rob_commit_i[0].exc_code == `_ECODE_TLBR) begin
                cur_tlbr_exception = 1'b1;
            end
        end
        /*取指例外 TODO 判断的信号从fetch来，
        要求fetch如果有例外要传一个fetch_excpetion信号，
        和一个存到exc_code里面的错误编码,要求在前面仲裁好是地址错还是tlb错
        （注意，后面如果有访存出错不能把取指错的错误码替掉）
        以及出错的虚拟地址va*/

        7'b001????: begin
            csr_exception_update.estat[`_ESTAT_ECODE]    = `_ECODE_SYS;
            csr_exception_update.estat[`_ESTAT_ESUBCODE] = '0;
        end /*syscall*/
        7'b0001???: begin
            csr_exception_update.estat[`_ESTAT_ECODE]    = `_ECODE_BRK;
            csr_exception_update.estat[`_ESTAT_ESUBCODE] = '0;
        end /*break*/
        7'b00001??: begin
            csr_exception_update.estat[`_ESTAT_ECODE]    = `_ECODE_INE;
            csr_exception_update.estat[`_ESTAT_ESUBCODE] = '0;
        end /*ine指令不存在*/
        7'b000001?: begin
            csr_exception_update.estat[`_ESTAT_ECODE]    = `_ECODE_IPE;
            csr_exception_update.estat[`_ESTAT_ESUBCODE] = '0;
        end /*ipe指令等级不合规*/
        /*译码例外，这几判断的个信号从decoder来*/

        7'b0000001: begin
            csr_exception_update.estat[`_ESTAT_ECODE]    = rob_commit_i[0].exc_code;
            csr_exception_update.estat[`_ESTAT_ESUBCODE] = '0;
            csr_exception_update.badv                    = rob_commit_i[0].badva; //存badv
            if (rob_commit_i[0].exc_code != `_ECODE_ALE) begin
                csr_exception_update.tlbehi[`_TLBEHI_VPPN] = rob_commit_i[0].badva[31:13];        //tlb例外存vppn
            end
            if (rob_commit_i[0].exc_code == `_ECODE_TLBR) begin
                cur_tlbr_exception = 1'b1;
            end
        end
        /*执行例外，
        TODO 访存级别如果有地址不对齐错误或者tlb错误
        要传execute_excpetion信号和错误号过来，
        同样需要出错虚地址badva，同取指部分的例外*/

        default: begin
            csr_exception_update = csr_q;
            cur_exception = 1'b0;
            /*csr_exception_update.prmd[`_PRMD_PPLV] = csr_q.prmd[`_PRMD_PPLV];
            csr_exception_update.prmd[`_PRMD_PIE]  = csr_q.prmd[`_PRMD_PIE];
            csr_exception_update.crmd[`_CRMD_PLV]  = csr_q.crmd[`_CRMD_PLV];
            csr_exception_update.crmd[`_CRMD_IE]   = csr_q.crmd[`_CRMD_IE];
            csr_exception_update.era               = csr_q.era;*/
        end
        /*没有例外，把开始的东西改回去*/
    endcase

end

//下面识别rob_commit[1]是不是有例外
wire a_fetch_excp    = rob_commit_i[1].fetch_exception;

wire a_syscall_excp  = rob_commit_i[1].syscall_inst;
wire a_break_excp    = rob_commit_i[1].break_inst;
wire a_ine_excp      = rob_commit_i[1].decode_err;
wire a_priv_excp     = rob_commit_i[1].priv_inst && (csr_q.crmd[`_CRMD_PLV] == 3);

wire a_execute_excp  = rob_commit_i[1].execute_exception;

wire another_exception    = rob_commit_valid_i[1] & |{a_fetch_excp, a_syscall_excp, a_break_excp, a_ine_excp,a_priv_excp, a_execute_excp};
//上面是1表示两条指令的后一条有例外



// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// CSR特权指令
csr_t csr, csr_q, csr_init;
wire  [1:0] csr_type = rob_commit_i[0].csr_type;
wire [13:0] csr_num  = rob_commit_i[0].csr_num;
//TODO fetch from imm

// CSR复位
always_comb begin
    csr_init                = '0;
    // 初始化要求非0的 CSR 寄存器值
    csr_init.crmd[`_CRMD_DA]= 1'd1;
    csr_init.asid[31:10]    = 22'h280;
    csr_init.cpuid          = CPU_ID;
    csr_init.tid            = CPU_ID;
end

logic [31:0] commit_csr_data_o;

// 从CSR读取的旧值（默认读出来）
always_comb begin
    //编号->csr寄存器
    commit_csr_data_o  = '0;
    unique case (csr_num)
        `_CSR_CRMD:     commit_csr_data_o  |= csr_q.crmd;
        `_CSR_PRMD:     commit_csr_data_o  |= csr_q.prmd;
        `_CSR_EUEN:     commit_csr_data_o  |= csr_q.euen;
        `_CSR_ECFG:     commit_csr_data_o  |= csr_q.ecfg;
        `_CSR_ESTAT:    commit_csr_data_o  |= csr_q.estat;
        `_CSR_ERA:      commit_csr_data_o  |= csr_q.era;
        `_CSR_BADV:     commit_csr_data_o  |= csr_q.badv;
        `_CSR_EENTRY:   commit_csr_data_o  |= csr_q.eentry;
        `_CSR_TLBIDX:   commit_csr_data_o  |= csr_q.tlbidx;
        `_CSR_TLBEHI:   commit_csr_data_o  |= csr_q.tlbehi;
        `_CSR_TLBELO0:  commit_csr_data_o  |= csr_q.tlbelo0;
        `_CSR_TLBELO1:  commit_csr_data_o  |= csr_q.tlbelo1;
        `_CSR_ASID:     commit_csr_data_o  |= csr_q.asid;
        `_CSR_PGDL:     commit_csr_data_o  |= csr_q.pgdl;
        `_CSR_PGDH:     commit_csr_data_o  |= csr_q.pgdh;
        `_CSR_PGD:      commit_csr_data_o  |= csr_q.badv[31] ? csr_q.pgdh : csr_q.pgdl;
        `_CSR_CPUID:    commit_csr_data_o  |= csr_q.cpuid;
        `_CSR_SAVE0:    commit_csr_data_o  |= csr_q.save0;
        `_CSR_SAVE1:    commit_csr_data_o  |= csr_q.save1;
        `_CSR_SAVE2:    commit_csr_data_o  |= csr_q.save2;
        `_CSR_SAVE3:    commit_csr_data_o  |= csr_q.save3;
        `_CSR_TID:      commit_csr_data_o  |= csr_q.tid;
        `_CSR_TCFG:     commit_csr_data_o  |= csr_q.tcfg;
        `_CSR_TVAL:     commit_csr_data_o  |= csr_q.tval;//读定时器
        `_CSR_TICLR:    commit_csr_data_o  |= csr_q.ticlr;
        `_CSR_LLBCTL:   commit_csr_data_o  |= {csr_q.llbctl[31:1], csr_q.llbit};//读llbit
        `_CSR_TLBRENTRY:commit_csr_data_o  |= csr_q.tlbrentry;
        `_CSR_DMW0:     commit_csr_data_o  |= csr_q.dmw0;
        `_CSR_DMW1:     commit_csr_data_o  |= csr_q.dmw1;
        default:
    endcase
end

logic timer_interrupt_clear;

//定义软件写csr寄存器的行为
`define write_csr_mask(csr_name, mask) csr.``csr_name``[mask] = write_data[mask];

task write_csr(input [31:0] write_data, input [13:0] csr_num);
    begin
        unique case (csr_num)
            `_CSR_CRMD: begin
                write_csr_mask(crmd, `_CRMD_PLV);
                write_csr_mask(crmd, `_CRMD_IE);
                write_csr_mask(crmd, `_CRMD_DA);
                write_csr_mask(crmd, `_CRMD_PG);
                write_csr_mask(crmd, `_CRMD_DATF);
                write_csr_mask(crmd, `_CRMD_DATM);
            end
            `_CSR_PRMD: begin
                write_csr_mask(prmd, `_PRMD_PIE);
                write_csr_mask(prmd, `_PRMD_PPLV);
            end
            `_CSR_EUEN: begin
                write_csr_mask(euen, `_EUEN_FPE);
            end
            `_CSR_ECFG: begin
                write_csr_mask(ecfg, `_ECFG_LIE1);
                write_csr_mask(ecfg, `_ECFG_LIE2);
            end
            `_CSR_ESTAT: begin
                write_csr_mask(estat, `_ESTAT_SOFT_IS);
            end
            `_CSR_ERA: begin
                write_csr_mask(era, 31:0);
            end
            `_CSR_BADV: begin
                write_csr_mask(badv, 31:0);
            end
            `_CSR_EENTRY: begin
                write_csr_mask(eentry, `_EENTRY_VA);
            end
            `_CSR_CPUID: begin
                //do nothing
            end
            `_CSR_SAVE0: begin
                write_csr_mask(save0, 31:0);
            end
            `_CSR_SAVE1: begin
                write_csr_mask(save1, 31:0);
            end
            `_CSR_SAVE2: begin
                write_csr_mask(save2, 31:0);
            end
            `_CSR_SAVE3: begin
                write_csr_mask(save3, 31:0);
            end
            `_CSR_LLBCTL: begin
                if (write_data[`_LLBCT_WCLLB]) begin
                    csr.llbit = 0;
                end
                write_csr_mask(llbctl, `_LLBCT_KLO);
            end
            `_CSR_TLBIDX: begin
                write_csr_mask(tlbidx, `_TLBIDX_INDEX);
                write_csr_mask(tlbidx, `_TLBIDX_PS);
                write_csr_mask(tlbidx, `_TLBIDX_NE);
            end
            `_CSR_TLBEHI: begin
                write_csr_mask(tlbehi, `_TLBEHI_VPPN);
            end
            `_CSR_TLBELO0: begin
                write_csr_mask(tlbelo0, `_TLBELO_TLB_V);
                write_csr_mask(tlbelo0, `_TLBELO_TLB_D);
                write_csr_mask(tlbelo0, `_TLBELO_TLB_PLV);
                write_csr_mask(tlbelo0, `_TLBELO_TLB_MAT);
                write_csr_mask(tlbelo0, `_TLBELO_TLB_G);
                write_csr_mask(tlbelo0, `_TLBELO_TLB_PPN);
            end
            `_CSR_TLBELO1: begin
                write_csr_mask(tlbelo1, `_TLBELO_TLB_V);
                write_csr_mask(tlbelo1, `_TLBELO_TLB_D);
                write_csr_mask(tlbelo1, `_TLBELO_TLB_PLV);
                write_csr_mask(tlbelo1, `_TLBELO_TLB_MAT);
                write_csr_mask(tlbelo1, `_TLBELO_TLB_G);
                write_csr_mask(tlbelo1, `_TLBELO_TLB_PPN);
            end
            `_CSR_ASID: begin
                write_csr_mask(asid, `_ASID);
            end
            `_CSR_PGDL: begin
                write_csr_mask(pgdl, `_PGD_BASE);
            end
            `_CSR_PGDH: begin
                write_csr_mask(pgdh, `_PGD_BASE);
            end
            `_CSR_PGD: begin
                //do nothing
            end
            `_CSR_TLBRENTRY: begin
                write_csr_mask(tlbrentry, `_TLBRENTRY_PA);
            end
            `_CSR_DMW0: begin
                write_csr_mask(dmw0, `_DMW_PLV0);
                write_csr_mask(dmw0, `_DMW_PLV3);
                write_csr_mask(dmw0, `_DMW_MAT);
                write_csr_mask(dmw0, `_DMW_PSEG);
                write_csr_mask(dmw0, `_DMW_VSEG);
            end
            `_CSR_DMW1: begin
                write_csr_mask(dmw1, `_DMW_PLV1);
                write_csr_mask(dmw1, `_DMW_PLV3);
                write_csr_mask(dmw1, `_DMW_MAT);
                write_csr_mask(dmw1, `_DMW_PSEG);
                write_csr_mask(dmw1, `_DMW_VSEG);
            end
            `_CSR_TID: begin
                write_csr_mask(tid, 31:0);
            end
            `_CSR_TCFG: begin
                write_csr_mask(tcfg, `_TCFG_EN);
                write_csr_mask(tcfg, `_TCFG_PERIODIC);
                write_csr_mask(tcfg, `_TCFG_INITVAL);
            end
            `_CSR_TVAL: begin
                //do nothing
            end
            `_CSR_TICLR: begin
                if (write_data[`_TICLR_CLR]) begin
                    timer_interrupt_clear = 1;
                end
            end
            default: //do nothing
        endcase
    end
endtask


//csr访问指令对csr寄存器的修改
always_comb begin
    csr = csr_q;
    timer_interrupt_clear = 0;

    unique case (csr_type)
        `_CSR_CSRRD: begin
            //do nothing
        end
        `_CSR_CSRWR: begin
            write_csr(rob_commit_i[0].data_rd, csr_num);
        end

        `_CSR_XCHG: begin
            write_csr((rob_commit_i[0].data_rd & rob_commit_i[0].data_rj), csr_num);
        end

        default: begin//do nothing
        end
    endcase
end



// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// TLB维护指令
// 不管理TLB的映射内容，只管理TLB的维护内容
// 相当于管理64个TLB表项，对应有一个ITLB和DTLB的映射
tlb_entry_t [`_TLB_ENTRY_NUM - 1 : 0] tlb_entries_q;
//我默认没有实现tlb的初始化，开始的时候由软件用INVTLB 0, r0, r0实现

//拿到维护类型
wire cur_tlbsrch = rob_commit_i[0].tlbsrch_en;
wire cur_tlbrd   = rob_commit_i[0].tlbrd_en;
wire cur_tlbwr   = rob_commit_i[0].tlbwr_en;
wire cur_tlbfill = rob_commit_i[0].tlbfill_en;
wire cur_invtlb  = rob_commit_i[0].invtlb_en;

//给下面准备的一些信号
csr_t tlb_update_csr;/*对csr的更新*/
tlb_entry_t tlb_entry/*前面是一个临时变量*/,tlb_update_entry;/*更新进tlb的内容*/
logic [`_TLB_ENTRY_NUM - 1:0] tlb_wr_req;/*更新进tlb的使能位*/

always_comb begin
    tlb_update_csr = csr_q;
    tlb_update_entry = '0;
    tlb_wr_req     = '0;

    if (cur_tlbsrch) begin
        //下面找对应的表项，同mmu里面的找法
        tlb_update_csr.tlbidx[`_TLBIDX_NE] = 1;
        for (genvar i = 0; i < `_TLB_ENTRY_NUM; i += 1) begin
            if (tlb_entries_q[i].key.e 
                && (tlb_entries_q[i].key.g || (tlb_entries_q[i].key.asid == csr_q.asid))
                && vppn_match(csr_q.tlbehi, tlb_entries_q[i].key.huge_page, tlb_entries_q[i].key.vppn)) begin
                    tlb_update_csr.tlbidx[`_TLBIDX_INDEX] = i; //不知道这里语法有没有问题
                    tlb_update_csr.tlbidx[`_TLBIDX_NE] = 0;
                    //写csr
            end
        end
    end

    else if (cur_tlbrd) begin
        tlb_entry = tlb_entries_q[csr_q.tlbidx[`_TLBIDX_INDEX]];
        if (tlb_entry.key.e) begin
            //找到了要存到特定的csr寄存器里面
            tlb_update_csr.tlbidx[`_TLBIDX_PS]      = tlb_entry.key.huge_page ? 21 : 12;
            tlb_update_csr.tlbidx[`_TLBIDX_NE]      = 0;

            tlb_update_csr.tlbehi[`_TLBEHI_VPPN]    = tlb_entry.key.vppn;

            tlb_update_csr.tlbelo0[`_TLBELO_TLB_V]  = tlb_entry.value[0].v;
            tlb_update_csr.tlbelo0[`_TLBELO_TLB_D]  = tlb_entry.value[0].d;
            tlb_update_csr.tlbelo0[`_TLBELO_TLB_PLV]= tlb_entry.value[0].plv;
            tlb_update_csr.tlbelo0[`_TLBELO_TLB_MAT]= tlb_entry.value[0].mat;
            tlb_update_csr.tlbelo0[`_TLBELO_TLB_G]  = tlb_entry.value[0].g;
            tlb_update_csr.tlbelo0[`_TLBELO_TLB_PPN]= tlb_entry.value[0].ppn;

            tlb_update_csr.tlbelo1[`_TLBELO_TLB_V]  = tlb_entry.value[1].v;
            tlb_update_csr.tlbelo1[`_TLBELO_TLB_D]  = tlb_entry.value[1].d;
            tlb_update_csr.tlbelo1[`_TLBELO_TLB_PLV]= tlb_entry.value[1].plv;
            tlb_update_csr.tlbelo1[`_TLBELO_TLB_MAT]= tlb_entry.value[1].mat;
            tlb_update_csr.tlbelo1[`_TLBELO_TLB_G]  = tlb_entry.value[1].g;
            tlb_update_csr.tlbelo1[`_TLBELO_TLB_PPN]= tlb_entry.value[1].ppn;
        end
        else begin
            tlb_update_csr.tlbidx[`_TLBIDX_NE]      = 1;
            tlb_update_csr.tlbidx[`_TLBIDX_PS]      = '0;

            tlb_update_csr.asid[`_ASID]             = '0;

            tlb_update_csr.tlbehi                   = '0;
            tlb_update_csr.tlbelo0                  = '0;
            tlb_update_csr.tlbelo1                  = '0;
        end
    end

    else if (cur_tlbwr) begin
        //把值更新到tlb_update_entry里面
        load_tlb_update_entry();
        tlb_wr_req[csr_q.tlbidx[`_TLBIDX_INDEX]] = 1;
    end

    else if (cur_tlbfill) begin
        load_tlb_update_entry();
        tlb_wr_req[timer_64_q[$clog2(`_TLB_ENTRY_NUM) - 1:0]] = 1;
        //同上，但是根据计时器的值随机更新一个表项
    end

    else if (cur_invtlb) begin
        tlb_update_entry       = '0;
        unique case (rob_commit_i[0].tlb_op)
            5'h0: begin
                tlb_wr_req = '1;
            end
            5'h1: begin
                tlb_wr_req = '1;
            end
            5'h2: begin
                for (genvar i = 0; i < `_TLB_ENTRY_NUM; i = i + 1) begin
                    if (tlb_entries_q[i].key.g) begin
                        tlb_wr_req[i] = 1;
                    end
                end
            end
            5'h3: begin
                for (genvar i = 0; i < `_TLB_ENTRY_NUM; i = i + 1) begin
                    if (!tlb_entries_q[i].key.g) begin
                        tlb_wr_req[i] = 1;
                    end
                end
            end
            5'h4: begin
                for (genvar i = 0; i < `_TLB_ENTRY_NUM; i = i + 1) begin
                    if (!tlb_entries_q[i].key.g && 
                        tlb_entries_q[i].key.asid == rob_commit_i[0].data_rj[9:0]) begin
                        tlb_wr_req[i] = 1;
                    end
                end
            end
            5'h5: begin
                for (genvar i = 0; i < `_TLB_ENTRY_NUM; i = i + 1) begin
                    if (!tlb_entries_q[i].key.g && 
                        tlb_entries_q[i].key.asid == rob_commit_i[0].data_rj[9:0] &&
                        vppn_match(rob_commit_i[0].data_rk, tlb_entries_q[i].key.huge_page, tlb_entries_q[i].key.vppn)) begin
                        tlb_wr_req[i] = 1;
                    end
                end
            end
            5'h6: begin
                for (genvar i = 0; i < `_TLB_ENTRY_NUM; i = i + 1) begin
                    if ((tlb_entries_q[i].key.g ||
                        tlb_entries_q[i].key.asid == rob_commit_i[0].data_rj[9:0]) &&
                        vppn_match(rob_commit_i[0].data_rk, tlb_entries_q[i].key.huge_page, tlb_entries_q[i].key.vppn)) begin
                        tlb_wr_req[i] = 1;
                    end
                end
            end
            default: 
        endcase
    end

    if (!rob_commit_valid_i[0]) begin
        tlb_wr_req = '0;
    end//无效rob表项则上面全部不用，不知道这样加会不会逻辑更复杂😭
end

function automatic logic vppn_match(logic [31:0] va, 
                                    logic huge_page, logic [18: 0] vppn)
    if (huge_page) begin
        return va[31:22] == vppn[18:9]; //this right
    end else begin
        return va[31:13] == vppn;
    end
endfunction

//把csr寄存器中存储的tlb信息存到某个tlb表项里面，用于tlbwr和tlbfill
task load_tlb_update_entry();
        tlb_update_entry.key.vppn      = csr_q.tlbehi[`_TLBEHI_VPPN];
        tlb_update_entry.key.huge_page = csr_q.tlbidx[`_TLBIDX_PS] == 21;
        tlb_update_entry.key.g         = csr_q.tlbelo0[`_TLBELO_TLB_G] & csr_q.tlbelo1[`_TLBELO_TLB_G];
        tlb_update_entry.key.asid      = csr_q.asid[`_ASID];

        tlb_update_entry.value[0].ppn  = csr_q.tlbelo0[`_TLBELO_TLB_PPN];
        tlb_update_entry.value[0].plv  = csr_q.tlbelo0[`_TLBELO_TLB_PLV];
        tlb_update_entry.value[0].mat  = csr_q.tlbelo0[`_TLBELO_TLB_MAT];
        tlb_update_entry.value[0].d    = csr_q.tlbelo0[`_TLBELO_TLB_D];
        tlb_update_entry.value[0].v    = csr_q.tlbelo0[`_TLBELO_TLB_V];

        tlb_update_entry.value[1].ppn  = csr_q.tlbelo1[`_TLBELO_TLB_PPN];
        tlb_update_entry.value[1].plv  = csr_q.tlbelo1[`_TLBELO_TLB_PLV];
        tlb_update_entry.value[1].mat  = csr_q.tlbelo1[`_TLBELO_TLB_MAT];
        tlb_update_entry.value[1].d    = csr_q.tlbelo1[`_TLBELO_TLB_D];
        tlb_update_entry.value[1].v    = csr_q.tlbelo1[`_TLBELO_TLB_V];

        if (csr_q.estat[`_ESTAT_ECODE] == `_ECODE_TLBR) begin
            tlb_update_entry.key.e     = 1;
        end
        else if (csr_q.tlbidx[`_TLBIDX_NE]) begin
            tlb_update_entry.key.e     = 0;
        end
        else begin
            tlb_update_entry.key.e     = 1;
        end
endtask

//纯组合逻辑输出
always_comb begin
    csr_o = csr_q;
    tlb_write_req_o.tlb_write_req   = tlb_wr_req;
    tlb_write_req_o.tlb_write_entry = tlb_update_entry;
end

//周期结束的时候更新进tlb，同时也发出去更新mmu里面的tlb
always_ff @( posedge clk ) begin
    for (genvar i = 0; i < `_TLB_ENTRY_NUM; i = i + 1) begin
        if (tlb_wr_req[i]) begin
            tlb_entries_q[i] <= tlb_update_entry;
        end
    end
end

//下面这个组合逻辑内部顺序不要更改
always_comb begin
    if (rob_commit_valid_i[0]) begin
        if (rob_commit_i[0].is_tlb_fix) begin
            csr_update = tlb_update_csr;
        end
        else if (rob_commit_i[0].is_csr_fix) begin
            csr_update = csr;
        end
        else if (rob_commit_i[0].ertn_en) begin
            csr_update.crmd[`_CRMD_PLV] = csr_q.prmd[`_PRMD_PPLV];
            csr_update.crmd[`_CRMD_IE]  = csr_q.prmd[`_PRMD_PIE];
            if (csr_q.llbctl[`_LLBCT_KLO]) begin
                csr_update.llbctl[`_LLBCT_KLO] = 0;
            end
            else begin
                csr_update.llbit = 0;
            end
        end
        else if (is_ll[0]) begin
            csr_update.llbit = 1;
        end
    end

    //下面这个放在这里，是因为中断/异常的优先级最高，并且当前指令一定有效或者是中断
    if(cur_exception) begin
        csr_update = csr_exception_update;
    end

    //上面那些每周期规定只有一条，因此没有交叉冒险的情况

    //下面这个放在这里，是因为cpu每个周期都要更新一些软件不能更新的东西
    //如果放在前面会被覆盖掉，放在后面，由于是软件不能改的位，不会把前面的覆盖掉
    csr_update.estat[`_ESTAT_HARD_IS]  = hard_is; //TODO从外面连过来

    //下面维护定时器
    csr_update.estat[`_ESTAT_TIMER_IS] = 0;
    if (csr_q.tcfg[`_TCFG_EN]) begin
        if (csr_q.tval != 0) begin
            csr_update.tval = csr_update.tval - 1;
        end
        else if (csr_q.tcfg[`_TCFG_PERIODIC]) begin
            csr_update.estat[`_ESTAT_TIMER_IS] = 1;
            csr_update.tval = {csr_q.tcfg[`_TCFG_INITVAL], 2'b0};
        end
        else begin
            csr_update.estat[`_ESTAT_TIMER_IS] = 1;
        end
    end

    //这个优先级最高，如果clear了就将其写入
    if (rob_commit_valid_i[0] & !cur_exception & timer_interrupt_clear) begin
        csr_update.estat[`_ESTAT_TIMER_IS] = 0;
    end

end

// 对csr_q的信息维护
always_ff @(posedge clk) begin
    if(~rst_n) begin
        csr_q <= csr_init; // 初始化 CSR
    end
    else begin
        csr_q <= csr_update;
    end
end

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


// -------------------------------------------------------------------

//idle指令
logic wait_for_int_q, wait_for_int;

always_comb begin
    wait_for_int = wait_for_int_q;
    if (wait_for_int) begin
        wait_for_int = ~int_excep;
    end
    else begin
        wait_for_int = cur_exception ? 0 : rob_commit_i[0].idle_en;
    end
end
//当处于等待状态时，一直flush，要求rob来的所有指令都不valid！

always_ff @( posedge clk ) begin
    if (~rst_n) begin
        wait_for_int_q <= 0;
    end
    else begin
        wait_for_int_q <= wait_for_int;
    end
end

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


// ------------------------------------------------------------------
// Cache维护指令：也需要进入状态机
logic [4:0] cache_code, cache_code_q;
assign cache_code = rob_commit_i[0].cache_code;
// code[2:0]指示操作的Cache对象
logic [2:0] cache_tar, cache_tar_q;
assign cache_tar = cache_code[2:0];
// code[4:3]指示操作类型
logic [1:0] cache_op, cache_op_q;
assign cache_op = cache_code[4:3];
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


// ------------------------------------------------------------------
// 对于lsu访存的状态机
// 涉及到Cache和AXI的多个子状态机

// 定义写的状态机
typedef enum logic[4:0] {
    // 正常状态
    S_NORMAL,
    // 讲Cache的内容读出
    S_CACHE_RD,
    // 讲选定的脏块写回
    S_AXI_WB,
    // 通过AXI总线读出内容
    S_AXI_RD,
    // 写入Cache
    S_CACHE,
    // UnCached情况下直接发起AXI请求
    S_UNCACHED,
    // 等待ICache请求完成
    S_ICACHE
} ls_fsm_s;
// 如果是is_uncached指令，直接发起AXI请求
// 状态机流程：
// 1. normal命中 -> write cache即可
// 2. miss -> 为脏需要写回：先read cache -> axi write back -> axi read -> write cache
// 3. miss -> 不需要写回，通过AXI读相应的内容

ls_fsm_s ls_fsm_q;
logic axi_return_back;
rob_commit_pkg_t rob_commit_q;

// 配置与Cache的握手信号
logic commit_cache_valid, commit_cache_valid_q;
assign commit_cache_valid_o = commit_cache_valid_q;

word_t [CACHE_BLOCK_NUM-1:0] cache_block_data;
word_t [CACHE_BLOCK_NUM-1:0] axi_block_data;

logic [$bits(CACHE_BLOCK_NUM):0] cache_block_ptr, cache_block_len;
logic [$bits(CACHE_BLOCK_NUM):0] axi_block_ptr, axi_block_len;

logic axi_wait;
logic icache_wait;

logic [31:0] cache_dirty_addr;

logic ll_bit;
assign ll_bit = csr_q.llbctl;

// Cache的特性是本周期发出请求，下周期才能得到回应
sb_ebtry_t sb_entry, sb_entry_q;
assign sb_entry = cache_commit_resp_i.sb_entry;

// 状态转移的组合逻辑
always_comb begin
    stall = stall_q;
    commit_cache_req = commit_cache_req_q;
    commit_cache_req.tag_we      = '0;
    commit_cache_req.fetch_sb    = '0;

    commit_axi_req = commit_axi_req_q;
    commit_axi_valid_o = '0;
    commit_axi_ready_o = '0;

    if(ls_fsm_q == S_NORMAL && is_lsu) begin
        stall |= ~cache_commit_hit;

        // Cache维护指令
        if(is_cache_fix[0]) begin
            // 发送Icache请求
            if(cache_tar == 0) begin
                // 配置Icache请求
                commit_icache_req.addr = lsu_info[0].paddr;
                commit_icache_req.cache_op = cache_op;

                if(~icache_commit_ready_i && ~icache_wait) begin
                    commit_icache_valid_o = '1;
                end
                else begin
                    commit_icache_valid_o = '0;
                end
            end

            else if(cache_tar == 1) begin
                commit_cache_valid = '1;
                // 对于Cache维护指令，将维护地址视作目的地址
                // Cache采用直接映射，故直接赋值即可
                commit_cache_req.addr         = lsu_info[0].paddr;
                commit_cache_req.way_choose   = get_way_choose(commit_cache_req.addr[0]); // 直接地址映射模式
                commit_cache_req.tag_data     = '0;
                commit_cache_req.tag_we       = '0;
                commit_cache_req.data_data    = '0;
                commit_cache_req.strb         = '0;
                commit_cache_req.fetch_sb     = '0;

                if(cache_op == 0) begin
                    commit_cache_req.tag_data = '0;
                    commit_cache_req.tag_we   = '1;
                end
                else if(cache_op == 1) begin
                    // 将Cache无效化，先读出对应的tag
                    commit_cache_req.tag_data  = '0;
                    commit_cache_req.tag_we    = '1;
                end
                else if(cache_op == 2 && cache_commit_hit) begin
                    // 将Cache无效化，先读出对应的tag
                    commit_cache_req.way_choose   = '0;
                    commit_cache_req.way_choose  |= lsu_info[0].tag_hit;
                    commit_cache_req.tag_data     = '0;
                    commit_cache_req.tag_we       = '1;
                end
            end
        end

        else if(is_uncached[0]) begin
            // 配置AXI的相应信息
            commit_axi_valid     = '1;
            commit_axi_req.data  = lsu_info[0].wdata;
            commit_axi_req.addr  = lsu_info[0].paddr;
            commit_axi_req.len   = 1;
            commit_axi_req.strb  = lsu_info[0].strb;
            commit_axi_req.rmask = lsu_info[0].rmask;
            commit_axi_req.read  = |lsu_info[0].rmask;
        end

        else if(cache_commit_hit) begin
            if((is_sc && ll_bit) || ~is_sc) begin
                // 配置Cache的相应信息
                commit_cache_valid = '1;
                commit_cache_req.addr         = lsu_info[0].paddr;
                commit_cache_req.way_choose   = lsu_info[0].tag_hit;
                commit_cache_req.tag_data     = '0;
                commit_cache_req.data_data    = lsu_info[0].wdata;
                commit_cache_req.strb         = lsu_info[0].strb;
                commit_cache_req.fetch_sb     = |lsu_info[0].strb;
            end
        end

        else begin
            // 读出Cache的整块数据，最后写回
            if(cache_commit_dirty) begin
                // 设置相应的Cache数据
                commit_cache_valid = '1;
                // 对齐一块的数据
                commit_cache_req.addr       = lsu_info[0].paddr & 32'hfffffff0;
                commit_cache_req.way_choose = lsu_info[0].refill;
                commit_cache_req.tag_data   = '0;
                commit_cache_req.tag_we     = '0;
                commit_cache_req.data_data  = '0;
                commit_cache_req.strb       = '0;
                // normal状态下未命中也要提交
                commit_cache_req.fetch_sb   = |lsu_info[0].strb;
            end
            // 发出AXI请求，直接读出数据
            else begin
                commit_axi_valid_o          = '1;
                // 对齐一个字的数据
                commit_axi_req.addr         = lsu_info[0].addr & 32'hfffffffc;
                commit_axi_req.len          = CACHE_BLOCK_NUM;
                commit_axi_req.strb         = '0;
                commit_axi_req.rmask        = lsu_info[i].rmask;
                commit_axi_req.read         = |lsu_info[i].rmask;

                // 配置Cache的相应信息
                commit_cache_valid          = '1;
                commit_cache_req.addr       = lsu_info[0].addr;
                commit_cache_req.way_choose = commit_cache_req.addr[0];
                commit_cache_req.tag_data   = '0;
                commit_cache_req.tag_we     = '0;
                commit_cache_req.data_data  = '0;
                commit_cache_req.strb       = '0;
                // normal状态下未命中也要提交
                commit_cache_req.fetch_sb   = |lsu_info[0].strb;
            end
        end
    end

    else if(ls_fsm_q == S_UNCACHED) begin
        // UnCached只需要发起一次请求即可
        if(axi_commit_valid_i) begin
            stall              = '0;
            commit_axi_valid_o = '0;
        end
    end

    // 与Cache进行读写操作
    else if (ls_fsm_q == S_CACHE) begin
        // Cache接受当前的读写请求
        commit_cache_req.addr      = commit_cache_req_q.addr + 4;
        // TODO way_choose
        commit_cache_req.tag_data  = get_cache_tag(commit_cache_req.addr, 1, 0);
        commit_cache_req.tag_we    = '1;
        commit_cache_req.data_data = cache_block_data[cache_block_ptr];
        commit_cache_req.strb      = '1;
        commit_cache_req.fetch_sb  = '0;
        // TODO ? 判断是否应该放在前面，如果不满足则不应该继续写Cache
        // 回到normal状态，取消提交级的阻塞
        if(cahce_block_ptr == cache_block_len) begin
            stall = '0;
        end
    end

    // 发起AXI请求，读出对应地址处的数据
    else if(ls_fsm_q == S_AXI_RD) begin
        commit_axi_ready_o          = '0;

        // 初始状态的握手信号
        if(axi_block_ptr == 0) begin
            // 接收到信息，不用置高位
            if(~axi_commit_ready_i) begin
                // 维持原有的请求信息
                commit_axi_valid_o          = '1;
                commit_axi_req.addr         = lsu_info[0].addr & 32'hfffffffc;
                commit_axi_req.len          = CACHE_BLOCK_NUM;
                commit_axi_req.strb         = '0;
                commit_axi_req.rmask        = lsu_info[i].rmask;
                commit_axi_req.read         = |lsu_info[i].rmask;
            end
        end

        // AXI传入一个数据
        commit_axi_ready_o = '0;
        if(axi_commit_valid_i) begin
            // AXI请求完成，进行下一步状态
            if(axi_block_ptr == axi_block_len) begin
                commit_cache_valid = '1;
                commit_cache_req   = commit_cache_req_q;
            end
            else begin
                commit_axi_ready_o = '1;
                // 对齐一个字的数据
                commit_axi_req.addr   = commit_axi_req_q.addr + 4;
                commit_axi_req.strb   = '0;
                commit_axi_req.rmask  = '1;
            end
        end
    end

    // 将需要写回部分的Cache整块数据读出
    else if(ls_fsm_q == S_CACHE_RD) begin
        // Cache固定延时一排出结果
        // 完成了整块的读出操作
        if(cache_block_ptr == cache_block_len) begin
            // 将读出的数据写回
            commit_axi_valid_o   = '1;
            commit_axi_req.data  = cache_block_data[0];
            // 对齐一块的数据
            commit_axi_req.addr  = cache_dirty_addr & 32'hfffffff0;
            commit_axi_req.len   = CACHE_BLOCK_NUM;
            commit_axi_req.strb  = '1;
            commit_axi_req.rmask = '0;
        end
        else begin
            // 设置下一轮的Cache数据
            commit_cache_req.addr = commit_cache_req_q.addr + 4;
            // way choose TODO
            commit_cache_req.tag_data = '0;
            commit_cache_req.tag_we = '0;
            commit_cache_req.data_data = '0;
            commit_cache_req.strb = '0;
            commit_cache_req.fetch_sb = '0;
        end
    end

    // 发起AXI请求，写回对应地址处的数据
    else if (ls_fsm_q == S_AXI_WB) begin
        commit_axi_valid_o   = '0;

        if(axi_block_ptr == 0) begin
            if(~axi_commit_ready_i) begin
                // 握手前维持原有请求不变
                commit_axi_valid_o   = '1;
                commit_axi_req.data  = cache_block_data[0];
                // 对齐一块的数据
                commit_axi_req.addr  = cache_dirty_addr & 32'hfffffff0;
                commit_axi_req.len   = CACHE_BLOCK_NUM;
                commit_axi_req.strb  = '1;
                commit_axi_req.rmask = '0;
            end
        end

        commit_axi_valid_o = '0;
        // AXI写回请求完成，再发送AXI请求进行读出所需处的数据
        if(axi_commit_ready_i) begin
            if(axi_block_ptr == axi_block_len) begin
                commit_axi_ready_o = '0;
                if(axi_return_back) begin

                end
                else begin
                    commit_axi_ready_o = '1;
                    // 设置相应的AXI数据
                    commit_axi_req.addr  = rob_commit_q.lsu_info.paddr;
                    commit_axi_req.len   = CACHE_BLOCK_NUM;
                    commit_axi_req.strb  = '0;
                    commit_axi_req.rmask = '1;
                end
            end
            else begin
                commit_axi_valid_o = '1;
                commit_axi_req.addr = commit_axi_req_q.addr;
                commit_axi_req.data = axi_block_data[axi_block_ptr];
            end
        end
    end

    else if(ls_fsm_q == S_ICACHE) begin
        if(~icache_wait) begin
            commit_icache_valid_o = '1;
        end
        else begin
            commit_icache_valid_o = '0;
        end
    end

    // 对于不应该出现的异常情况
    else begin
        stall = '0;
    end
end

// 状态机转移的时序逻辑
always_ff @(posedge clk) begin
    stall_q <= stall;
    commit_cache_req_q  <= commit_cache_req;
    commit_axi_req_q    <= commit_axi_req;
    commit_icache_req_q <= commit_icache_req;

    if(~rst_n) begin
        ls_fsm_q <=  S_NORMSAL;
        axi_wait <= '0;

        cache_block_data<= '0;
        cache_block_ptr <= '0;
        cache_block_len <= '0;

        axi_block_data  <= '0;
        axi_block_ptr   <= '0;
        axi_block_len   <= '0;
    end

    else begin
        // normal状态 且 需要进入Cache状态机
        if(ls_fsm_q == S_NORMAL && is_lsu) begin
            rob_commit_q <= rob_commit_i;

            // Cache维护指令
            if(is_cache_fix[0]) begin
                if(cache_tar == 0) begin
                    if(icache_commit_valid_i) begin
                        ls_fsm_q <= S_ICACHE;
                        icache_wait <= '0;
                    end

                    if(icache_commit_ready_i) begin
                        ls_fsm_q <= S_ICACHE;
                        icache_wait <= '1;
                    end
                end
                else if(cache_tar == 1) begin
                    if(cache_op == 0) begin
                        ls_fsm_q <= S_NORMAL;
                    end
                    else if(cache_op == 1) begin
                        if (lsu_info[0].cacop_dirty) begin
                            ls_fsm_q <= S_CACHE_RD;
                            axi_return_back <= '1;

                            cache_block_ptr <= 0;
                            cache_block_len <= CACHE_BLOCK_NUM;
                            cache_block_data <= '0;
                        end
                        else begin
                            ls_fsm_q <= S_NORMAL;
                        end
                    end
                    else if(cache_op == 2) begin
                        if (lsu_info[0].hit_dirty) begin
                            ls_fsm_q <= S_CACHE_RD;
                            axi_return_back <= '1;

                            cache_block_ptr <= 0;
                            cache_block_len <= CACHE_BLOCK_NUM;
                            cache_block_data <= '0;
                        end
                        else begin
                            ls_fsm_q <= S_NORMAL;
                        end
                    end
                    else begin
                        ls_fsm_q <= S_NORMAL;
                    end
                end

                cache_code_q <= cache_code;
                cache_tar_q <= cache_tar;
                cache_op_q <= cache_op;
            end
            // 如果是uncached请求，直接发起AXI请求
            else if(is_uncached[0]) begin
                ls_fsm_q <= S_UNCACHED;
            end
            // Cache命中
            else if(cache_commit_hit) begin
                ls_fsm_q <= S_NORMAL;
            end
            // Cache不命中
            else begin
                // 读出Cache的整块数据，最后写回
                if(cache_commit_dirty) begin
                    ls_fsm_q <= S_CACHE_RD;

                    cache_dirty_addr <= rob_commit_i[0].cache_dirty_addr & 32'hfffffff0;

                    cache_block_ptr <= 0;
                    cache_block_len <= CACHE_BLOCK_NUM;
                    cache_block_data <= '0;
                end
                // 发出AXI请求，直接读出数据
                else begin
                    ls_fsm_q <= S_AXI_RD;

                    axi_block_ptr <= 0;
                    axi_block_len <= CACHE_BLOCK_NUM;
                    axi_block_data <= '0;
                end
            end
        end

        else if(ls_fsm_q == S_UNCACHED) begin
            // UnCached只需要发起一次请求即可
            if(axi_commit_valid_i) begin
                ls_fsm_q <= S_NORMAL;

                cache_block_ptr <= '0;
                cache_block_len <= '0;
                cache_block_data <= '0;
            end
        end

        // 与Cache进行读写操作
        else if (ls_fsm_q == S_CACHE) begin
            // Cache接受当前的读写请求
            // 回到normal状态，取消提交级的阻塞
            if(cahce_block_ptr == cache_block_len) begin
                ls_fsm_q <= S_NORMAL;

                cache_block_ptr <= '0;
                cache_block_len <= '0;
            end
            else begin
                cache_block_ptr <= cache_block_ptr + 1;
            end
        end

        // 发起AXI请求，读出对应地址处的数据
        else if(ls_fsm_q == S_AXI_RD) begin
            if(axi_commit_valid_i) begin
                // AXI请求完成，进行下一步状态
                if(axi_block_ptr == axi_block_len) begin
                    ls_fsm_q <= S_CACHE;

                    axi_block_ptr <= '0;

                    cache_block_len <= CACHE_BLOCK_NUM;
                    cache_block_ptr <= 0;
                    cache_block_data <= axi_block_data;
                end
                else begin
                    axi_block_data[axi_block_ptr] <= axi_commit_resp_i.data;
                    axi_block_ptr <= axi_block_ptr + 1;
                end
            end
        end

        // 将需要写回部分的Cache整块数据读出
        else if(ls_fsm_q == S_CACHE_RD) begin
            // Cache固定延时一拍出结果
            // 完成了整块的读出操作
            if(cache_block_ptr == cache_block_len) begin
                // 将读出的数据写回
                ls_fsm_q <= S_AXI_WB;
                axi_return_back <= '0;

                axi_block_len <= CACHE_BLOCK_NUM;
                axi_block_ptr <= 0;
                axi_block_data <= cache_block_data;
            end
            else begin
                cache_block_data[cache_block_ptr] <= cache_commit_resp_i.data;
                cache_block_ptr <= cache_block_data + 1;
            end
        end

        // 发起AXI请求，写回对应地址处的数据
        else if (ls_fsm_q == S_AXI_WB) begin
            if(axi_commit_ready_i) begin
                // AXI写回请求完成，再发送AXI请求进行读出所需处的数据
                if(axi_block_ptr == axi_block_len) begin
                    if(axi_return_back) begin
                        ls_fsm_q <= S_NORMAL;
                        axi_return_back <= '0;
                        // 设置相应的AXI数据
                        axi_block_ptr <= '0;
                        axi_block_len <= '0;
                        axi_block_data <= '0;
                    end
                    else begin
                        ls_fsm_q <= S_AXI_RD;
                        // 设置相应的AXI数据
                        axi_block_ptr <= '0;
                        axi_block_len <= CACHE_BLOCK_NUM;
                        axi_block_data <= '0;
                    end
                end
                else begin
                    axi_block_ptr <= axi_block_ptr + 1;
                end
            end
        end

        else if(ls_fsm_q == S_ICACHE) begin
            // 完成了ICache请求
            if(icache_commit_valid_i) begin
                ls_fsm_q <= S_NORMAL;
                icache_wait <= '0;
            end

            if(icache_commit_ready_i) begin
                icache_wait <= '1;
            end
        end

        // 对于不应该出现的异常情况
        else begin
            ls_fsm_q <= S_NORMAL;
        end
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

endmodule
