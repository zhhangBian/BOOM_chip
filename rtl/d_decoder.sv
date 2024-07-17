`include "a_decoder.svh"

// 纯组合逻辑，D流水级的时序在顶层模块上，其实也就是在进来的时候打了一拍放到了FIFO中而已。
module decoder (
    handshake_if.receiver               receiver, // f_d_pkg_t type
    handshake_if.sender                 sender,

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

// 内置两个decoder
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
    assign d_r_pkg_o.reg_need[(1 << i)    ] = decode_infos_o[i].reg_type_r0 == _REG_ZERO | decode_infos_o[i].reg_type_r0 == _REG_IMM;
    assign d_r_pkg_o.reg_need[(1 << i) + 1] = decode_infos_o[i].reg_type_r1 == _REG_ZERO | decode_infos_o[i].reg_type_r1 == _REG_IMM;

    assign d_r_pkg_o.use_imm[(1 << i)    ] = decode_infos_o[i].reg_type_r0 == _REG_IMM;
    assign d_r_pkg_o.use_imm[(1 << i) + 1] = decode_infos_o[i].reg_type_r1 == _REG_IMM;

    assign d_r_pkg_o.alu_type[i] = decode_infos_o[i].alu_inst;
    assign d_r_pkg_o.mdu_type[i] = decode_infos_o[i].mul_inst | decode_infos_o[i].div_inst;
    assign d_r_pkg_o.lsu_type[i] = decode_infos_o[i].lsu_inst;
end

// arftable逻辑
for (genvar i = 0; i < 2; i++) begin
    // TODO
end

// 立即数逻辑
// TODO: 用 function 替代下面的一坨。学长的function定义在structure中，需要改动。
logic [1:0][31:0] data_imms;
logic [1:0][31:0] addr_imms;
for (genvar i = 0; i < 2; i++) begin
    logic inst;
    assign inst = decode_infos_o[i].inst;

    // data_imms 逻辑
    logic [31:0]    data_imm_s12, 
                    data_imm_s20,
                    data_imm_u12;
                    data_imm_u5;

    assign data_imm_s12 = {20{inst[21]}, inst[21:10]};
    assign data_imm_s20 = {12{inst[24]}, inst[24:5]};
    assign data_imm_u12 = {20'b0,        inst[21:10]};
    assign data_imm_u5  = inst[14:10];

    case (decode_infos_o[i].imm_type)
        _IMM_S12: data_imms[i] = data_imm_s12;
        _IMM_S20: data_imms[i] = data_imm_s20;
        _IMM_U5: data_imms[i] = data_imm_u5;
        default: 
        _IMM_U12: data_imms[i] = data_imm_u12;
    endcase

    // addr_imms 逻辑
    logic [31:0]    addr_imm_s12, // 仅用于store/load指令，低位不补零;
                    addr_imm_s14, // 仅用于原子访存指令，低位补两个0;
                    addr_imm_s16, // 仅用于计算分支offset，低位补两个0;
                    // addr_imm_s21, // 仅浮点指令使用，暂时不使用
                    addr_imm_s26; // 仅用于计算分支offset，低位补两个0;
    
    assign addr_imm_s12 = {20{inst[21]}, inst[21:10]};
    assign addr_imm_s14 = {16{inst[23]}, inst[23:10], 2'b0};
    assign addr_imm_s16 = {14{inst[25]}, inst[25:10], 2'b0};
    assign addr_imm_s26 = {4 {inst[ 9]}, inst[ 9:0 ], inst[25:10], 2'b0};

    case (decode_infos_o[i].addr_imm_type) 
        _ADDR_IMM_S12: addr_imms[i] = addr_imm_s12;
        _ADDR_IMM_S14: addr_imms[i] = addr_imm_s14;
        _ADDR_IMM_S16: addr_imms[i] = addr_imm_s16;
        default: 
        _ADDR_IMM_S26: addr_imms[i] = addr_imm_s26;
    endcase
end
assign d_r_pkg_o.data_imm = data_imms;
assign d_r_pkg_o.addr_imm = addr_imms; // TODO: addr_imm member is not implemented yet. 

endmodule