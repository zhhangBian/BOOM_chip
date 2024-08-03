`include "a_defines.svh"

//用寄存器存的tlb表项，打一拍出结果
//待测试
module mmu #(
    parameter int unsigned TLB_ENTRY_NUM = `_TLB_ENTRY_NUM,
    parameter int TLB_SWITCH_OFF = 0 //这个暂时没用
) (
    input  wire  clk,
    input  wire  rst_n,
    input  wire  flush,
    // 地址翻译
    input  logic [31:0]           va,
    input  csr_t                  csr,
    input  logic  [1:0]            mmu_mem_type,  //类型，定义见a_mmu_defines // 
    // 维护
    input  tlb_write_req_t  tlb_write_req_i,   //tlb维护的请求，包括写的独热码，见a_mmu_defines

    output trans_result_t trans_result_o,    //包含pa，mat，valid，见a_mmu_defines
    output tlb_exception_t tlb_exception_o  //tlb相关的例外，例外代码的编号在a_csr里面，默认为零，只有在result里面valid为0的时候这个错误码才有意义
    //output tlb_entry_t    tlb_entry_o        //tlb维护（读）时找到的tlb_entry，暂时写成一拍后得到结果，但也可以马上得到
);


// logic [31:0] va;
// logic [1:0]  mmu_mem_type;

//查tlb
wire  [9:0] cur_asid = csr.asid[`_ASID];
logic tlb_found;
tlb_key_t   tlb_key_read;
tlb_value_t tlb_value_read;

tlb_key_t   [TLB_ENTRY_NUM - 1:0]      tlb_key_q;
tlb_value_t [TLB_ENTRY_NUM - 1:0][1:0] tlb_value_q;
/*===================ok===================*/
always_comb begin
    tlb_found = 0;
    tlb_key_read = '0;
    tlb_value_read = '0;
    for (integer i = 0; i < TLB_ENTRY_NUM; i+= 1) begin
        if (tlb_key_q[i].e 
        && (tlb_key_q[i].g || (tlb_key_q[i].asid == cur_asid))
        && vppn_match(va, tlb_key_q[i].huge_page, tlb_key_q[i].vppn)) begin
            tlb_found = 1;
            tlb_key_read = tlb_key_q[i];
            if (tlb_key_q[i].huge_page) begin
                tlb_value_read = tlb_value_q[i][va[21]];   //4MB,2MB，TODO ？
            end else begin
                tlb_value_read = tlb_value_q[i][va[12]];   //4KB
            end
        end
    end
end
/*===================ok===================*/
function automatic logic vppn_match(input logic [31:0] va_param, 
                                    input logic huge_page, input logic [18: 0] vppn);//位宽好像错了
    if (huge_page) begin
        return va_param[31:22] == vppn[18:9]; //ok
    end else begin
        return va_param[31:13] == vppn;
    end
endfunction

//tlb写请求
always_ff @(posedge clk) begin
    for (integer i = 0; i < TLB_ENTRY_NUM; i += 1) begin
        if (tlb_write_req_i.tlb_write_req[i]) begin
            tlb_key_q[i]      <= tlb_write_req_i.tlb_write_entry.key;
            tlb_value_q[i][0] <= tlb_write_req_i.tlb_write_entry.value[0];
            tlb_value_q[i][1] <= tlb_write_req_i.tlb_write_entry.value[1];
        end
    end
end

//查dmw
wire [31:0] dmw0 = csr.dmw0;
wire [31:0] dmw1 = csr.dmw1;

wire    plv0     = csr.crmd[`_CRMD_PLV] == 2'd0;
wire    plv3     = csr.crmd[`_CRMD_PLV] == 2'd3;
wire dmw0_plv_ok = (plv0 && dmw0[`_DMW_PLV0]) || (plv3 && dmw0[`_DMW_PLV3]);
wire dmw1_plv_ok = (plv0 && dmw1[`_DMW_PLV0]) || (plv3 && dmw1[`_DMW_PLV3]);

wire    dmw0_hit = (dmw0[`_DMW_VSEG] == va[31:29]) && dmw0_plv_ok;
wire    dmw1_hit = (dmw1[`_DMW_VSEG] == va[31:29]) && dmw1_plv_ok;

wire        dmw_hit  = dmw0_hit || dmw1_hit;
wire [31:0] dmw_read = dmw0_hit ? dmw0 :
                       dmw1_hit ? dmw1 :
                       '0;

//choose from tlb/dmw/da
trans_result_t trans_result;

wire da = csr.crmd[`_CRMD_DA];
// wire pg = csr.crmd[`_CRMD_PG]; /*2024/07/24 fix ??? 没有改，这个好像没用，逻辑上是不是要和DA结合起来*/

logic [5:0] ecode;
logic [8:0] esubcode;

always_comb begin
    ecode = 6'h0;
    esubcode = 9'h0;
    trans_result = '0;

    if (da) begin
        trans_result.pa = va;
        trans_result.mat = (mmu_mem_type == `_MEM_FETCH) ? 
            csr.crmd[`_CRMD_DATF] : csr.crmd[`_CRMD_DATM];
        trans_result.valid = 1;
    end else begin
        if (dmw_hit) begin
            trans_result.pa = {dmw_read[`_DMW_PSEG],va[28:0]};
            trans_result.mat = dmw_read[`_DMW_MAT];
            trans_result.valid = 1;
        end else begin
            if (tlb_key_read.huge_page) begin //fixed
                trans_result.pa = {tlb_value_read.ppn, va[11:0]};
                trans_result.mat = tlb_value_read.mat;
            end else begin
                trans_result.pa = {tlb_value_read.ppn[19:10], va[21:0]};
                trans_result.mat = tlb_value_read.mat;
            end
            trans_result.valid = tlb_found;
            if (!tlb_found) begin
                ecode = `_ECODE_TLBR;
            end else if (!tlb_value_read.v) begin
                trans_result.valid = 0;
                case (mmu_mem_type)
                    `_MEM_FETCH:
                        ecode = `_ECODE_PIF;
                    `_MEM_LOAD:
                        ecode = `_ECODE_PIL;
                    `_MEM_STORE:
                        ecode = `_ECODE_PIS;
                    default: begin
                    end
                endcase
            end else if(csr.crmd[`_CRMD_PLV] > tlb_value_read.plv) begin
                trans_result.valid = 0;
                ecode = `_ECODE_PPI;
            end else if((mmu_mem_type == `_MEM_STORE) && (!tlb_value_read.d)) begin//fixed
                trans_result.valid = 0;
                ecode = `_ECODE_PME;
            end
        end
    end
end

// always_ff @(posedge clk) begin
//     va_q <= va;
//     mmu_mem_type_q <= mmu_mem_type;
// end//没有reset，外面需要有效位保证

// assign trans_result_o = trans_result;
// assign tlb_exception_o.ecode = ecode;
// assign tlb_exception_o.esubcode = esubcode;

// always_ff @(posedge clk) begin
//     if (~rst_n | flush) begin
//         trans_result_o <= '0;
//         tlb_exception_o <= '0;
//     end else begin
//         trans_result_o <= trans_result;
//         tlb_exception_o.ecode <= ecode;
//         tlb_exception_o.esubcode <= esubcode;
//     end
// end

always_ff @( posedge clk) begin
    trans_result_o <= trans_result;
    tlb_exception_o.ecode <= ecode;
    tlb_exception_o.esubcode <= esubcode;
end


endmodule
