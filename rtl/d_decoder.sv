`include "a_decoder.svh"

// 纯组合逻辑，D流水级的时序在顶层模块上，其实也就是在进来的时候打了一拍放到了FIFO中而已。
module decoder (
    handshake_if.receiver               receiver, // f_d_pkg_t type
    handshake_if.sender                 sender, // d_r_pkg_t type

    output decoder_info_t   [1:0]       decode_infos_o, // TODO: 需要合并到sender中
);

// input && output
logic [1:0]         mask_i;
logic [1:0][31:0]   pc_i;
logic [1:0][31:0]   insts_i;
d_r_pkg_t           d_r_pkg_o;

assign mask_i = receiver.data.preict_info.mask;
assign pc_i = receiver.data.preict_info.pc;
assign insts_i = receiver.data.insts;

assign sender.data = d_r_pkg_o;
// 由于这个模块是一个组合逻辑模块，因此只需要将模块前后的 ready 和 valid 接在一起就行，唯一的改变仅在于 data 上
assign sender.valid = receiver.valid;
assign receiver.ready = sender.ready;

// 内置两个decoder, decode_infos_o 生成逻辑
for (genvar i = 0; i < 2; i++) begin
    basic_decoder basic_decoder (
        .ins_i(insts_i[i]),
        .decode_info_o(decode_infos_o[i])
    );
end

// d_r_pkg_o 逻辑
assign d_r_pkg_o.r_valid = mask_i;
assign d_r_pkg_o.pc = pc_i;

for (genvar i = 0; i < 2; i++) begin
    assign d_r_pkg_o.w_reg[i] = decode_infos_o[i].reg_type_w == _REG_W_NONE;
    assign d_r_pkg_o.w_mem[i] = decode_infos_o[i].mem_type_write;
    assign d_r_pkg_o.reg_need[2*i    ] = decode_infos_o[i].reg_type_r0 == _REG_ZERO | decode_infos_o[i].reg_type_r0 == _REG_IMM;
    assign d_r_pkg_o.reg_need[2*i + 1] = decode_infos_o[i].reg_type_r1 == _REG_ZERO | decode_infos_o[i].reg_type_r1 == _REG_IMM;

    assign d_r_pkg_o.use_imm[2*i    ] = decode_infos_o[i].reg_type_r0 == _REG_IMM;
    assign d_r_pkg_o.use_imm[2*i + 1] = decode_infos_o[i].reg_type_r1 == _REG_IMM;

    assign d_r_pkg_o.alu_type[i] = decode_infos_o[i].alu_inst;
    assign d_r_pkg_o.mdu_type[i] = decode_infos_o[i].mul_inst | decode_infos_o[i].div_inst;
    assign d_r_pkg_o.lsu_type[i] = decode_infos_o[i].lsu_inst;
end

// arftable逻辑
for (genvar i = 0; i < 2; i++) begin
    logic [31:0] inst;
    assign inst = decode_infos_o[i].inst;

    logic [4:0] rd, rj, rk;
    assign rd = inst[ 4:0 ]
    assign rj = inst[ 9:5 ];
    assign rk = inst[14:10];

    always_comb begin
        // 第一个读寄存器
        case (decode_infos_o[i].reg_type_r0)
        _REG_RD: d_r_pkg_o.arf_table.r_arfid[2*i] = rd;
        _REG_RJ: d_r_pkg_o.arf_table.r_arfid[2*i] = rj;
        _REG_RK: d_r_pkg_o.arf_table.r_arfid[2*i] = rk;
        default: d_r_pkg_o.arf_table.r_arfid[2*i] = '0; // 默认不使用 GR 的时候即为使用 GR[0], 哪怕是使用 IMM 也会传入0
        endcase

        // 第二个读寄存器
        case (decode_infos_o[i].reg_type_r0)
        _REG_RD: d_r_pkg_o.arf_table.r_arfid[2*i+1] = rd;
        _REG_RJ: d_r_pkg_o.arf_table.r_arfid[2*i+1] = rj;
        _REG_RK: d_r_pkg_o.arf_table.r_arfid[2*i+1] = rk;
        default: d_r_pkg_o.arf_table.r_arfid[2*i+1] = '0; // 默认不使用 GR 的时候即为使用 GR[0], 哪怕是使用 IMM 也会传入0
        endcase

        // 第一个写寄存器
        case (decode_infos_o[i].reg_type_w)
        _REG_W_RD: d_r_pkg_o.arf_table.w_arfid[i] = rd;
        _REG_W_RJ: d_r_pkg_o.arf_table.w_arfid[i] = rj;
        _REG_W_R1: d_r_pkg_o.arf_table.w_arfid[i] = 1; // 仅出现在 BL 指令中
        default:   d_r_pkg_o.arf_table.w_arfid[i] = '0; // 默认不写入寄存器的时候即为写入 GR[0]
        endcase
    end
end

// 立即数逻辑
for (genvar i = 0; i < 2; i++) begin
    logic [31:0] inst;
    assign inst = decode_infos_o[i].inst;

    assign d_r_pkg_o.data_imm[i] = inst_to_data_imm(inst, decode_infos_o[i].imm_type);
    assign d_r_pkg_o.addr_imm[i] = inst_to_addr_imm(inst, decode_infos_o[i].addr_imm_type);
end

endmodule