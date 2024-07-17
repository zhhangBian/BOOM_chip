`include "a_defines.svh"

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
    input   rob_commit_pkg_t [1:0] rob_commit_i,

    // 给ROB的输出信号，确定提交相关指令
    output  logic   commit_ready_o,
    output  logic   [1:0]   commit_request_o,

    output  logic   [31:0]  commit_csr_data_o,
    output  logic   commit_csr_valid_o,

    // commit与DCache的接口
    output  commit_cache_req_t  commit_cache_req_o,
    input   cache_commit_resp_t cache_commit_resp_i,
    // 对应地址是否命中
    input   logic   cache_commit_hit_i,
    input   logic   cache_commit_dirty_i,
    input   tag.    cache_commit_tag_i,     // TODO：返回了tag的信息
    // commit与cache的握手信号
    input   logic   commit_cache_ready_i,
    output  logic   commit_cache_valid_o,
    input   logic   cache_commit_valid_i,
    output  logic   cache_commit_ready_o,

    // commit与AXI的接口
    // 接口好多啊
    output  commit_axi_req_t  commit_axi_req_o,
    input   axi_commit_resp_t axi_commit_resp_i,
    // 按照axi-crossbar的逻辑设计
    output  logic   commit_axi_ready_o,
    input   logic   axi_commit_valid_i,
    input   logic   commit_axi_valid_o,
    output  logic   axi_commit_ready_i,
    // 其实没有用到
    input   logic   axi_commit_last_i
);

// 是否将整个提交阻塞
logic stall, stall_q;
assign stall_o = stall;
assign commit_ready_o = ~stall_all;

assign commit_axi_ready = '1;
assign commit_cache_reday = '1;

logic [31:0] commit_data, commit_data_q;
assign commit_data_o = commit_data_q;

// 维护一个提交级的时钟
logic [5:0] timer_64, timer_64_q;
assign timer_64 = timer_64_q;

// TODO1 选择提交指令，将指令信息（写寄存器，读写内存）
// 对于正常提交
// 正常情况都不需要进入状态机，直接提交即可
always_comb begin
    commit_request_o[0] = rob_commit_valid_i[0];
    // CSR指令、Uncached指令允许提交
    commit_request_o[0] &= ~(is_lsu & ~is_uncached);

    commit_request_o[1] = rob_commit_valid_i[0] &
                          rob_commit_valid_i[1] &
                          ~rob_commit_i[0].first_commit &
                          ~rob_commit_i[1].first_commit;
end

// ------------------------------------------------------------------
// 代表相应的指令属性
logic [1:0] is_lsu_write, is_lsu_read, is_lsu;
logic [1:0] is_uncached;
logic [1:0] is_csr;
logic [1:0] is_cache;
logic [1:0] is_tlb;

// 与DCache的一级流水交互
iq_lsu_pkg_t [1:0] lsu_info;
assign lsu_info[1] = rob_commit_i[1].lsu_info;
assign lsu_info[0] = rob_commit_i[0].lsu_info;

commit_cache_req_t commit_cache_req, commit_cache_req_q;
assign commit_cache_req_o = commit_cache_req_q;

always_comb begin
    commit_cache_req.data = lsu_info[0].data;
    commit_cache_req.addr = lsu_info[0].addr;
    commit_cache_req.strb = lsu_info[0].strb;
    commit_cache_req.rmask = lsu_info[0].rmask;
end

commit_axi_req_t commit_axi_req_q;
assign commit_axi_req_o = commit_axi_req_q;

// 判断指令类型
for(integer i = 0; i < 2; i += 1) begin
    always_comb begin
        // 处理后续的竞争逻辑
        is_lsu_write[i] = |lsu_info[i].strb;
        is_lsu_read[i]  = |lsu_info[i].rmask;
        is_lsu[i]       = is_lsu_write[i] | is_lsu_read[i];
        is_uncached[i]  = lsu_info.is_uncached;

        is_csr[i]       = |rob_commit_i[i].csr_type;
        is_cache[i]     = |rob_commit_i[i].cache_code;
        is_tlb[i]       = |rob_commit_i[i].tlb_type;
    end
end

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// 信息梳理

// TODO2 特殊处理
// tlb维护指令
// is_uncached指令
// cache维护指令
// dbar,ibar
/*******************************/
// 分支预测失败
// 写csr指令
// 异常处理

// 以上所有指令只允许单条提交

// ------------------------------------------------------------------
// 处理全局flush信息
always_comb begin
    // 此种情况包含了Cache，CSR和TLB维护的情况
    if(~(|commit_request_o)) begin
        flush = '1;
    end
    else if(is_dbar || is_ibar) begin
        flush = '1'
    end
    else if(|is_lsu) begin
        if(ls_fsm_q == S_NORMAL) begin
            if(!cache_commit_hit_i) begin
                if(is_lsu_write && is_uncached) begin
                    flush = '0;
                end
                else begin
                    flush = '1;
                end
            end
            else begin
                flush = '0;
            end
        end
    end
    else begin
        flush = '0;
    end
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 处理CSR逻辑
csr_t csr, csr_q, csr_init;
logic [2:0] csr_type = rob_commit_i[0].csr_type;
logic [13:0] csr_num = rob_commit_i[0].csr_num;

// 维护CSR信息
always_comb begin
    csr_init                = '0;
    csr_init.crmd[`_CRMD_DA]= 1'd1; // 初始化要求非0的 CSR 寄存器值
    csr_init.asid[31:10]    = 22'h280;
    csr_init.cpuid          = CPU_ID;
    csr_init.tid            = CPU_ID;
end

// 对csr_q的信息维护
always_ff @(posedge clk) begin
    if(~rst_n) begin
        csr_q <= csr_init; // 初始化 CSR
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
            // TODO：csr_t的结构需要进一步匹配
            commit_csr_data_o |= csr_q[csr_num];
        end 

        `_CSR_CSRWR: begin
            commit_csr_valid_o |= '1;
            // TODO：csr_t的结构需要进一步匹配
            commit_csr_data_o |= csr_q[csr_num];
            csr[csr_num] = rob_commit_i[0].data_rd;
        end

        `_CSR_XCHG: begin
            commit_csr_valid_o |= '1;
            // TODO：csr_t的结构需要进一步匹配
            commit_csr_data_o |= csr_q[csr_num];
            csr[csr_num] = rob_commit_i[0].data_rd & rob_commit_i[0].data_rj;
        end

        default: begin
            
        end
    endcase
end
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// ------------------------------------------------------------------
// 进行tlb 维护，在commit级统一管理TLB，对应有一个ITLB和DTLB的映射
tlb_entry_t [63 : 0] tlb_entrys;
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


// cache维护指令


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
    S_UNCACHED
} ls_fsm_s;
// 如果是is_uncached指令，直接发起AXI请求
// 状态机流程：
// 1. normal命中 -> write即可
// 2. miss -> 为脏需要写回：先read -> write back -> read
// 3. miss -> 不需要写回通过AXI读相应的内容

ls_fsm_s ls_fsm_q, ls_fsm;
logic 

// 配置与Cache的握手信号
logic commit_cache_valid, commit_cache_valid_q;
assign commit_cache_valid_o = commit_cache_valid_q;

word_t [CACHE_BLOCK_NUM-1:0] cache_block_data;
word_t [CACHE_BLOCK_NUM-1:0] axi_block_data;

logic [$bits(CACHE_BLOCK_NUM):0] cache_block_ptr, cache_block_len;
logic [$bits(CACHE_BLOCK_NUM):0] axi_block_ptr, axi_block_len;

// 状态机转移的时序逻辑
always_ff @(posedge clk) begin
    if(~rst_n) begin
        ls_fsm_q <= S_NORMAL;
    end
    else begin
        ls_fsm_q <= ls_fsm;

        if(ls_fsm_q == S_NORMAL && is_lsu) begin
            stall_all <= '1;
        end
    end
end

// 状态转移的组合逻辑
always_comb begin
    ls_fsm = ls_fsm_q;
    stall = stall_all;

    

    if(ls_fsm_q == S_NORMAL && is_lsu) begin
        
    end

    else begin
        ls_fsm = ls_fsm_q;

        
    end
end

always_ff @(posedge clk) begin
    if(~rst_n) begin
        ls_fsm_q <=  S_NORMSAL;
        commit_cache_valid_q <= '0;
        commit_cache_req_q <= '0;

        cache_block_data <= '0;
        cache_block_ptr <= '0;
        cache_block_len <= '0;
        axi_block_data <= '0;
        axi_block_ptr <= '0;
        axi_block_len <= '0;
    end

    else begin
        // normal状态 且 需要进入Cache状态机
        if(ls_fsm_q == S_NORMAL && is_lsu) begin
            // 在完成Cache前将提交阻塞
            stall_all <= '1;

            // 如果是uncached请求，直接发起AXI请求
            if(is_uncached) begin
                ls_fsm_q <= S_AXI_WB;
                commit_axi_valid_o <= '1;

                axi_block_len <= 1;
                axi_block_ptr <= 0;
                axi_block_data <= lus_info[0].data;

                commit_axi_req_q.addr <= lsu_info[0].addr;
                commit_axi_req_q.len <= 1;
                commit_axi_req_q.is_write <= |lsu_info[0].strb;
                commit_axi_req_q.is_read <= |lsu_info[0].rmask;
            end
            // Cache命中
            else if(cache_commit_hit_i) begin
                ls_fsm_q <= S_CACHE;
                commit_cache_valid_q <= '1;
                commit_cache_req_q <= commit_cache_req;

                cache_block_data[0] <= commit_cache_req.data;
                cache_block_ptr <= '0;
                cache_block_len <= 1;
            end
            // Cache不命中
            else begin
                // 读出Cache的整块数据，最后写回
                if(cache_commit_dirty_i) begin
                    ls_fsm_q <= S_CACHE_RD;
                    // 设置相应的Cache数据
                    commit_cache_valid_o <= '1;
                    commit_cache_req_q.addr <= cache_commit_resp_i.addr;
                    commit_cache_req_q.rmask <= '1;

                    cache_block_ptr <= '0;
                    cache_block_len <= CACHE_BLOCK_NUM;
                    cache_block_data <= '0;
                end
                // 发出AXI请求，直接读出数据
                else begin
                    ls_fsm_q <= S_UNCACHED;
                    commit_axi_valid_o <= '1;

                    commit_axi_req_q.addr <= lsu_info[0].addr;
                    commit_axi_req_q.len <= CACHE_BLOCK_NUM;
                    commit_axi_req_q.is_write <= 0;
                    commit_axi_req_q.is_read <= 1;

                    axi_block_ptr <= '0;
                    axi_block_len <= 1;
                    axi_block_data <= '0;
                end
            end
        end

        else if(ls_fsm_q == S_UNCACHED) begin
            if(axi_commit_valid_i) begin
                ls_fsm_q <= S_NORMAL;
                stall_all <= '0;

                commit_axi_valid_o <= '0;
                cache_block_ptr <= '0;
                cache_block_len <= '0;
                cache_block_data <= '0;
            end
        end

        // 与Cache进行读写操作
        else if (ls_fsm_q == S_CACHE) begin
            // Cache接受当前的读写请求
            if(cache_commit_valid_i) begin
                commit_cache_req_q.data <= cache_block_data[cache_block_ptr + 1];
                commit_cache_req_q.addr <= commit_cache_req_q.addr + 4;
                cache_block_ptr <= cache_block_ptr + 1;

                // 回到normal状态，取消提交级的阻塞
                if(cahce_ptr == cache_block_len - 1) begin
                    ls_fsm_q <= S_NORMAL;
                    stall_all <= '0;

                    cache_block_ptr <= '0;
                    cache_block_len <= '0;
                    cache_block_data <= '0;
                end
            end
        end

        // 发起AXI请求，读出对应地址处的数据
        else if(ls_fsm_q == S_AXI_RD) begin
            if(axi_commit_valid_i) begin
                // AXI请求完成，进行下一步状态
                if(axi_block_ptr == axi_block_len - 1) begin
                    ls_fsm_q <= S_CACHE;
                    commit_cache_valid_q <= '1;
                    commit_cache_req_q <= commit_cache_req

                    cache_block_len <= CACHE_BLOCK_NUM;
                    cache_block_ptr <= 0;
                    cache_block_data <= axi_block_data;
                end

                axi_block_data[block_ptr] <= axi_commit_resp_i.data;
                axi_block_ptr <= axi_block_ptr + 1;
            end
        end

        // 将需要写回部分的Cache整块数据读出
        else if(ls_fsm_q == S_CACHE_RD) begin
            // 完成了整块的读出操作
            if(cache_commit_valid_i) begin
                cache_block_data[cache_block_ptr] <= cache_commit_resp.data;
                cache_block_ptr <= cache_block_data + 1;
                // 设置下一轮的Cache数据
                commit_cache_addr_q <= commit_cache_addr_q + 4;

                if(cache_block_ptr == cache_block_len - 1) begin
                    // 将读出的数据写回
                    ls_fsm_q <= S_AXI_WB;
                    commit_axi_valid_o <= '1;

                    axi_block_len <= CACHE_BLOCK_NUM;
                    axi_block_ptr <= 0;
                    axi_block_data <= cache_block_data;

                    commit_axi_req_q.addr <= lsu_info[0].addr;
                    commit_axi_req_q.len <= CACHE_BLOCK_NUM;
                    commit_axi_req_q.is_write <= 1;
                    commit_axi_req_q.is_read <= 0;
                end
            end
        end

        // 发起AXI请求，写回对应地址处的数据
        else if (ls_fsm_q == S_AXI_WB) begin
            // AXI写回请求完成，再发送AXI请求进行读出所需处的数据
            if(axi_commit_valid_i) begin
                if(axi_block_ptr == axi_block_len - 1) begin
                    ls_fsm_q <= S_AXI_RD;
                    commit_axi_valid_o <= '1;
                    // 设置相应的AXI数据
                    axi_block_ptr <= '0;
                    axi_block_len <= CACHE_BLOCK_NUM;
                    axi_block_data <= '0;

                    commit_axi_req_q.addr <= lsu_info[0].addr;
                    commit_axi_req_q.len <= CACHE_BLOCK_NUM;
                    commit_axi_req_q.is_write <= 0;
                    commit_axi_req_q.is_read <= 1;
                end
                
                commit_axi_req_q.addr <= commit_axi_req_q.addr + 4;
                commit_axi_req_q.data <= axi_block_data[axi_block_ptr];
            end
        end

        // 对于不应该出现的异常情况
        else begin
            ls_fsm_q <= S_NORMAL;
            stall_all <= '0;

            commit_cache_valid_q <= '0;
            commit_cache_req_q <= '0;
        end
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