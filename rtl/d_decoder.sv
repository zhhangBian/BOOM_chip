`include "a_defines.svh"

function logic [31:0] inst_to_data_imm (input logic[31:0] inst, input imm_type_t data_imm_type);
    logic [31:0] ret;
    // inst[4:0] and [31:25] unused
    case (data_imm_type)
        `_IMM_S12:  ret =  {{20{inst[21]}}, inst[21:10]};
        `_IMM_S20:  ret =  {{12{inst[24]}}, inst[24: 5]};
        `_IMM_U5:   ret =  {27'b0,          inst[14:10]};
        // `_IMM_U12:
        default:    ret =  {20'b0,          inst[21:10]}; 
    endcase
    return ret;
endfunction

function logic [31:0] inst_to_addr_imm (input logic[31:0] inst, input addr_imm_type_t addr_imm_type);
    logic [31:0] ret;
    // inst[31:26] unused
    case (addr_imm_type)
        `_ADDR_IMM_S12: ret =  {{20{inst[21]}}, inst[21:10]}; // 仅用于store/load指令，低位不补零;
        `_ADDR_IMM_S14: ret =  {{16{inst[23]}}, inst[23:10], 2'b0}; // 仅用于原子访存指令，低位补两个0;
        `_ADDR_IMM_S16: ret =  {{14{inst[25]}}, inst[25:10], 2'b0}; // 仅用于计算分支offset，低位补两个0;
        // _ADDR_IMM_S21:  // 仅用于浮点分支指令使用，也就是暂时不使用
        // `_ADDR_IMM_S26:
        default:        ret =  {{4 {inst[ 9]}}, inst[ 9:0 ], inst[25:10], 2'b0};
    endcase
    return ret;
endfunction

// 纯组合逻辑，D流水级的时序在顶层模块上，其实也就是在进来的时候打了一拍放到了FIFO中而已。
module decoder (
    handshake_if.receiver               receiver, // f_d_pkg_t type
    handshake_if.sender                 sender, // d_r_pkg_t type

    // output d_decoder_info_t   [1:0]       decode_infos, // TODO: 需要合并到sender中
);

// TODO: csr_num not handled!!!!!!!!!!!

// input && output
logic [1:0]         mask;
logic [1:0][31:0]   pc;
logic [1:0][31:0]   insts_i;
d_r_pkg_t           d_r_pkg;

assign mask = receiver.data.mask;
assign pc = {receiver.data.pc | 32'h00000004, receiver.data.pc};
assign insts_i = receiver.data.insts;

assign sender.data = d_r_pkg;
// 由于这个模块是一个组合逻辑模块，因此只需要将模块前后的 ready 和 valid 接在一起就行，唯一的改变仅在于 data 上
assign sender.valid = receiver.valid;
assign receiver.ready = sender.ready;

// 内置两个decoder, decode_infos 生成逻辑
for (genvar i = 0; i < 2; i=i+1) begin
    basic_decoder basic_decoder (
        .ins_i(insts_i[i]),
        .decode_info_o(decode_infos[i])
    );
end

// d_r_pkg 逻辑
assign d_r_pkg.r_valid = mask;
assign d_r_pkg.pc = pc;
// 2024/07/22 ADD
assign d_r_pkg.predict_infos = receiver.data.predict_infos;
assign d_r_pkg.fetch_exc_info = receiver.data.fetch_exc_info;
for (genvar i = 0; i < 2; i=i+1) begin
    assign d_r_pkg.w_reg[i] = |decode_infos[i].reg_type_w;
    assign d_r_pkg.w_mem[i] = |decode_infos[i].mem_type_write;
    assign d_r_pkg.reg_need[2*i    ] = decode_infos[i].reg_type_r0 != `_REG_ZERO; // & decode_infos[i].reg_type_r0 != `_REG_IMM;
    assign d_r_pkg.reg_need[2*i + 1] = decode_infos[i].reg_type_r1 != `_REG_ZERO; // & decode_infos[i].reg_type_r1 != `_REG_IMM;

    assign d_r_pkg.use_imm[2*i    ] = decode_infos[i].reg_type_r0 == `_REG_IMM;
    assign d_r_pkg.use_imm[2*i + 1] = decode_infos[i].reg_type_r1 == `_REG_IMM;
end

// arftable逻辑
for (genvar i = 0; i < 2; i=i+1) begin
    logic [31:0] inst;
    assign inst = decode_infos[i].inst;

    logic [4:0] rd, rj, rk;
    assign rd = inst[ 4:0 ];
    assign rj = inst[ 9:5 ];
    assign rk = inst[14:10];

    always_comb begin
        // 第一个读寄存器
        case (decode_infos[i].reg_type_r0)
        _REG_RD: d_r_pkg.arf_table.r_arfid[2*i] = rd;
        _REG_RJ: d_r_pkg.arf_table.r_arfid[2*i] = rj;
        _REG_RK: d_r_pkg.arf_table.r_arfid[2*i] = rk;
        default: d_r_pkg.arf_table.r_arfid[2*i] = '0; // 默认不使用 GR 的时候即为使用 GR[0], 哪怕是使用 IMM 也会传入0
        endcase

        // 第二个读寄存器
        case (decode_infos[i].reg_type_r1)
        _REG_RD: d_r_pkg.arf_table.r_arfid[2*i+1] = rd;
        _REG_RJ: d_r_pkg.arf_table.r_arfid[2*i+1] = rj;
        _REG_RK: d_r_pkg.arf_table.r_arfid[2*i+1] = rk;
        default: d_r_pkg.arf_table.r_arfid[2*i+1] = '0; // 默认不使用 GR 的时候即为使用 GR[0], 哪怕是使用 IMM 也会传入0
        endcase

        // 第一个写寄存器
        case (decode_infos[i].reg_type_w)
        _REG_W_RD: d_r_pkg.arf_table.w_arfid[i] = rd;
        _REG_W_RJ: d_r_pkg.arf_table.w_arfid[i] = rj;
        _REG_W_R1: d_r_pkg.arf_table.w_arfid[i] = 1; // 仅出现在 BL 指令中
        default:   d_r_pkg.arf_table.w_arfid[i] = '0; // 默认不写入寄存器的时候即为写入 GR[0]
        endcase
    end
end

// 立即数逻辑
for (genvar i = 0; i < 2; i=i+1) begin
    logic [31:0] inst;
    assign inst = decode_infos[i].inst;

    assign d_r_pkg.data_imm[i] = inst_to_data_imm(inst, decode_infos[i].imm_type);
    assign d_r_pkg.addr_imm[i] = inst_to_addr_imm(inst, decode_infos[i].addr_imm_type);
end

// predict_infos 逻辑
for (genvar i = 0; i < 2; i=i+1) begin
    assign d_r_pkg.predict_infos[i] = receiver.predict_infos[i];
end

// ALU 信号逻辑
for (genvar i = 0; i < 2; i=i+1) begin
    assign d_r_pkg.grand_op = decode_infos[i].alu_grand_op;
    assign d_r_pkg.op = decode_infos[i].alu_op;
    assign d_r_pkg.msigned = decode_infos[i].mem_signed;
    assign d_r_pkg.msize = mem_size;
end

// 指令类型
for (genvar i = 0; i < 2; i=i+1) begin
    assign d_r_pkg.alu_type[i] = decode_infos[i].alu_inst;
    assign d_r_pkg.mdu_type[i] = decode_infos[i].mdu_inst;
    assign d_r_pkg.lsu_type[i] = decode_infos[i].lsu_inst;

    assign d_r_pkg.flush_inst[i] = decode_infos[i].flush_inst;
    assign d_r_pkg.jump_inst[i] = decode_infos[i].jump_inst;
    assign d_r_pkg.priv_inst[i] = decode_infos[i].priv_inst;
    assign d_r_pkg.rdcnt_inst[i] = decode_infos[i].rdcnt_inst;
    assign d_r_pkg.tlb_inst[i] = decode_infos[i].tlb_inst;
end

// 特殊指令的独热信号
for (genvar i = 0; i < 2; i=i+1) begin
    assign d_r_pkg.break_inst[i] = decode_infos[i].break_inst;
    assign d_r_pkg.cacop_inst[i] = decode_infos[i].cacop_inst;
    assign d_r_pkg.dbar_inst[i] = decode_infos[i].dbar_inst;
    assign d_r_pkg.ertn_inst[i] = decode_infos[i].ertn_inst;
    assign d_r_pkg.ibar_inst[i] = decode_infos[i].ibar_inst;
    assign d_r_pkg.idle_inst[i] = decode_infos[i].idle_inst;
    assign d_r_pkg.invtlb_inst[i] = decode_infos[i].invtlb_inst;
    assign d_r_pkg.ll_inst[i] = decode_infos[i].ll_inst;

    assign d_r_pkg.rdcntid_inst[i] = decode_infos[i].rdcntid_inst;
    assign d_r_pkg.rdcntvh_inst[i] = decode_infos[i].rdcntvh_inst;
    assign d_r_pkg.rdcntvl_inst[i] = decode_infos[i].rdcntvl_inst;

    assign d_r_pkg.sc_inst[i] = decode_infos[i].sc_inst;
    assign d_r_pkg.syscall_inst[i] = decode_infos[i].syscall_inst;
    assign d_r_pkg.tlbfill_inst[i] = decode_infos[i].tlbfill_inst;
    assign d_r_pkg.tlbrd_inst[i] = decode_infos[i].tlbrd_inst;
    assign d_r_pkg.tlbsrch_inst[i] = decode_infos[i].tlbsrch_inst;
    assign d_r_pkg.tlbwr_inst[i] = decode_infos[i].tlbwr_inst;

    assign d_r_pkg.csr_op_type[i] = decode_infos[i].csr_op_type;
    assign d_r_pkg.csr_num[i] = decode_infos[i].inst[23:10];
    assign d_r_pkg.inst_4_0[i] = decode_infos[i].inst[4:0];
    assign d_r_pkg.decode_err[i] = decode_infos[i].decode_err;
    assign d_r_pkg.is_branch[i] = decode_infos[i].jump_inst;
end

endmodule
