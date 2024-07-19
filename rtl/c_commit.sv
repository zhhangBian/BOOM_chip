`include "a_defines.svh"

function cache_tag_t get_cache_tag(
    input logic [31:0] addr,
    input logic v,
    input logic d
);
    cache_tag_t cache_tag;
    cache_tag.tag = addr[31:20];
    cache_tag.v = v;
    cache_tag.d = d;.

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

    // 将CSR对应位的值写到寄存器中
    output  logic   commit_csr_valid_o,
    output  logic   [31:0]  commit_csr_data_o,

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
    input   logic   axi_commit_valid_i,
    output  logic   commit_axi_valid_o,
    input   logic   axi_commit_ready_i,
    // 其实没有用到：对axi的last信号
    input   logic   axi_commit_last_i,

    // commit与ARF的接口
    output  logic   [1:0]   commit_arf_we_o,
    output  word_t  [1:0]   commit_arf_data_o,
    output  word_t  [1:0]   commit_arf_areg_o,

    // commit与BPU的接口
    output  logic   commit_bpu_predict_right_o,
    output  word_t  commit_bpu_real_pc_o
);

// ------------------------------------------------------------------
// 处理指令提交逻辑
// 是否将整个提交阻塞
logic stall, stall_q;
assign stall_o = stall;
assign commit_ready_o = ~stall;

assign commit_axi_ready = '1;
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


    if(ls_fsm_q == S_NORMAL) begin
        commit_arf_we_o[0] = commit_request_o[0] & rob_commit_i[0].w_reg;
        commit_arf_data_o[0] = rob_commit_i[0].w_data;
        commit_arf_areg_o[0] = rob_commit_i[0].w_areg;
    end
    else if(ls_fsm_q == S_UNCACHED) begin
        if(axi_commit_valid_i) begin
            commit_arf_we_o[0] = |rob_commit_q.lsu_info.strb;
            commit_arf_data_o[0] = axi_commit_resp_i.data;
            commit_arf_areg_o[0] = rob_commit_q.w_areg;
        end
    end
    // 其余情况均不提交
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 代表相应的指令属性
logic [1:0] is_exc;
logic [1:0] is_lsu_write, is_lsu_read, is_lsu;
logic [1:0] is_uncached;    // 指令为Uncached指令
logic [1:0] is_csr_fix;     // 指令为CSR特权指令
logic [1:0] is_cache_fix;   // 指令为Cache维护指令
logic [1:0] is_tlb_fix;     // 指令为TLB维护指令
logic [1:0] cache_commit_hit; // 此周期输入到cache的地址没有命中
logic [1:0] cache_commit_dirty;

// 与DCache的一级流水交互
lsu_iq_pkg_t [1:0] lsu_info;
assign lsu_info[0] = rob_commit_i[0].lsu_info;
assign lsu_info[1] = rob_commit_i[1].lsu_info;

commit_cache_req_t commit_cache_req, commit_cache_req_q;
assign commit_cache_req_o = commit_cache_req;

commit_axi_req_t commit_axi_req_q, commit_axi_req;
assign commit_axi_req_o = commit_axi_req;

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
    end
end

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 处理全局flush信息
always_comb begin
    // 只要不是现在提交，就刷
    // 此种情况包含了Cache，CSR和TLB维护的情况
    if(~(commit_request_o[0]) && ls_fsm_q == S_NORMAL) begin
        flush = '1;
    end
    else if(is_dbar || is_ibar) begin
        flush = '1;
    end
    else if(|is_lsu) begin
        if(ls_fsm_q == S_NORMAL) begin
            if(!cache_commit_hit) begin
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
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 异常处理
//识别rob_commit_i[0]这一条指令是不是有异常，如果有，修改csr

//cpu要每周期采样中断信号 TODO

//都不是寄存器
logic cur_exception;       //提交的第0条是不是异常指令
logic cur_tlbr_exception;  //提交的第0条指令的异常是不是tlbr异常，用于判断异常入口，上面信号为1才有意义
csr_t csr_exception_update;//周期结束时候写入csr_q

//中断识别
wire [12:0] int_vec = csr_q.estat[`_ESTAT_IS] & csr_q.ecfg[`_ECTL_LIE];
wire int_excep     = csr_q.crmd[`_CRMD_IE] && |int_vec;

//取指异常 TODO 判断的信号从fetch来，要求fetch如果有例外要传一个fetch_exception
wire fetch_excp    = rob_commit_i[0].fetch_exception;

//译码异常 下面的信号来自decoder TODO
wire syscall_excp  = rob_commit_i[0].syscall_inst;
wire break_excp    = rob_commit_i[0].break_inst;
wire ine_excp      = rob_commit_i[0].decode_err;
wire priv_excp     = rob_commit_i[0].priv_inst && csr_q.crmd[`_CRMD_PLV] == 3;

//执行异常 TODO 访存级别如果有地址不对齐错误或者tlb错要传execute_exception信号
wire execute_excp  = rob_commit_i[0].execute_exception;

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
wire a_priv_excp     = rob_commit_i[1].priv_inst && csr_q.crmd[`_CRMD_PLV] == 3;

wire a_execute_excp  = rob_commit_i[1].execute_exception;

wire another_exception    = |{a_fetch_excp, a_syscall_excp, a_break_excp, a_ine_excp,a_priv_excp, a_execute_excp};
//上面是1表示两条指令的后一条有例外

//下面这个部分暂时这样写，是打一排以后把要写入csr的内容最后写入csr中，
//要把它和后面的csr维护等内容考虑冒险之后合并在一起。
//这一部分一定要和后面合在一起重写！！！TODO
always_ff @(posedge clk) begin
    if (rst_n) begin
        <merge with other code>
    end
    else begin
        csr_q <= csr_exception_update;
        <merge with other code>
    end
end


// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// CSR特权指令
// TODO：csr_t的结构需要进一步匹配
csr_t csr, csr_q, csr_init;
logic [2:0] csr_type = rob_commit_i[0].csr_type;
logic [13:0] csr_num = rob_commit_i[0].csr_num;

// 维护CSR信息
always_comb begin
    csr_init                = '0;
    // 初始化要求非0的 CSR 寄存器值
    csr_init.crmd[`_CRMD_DA]= 1'd1;
    csr_init.asid[31:10]    = 22'h280;
    csr_init.cpuid          = CPU_ID;
    csr_init.tid            = CPU_ID;
end

// 对csr_q的信息维护
always_ff @(posedge clk) begin
    if(~rst_n) begin
        csr_q <= csr_init; // 初始化 CSR
    end
    elif (cur_exception) begin
        csr_q <= csr_exception_update; //更改：如果有异常更新为异常
    end
    else begin
        csr_q <= csr;
    end
end

// 对CSR信息的维护
always_comb begin
    csr = csr_q;
    commit_csr_data_o = '0;
    commit_csr_valid_o = '0;

    case (csr_type)
        `_CSR_CSRRD: begin
            commit_csr_valid_o |= '1;
            commit_csr_data_o |= csr_q[csr_num];
        end

        `_CSR_CSRWR: begin
            commit_csr_valid_o |= '1;
            commit_csr_data_o |= csr_q[csr_num];
            csr[csr_num] = rob_commit_i[0].data_rd;
        end

        `_CSR_XCHG: begin
            commit_csr_valid_o |= '1;
            commit_csr_data_o |= csr_q[csr_num];
            csr[csr_num] = rob_commit_i[0].data_rd & rob_commit_i[0].data_rj;
        end

        default: begin

        end
    endcase
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// TLB维护指令
// 不管理TLB的映射内容，只管理TLB的维护内容
// 相当于管理64个TLB表项，对应有一个ITLB和DTLB的映射
tlb_entry_t [63 : 0] tlb_entrys;




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
    // 将Cache表项无效化
    S_CACHE_INVALID
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

logic [31:0] cache_dirty_addr;

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

    if(ls_fsm_q == S_NORMAL && is_lsu) begin
        stall |= ~cache_commit_hit;

        // Cache维护指令
        if(is_cache_fix[0]) begin
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
            // 配置Cache的相应信息
            commit_cache_valid = '1;
            commit_cache_req.addr         = lsu_info[0].paddr;
            commit_cache_req.way_choose   = lsu_info[0].tag_hit;
            commit_cache_req.tag_data     = '0;
            commit_cache_req.data_data    = lsu_info[0].wdata;
            commit_cache_req.strb         = lsu_info[0].strb;
            commit_cache_req.fetch_sb     = |lsu_info[0].strb;
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
            // TODO 写寄存器
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
        if(axi_commit_valid_i) begin
            // AXI请求完成，进行下一步状态
            if(axi_block_ptr == axi_block_len) begin
                commit_cache_valid = '1;
                // TODO ? 
                commit_cache_req   = commit_cache_req
            end
            else begin
                commit_axi_valid_o = '1;
                // 对齐一个字的数据
                // TODO ?
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
        // AXI写回请求完成，再发送AXI请求进行读出所需处的数据
        if(axi_commit_valid_i) begin
            if(axi_block_ptr == axi_block_len) begin
                if(axi_return_back) begin

                end
                else begin
                    commit_axi_valid_o = '1;
                    // 设置相应的AXI数据
                    commit_axi_req.addr  = rob_commit_q.lsu_info.paddr;
                    commit_axi_req.len   = CACHE_BLOCK_NUM;
                    commit_axi_req.strb  = '0;
                    commit_axi_req.rmask = '1;
                end
            end
            else begin
                commit_axi_req.addr = commit_axi_req_q.addr + 4;
                commit_axi_req.data = axi_block_data[axi_block_ptr];
            end
        end
    end

    else if(ls_fsm_q == S_CACHE_INVALID) begin
        if((cache_op_q == 2'd1) || (cache_op_q == 2'd2)) begin
            // 将无效tag写回
            // commit_cache_valid = '1;
            // commit_cache_req.addr = lsu_info[0].addr;
            // commit_cache_req.way_choose = commit_cache_req.addr[0];
            // 将tag无效
            // commit_cache_req.tag_data = get_cache_tag(cache_commit_resp_i.sb_entry.target_addr, '0, '0);
            // commit_cache_req.tag_we = '1;
            // commit_cache_req.data_data = '0;
            // commit_cache_req.strb = '0;
            // commit_cache_req.fetch_sb = '0;
            // 发起AXI请求写回Cache内容
            commit_axi_valid_o = '1;
            commit_axi_req.addr = cache_commit_resp_i.sb_entry.target_addr & 32'hfffffff0;
            commit_axi_req.len = CACHE_BLOCK_NUM;
            commit_axi_req.strb = '1;
            commit_axi_req.rmask = '0;
        end
        else begin

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
    commit_cache_req_q <= commit_cache_req;
    commit_axi_req_q <= commit_axi_req;

    if(~rst_n) begin
        ls_fsm_q <=  S_NORMSAL;

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
                if(cache_op == 0) begin
                    ls_fsm_q <= S_NORMAL;
                end
                else if(cache_op == 1) begin
                    if (lsu_info[0].cacop_dirty) begin
                        ls_fsm_q <= S_CACHE_INVALID;
                    end else begin
                        ls_fsm_q <= S_NORMAL;
                    end
                end
                else if(cache_op == 2) begin
                    if (lsu_info[0].hit_dirty) begin
                        ls_fsm_q <= S_CACHE_INVALID;
                    end else begin
                        ls_fsm_q <= S_NORMAL;
                    end
                end
                else begin
                    ls_fsm_q <= S_NORMAL;
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
                    axi_block_data[block_ptr] <= axi_commit_resp_i.data;
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
            // AXI写回请求完成，再发送AXI请求进行读出所需处的数据
            if(axi_commit_valid_i) begin
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

        else if(ls_fsm_q == S_CACHE_INVALID) begin
            if((cache_op_q == 2'd1) || (cache_op_q == 2'd2)) begin
                ls_fsm_q <= S_AXI_WB;
                axi_return_back <= '1;

                axi_block_len <= CACHE_BLOCK_NUM;
                axi_block_ptr <= 0;
                axi_block_data <= cache_block_data;
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

/* 不出bug
__________████████_____██████
_________█░░░░░░░░██_██░░░░░░█
________█░░░░░░░░░░░█░░░░░░░░░█
_______█░░░░░░░███░░░█░░░░░░░░░█
_______█░░░░███░░░███░█░░░████░█
______█░░░██░░░░░░░░███░██░░░░██
_____█░░░░░░░░░░░░░░░░░█░░░░░░░░███
____█░░░░░░░░░░░░░██████░░░░░████░░█
____█░░░░░░░░░█████░░░████░░██░░██░░█
___██░░░░░░░███░░░░░░░░░░█░░░░░░░░███
__█░░░░░░░░░░░░░░█████████░░█████████
_█░░░░░░░░░░█████_████___████_█████___█
_█░░░░░░░░░░█______█_███__█_____███_█___█
█░░░░░░░░░░░░█___████_████____██_██████
░░░░░░░░░░░░░█████████░░░████████░░░█
░░░░░░░░░░░░░░░░█░░░░░█░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░██░░░░█░░░░░░██
░░░░░░░░░░░░░░░░░░██░░░░░░░███████
░░░░░░░░░░░░░░░░██░░░░░░░░░░█░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
░░░░░░░░░░░█████████░░░░░░░░░░░░░░██
░░░░░░░░░░█▒▒▒▒▒▒▒▒███████████████▒▒█
░░░░░░░░░█▒▒███████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█
░░░░░░░░░█▒▒▒▒▒▒▒▒▒█████████████████          没有bug对吧
░░░░░░░░░░████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█
░░░░░░░░░░░░░░░░░░██████████████████
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█
██░░░░░░░░░░░░░░░░░░░░░░░░░░░██
▓██░░░░░░░░░░░░░░░░░░░░░░░░██
▓▓▓███░░░░░░░░░░░░░░░░░░░░█
▓▓▓▓▓▓███░░░░░░░░░░░░░░░██
▓▓▓▓▓▓▓▓▓███████████████▓▓█
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█
    */