`include "a_defines.svh"

//用寄存器存的tlb表项，打一拍出结果
//目前完成地址翻译，错误码和tlb的读写支持待补充
module mmu #(
    parameter TLB_ENTRY_NUM = 64,
    parameter TLB_SWITCH_OFF = 0
) (
    input  wire  clk,
    input  wire  rst_n,
    input  wire  flush,

    input  logic [31:0]           va,
    input  csr_t                  csr,
    input  wire  [1:0]            mem_type,//类型，定义见a_mmu_defines

    output trans_result_t trans_result_o
)

wire cur_asid = csr.asid;
logic tlb_found;
logic tlb_entry_t tlb_value_read;

logic tlb_key_t   [TLB_ENTRY_NUM - 1:0]      tlb_key_q;
logic tlb_entry_t [1:0][TLB_ENTRY_NUM - 1:0] tlb_entry_q;

always_comb begin
    tlb_found = 0;
    for (integer i = 0; i < TLB_ENTRY_NUM; i+= 1) begin
        if (tlb_key_q[i].e 
        && (tlb_entry_q[i].g || (tlb_entry_q[i].asid == cur_asid))
        && vppn_match(va, tlb_key_q[i].huge_ps)) begin
            tlb_found = 1;
            if (tlb_key_q[i].huge_ps) begin
                tlb_value_read = tlb_value_q[va[22]][i];   //4MB
            end else begin
                tlb_value_read = tlb_value_q[va[12]][i]; //4KB
                end
            end
        end
end

function automatic logic vppn_match(logic [31:0] va, 
                                    logic huge_ps)
    if (huge_ps) begin
        return va[31:23] == tlb_key.vppn[18:10]; ???
    end else begin
        return va[31:13] == tlb_key.vppn;
    end
endfunction

wire [31:0] dmw0 = csr.dmw0;
wire [31:0] dmw1 = csr.dmw1;

wire    plv0     = csr.crmd[`_CRMD_PLV] == 2'd0;
wire    plv3     = csr.crmd[`_CRMD_PLV] == 2'd3;
wire dmw0_plv_ok = (plv0 && dmw0[`_DMW_PLV0]) || (plv3 && dmw0[`_DMW_PLV3]);
wire dmw1_plv_ok = (plv0 && dmw1[`_DMW_PLV0]) || (plv3 && dmw1[`_DMW_PLV3]);

wire    dmw0_hit = dmw0[`_DMW_VSEG] == va[31:29];
wire    dmw1_hit = dmw1[`_DMW_VSEG] == va[31:29];

logic        dmw_hit  = (dmw0_hit && dmw0_plv_ok) 
                     || (dmw1_hit && dmw1_plv_ok);
logic [31:0] dmw_read = dmw0_hit ? dmw0 :
                        dmw1_hit ? dmw1 :
                        '0;

logic trans_result_t trans_result;

wire da = csr.crmd.`_CRMD_DA;
wire pg = csr.crmd.`_CRMD_PG;

always_comb begin
    if (da) begin
        trans_result.pa = va;
        trans_result.mat = (mem_type == `_MEM_FETCH) ? 
            csr.crmd[`_CRMD_DATF] : csr.crmd[`_CRMD_DATM];
        trans_result.valid = 1;
    end else begin
        if (dmw_hit) begin
            trans_result.pa = {dmw_read[`_DMW_PSEG],va[28:0]};
            trans_result.mat = dmw_read[`_DMW_MAT];
            trans_result.valid = 1;
        end else begin
            if (tlb_value_read.huge_ps) begin
                trans_result.pa = {tlb_value_read.ppn, va[11:0]};
                trans_result.mat = tlb_value_read.mat;
            end else begin
                trans_result.pa = {tlb_value_read.ppn[19:10], va[21:0]};
                trans_result.mat = tlb_value_read.mat;
            end
            trans_result_valid = 1;
            if (!tlb_value_read.v) begin
                trans_result.valid = 0;
                case (mem_type)
                    `FETCH:;
                    `LOAD:;
                    `STORE:;
                endcase
            end elif(csr.crmd[`_CRMD_PLV] > tlb_value_read.plv) begin
                trans_result.valid = 0;
            end elif(mem_type == `STORE && !trans_result.d) begin
                trans_result.valid = 0;
            end
        end
    end
end

always_ff @(posedge clk) begin
    if (rst_n || flush) begin
        trans_result_o <= '0;
    end else begin
        trans_result_o <= trans_result;
    end
end

endmodule