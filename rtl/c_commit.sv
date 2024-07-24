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

function automatic logic [31:0] offset(input logic [31:0] data, input [1:0] m_size, input [3:0] mask, input msigned);
    logic [31:0] lw_data;
    logic        sign;
    lw_data = '0;
    sign    = '0;
    if (m_size == 2'd0) begin
        for (integer i = 0; i < 4; i++) begin
            lw_data[7 : 0]     |= mask[i] ? data[8 * i + 7 -: 8] : '0;
            sign               |= mask[i] ? data[8 * i + 7]         : '0;
        end
        lw_data[31: 8]         |= {24{sign & msigned}};
    end else if (m_size == 2'd1) begin
        for (integer i = 0; i < 2; i++) begin
            lw_data[15: 0]     |= mask[2*i] ? data[16 * i + 15 -: 16] : '0;
            sign               |= mask[2*i] ? data[16 * i + 15]          : '0;
        end
        lw_data[31:16]         |= {16{sign & msigned}};
    end else begin
        lw_data                |= data;
    end
    return lw_data;
endfunction

module commit #(
    parameter int CACHE_BLOCK_NUM = 4,
    parameter int CPU_ID = 0
) (
    input   logic   clk,
    input   logic   rst_n,
    // 唯一一处flush的输出
    output  logic   flush,
    output  logic   stall_o,

    //外部中断接入
    input   logic   [7:0]  hard_is_i,

    // 可能没用
    input   logic   [1:0]   rob_commit_valid_i,
    input   rob_commit_pkg_t rob_commit_i [1:0],

    // 给ROB的输出信号，确定提交相关指令
    //加上的：不是提交，是从rob里面取出
    output  logic   [1:0]   commit_request_o,

    // commit与DCache的接口
    output  commit_cache_req_t  commit_cache_req_o,
    input   cache_commit_resp_t cache_commit_resp_i,

    // commit与AXI的接口
    // axi读端口
    output  logic   commit_axi_arvalid_o,
    input   logic   axi_commit_arready_i,
    input   logic   axi_commit_rvalid_i,
    input   logic   axi_commit_last_i,
    // axi写端口
    output  logic   commit_axi_awvalid_o,
    input   logic   axi_commit_awready_i,
    output  logic   commit_axi_wvalid_o,
    output  logic   commit_axi_wlast_o,
    input   logic   axi_commit_wready_i,

    output  commit_axi_req_t    commit_axi_req_o,
    input   axi_commit_resp_t   axi_commit_resp_i,

    // commit与ARF的接口
    output  logic [31:0] commit_debug_pc_o [1:0],
    output  logic   [1:0]   commit_arf_we_o,
    output  word_t  [1:0]   commit_arf_data_o,
    output  logic [1:0][4:0]commit_arf_areg_o,
    output  logic [1:0][5:0]commit_arf_preg_o,
    output  logic   [1:0]   commit_arf_check_o,

    output  logic [1:0]     retire_request_o,//新增

    // commit与BPU的接口
    output  correct_info_t [1:0]    correct_info_o,
    output  logic [31:0]            redir_addr_o,

    //commit与两个外部tlb/mmu的接口
    output  csr_t            csr_o,
    output  tlb_write_req_t  tlb_write_req_o,

    // commit与ICache的握手信号
    output  commit_icache_req_t     commit_icache_req_o,
    // 2'b01 tlb_exc, 2'b10 tag_miss, other normal
    input   logic [1:0]             icache_cacop_flush_i,
    // ICache返回TLB异常
    input   tlb_exception_t         icache_cacop_tlb_exc_i,
    input   logic [31:0]            icache_cacop_bvaddr_i,
    output  logic   commit_icache_valid_o,
    input   logic   icache_commit_ready_i,
    input   logic   icache_commit_valid_i
);

// ------------------------------------------------------------------
// 处理指令提交逻辑
// 是否将整个提交阻塞
logic stall, stall_q;
assign stall_o = stall;

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
//TODO : 最后提交的逻辑，flush的逻辑，部分接线，ibar（不实现）

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// -----------------------------------------------------------------
//选择往后流水的逻辑，逻辑是要么传过去能提交的指令，要么传过去的第一条是要进状态机的

//这个部分在第一级：整理信号，判断有无异常，判断分支预测结果
logic [1:0] is_branch;
logic [1:0] taken;
logic [1:0] predict_success;

logic [1:0] first_commit;
logic cur_exception;       //提交的第0条是不是异常指令

//都不是寄存器
logic cur_tlbr_exception;  //提交的第0条指令的异常是不是tlbr异常，用于判断异常入口，上面信号为1才有意义
csr_t csr_exception_update;//周期结束时候写入csr_q

//__forward()
logic cur_exception_q;
logic cur_tlbr_exception_q;
csr_t csr_exception_update_q;

logic fsm_flush;
logic [31:0] fsm_npc;
logic [31:0] pc_s;

//idle指令
logic wait_for_int_q, wait_for_int;

csr_t csr_q;//这个是正宗的csr本体

always_comb begin
    //在有效的情况下是不是单提交的情况
    first_commit[0]     = rob_commit_i[0].flush_inst | //一定flush指令
                          (|rob_commit_i[0].lsu_info.strb) | //store
                          cur_exception | //异常
                          ~rob_commit_i[0].lsu_info.hit | //cache miss
                          ~predict_success[0];//预测错

    first_commit[1]     = rob_commit_i[1].flush_inst | 
                          (|rob_commit_i[1].lsu_info.strb) | 
                          another_exception | 
                          ~rob_commit_i[1].lsu_info.hit;//仅第二条分支预测失败也可以双提

    commit_request_o[0] = rob_commit_valid_i[0] & ~stall;

`ifdef _VERILATOR
    commit_request_o[1] = rob_commit_valid_i[0] &
                          rob_commit_valid_i[1] &
                          ~stall &
                          ~first_commit[0] &
                          ~first_commit[1];
`endif

`ifdef _FPGA
    commit_request_o[1]  = 0;
`endif

end


//下面两个是第二级的数据来源，这样也避免了一些情况，比如说刷掉流水导致找不到之前的数据
//flush对1->2部分的数据不应该刷掉自己
logic [1:0] commit_request_q;
rob_commit_pkg_t rob_commit_q [1:0];
//__forward()
//下面只是一个组合逻辑，如果传指令过去就一起传包，否则全0
rob_commit_pkg_t rob_commit_flow[1:0];

assign rob_commit_flow[0] = commit_request_o[0] ? rob_commit_i[0] : '0;
assign rob_commit_flow[1] = commit_request_o[1] ? rob_commit_i[1] : '0;

//注意flush把这一级也flush了
always_ff @( posedge clk ) begin
    if (~rst_n) begin
        commit_request_q <= '0;
        rob_commit_q <= '{'0,'0};
    end
    else if (stall) begin
        //注意：对于stall的情况，我保留了之前的请求，这意味着retire的时候不能直接用commit_request_q
        commit_request_q <= commit_request_q;
        rob_commit_q     <= rob_commit_q;
    end
    else if (flush) begin//TODO 放在stall后面，也就是说如果stall（进状态机）会保留信息
        commit_request_q <= '0;
        rob_commit_q <= '{'0,'0};
    end
    else begin
        commit_request_q <= commit_request_o;
        rob_commit_q     <= rob_commit_flow;
    end
end

///////////////////////////////////////////////////////////////////////
//第二级
//引入了retire_request，区别于commit_request
assign retire_request_o[0] = commit_request_q[0] & ~stall;
assign retire_request_o[1] = commit_request_q[1] & ~stall;

logic [31:0] rdcnt_data;
logic [31:0] rdcnt_data_q;
logic [31:0] commit_csr_data_q;

// 定义写的状态机
typedef enum logic[4:0] {
    // 正常状态
    S_NORMAL,
    // 将Cache的内容读出
    S_CACHE_RD,
    // 通过AXI总线读出内容
    S_AXI_RD,
    // UnCached情况下直接发起AXI请求
    S_UNCACHED_RD,
    S_UNCACHED_WB,
    // 等待ICache请求完成
    S_ICACHE
} ls_fsm_s;
ls_fsm_s ls_fsm, ls_fsm_q;

// 处理对ARF的接口
always_comb begin
    commit_arf_we_o = '0;
    commit_arf_data_o = '0;
    commit_arf_areg_o = '0;
    commit_arf_preg_o = '0;
    commit_arf_check_o = '0;

    for (integer i = 0; i < 2; i = i + 1) begin
        commit_arf_we_o[i]   = retire_request_o[i] & rob_commit_q[i].w_reg & !cur_exception_q;
        //接到rename级的要用这个！

        commit_debug_pc_o[i]   = rob_commit_q[i].pc;
        commit_arf_data_o[i] = rob_commit_q[i].rdcnt_en  ? rdcnt_data_q:
                               |rob_commit_q[i].csr_type ? commit_csr_data_q:
                               rob_commit_q[i].w_data;

        commit_arf_areg_o[i] = rob_commit_q[i].arf_id;
        commit_arf_preg_o[i] = rob_commit_q[i].rob_id;
        commit_arf_check_o[i] = rob_commit_q[i].check;
    end

    if(ls_fsm_q == S_UNCACHED_RD) begin
        if(axi_commit_rvalid_i) begin
            commit_debug_pc_o[0]   = rob_commit_q[0].pc;
            commit_arf_we_o[0]   = |rob_commit_q[0].lsu_info.rmask;
            commit_arf_data_o[0] = offset(axi_commit_resp_i.rdata, rob_commit_q[0].lsu_info.msize, rob_commit_q[0].lsu_info.rmask, rob_commit_q[0].lsu_info.msigned);//TODO rdata mask
            commit_arf_areg_o[0] = rob_commit_q[0].arf_id;
            commit_arf_preg_o[0] = rob_commit_q[0].rob_id;
            commit_arf_check_o[0] = rob_commit_q[0].check;
            //有了上面哪个时序，这个rob_commit_q就可以直接用了
        end
    end
// TODO 好像还有sc
/*
    if(~stall) begin
        commit_arf_we_o[1] = commit_request_o[1] & rob_commit_i[1].w_reg;
        commit_arf_data_o[1] = rob_commit_i[1].w_data;
        commit_arf_areg_o[1] = rob_commit_i[1].arf_id;
        commit_arf_preg_o[1] = rob_commit_i[1].rob_id;
    end
//下面与状态机有关的情况还得加到上面去，已经加了，只有uncached

    if(is_csr_fix[0]) begin
        commit_arf_we_o[0]   = commit_request_o[0] & !cur_exception;
        commit_arf_data_o[0] = commit_csr_data_o;
        commit_arf_areg_o[0] = rob_commit_i[0].arf_id;
        commit_arf_preg_o[0] = rob_commit_i[0].rob_id;
    end
    else if (rdcnt_en[0]) begin
        commit_arf_we_o[0]   = commit_request_o[0] & !cur_exception;
        commit_arf_data_o[0] = rdcnt_data_o;
        commit_arf_areg_o[0] = rob_commit_i[0].arf_id;
        commit_arf_preg_o[0] = rob_commit_i[0].rob_id;
    end
    //csr指令和rdcnt指令的提交，已完成

    else if(ls_fsm_q == S_NORMAL) begin
        commit_arf_we_o[0]   = commit_request_o[0] & & !cur_exception & rob_commit_i[0].w_reg;
        commit_arf_data_o[0] = rob_commit_i[0].w_data;
        commit_arf_areg_o[0] = rob_commit_i[0].arf_id;
        commit_arf_preg_o[0] = rob_commit_i[0].rob_id;
    end
    else if(ls_fsm_q == S_UNCACHED) begin
        if(axi_commit_valid_i) begin
            commit_arf_we_o[0]   = |rob_commit_q.lsu_info.rmask;
            commit_arf_data_o[0] = axi_commit_resp_i.data;
            commit_arf_areg_o[0] = rob_commit_q.arf_id;
            commit_arf_preg_o[0] = rob_commit_q.rob_id;
        end
    end
    // 其余情况均不提交
*/
end

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 代表相应的指令属性
//这些全部都是第二级的，但是没有加_q！！！！！！！！！！！！！！！！！！！！
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
lsu_iq_pkg_t lsu_info [1:0];
assign lsu_info[0] = rob_commit_q[0].lsu_info;
assign lsu_info[1] = rob_commit_q[1].lsu_info;

// 判断指令类型
for(genvar i = 0; i < 2; i += 1) begin
    always_comb begin
        // 处理后续的竞争逻辑
        is_lsu_write[i] = |lsu_info[i].strb;
        is_lsu_read[i]  = |lsu_info[i].rmask;

        is_lsu[i]       = is_lsu_write[i] | is_lsu_read[i];
        is_uncached[i]  = rob_commit_q[i].is_uncached;
        is_csr_fix[i]   = rob_commit_q[i].is_csr_fix;
        is_cache_fix[i] = rob_commit_q[i].is_cache_fix;
        is_tlb_fix[i]   = rob_commit_q[i].is_tlb_fix;

        cache_commit_hit[i]   = lsu_info[i].hit;
        cache_commit_dirty[i] = lsu_info[i].dirty;

        is_ll[i]        = rob_commit_q[i].is_ll;
        is_sc[i]        = rob_commit_q[i].is_sc;
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 处理全局flush信息
// 只在第二级

logic [1:0] commit_flush_info;
logic [1:0] predict_success_q;
logic [1:0][31:0] next_pc_q;
predict_info_t predict_info_q [1:0];
logic [1:0] taken_q;
branch_info_t branch_info_q [1:0];
logic [1:0][31:0] real_target_q;
logic [31:0]      exp_pc_q;
logic [1:0]       predict_branch_q;
logic [1:0]       is_branch_q;

always_comb begin
    commit_flush_info = '0;

    if (fsm_flush) begin
        commit_flush_info = 2'b01;
    end//访存相关的flush

    else if (cur_exception_q) begin
        commit_flush_info = 2'b01;
    end
    //异常则flush

    else if (retire_request_o[0]) begin
        if (rob_commit_q[0].flush_inst) begin
            commit_flush_info = 2'b01;
        end//要提交且一定会flush的指令
        else if (~predict_success_q[0])begin
            commit_flush_info = 2'b01;
        end//分支预测失败
        else if (retire_request_o[1] & ~predict_success_q[1]) begin
            commit_flush_info = 2'b10;
        end//第一条成功但第二条失败了
    end

//下面这一大坨就用上面的替代掉了
/*
    if(((ls_fsm_q == S_ICACHE) && icache_commit_valid_i) ||
            ((ls_fsm_q == S_NORMAL) && commit_icache_valid_o &&
              icache_commit_valid_i && icache_commit_ready_i)) begin
        commit_flush_info = 2'b01;
    end

    else if(|is_lsu//是不是要加valid) begin
        if(ls_fsm_q == S_NORMAL) begin
            if(!&cache_commit_hit) begin
                flush = '1;
            end
            else if(is_uncached[0]) begin
                commit_flush_info = 2'b01;
            end
        end
    end //存储指令
*/

//这个不太一样，是idle的状态
    if (wait_for_int_q) begin
        commit_flush_info = 2'b01;
    end//idle持续flush

    flush = |commit_flush_info;
end

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 处理分支预测信息
//在第一级

// 分支预测是否正确：按照第一条错误的分支指令来

word_t [1:0] next_pc;
word_t [1:0] real_target;

predict_info_t [1:0] predict_info;
assign predict_info[0] = rob_commit_i[0].predict_info;
assign predict_info[1] = rob_commit_i[1].predict_info;

logic [1:0] predict_branch;

branch_info_t [1:0] branch_info;
assign branch_info[0] = rob_commit_i[0].branch_info;
assign branch_info[1] = rob_commit_i[1].branch_info;


// 异常PC入口
logic [31:0] exp_pc;
assign exp_pc = cur_tlbr_exception ? csr_q.tlbrentry : csr_q.eentry ;

// 计算实际跳转的PC
// 
for(genvar i = 0; i < 2; i += 1) begin
    always_comb begin
        real_target[i] = '0;
        next_pc[i] = rob_commit_i[i].pc + 4;
        predict_branch[i] = predict_info[i].is_branch;//fixed

        case (branch_info[i].br_type)
            // 比较结果由ALU进行计算
            BR_B: begin
                real_target[i] = rob_commit_i[i].pc + rob_commit_i[i].data_imm;
                next_pc[i] = real_target[i]; // TODO: check
            end
            BR_NORMAL: begin
                real_target[i] = rob_commit_i[i].pc + rob_commit_i[i].data_imm;
                if (rob_commit_i[i].w_data == 1) begin
                    next_pc[i] = real_target[i]; // TODO: check
                end
            end
            BR_CALL: begin
                real_target[i] = rob_commit_i[i].data_imm;
                next_pc[i] = rob_commit_i[i].data_imm;
            end
            BR_RET: begin
                real_target[i] = rob_commit_i[i].data_imm + rob_commit_i[i].data_rj;
                next_pc[i] = real_target[i]; // TODO: check
            end
            default: begin
            end
        endcase
    end
end

// 计算分支预测是否正确
for(genvar i = 0; i < 2; i += 1) begin
    always_comb begin
        is_branch[i] = branch_info[i].is_branch;
        taken[i] = ((branch_info[i].br_type != BR_NORMAL) ||
                    (rob_commit_i[i].w_data == 1));
        predict_success[i] = predict_info[i].next_pc == next_pc[i];
    end
end

always_ff @( posedge clk ) begin
    if (~rst_n) begin
        predict_success_q <= '0;
        next_pc_q         <= '0;
        predict_info_q    <= '{'0,'0};
        taken_q           <= '0;
        branch_info_q     <= '{'0,'0};
        real_target_q     <= '0;
        exp_pc_q          <= '0;
        predict_branch_q  <= '0;
        is_branch_q       <= '0;
    end
    else if (stall) begin
        predict_success_q <= predict_success_q;
        next_pc_q         <= next_pc_q;
        predict_info_q    <= predict_info_q;
        taken_q           <= taken_q;
        branch_info_q     <= branch_info_q;
        real_target_q     <= real_target_q;
        exp_pc_q          <= exp_pc_q;
        predict_branch_q  <= predict_branch_q;
        is_branch_q       <= is_branch_q;
    end
    else if (flush) begin
        predict_success_q <= '0;
        next_pc_q         <= '0;
        predict_info_q    <= '{'0,'0};
        taken_q           <= '0;
        branch_info_q     <= '{'0,'0};
        real_target_q     <= '0;
        exp_pc_q          <= '0;
        predict_branch_q  <= '0;
        is_branch_q       <= '0;
    end
    else begin
        predict_success_q <= predict_success;
        next_pc_q         <= next_pc;
        predict_info_q    <= {predict_info[1],predict_info[0]};
        taken_q           <= taken;
        branch_info_q     <= {branch_info[1],branch_info[0]};
        real_target_q     <= real_target;
        exp_pc_q          <= exp_pc;
        predict_branch_q  <= predict_branch;
        is_branch_q       <= is_branch;
    end
end


///////////////////////////////////////////////////////////////////////////////////
//在第二级
//把之前打包的东西打一拍过来TODO

//flush的时候才有意义，所以可以省掉一些逻辑
assign redir_addr_o = (fsm_flush) ? fsm_npc ://fsm来的npc
                     (cur_exception_q) ? exp_pc_q : //异常入口
                     (rob_commit_q[0].ertn_en) ? csr_q.era : //异常返回
                     next_pc_q[commit_flush_info[1]];//执行next_pc，这里认为flush只可能来自某条commit

assign correct_info_o[0].update = retire_request_o[0] &
                           ((predict_info_q[0].need_update) |
                           (predict_branch_q[0]) |
                           (is_branch_q[0]));

assign correct_info_o[1].update = retire_request_o[1] &
                           ((predict_info_q[1].need_update) |
                           (predict_branch_q[1]) |
                           (is_branch_q[1])) &
                           commit_flush_info[1];//如果是前一条flush则不更新这一条
                        //表示是第二条带来的flush
                        // 如果是由0发出的flush，则1不update，可以通过第二级的组合逻辑信号commit_flush_info知道是哪个导致了flush


//全部要打一拍！
for(genvar i = 0; i < 2; i += 1) begin
    always_comb begin
        correct_info_o[i].pc = rob_commit_q[i].pc;

        correct_info_o[i].target_miss = (predict_info_q[i].target_pc != real_target_q[i]);
        correct_info_o[i].type_miss = (predict_info_q[i].br_type != branch_info_q[i].br_type);

        correct_info_o[i].taken = taken_q[i];
        correct_info_o[i].is_branch = branch_info_q[i].is_branch;
        correct_info_o[i].branch_type = branch_info_q[i].br_type;

        correct_info_o[i].target_pc = real_target_q[i];

        correct_info_o[i].history = predict_info_q[i].history;
        correct_info_o[i].scnt = predict_info_q[i].scnt;
    end
end

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 维护提交级的计时器
// 在第一级

// 维护一个提交级的时钟
logic [63:0] timer_64, timer_64_q;

always_ff @(posedge clk) begin
    if(~rst_n) begin
        timer_64_q <= '0;
    end
    else begin
        timer_64_q <= timer_64;
    end
end

always_comb begin
    timer_64 = timer_64_q + 64'b01;
end

//rdcnt命令
//__forward()

//第一级读取
always_comb begin
    rdcnt_data = '0;
    if (rob_commit_i[0].rdcntvl_en) begin
        rdcnt_data = timer_64_q[31:0];
    end
    else if (rob_commit_i[0].rdcntvh_en) begin
        rdcnt_data = timer_64_q[63:32];
    end
    else if (rob_commit_i[0].rdcntid_en) begin
        rdcnt_data = csr_q.tid;
    end
end

always_ff @( posedge clk ) begin
    rdcnt_data_q <= rdcnt_data;
end

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 异常处理
//识别rob_commit_i[0]这一条指令是不是有异常，如果有，修改csr
//识别在第一级，写入csr和刷流水线在第二级
//TODO icache异常在第二级处理

//icache的维护指令出现tlb异常 wire cacop_excep   = |icache_cacop_tlb_exc_i;
/*
        //cacop
        7'b001?????: begin
            csr_exception_update.estat[`_ESTAT_ECODE]    = icache_cacop_tlb_exc_i.exc_code;
            csr_exception_update.estat[`_ESTAT_ESUBCODE] = '0;
            csr_exception_update.badv                    = icache_cacop_bvaddr_i; //存badv
            csr_exception_update.tlbehi[`_TLBEHI_VPPN]   = icache_cacop_bvaddr_i[31:13];  //一定是tlb异常，tlb例外存vppn
            if (rob_commit_i[0].exc_code == `_ECODE_TLBR) begin
                cur_tlbr_exception = 1'b1;
            end
        end
*/



//中断识别
wire [12:0] int_vec = csr_q.estat[`_ESTAT_IS] & csr_q.ecfg[`_ECFG_LIE];
wire int_excep      = csr_q.crmd[`_CRMD_IE] && |int_vec;

//TODO 现在为了消除“环”，cur_excpetion信号在无效的时候也可能为1
//取指异常  判断的信号从fetch来，要求fetch如果有例外要传一个fetch_exception
wire fetch_excp    = rob_commit_i[0].fetch_exception;


//译码异常 下面的信号来自decoder
wire syscall_excp  = rob_commit_i[0].syscall_inst;
wire break_excp    = rob_commit_i[0].break_inst;
wire ine_excp      = rob_commit_i[0].decode_err;
wire priv_excp     = rob_commit_i[0].priv_inst && (csr_q.crmd[`_CRMD_PLV] == 3);

//执行异常  访存级别如果有地址不对齐错误或者tlb错要传execute_exception信号
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
    /*对应2，TODO:要pc，如果在状态机里面要去其他地方拿!!!*/

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
            csr_exception_update.badv                    = rob_commit_i[0].badva; //存badv
            if (rob_commit_i[0].exc_code != `_ECODE_ADEF) begin
                csr_exception_update.tlbehi[`_TLBEHI_VPPN] = rob_commit_i[0].badva[31:13];        //tlb例外存vppn
            end
            if (rob_commit_i[0].exc_code == `_ECODE_TLBR) begin
                cur_tlbr_exception = 1'b1;
            end
        end
        /*取指例外 判断的信号从fetch来，
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
        访存级别如果有地址不对齐错误或者tlb错误
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

assign another_exception    = |{a_fetch_excp, a_syscall_excp, a_break_excp, a_ine_excp,a_priv_excp, a_execute_excp};
//上面是1表示两条指令的后一条有例外
//注意：这个信号只用来判断是不是单个提交，所以不用判断指令是否有效，其他地方后面不能直接用！！！

always_ff @( posedge clk ) begin
    if (~rst_n) begin
        cur_exception_q <= '0;
        cur_tlbr_exception_q <= '0;
        csr_exception_update_q <= '0;
    end
    else if (stall) begin
        cur_exception_q      <= cur_exception_q;
        cur_tlbr_exception_q <= cur_tlbr_exception_q;
        csr_exception_update_q <= csr_exception_update_q;
    end
    else if (flush) begin
        cur_exception_q <= '0;
        cur_tlbr_exception_q <= '0;
        csr_exception_update_q <= '0;
    end
    else begin
        cur_exception_q <= cur_exception;
        cur_tlbr_exception_q <= cur_tlbr_exception;
        csr_exception_update_q <= csr_exception_update;
    end
end

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// CSR特权指令


csr_t csr, csr_maintain_q, csr_init;
wire  [1:0] csr_type = rob_commit_i[0].csr_type;
wire [13:0] csr_num  = rob_commit_i[0].csr_num;
//在第一级读出来，写到临时地方
//第二级和tlb什么的仲裁一下

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
//__forward();

// 从CSR读取的旧值（默认在第一级读出来）
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
        default: begin
        end
    endcase
end

//传到第二级arf，不管有没有用都读出来
always_ff @( posedge clk ) begin
    if (~rst_n) begin
        commit_csr_data_q <= '0;
        csr_maintain_q    <= '0;
    end
    else begin
        commit_csr_data_q <= commit_csr_data_o;
        csr_maintain_q    <= csr;
    end
end

////////////////////////////////////////////////////////////////////////////////
//csr写
//csr写处理在第一级，写入在第二级
logic timer_interrupt_clear;
logic timer_interrupt_clear_q;
//__forward()

always_ff @( posedge clk ) begin
    if (~rst_n) begin
        timer_interrupt_clear_q <= '0;
    end
    else begin
        timer_interrupt_clear_q <= timer_interrupt_clear;
    end
end

//定义软件写csr寄存器的行为
`define write_csr_mask(csr_name, mask) csr.``csr_name``[mask] = write_data[mask];

task write_csr(input [31:0] write_data, input [13:0] csr_num_param);
    timer_interrupt_clear = 0;
    begin
        unique case (csr_num_param)
            `_CSR_CRMD: begin
                `write_csr_mask(crmd, `_CRMD_PLV);
                `write_csr_mask(crmd, `_CRMD_IE);
                `write_csr_mask(crmd, `_CRMD_DA);
                `write_csr_mask(crmd, `_CRMD_PG);
                `write_csr_mask(crmd, `_CRMD_DATF);
                `write_csr_mask(crmd, `_CRMD_DATM);
            end
            `_CSR_PRMD: begin
                `write_csr_mask(prmd, `_PRMD_PIE);
                `write_csr_mask(prmd, `_PRMD_PPLV);
            end
            `_CSR_EUEN: begin
                `write_csr_mask(euen, `_EUEN_FPE);
            end
            `_CSR_ECFG: begin
                `write_csr_mask(ecfg, `_ECFG_LIE1);
                `write_csr_mask(ecfg, `_ECFG_LIE2);
            end
            `_CSR_ESTAT: begin
                `write_csr_mask(estat, `_ESTAT_SOFT_IS);
            end
            `_CSR_ERA: begin
                `write_csr_mask(era, 31:0);
            end
            `_CSR_BADV: begin
                `write_csr_mask(badv, 31:0);
            end
            `_CSR_EENTRY: begin
                `write_csr_mask(eentry, `_EENTRY_VA);
            end
            `_CSR_CPUID: begin
                //do nothing
            end
            `_CSR_SAVE0: begin
                `write_csr_mask(save0, 31:0);
            end
            `_CSR_SAVE1: begin
                `write_csr_mask(save1, 31:0);
            end
            `_CSR_SAVE2: begin
                `write_csr_mask(save2, 31:0);
            end
            `_CSR_SAVE3: begin
                `write_csr_mask(save3, 31:0);
            end
            `_CSR_LLBCTL: begin
                if (write_data[`_LLBCT_WCLLB]) begin
                    csr.llbit = 0;
                end
                `write_csr_mask(llbctl, `_LLBCT_KLO);
            end
            `_CSR_TLBIDX: begin
                `write_csr_mask(tlbidx, `_TLBIDX_INDEX);
                `write_csr_mask(tlbidx, `_TLBIDX_PS);
                `write_csr_mask(tlbidx, `_TLBIDX_NE);
            end
            `_CSR_TLBEHI: begin
                `write_csr_mask(tlbehi, `_TLBEHI_VPPN);
            end
            `_CSR_TLBELO0: begin
                `write_csr_mask(tlbelo0, `_TLBELO_TLB_V);
                `write_csr_mask(tlbelo0, `_TLBELO_TLB_D);
                `write_csr_mask(tlbelo0, `_TLBELO_TLB_PLV);
                `write_csr_mask(tlbelo0, `_TLBELO_TLB_MAT);
                `write_csr_mask(tlbelo0, `_TLBELO_TLB_G);
                `write_csr_mask(tlbelo0, `_TLBELO_TLB_PPN);
            end
            `_CSR_TLBELO1: begin
                `write_csr_mask(tlbelo1, `_TLBELO_TLB_V);
                `write_csr_mask(tlbelo1, `_TLBELO_TLB_D);
                `write_csr_mask(tlbelo1, `_TLBELO_TLB_PLV);
                `write_csr_mask(tlbelo1, `_TLBELO_TLB_MAT);
                `write_csr_mask(tlbelo1, `_TLBELO_TLB_G);
                `write_csr_mask(tlbelo1, `_TLBELO_TLB_PPN);
            end
            `_CSR_ASID: begin
                `write_csr_mask(asid, `_ASID);
            end
            `_CSR_PGDL: begin
                `write_csr_mask(pgdl, `_PGD_BASE);
            end
            `_CSR_PGDH: begin
                `write_csr_mask(pgdh, `_PGD_BASE);
            end
            `_CSR_PGD: begin
                //do nothing
            end
            `_CSR_TLBRENTRY: begin
                `write_csr_mask(tlbrentry, `_TLBRENTRY_PA);
            end
            `_CSR_DMW0: begin
                `write_csr_mask(dmw0, `_DMW_PLV0);
                `write_csr_mask(dmw0, `_DMW_PLV3);
                `write_csr_mask(dmw0, `_DMW_MAT);
                `write_csr_mask(dmw0, `_DMW_PSEG);
                `write_csr_mask(dmw0, `_DMW_VSEG);
            end
            `_CSR_DMW1: begin
                `write_csr_mask(dmw1, `_DMW_PLV0);
                `write_csr_mask(dmw1, `_DMW_PLV3);
                `write_csr_mask(dmw1, `_DMW_MAT);
                `write_csr_mask(dmw1, `_DMW_PSEG);
                `write_csr_mask(dmw1, `_DMW_VSEG);
            end
            `_CSR_TID: begin
                `write_csr_mask(tid, 31:0);
            end
            `_CSR_TCFG: begin
                `write_csr_mask(tcfg, `_TCFG_EN);
                `write_csr_mask(tcfg, `_TCFG_PERIODIC);
                `write_csr_mask(tcfg, `_TCFG_INITVAL);
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
            begin
            end
        endcase
    end
endtask


//csr访问指令对csr寄存器的修改
//第一级
always_comb begin
    csr = csr_q;

    unique case (csr_type)
        `_CSR_CSRRD: begin
            //do nothing
        end
        `_CSR_CSRWR: begin
            write_csr(rob_commit_i[0].data_rk, csr_num);//rk是rd TODO
        end

        `_CSR_CSRXCHG: begin
            write_csr((rob_commit_i[0].data_rk & rob_commit_i[0].data_rj), csr_num);//rk是rd
        end

        default: begin//do nothing
        end
    endcase
end



// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
//在第一级
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
csr_t tlb_update_csr, tlb_update_csr_q;/*对csr的更新*/
tlb_entry_t tlb_entry/*前面是一个临时变量*/,tlb_update_entry,tlb_update_entry_q;/*更新进tlb的内容*/
logic [`_TLB_ENTRY_NUM - 1:0] tlb_wr_req, tlb_wr_req_q;/*更新进tlb的使能位*/
//__forward()

always_ff @( posedge clk ) begin
    if (~rst_n) begin
        tlb_update_csr_q <= '0;
        tlb_update_entry_q <= '0;
        tlb_wr_req_q <= '0;
    end
    else if (stall) begin
        tlb_update_csr_q     <= tlb_update_csr_q;
        tlb_update_entry_q   <= tlb_update_entry_q;
        tlb_wr_req_q         <= tlb_wr_req_q;
    end
    else if (flush) begin
        tlb_update_csr_q <= '0;
        tlb_update_entry_q <= '0;
        tlb_wr_req_q <= '0;
    end
    else begin
        tlb_update_csr_q <= tlb_update_csr;
        tlb_update_entry_q <= tlb_update_entry;
        tlb_wr_req_q <= tlb_wr_req;
    end
end

always_comb begin
    tlb_update_csr = csr_q;
    tlb_update_entry = '0;
    tlb_wr_req     = '0;
    tlb_entry      = '0;

    if (cur_tlbsrch) begin
        //下面找对应的表项，同mmu里面的找法
        tlb_update_csr.tlbidx[`_TLBIDX_NE] = 1;
        for (integer i = 0; i < `_TLB_ENTRY_NUM; i += 1) begin
            if (tlb_entries_q[i].key.e
                && (tlb_entries_q[i].key.g || (tlb_entries_q[i].key.asid == csr_q.asid[`_ASID]))
                && vppn_match(csr_q.tlbehi, tlb_entries_q[i].key.huge_page, tlb_entries_q[i].key.vppn)) begin
                    tlb_update_csr.tlbidx[`_TLBIDX_INDEX] = i[$clog2(`_TLB_ENTRY_NUM) - 1:0]; //不知道这里语法有没有问题
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
            tlb_update_csr.tlbelo0[`_TLBELO_TLB_G]  = tlb_entry.key.g;
            tlb_update_csr.tlbelo0[`_TLBELO_TLB_PPN]= tlb_entry.value[0].ppn;

            tlb_update_csr.tlbelo1[`_TLBELO_TLB_V]  = tlb_entry.value[1].v;
            tlb_update_csr.tlbelo1[`_TLBELO_TLB_D]  = tlb_entry.value[1].d;
            tlb_update_csr.tlbelo1[`_TLBELO_TLB_PLV]= tlb_entry.value[1].plv;
            tlb_update_csr.tlbelo1[`_TLBELO_TLB_MAT]= tlb_entry.value[1].mat;
            tlb_update_csr.tlbelo1[`_TLBELO_TLB_G]  = tlb_entry.key.g;
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
                for (integer i = 0; i < `_TLB_ENTRY_NUM; i = i + 1) begin
                    if (tlb_entries_q[i].key.g) begin
                        tlb_wr_req[i] = 1;
                    end
                end
            end
            5'h3: begin
                for (integer i = 0; i < `_TLB_ENTRY_NUM; i = i + 1) begin
                    if (!tlb_entries_q[i].key.g) begin
                        tlb_wr_req[i] = 1;
                    end
                end
            end
            5'h4: begin
                for (integer i = 0; i < `_TLB_ENTRY_NUM; i = i + 1) begin
                    if (!tlb_entries_q[i].key.g &&
                        tlb_entries_q[i].key.asid == rob_commit_i[0].data_rj[9:0]) begin
                        tlb_wr_req[i] = 1;
                    end
                end
            end
            5'h5: begin
                for (integer i = 0; i < `_TLB_ENTRY_NUM; i = i + 1) begin
                    if (!tlb_entries_q[i].key.g &&
                        tlb_entries_q[i].key.asid == rob_commit_i[0].data_rj[9:0] &&
                        vppn_match(rob_commit_i[0].data_rk, tlb_entries_q[i].key.huge_page, tlb_entries_q[i].key.vppn)) begin
                        tlb_wr_req[i] = 1;
                    end
                end
            end
            5'h6: begin
                for (integer i = 0; i < `_TLB_ENTRY_NUM; i = i + 1) begin
                    if ((tlb_entries_q[i].key.g ||
                        tlb_entries_q[i].key.asid == rob_commit_i[0].data_rj[9:0]) &&
                        vppn_match(rob_commit_i[0].data_rk, tlb_entries_q[i].key.huge_page, tlb_entries_q[i].key.vppn)) begin
                        tlb_wr_req[i] = 1;
                    end
                end
            end
            default: begin
            end
        endcase
    end

    if (!commit_request_o[0]) begin
        tlb_wr_req = '0;
    end//不是将要提交的命令，则上面全部不用，注意可能有异常！！！
end

function automatic logic vppn_match(input logic [31:0] va,
                                    input logic huge_page, input logic [18: 0] vppn);
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

/////////////////////////////////////////////////////////////////////////
//第二级
//纯组合逻辑输出

always_comb begin
    csr_o = csr_q;
    tlb_write_req_o.tlb_write_req   = cur_exception_q ? 0 : tlb_wr_req_q;//这个放在第二级是因为前一级比较爆炸
    tlb_write_req_o.tlb_write_entry = tlb_update_entry_q;
end

//周期结束的时候更新进tlb，同时也发出去更新mmu里面的tlb
always_ff @( posedge clk ) begin
    for (integer i = 0; i < `_TLB_ENTRY_NUM; i = i + 1) begin
        if (~cur_exception_q & tlb_wr_req_q[i]) begin
            tlb_entries_q[i] <= tlb_update_entry_q;
        end
    end
end

csr_t csr_update;

//下面这个组合逻辑内部顺序不要更改
always_comb begin
    if (retire_request_o[0]) begin
        if (rob_commit_q[0].is_tlb_fix) begin
            csr_update = tlb_update_csr_q;
        end
        else if (rob_commit_q[0].is_csr_fix) begin
            csr_update = csr_maintain_q;
        end
        else if (rob_commit_q[0].ertn_en) begin
            csr_update.crmd[`_CRMD_PLV] = csr_q.prmd[`_PRMD_PPLV];
            csr_update.crmd[`_CRMD_IE]  = csr_q.prmd[`_PRMD_PIE];
            if (csr_q.llbctl[`_LLBCT_KLO]) begin
                csr_update.llbctl[`_LLBCT_KLO] = 0;
            end
            else begin
                csr_update.llbit = 0;
            end
        end
        else if (is_ll[0]) begin//注意，这个信号虽然没有_q，但是的确是第二拍的！
            csr_update.llbit = 1;
        end
        else if (|icache_cacop_tlb_exc_i) begin
            csr_update.estat[`_ESTAT_ECODE]    = icache_cacop_tlb_exc_i.ecode;
            csr_update.estat[`_ESTAT_ESUBCODE] = '0;
            csr_update.badv                    = icache_cacop_bvaddr_i; //存badv
            csr_update.tlbehi[`_TLBEHI_VPPN]   = icache_cacop_bvaddr_i[31:13];  //一定是tlb异常，tlb例外存vppn
        end//cacop维护出现的异常
    end

    //下面这个放在这里，是因为中断/异常的优先级最高，并且当前指令一定有效或者是中断
    if(cur_exception_q) begin
        csr_update = csr_exception_update_q;
    end
    //上面那些每周期规定只有一条，因此没有交叉冒险的情况

    //下面这个放在这里，是因为cpu每个周期都要更新一些软件不能更新的东西
    //如果放在前面会被覆盖掉，放在后面，由于是软件不能改的位，不会把前面的覆盖掉
    csr_update.estat[`_ESTAT_HARD_IS]  = hard_is_i; //从外面连过来中断

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
    if (retire_request_o[0] & !cur_exception_q & timer_interrupt_clear_q) begin
        csr_update.estat[`_ESTAT_TIMER_IS] = 0;
    end//要提交且是csr写，且写入对应位，且无例外

end

// 对csr_q的信息维护，第二级结尾写入
always_ff @(posedge clk) begin
    if(~rst_n) begin
        csr_q <= csr_init; // 初始化 CSR
    end
    else if (retire_request_o[0]) begin
        csr_q <= csr_update;
    end
    else begin
        csr_q <= csr_q;
    end
end

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


// -------------------------------------------------------------------

//在第二级


always_comb begin
    wait_for_int = wait_for_int_q;
    if (wait_for_int) begin
        wait_for_int = ~int_excep;
    end
    else begin
        wait_for_int = retire_request_o[0] ? 0 : rob_commit_q[0].idle_en;
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
//在第二级
// Cache维护指令：也需要进入状态机

logic [4:0] cache_code;
assign cache_code = rob_commit_q[0].cache_code;//用于状态机，在第二级
// code[2:0]指示操作的Cache对象
logic [2:0] cache_tar;
assign cache_tar = cache_code[2:0];
// code[4:3]指示操作类型
logic [1:0] cache_op;
assign cache_op = cache_code[4:3];
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


// ------------------------------------------------------------------
// 对于lsu访存的状态机
// 涉及到Cache和AXI的多个子状态机

// 如果是is_uncached指令，直接发起AXI请求
// 状态机流程：
// 1. normal命中 -> write cache即可
// 2. miss -> 为脏需要写回：先read cache -> axi write back -> axi read -> write cache
// 3. miss -> 不需要写回，通过AXI读相应的内容



assign       pc_s = rob_commit_q[0].pc;

commit_cache_req_t  commit_cache_req,  commit_cache_req_q;
commit_axi_req_t    commit_axi_req,    commit_axi_req_q;
commit_icache_req_t commit_icache_req, commit_icache_req_q;

assign commit_cache_req_o  = commit_cache_req;
assign commit_axi_req_o    = commit_axi_req;
assign commit_icache_req_o = commit_icache_req;

logic axi_back_target, axi_back_target_q;

lsu_iq_pkg_t lsu_info_s, lsu_info_q;

word_t cache_block_data [CACHE_BLOCK_NUM-1:0];
word_t cache_block_data_q [CACHE_BLOCK_NUM-1:0];
logic [$bits(CACHE_BLOCK_NUM):0] cache_block_ptr,  cache_block_ptr_q;
logic [$bits(CACHE_BLOCK_NUM):0] cache_block_len,  cache_block_len_q;

word_t axi_block_data [CACHE_BLOCK_NUM-1:0];
word_t axi_block_data_q [CACHE_BLOCK_NUM-1:0];
logic [$bits(CACHE_BLOCK_NUM):0] axi_block_ptr,    axi_block_ptr_q;
logic [$bits(CACHE_BLOCK_NUM):0] axi_block_len,    axi_block_len_q;

logic axi_wait,    axi_wait_q;
logic icache_wait, icache_wait_q;

logic [31:0] cache_dirty_addr, cache_dirty_addr_q;

logic ll_bit;
assign ll_bit = csr_q.llbit;

// 只在只能单条提交时起作用
always_comb begin
    // 值初始化
    ls_fsm              = ls_fsm_q;
    stall               = stall_q;
    fsm_flush           = '0;
    fsm_npc             = pc_s + 4;

    axi_wait            = axi_wait_q;
    icache_wait         = icache_wait_q;

    lsu_info_s          = lsu_info_q;
    cache_dirty_addr    = cache_dirty_addr_q;

    commit_cache_req    = commit_cache_req_q;
    commit_icache_req   = commit_icache_req_q;
    commit_axi_req      = commit_axi_req_q;

    axi_back_target     = axi_back_target_q;

    cache_block_data    = cache_block_data_q;
    cache_block_ptr     = cache_block_ptr_q;
    cache_block_len     = cache_block_len_q;

    axi_block_data      = axi_block_data_q;
    axi_block_ptr       = axi_block_ptr_q;
    axi_block_len       = axi_block_len_q;

    commit_axi_req      = '0;
    commit_axi_arvalid_o= '0;
    commit_axi_awvalid_o= '0;
    commit_axi_wvalid_o = '0;
    commit_axi_wlast_o  = '0;

    if(ls_fsm_q == S_NORMAL) begin
        // 如果是Cache维护指令
        if(is_cache_fix[0]) begin
            commit_icache_valid_o = '0;
            icache_wait = '0;

            if(cache_tar == 0) begin
                ls_fsm = (icache_commit_ready_i & icache_commit_valid_i) ? S_NORMAL : S_ICACHE;
                stall = ~(icache_commit_ready_i & icache_commit_valid_i);
                fsm_flush = (icache_commit_ready_i & icache_commit_valid_i) ? '1 : '0;
                fsm_npc = (|(icache_cacop_flush_i ^ 2'b01)) ? (pc_s + 4) :
                          (icache_cacop_tlb_exc_i.ecode == `_ECODE_TLBR) ? csr_q.tlbrentry :
                          csr_q.eentry;
                icache_wait = ~icache_commit_ready_i;

                commit_icache_valid_o      = '1;
                commit_icache_req.addr     = lsu_info[0].paddr;
                commit_icache_req.cache_op = cache_op;
            end
            else if(cache_tar == 1) begin
                // 对于Cache维护指令，将维护地址视作目的地址
                commit_cache_req.addr         = lsu_info[0].paddr;
                commit_cache_req.way_choose   = commit_cache_req.addr[0] ? 2'b10 : 2'b1;
                commit_cache_req.tag_data     = '0;
                commit_cache_req.tag_we       = '0;
                commit_cache_req.data_data    = '0;
                commit_cache_req.strb         = '0;
                commit_cache_req.fetch_sb     = '0;

                case (cache_op)
                    // 仅需要无效化即可
                    0: begin
                        ls_fsm = S_NORMAL;
                        stall = '0;
                        fsm_flush = '1;
                        fsm_npc = pc_s + 4;

                        commit_cache_req.tag_data = '0;
                        commit_cache_req.tag_we   = '1;
                    end

                    // 将Cache无效化，并将数据写回
                    1: begin
                        // 将Cache的tag无效化
                        commit_cache_req.tag_data  = '0;
                        commit_cache_req.tag_we    = '1;
                        //如果数据是脏的，则需要写回
                        if (lsu_info[0].cacop_dirty) begin
                            ls_fsm = S_CACHE_RD;
                            stall = '1;
                            axi_back_target = '1;
                            // 设置后续状态机的属性
                            cache_block_ptr = '0;
                            cache_block_len = 4;
                            for(int i =0; i < CACHE_BLOCK_NUM; i += 1) begin
                                cache_block_data[i] = '0;
                            end
                        end
                        // 否则即完成
                        else begin
                            ls_fsm = S_NORMAL;
                            stall = '0;
                            fsm_flush = '1;
                            fsm_npc = pc_s + 4;
                        end
                    end

                    2: begin
                        // 如果命中再维护
                        if(cache_commit_hit) begin
                            ls_fsm = lsu_info[0].hit_dirty ? S_CACHE_RD : S_NORMAL;
                            stall = lsu_info[0].hit_dirty;
                            axi_back_target = lsu_info[0].hit_dirty;
                            // 将Cache无效化，先读出对应的tag
                            commit_cache_req.way_choose   = lsu_info[0].tag_hit;
                            commit_cache_req.tag_data     = '0;
                            commit_cache_req.tag_we       = '1;
                        end
                        else begin
                            ls_fsm = S_NORMAL;
                            stall = '0;
                            fsm_flush = '0;
                        end
                    end
                    default: begin
                    end
                endcase

            end
        end
        // 如果是Uncached指令
        else if(is_uncached[0]) begin
            stall = '1;
            // 如果是Uncached read
            if(is_lsu_read[0]) begin
                ls_fsm = S_UNCACHED_RD;
                stall = '1;
                // 发起AXI请求
                commit_axi_req.raddr = lsu_info[0].paddr;
                commit_axi_req.rlen = 1;
                commit_axi_req.rmask = lsu_info[0].rmask;
                commit_axi_arvalid_o = '1;
                // 进行AXI握手
                axi_wait = ~axi_commit_arready_i;
            end
            else begin
                ls_fsm = S_UNCACHED_WB;
                stall = '1;
                fsm_flush = '1;
                fsm_npc = pc_s + 4;
                // 发起AXI请求
                commit_axi_req.waddr = lsu_info[0].paddr;
                commit_axi_req.wlen = 1;
                commit_axi_req.strb = lsu_info[0].strb;
                commit_axi_awvalid_o = '1;
                axi_block_data[0] = lsu_info[0].wdata;
                // 进行AXI握手
                axi_wait = ~axi_commit_awready_i;
            end
        end
        // 如果是一般的访存指令
        else if(is_lsu[0]) begin
            lsu_info_s = lsu_info[0];
            // 如果是load指令 且 缺失
            if(is_lsu_read[0]) begin
                // 读命中直接提交即可
                if(cache_commit_hit[0]) begin
                    ls_fsm = S_NORMAL;
                    stall = '0;
                    fsm_flush = '0;
                end
                else begin
                    // 不是脏的，发起AXI请求写入Cache
                    if(~cache_commit_dirty[0]) begin
                        ls_fsm = S_AXI_RD;
                        stall = '1;
                        // 设置相应的AXI请求
                        commit_axi_req.raddr = lsu_info[0].paddr;
                        commit_axi_req.rlen = 1;
                        commit_axi_req.rmask = lsu_info[0].rmask;
                        commit_axi_arvalid_o = '1;
                        // 进行AXI握手
                        axi_wait = ~axi_commit_arready_i;
                        // 设置相应的指针
                        for(integer i = 0; i < CACHE_BLOCK_NUM; i += 1) begin
                            cache_block_data[i] = '0;
                        end
                        axi_block_ptr = '0;
                        axi_block_len = 1;
                    end
                    // 开始重填，将Cache原始数据读出
                    else begin
                        ls_fsm = S_CACHE_RD;
                        stall = '1;
                        axi_back_target = '0;
                        // 设置相应的Cache请求
                        commit_cache_req.addr       = lsu_info[0].paddr & 32'hfffffff0;
                        commit_cache_req.way_choose = lsu_info[0].refill;
                        commit_cache_req.tag_data   = '0;
                        commit_cache_req.tag_we     = '0;
                        commit_cache_req.data_data  = '0;
                        commit_cache_req.strb       = '0;
                        commit_cache_req.fetch_sb   = '0;
                        // 设置相应的指针
                        for(integer i = 0; i < CACHE_BLOCK_NUM; i += 1) begin
                            cache_block_data[i] = '0;
                        end
                        cache_block_ptr = '0;
                        cache_block_len = 4;
                        cache_dirty_addr = lsu_info[0].cache_dirty_addr;
                        // 设置相应的AXI请求
                        commit_axi_req = '0;
                        commit_axi_req.waddr = cache_dirty_addr;
                        commit_axi_req.wlen = 4;
                        commit_axi_req.strb = '1;
                        commit_axi_awvalid_o = '1;
                        axi_wait = ~axi_commit_awready_i;
                        // 设置相应的指针
                        axi_block_ptr = '0;
                        axi_block_len = 4;
                        for(integer i = 0; i < CACHE_BLOCK_NUM; i += 1) begin
                            cache_block_data[i] = '0;
                        end
                    end
                end
            end
            // 如果是store指令，只能单提交
            else if(is_lsu_write[0]) begin
                // 如果命中，只需要写回
                if(cache_commit_hit[0]) begin
                    fsm_flush = '0;
                    // SC但没有LLbit，返回normal状态
                    if(is_sc && ~ll_bit) begin
                        ls_fsm = S_NORMAL;
                        stall = '0;
                    end
                    else begin
                        // 命中一周期即可返回
                        ls_fsm = S_NORMAL;
                        stall = '1;
                        // 发送Cache请求
                        commit_cache_req.addr       = lsu_info[0].paddr;
                        commit_cache_req.way_choose = lsu_info[0].tag_hit;
                        commit_cache_req.tag_data   = '0;
                        commit_cache_req.tag_we     = '0;
                        commit_cache_req.data_data  = lsu_info[0].wdata;
                        commit_cache_req.strb       = lsu_info[0].strb;
                        commit_cache_req.fetch_sb   = |lsu_info[0].strb;
                    end
                end
                // 如果没有命中
                else begin
                    // 直接刷掉流水
                    fsm_flush = '1;
                    fsm_npc = pc_s;
                    // 不是脏的，直接写入Cache即可
                    if(~cache_commit_dirty[0]) begin
                        ls_fsm = S_NORMAL;
                        stall = '1;
                        // 发送Cache请求
                        commit_cache_req.addr       = lsu_info[0].paddr;
                        commit_cache_req.way_choose = lsu_info[0].refill;
                        commit_cache_req.tag_data   = get_cache_tag(lsu_info[0].paddr, '1, '0);
                        commit_cache_req.tag_we     = '1;
                        commit_cache_req.data_data  = '0;
                        commit_cache_req.strb       = '0;
                        commit_cache_req.fetch_sb   = '0;
                    end
                    // 开始重填
                    else begin
                        ls_fsm = S_CACHE_RD;
                        stall = '1;
                        axi_back_target = '0;
                        // 设置相应的Cache数据
                        // 对齐一块的数据
                        commit_cache_req.addr       = lsu_info[0].paddr & 32'hfffffff0;
                        commit_cache_req.way_choose = lsu_info[0].refill;
                        commit_cache_req.tag_data   = '0;
                        commit_cache_req.tag_we     = '0;
                        commit_cache_req.data_data  = '0;
                        commit_cache_req.strb       = '0;
                        commit_cache_req.fetch_sb   = |lsu_info[0].strb;
                        // 设置相应的指针
                        for(integer i = 0; i < CACHE_BLOCK_NUM; i += 1) begin
                            cache_block_data[i] = '0;
                        end
                        cache_block_ptr = '0;
                        cache_block_len = 4;
                        cache_dirty_addr = lsu_info[0].cache_dirty_addr;
                        // 设置相应的AXI请求
                        commit_axi_req = '0;
                        commit_axi_req.waddr = cache_dirty_addr;
                        commit_axi_req.wlen = 4;
                        commit_axi_req.strb = '1;
                        commit_axi_awvalid_o = '1;
                        axi_wait = ~axi_commit_awready_i;
                        // 设置相应的指针
                        axi_block_ptr = '0;
                        axi_block_len = 4;
                        for(integer i = 0; i < CACHE_BLOCK_NUM; i += 1) begin
                            axi_block_data[i] = '0;
                        end
                    end
                end
            end
        end
        else begin
            ls_fsm = S_NORMAL;
            stall = '1;
            fsm_flush = '0;
        end
    end

    else if(ls_fsm_q == S_UNCACHED_RD) begin
        // 等待握手
        if(axi_wait_q) begin
            axi_wait = axi_wait_q & ~axi_commit_arready_i;
            commit_axi_arvalid_o = '1;
        end
        // 读入数据
        else begin
            if(axi_commit_rvalid_i) begin
                ls_fsm = S_NORMAL;
                stall = '0;
                // uncache读入后再刷
                fsm_flush = '1;
                fsm_npc = pc_s + 4;

                axi_block_data[axi_block_ptr_q] = axi_commit_resp_i.rdata;
            end
        end
    end

    else if(ls_fsm_q == S_UNCACHED_WB) begin
        // 等待握手
        if(axi_wait_q) begin
            commit_axi_awvalid_o = '1;
            if(axi_commit_awready_i) begin
                axi_wait = '0;
            end
            else begin
                axi_wait = '1;
            end
        end
        // 读入数据
        else begin
            // 发送AXI请求
            commit_axi_req.wdata = axi_block_data[axi_block_ptr_q];
            commit_axi_wvalid_o = '1;
            commit_axi_wlast_o = '1;

            if(axi_commit_wready_i) begin
                ls_fsm = S_NORMAL;
                stall = '0;
            end
            else begin
                ls_fsm = S_UNCACHED_WB;
                stall = '1;
            end
        end
    end

    // 读了立即发送AXI，同时读写
    else if(ls_fsm_q == S_CACHE_RD) begin
        if(cache_block_ptr_q == cache_block_len) begin
        end
        else begin
            // 读Cache数据
            cache_block_data[cache_block_ptr_q] = cache_commit_resp_i.data;
            cache_block_ptr = cache_block_ptr_q + 1;
            // 设置相应的Cache请求
            commit_cache_req.addr       = commit_cache_req_q.addr + 4;
            commit_cache_req.way_choose = commit_cache_req_q.way_choose;
            commit_cache_req.tag_data   = '0;
            commit_cache_req.tag_we     = '0;
            commit_cache_req.data_data  = '0;
            commit_cache_req.strb       = '0;
            commit_cache_req.fetch_sb   = '0;
        end

        // 等待握手
        if(axi_wait_q) begin
            commit_axi_awvalid_o = '1;
            if(axi_commit_awready_i) begin
                axi_wait = '0;
            end
            else begin
                axi_wait = '1;
            end
        end
        // 读入数据
        else begin
			commit_axi_wvalid_o = (cache_block_ptr_q > axi_block_ptr_q);
            commit_axi_req.wdata = cache_block_data[axi_block_ptr_q];
            commit_axi_wlast_o = (axi_block_ptr_q == axi_block_len - 1);

            if(axi_commit_wready_i) begin
                axi_block_ptr = axi_block_ptr_q + 1;
            end
        end

        if(axi_block_ptr_q == axi_block_len) begin
            if(axi_back_target) begin
                ls_fsm = S_NORMAL;
                stall = '0;
                fsm_flush = '1;
                fsm_npc = pc_s + 4;
            end
            else begin
                ls_fsm = S_AXI_RD;
                stall = '1;

                // 设置相应的AXI请求
                commit_axi_req = '0;
                commit_axi_req.raddr = cache_dirty_addr;
                commit_axi_req.rlen = 4;
                commit_axi_req.strb = '0;
                commit_axi_arvalid_o = '1;

                // 设置相应的指针
                axi_block_ptr = '0;
                axi_block_len = 4;
                for(integer i = 0; i < CACHE_BLOCK_NUM; i += 1) begin
                    axi_block_data[i] = '0;
                end

                if(axi_commit_arready_i) begin
                    axi_wait = '0;
                    // 设置相应的指针
                    cache_block_ptr = '0;
                    cache_block_len = 4;
                    for(integer i = 0; i < CACHE_BLOCK_NUM; i += 1) begin
                        cache_block_data[i] = '0;
                    end
                end
                else begin
                    axi_wait = '1;
                end
            end
        end
        else begin
            ls_fsm = S_CACHE_RD;
        end
    end

    // 读了立即发送Cache，同时读写
    else if(ls_fsm_q == S_AXI_RD) begin
        if(axi_block_ptr_q == axi_block_len) begin
        end
        else begin
            // 等待握手
            if(axi_wait_q) begin
                commit_axi_arvalid_o = '1;
                axi_wait = axi_wait_q & ~axi_commit_arready_i;
            end
            // 读入数据
            else begin
                if(axi_commit_rvalid_i) begin
                    axi_block_data[axi_block_ptr_q] = axi_commit_resp_i.rdata;
                    axi_block_ptr = axi_block_ptr_q + 1;
                end
                else begin
                end
            end
        end

        if(cache_block_ptr_q == cache_block_len) begin
            ls_fsm = S_NORMAL;
            stall = '0;
        end
        else begin
            ls_fsm = S_AXI_RD;
            stall = '0;

            if(cache_block_ptr_q < axi_block_ptr_q) begin
                // 设置相应的Cache数据
                cache_block_ptr = cache_block_ptr_q + 1;
                // 对齐一块的数据
                commit_cache_req.addr       = (lsu_info_s.paddr & 32'hfffffff0) | (cache_block_ptr_q << 2);
                commit_cache_req.way_choose = lsu_info_s.refill;
                commit_cache_req.tag_data   = get_cache_tag(lsu_info_s.paddr & 32'hfffffff0, '1, '0);
                commit_cache_req.tag_we     = '1;
                commit_cache_req.data_data  = axi_block_data[cache_block_ptr_q];
                commit_cache_req.strb       = '1;
                commit_cache_req.fetch_sb   = '0;
            end
            else begin
                commit_cache_req.tag_data   = '0;
                commit_cache_req.tag_we     = '0;
                commit_cache_req.data_data  = '0;
                commit_cache_req.strb       = '0;
            end
        end
    end

    else if(ls_fsm_q == S_ICACHE) begin
        commit_icache_valid_o = icache_wait_q;
        icache_wait = icache_wait_q & ~icache_commit_ready_i;

        if(icache_wait_q) begin
            commit_icache_valid_o      = '1;
        end
        else begin
            commit_icache_valid_o      = '0;

            if(icache_commit_valid_i) begin
                ls_fsm = S_NORMAL;
                stall = '0;
                fsm_flush = '1;
                fsm_npc = (|(icache_cacop_flush_i ^ 2'b01)) ? (pc_s + 4) :
                          (icache_cacop_tlb_exc_i.ecode == `_ECODE_TLBR) ? csr_q.tlbrentry :
                          csr_q.eentry;
            end
        end
    end

    else begin
        ls_fsm = S_NORMAL;
        stall = '0;
        fsm_flush = '0;
    end
end

// 时序逻辑只保存状态
always_ff @(posedge clk) begin
    if(~rst_n || cur_exception) begin
        ls_fsm_q            <= S_NORMAL;
        stall_q             <= '0;

        axi_wait_q          <= '0;
        icache_wait_q       <= '0;

        lsu_info_q          <= '0;
        cache_dirty_addr_q  <= '0;

        axi_back_target_q   <= '0;

        commit_icache_req_q <= '0;
        commit_cache_req_q  <= '0;
        commit_axi_req_q    <= '0;

        for(integer i = 0; i < CACHE_BLOCK_NUM; i += 1) begin
            cache_block_data_q[i] <= '0;
        end
        cache_block_ptr_q   <= '0;
        cache_block_len_q   <= '0;

        for(integer i = 0; i < CACHE_BLOCK_NUM; i += 1) begin
            axi_block_data_q[i] <= '0;
        end
        axi_block_ptr_q     <= '0;
        axi_block_len_q     <= '0;
    end
    else begin
        ls_fsm_q            <= ls_fsm;
        stall_q             <= stall;

        axi_wait_q          <= axi_wait;
        icache_wait_q       <= icache_wait;

        lsu_info_q          <= lsu_info_s;
        cache_dirty_addr_q  <= cache_dirty_addr;

        axi_back_target_q   <= axi_back_target;

        commit_icache_req_q <= commit_icache_req;
        commit_cache_req_q  <= commit_cache_req;
        commit_axi_req_q    <= commit_axi_req;

        cache_block_data_q  <= cache_block_data;
        cache_block_ptr_q   <= cache_block_ptr;
        cache_block_len_q   <= cache_block_len;

        axi_block_data_q    <= axi_block_data;
        axi_block_ptr_q     <= axi_block_ptr;
        axi_block_len_q     <= axi_block_len;
    end
end

endmodule
