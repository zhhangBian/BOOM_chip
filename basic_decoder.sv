/**
 * Decoder， 用于解码LA精简指令集的指令。
 * 解码的指令包括：
 *      算术：              ADD.W,  SLL.W,  SRL.W,  SRA.W,  SUB.W,  NOR,    AND,    OR,     XOR,    SLT,    SLTU, 
 *      算术 + 12位立即数:  ADDI.W, LU12I.W,SLLI.W, SRLI.W, SRAI.W, ANDI,   ORI,    XORI,   SLTI,   SLTUI, 
 *      乘除：              MUL.W,  MULH.W, MULH.WU,DIV.W,  MOD.W,  DIV.WU, MOD.WU,
 *      分支指令：          BEQ,    BNE,    BLTU,   BLT,    BGEU,   BGE,    B,      BL,     JIRL, 
 *      访存指令：          LD.B,   LD.BU,  LD.H,   LD.HU,  LD.W,   ST.B,   ST.H,   ST.W, 
 *      原子访存：          LL.W,   SC.W, 
 *      CSR:               CSRRD,  CSRWR,  CSRXCHG
 *      CACHE:             CACOP
 *      TLB:               TLBSRCH,TLBRD,  TLBWR,  TLBFILL,INVTLB
 *      栅障指令：          DBAR,   IBAR ??????
 *      其他：              BREAK, SYSCALL, PCADDU12I, NOP, RDCNTVL.W, RDCNTVLH.W, RDCNTID, ERTN, IDLE
 * 
 * 注意事项：
 *      1. 该解码器模块仅解码一条指令，
 *      2. 该解码器为**纯组合逻辑**，记得在前端顶层模块中搭配 skidbuf/FIFO 使用
 *      3. 
 */

`include "a_defines.svh"

module basic_decoder (
    input logic[31:0]       ins_i, // input data include **ONLY ONE** 32-bit instructions.
    output d_decode_info_t    decode_info_o // output data include **ONLY ONE** decode information
);
always_comb begin
    decode_info_o.addr_imm_type = `_ADDR_IMM_S26;
    decode_info_o.alu_grand_op = 3'd0;
    decode_info_o.alu_inst = 1'd0;
    decode_info_o.alu_op = 3'd0;
    decode_info_o.break_inst = 1'd0;
    decode_info_o.csr_op_type = `_CSR_CSRNONE;
    decode_info_o.dbar_inst = 1'd0;
    decode_info_o.decode_err = 1'b0; // 有修改
    decode_info_o.ertn_inst = 1'd0;
    decode_info_o.flush_inst = 1'd0;
    decode_info_o.inst = ins_i;
    decode_info_o.ibar_inst = 1'd0;
    decode_info_o.idle_inst = 1'd0;
    decode_info_o.imm_type = `_IMM_U12;
    decode_info_o.invtlb_inst = 1'd0;
    decode_info_o.ll_inst = 1'd0;
    decode_info_o.lsu_inst = 1'd0;
    decode_info_o.jirl_as_call = 1'd0;
    decode_info_o.jirl_as_ret = 1'd0;
    decode_info_o.jirl_as_normal = 1'd0;
    decode_info_o.jump_inst = 1'd0;
    decode_info_o.cacop_inst = 1'd0;
    decode_info_o.mem_read = 1'd0;
    decode_info_o.mem_signed = 1'd0;
    decode_info_o.mem_size = 2'd0;
    decode_info_o.mem_write = 1'd0;
    decode_info_o.mdu_inst = 1'd0;
    decode_info_o.priv_inst = 1'd0;
    decode_info_o.rdcnt_inst = 1'd0;
    decode_info_o.rdcntvl_inst = 1'd0;
    decode_info_o.rdcntvh_inst = 1'd0;
    decode_info_o.rdcntid_inst = 1'd0;
    decode_info_o.reg_type_r0 = `_REG_ZERO;
    decode_info_o.reg_type_r1 = `_REG_ZERO;
    decode_info_o.reg_type_w = `_REG_W_NONE;
    decode_info_o.sc_inst = 1'd0;
    decode_info_o.syscall_inst = 1'd0;
    decode_info_o.target_type = 1'd0;
    decode_info_o.tlb_inst = 1'd0;
    decode_info_o.tlbfill_inst = 1'd0;
    decode_info_o.tlbrd_inst = 1'd0;
    decode_info_o.tlbsrch_inst = 1'd0;
    decode_info_o.tlbwr_inst = 1'd0;
    /*
    decode_info_o.bceqz = 1'd0;
    decode_info_o.bcnez = 1'd0;
    decode_info_o.fpu_op = 4'd0;
    decode_info_o.fpu_mode = 1'd0;
    decode_info_o.rnd_mode = 4'd0;
    decode_info_o.fpd_inst = 1'd0;
    decode_info_o.fcsr_upd = 1'd0;
    decode_info_o.fcmp = 1'd0;
    decode_info_o.fcsr2gr = 1'd0;
    decode_info_o.gr2fcsr = 1'd0;
    decode_info_o.upd_fcc = 1'd0;
    decode_info_o.fsel = 1'd0;
    decode_info_o.fclass = 1'd0;
    decode_info_o.fpu_inst = 1'd0;
    decode_info_o.fbranch_inst = 1'd0;
    decode_info_o.fr0 = 1'd0;
    decode_info_o.fr1 = 1'd0;
    decode_info_o.fr2 = 1'd0;
    decode_info_o.fw = 1'd0;
    */
    unique casez(ins_i) // unique 会检查确保每一个情况都是互斥的
        /*==================== 算术指令 ====================*/
        // ADD.W
        32'b00000000000100000???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_grand_op = `_GRAND_OP_INT;
            decode_info_o.alu_op = `_INT_ADD;
        end
        // SUB.W
        32'b00000000000100010???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_grand_op = `_GRAND_OP_INT;
            decode_info_o.alu_op = `_INT_SUB;
        end
        // SLT
        32'b00000000000100100???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_grand_op = `_GRAND_OP_INT;
            decode_info_o.alu_op = `_INT_SLT;
        end
        // SLTU
        32'b00000000000100101???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_grand_op = `_GRAND_OP_INT;
            decode_info_o.alu_op = `_INT_SLTU;
        end
        // NOR
        32'b00000000000101000???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_grand_op = `_GRAND_OP_BW;
            decode_info_o.alu_op = `_BW_NOR;
        end
        // AND
        32'b00000000000101001???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_grand_op = `_GRAND_OP_BW;
            decode_info_o.alu_op = `_BW_AND;
        end
        // OR
        32'b00000000000101010???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_grand_op = `_GRAND_OP_BW;
            decode_info_o.alu_op = `_BW_OR;
        end
        // XOR
        32'b00000000000101011???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_grand_op = `_GRAND_OP_BW;
            decode_info_o.alu_op = `_BW_XOR;
        end
        // SLL.W
        32'b00000000000101110???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_grand_op = `_GRAND_OP_SFT;
            decode_info_o.alu_op = `_SFT_SLL;
        end
        // SRL.W
        32'b00000000000101111???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_grand_op = `_GRAND_OP_SFT;
            decode_info_o.alu_op = `_SFT_SRL;
        end
        // SRA.W
        32'b00000000000110000???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_grand_op = `_GRAND_OP_SFT;
            decode_info_o.alu_op = `_SFT_SRA;
        end
        /*==================== 算术 + 立即数 ====================*/
        // SLLI.W
        32'b00000000010000001???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_IMM;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.imm_type = `_IMM_U5;
            decode_info_o.alu_grand_op = `_GRAND_OP_SFT;
            decode_info_o.alu_op = `_SFT_SLL;
        end
        // SRLI.W
        32'b00000000010001001???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_IMM;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.imm_type = `_IMM_U5;
            decode_info_o.alu_grand_op = `_GRAND_OP_SFT;
            decode_info_o.alu_op = `_SFT_SRL;
        end
        // SRAI.W
        32'b00000000010010001???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_IMM;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.imm_type = `_IMM_U5;
            decode_info_o.alu_grand_op = `_GRAND_OP_SFT;
            decode_info_o.alu_op = `_SFT_SRA;
        end
        // LU12I.W
        32'b0001010?????????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_IMM;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.imm_type = `_IMM_S20;
            decode_info_o.alu_grand_op = `_GRAND_OP_LI;
            decode_info_o.alu_op = `_LI_LUI;
        end
        // PCADDU12I
        32'b0001110?????????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_IMM;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.imm_type = `_IMM_S20;
            decode_info_o.alu_grand_op = `_GRAND_OP_LI;
            decode_info_o.alu_op = `_LI_PCADDUI;
        end
        // SLTI
        32'b0000001000??????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_IMM;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.imm_type = `_IMM_S12;
            decode_info_o.alu_grand_op = `_GRAND_OP_INT;
            decode_info_o.alu_op = `_INT_SLT;
        end
        // SLTUI
        32'b0000001001??????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_IMM;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.imm_type = `_IMM_S12;
            decode_info_o.alu_grand_op = `_GRAND_OP_INT;
            decode_info_o.alu_op = `_INT_SLTU;
        end
        // ADDI.W
        32'b0000001010??????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_IMM;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.imm_type = `_IMM_S12;
            decode_info_o.alu_grand_op = `_GRAND_OP_INT;
            decode_info_o.alu_op = `_INT_ADD;
        end
        // ANDI
        32'b0000001101??????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_IMM;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.imm_type = `_IMM_U12;
            decode_info_o.alu_grand_op = `_GRAND_OP_BW;
            decode_info_o.alu_op = `_BW_AND;
        end
        // ORI
        32'b0000001110??????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_IMM;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.imm_type = `_IMM_U12;
            decode_info_o.alu_grand_op = `_GRAND_OP_BW;
            decode_info_o.alu_op = `_BW_OR;
        end
        // XORI
        32'b0000001111??????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_IMM;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.imm_type = `_IMM_U12;
            decode_info_o.alu_grand_op = `_GRAND_OP_BW;
            decode_info_o.alu_op = `_BW_XOR;
        end
        /*==================== 乘除指令 MDU ====================*/
        // MUL.W
        32'b00000000000111000???????????????: begin
            decode_info_o.mdu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_op = `_MDU_MUL;
            decode_info_o.flush_inst = 1'd1;
        end
        // MULH.W
        32'b00000000000111001???????????????: begin
            decode_info_o.mdu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_op = `_MDU_MULH;
            decode_info_o.flush_inst = 1'd1;
        end
        // MULH.WU
        32'b00000000000111010???????????????: begin
            decode_info_o.mdu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_op = `_MDU_MULHU;
            decode_info_o.flush_inst = 1'd1;
        end
        // DIV.W
        32'b00000000001000000???????????????: begin
            decode_info_o.mdu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_op = `_MDU_DIV;
            decode_info_o.flush_inst = 1'd1;
        end
        // MOD.W
        32'b00000000001000001???????????????: begin
            decode_info_o.mdu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_op = `_MDU_MOD;
            decode_info_o.flush_inst = 1'd1;
        end
        // DIV.WU
        32'b00000000001000010???????????????: begin
            decode_info_o.mdu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_op = `_MDU_DIVU;
            decode_info_o.flush_inst = 1'd1;
        end
        // MOD.WU
        32'b00000000001000011???????????????: begin
            decode_info_o.mdu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.alu_op = `_MDU_MODU;
            decode_info_o.flush_inst = 1'd1;
        end
        /*==================== 分支指令 ====================*/
        // JIRL
        32'b010011??????????????????????????: begin
            // JIRL as normal branch instruction
            decode_info_o.alu_inst = 1'd1;
			if (ins_i[25:5] == 21'd1) begin
				decode_info_o.jirl_as_ret = 1'd1;
			end
			else if (ins_i[4:0] == 5'd1) begin
				decode_info_o.jirl_as_call = 1'd1;
			end
			else begin
				decode_info_o.jirl_as_normal = 1'd1;
			end
            decode_info_o.br_type = BR_RET;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S16;
            decode_info_o.alu_grand_op = `_GRAND_OP_COM;
            decode_info_o.alu_op = `_COM_PCADD4;
            decode_info_o.target_type = `_TARGET_ABS;
            decode_info_o.jump_inst = 1'd1;
        end
        // B
        32'b010100??????????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.br_type = BR_B;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S26;
            decode_info_o.target_type = `_TARGET_REL;
            decode_info_o.jump_inst = 1'd1;
        end
        // BL
        32'b010101??????????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.br_type = BR_CALL;
            decode_info_o.reg_type_w = `_REG_W_R1;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S26;
            decode_info_o.alu_grand_op = `_GRAND_OP_COM;
            decode_info_o.alu_op = `_COM_PCADD4;
            decode_info_o.target_type = `_TARGET_REL;
            decode_info_o.jump_inst = 1'd1;
        end
        // BEQ
        32'b010110??????????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.br_type = BR_NORMAL;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S16;
            decode_info_o.target_type = `_TARGET_REL;
            decode_info_o.alu_grand_op = `_GRAND_OP_COM;
            decode_info_o.alu_op = `_COM_EQ;
            decode_info_o.jump_inst = 1'd1;
        end
        // BNE
        32'b010111??????????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.br_type = BR_NORMAL;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S16;
            decode_info_o.target_type = `_TARGET_REL;
            decode_info_o.alu_grand_op = `_GRAND_OP_COM;
            decode_info_o.alu_op = `_COM_NE;
            decode_info_o.jump_inst = 1'd1;
        end
        // BLT
        32'b011000??????????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.br_type = BR_NORMAL;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S16;
            decode_info_o.target_type = `_TARGET_REL;
            decode_info_o.alu_grand_op = `_GRAND_OP_COM;
            decode_info_o.alu_op = `_COM_LT;
            decode_info_o.jump_inst = 1'd1;
        end
        // BGE
        32'b011001??????????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.br_type = BR_NORMAL;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S16;
            decode_info_o.target_type = `_TARGET_REL;
            decode_info_o.alu_grand_op = `_GRAND_OP_COM;
            decode_info_o.alu_op = `_COM_GE;
            decode_info_o.jump_inst = 1'd1;
        end
        // BLTU
        32'b011010??????????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.br_type = BR_NORMAL;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S16;
            decode_info_o.target_type = `_TARGET_REL;
            decode_info_o.alu_grand_op = `_GRAND_OP_COM;
            decode_info_o.alu_op = `_COM_LTU;
            decode_info_o.jump_inst = 1'd1;
        end
        // BGEU
        32'b011011??????????????????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.br_type = BR_NORMAL;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S16;
            decode_info_o.target_type = `_TARGET_REL;
            decode_info_o.alu_grand_op = `_GRAND_OP_COM;
            decode_info_o.alu_op = `_COM_GEU;
            decode_info_o.jump_inst = 1'd1;
        end
        /*==================== CSR ====================*/
        // CSRRD, CSRWR, CSRXCHG
        32'b00000100????????????????????????: begin
            decode_info_o.priv_inst = 1'd1;
            decode_info_o.flush_inst = 1'd1;
            case (ins_i[9:5])
                5'b0:
                    // CSRRD
                    decode_info_o.csr_op_type = `_CSR_CSRRD;
                5'b1: 
                    // CSRWR
                    decode_info_o.csr_op_type = `_CSR_CSRWR;
                default: 
                    // CSRXCHG
                    decode_info_o.csr_op_type = `_CSR_CSRXCHG;
            endcase
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RD;
            decode_info_o.reg_type_w = `_REG_W_RD;
        end
        /*==================== 原子访存 ====================*/
        // LL.W
        32'b00100000????????????????????????: begin
            decode_info_o.lsu_inst = 1'd1;
            decode_info_o.reg_type_r1 = `_REG_RJ; // 所有访存的 RJ 都是 r1
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S14;
            decode_info_o.mem_size = 2'd3;
            decode_info_o.mem_signed = 1'd1;
            decode_info_o.mem_read = 1'd1;
            decode_info_o.ll_inst = 1'd1;
            decode_info_o.flush_inst = 1'd1;
        end
        // SC.W
        32'b00100001????????????????????????: begin
            decode_info_o.lsu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RD;
            decode_info_o.reg_type_r1 = `_REG_RJ; // 所有访存的 RJ 都是 r1
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S14;
            decode_info_o.mem_size = 2'd3;
            decode_info_o.mem_signed = 1'd1;
            decode_info_o.mem_write = 1'd1;
            decode_info_o.sc_inst = 1'd1;
            decode_info_o.flush_inst = 1'd1;
        end
        /*==================== CACHE ====================*/
        // CACOP
        32'b0000011000??????????????????????: begin
            decode_info_o.priv_inst = (ins_i[4:3] != 2'b10); // 
            decode_info_o.flush_inst = 1'd1;
            decode_info_o.lsu_inst = 1'd1;
            decode_info_o.reg_type_r1 = `_REG_RJ; // 所有访存的 RJ 都是 r1
            decode_info_o.addr_imm_type = `_ADDR_IMM_S12;
            decode_info_o.mem_size = 2'd0;
            decode_info_o.mem_signed = 1'd1;
            decode_info_o.cacop_inst = 1'd1;
        end
        /*==================== 访存指令 ====================*/
        // LD.B
        32'b0010100000??????????????????????: begin
            decode_info_o.lsu_inst = 1'd1;
            decode_info_o.reg_type_r1 = `_REG_RJ; // 所有访存的 RJ 都是 r1
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S12;
            decode_info_o.mem_size = 2'd0;
            decode_info_o.mem_signed = 1'd1;
            decode_info_o.mem_read = 1'd1;
        end
        // LD.H
        32'b0010100001??????????????????????: begin
            decode_info_o.lsu_inst = 1'd1;
            decode_info_o.reg_type_r1 = `_REG_RJ; // 所有访存的 RJ 都是 r1
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S12;
            decode_info_o.mem_size = 2'd1;
            decode_info_o.mem_signed = 1'd1;
            decode_info_o.mem_read = 1'd1;
        end
        // LD.W
        32'b0010100010??????????????????????: begin
            decode_info_o.lsu_inst = 1'd1;
            decode_info_o.reg_type_r1 = `_REG_RJ; // 所有访存的 RJ 都是 r1
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S12;
            decode_info_o.mem_size = 2'd3;
            decode_info_o.mem_signed = 1'd1;
            decode_info_o.mem_read = 1'd1;
        end
        // ST.B
        32'b0010100100??????????????????????: begin
            decode_info_o.lsu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RD;
            decode_info_o.reg_type_r1 = `_REG_RJ; // 所有访存的 RJ 都是 r1
            decode_info_o.addr_imm_type = `_ADDR_IMM_S12;
            decode_info_o.mem_size = 2'd0;
            decode_info_o.mem_signed = 1'd1;
            decode_info_o.mem_write = 1'd1;
        end
        // ST.H
        32'b0010100101??????????????????????: begin
            decode_info_o.lsu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RD;
            decode_info_o.reg_type_r1 = `_REG_RJ; // 所有访存的 RJ 都是 r1
            decode_info_o.addr_imm_type = `_ADDR_IMM_S12;
            decode_info_o.mem_size = 2'd1;
            decode_info_o.mem_signed = 1'd1;
            decode_info_o.mem_write = 1'd1;
        end
        // ST.W
        32'b0010100110??????????????????????: begin
            decode_info_o.lsu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RD;
            decode_info_o.reg_type_r1 = `_REG_RJ; // 所有访存的 RJ 都是 r1
            decode_info_o.addr_imm_type = `_ADDR_IMM_S12;
            decode_info_o.mem_size = 2'd3;
            decode_info_o.mem_signed = 1'd1;
            decode_info_o.mem_write = 1'd1;
        end
        // LD.BU
        32'b0010101000??????????????????????: begin
            decode_info_o.lsu_inst = 1'd1;
            decode_info_o.reg_type_r1 = `_REG_RJ; // 所有访存的 RJ 都是 r1
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S12;
            decode_info_o.mem_size = 2'd0;
            decode_info_o.mem_signed = 1'd0;
            decode_info_o.mem_read = 1'd1;
        end
        // LD.HU
        32'b0010101001??????????????????????: begin
            decode_info_o.lsu_inst = 1'd1;
            decode_info_o.reg_type_r1 = `_REG_RJ; // 所有访存的 RJ 都是 r1
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S12;
            decode_info_o.mem_size = 2'd1;
            decode_info_o.mem_signed = 1'd0;
            decode_info_o.mem_read = 1'd1;
        end
        /*==================== 其他指令 ====================*/
        // BREAK
        32'b00000000001010100???????????????: begin
            decode_info_o.break_inst = 1'd1;
            decode_info_o.alu_inst = 1'd1;
        end
        // SYSCALL
        32'b00000000001010110???????????????: begin
            decode_info_o.syscall_inst = 1'd1;
            decode_info_o.alu_inst = 1'd1;
        end
        // ERTN
        32'b0000011001001000001110??????????: begin
            decode_info_o.priv_inst = 1'd1;
            decode_info_o.ertn_inst = 1'd1;
            decode_info_o.flush_inst = 1'd1;
            decode_info_o.alu_inst = 1'd1;
        end
        // IDLE
        32'b00000110010010001???????????????: begin
            decode_info_o.priv_inst = 1'd1;
            decode_info_o.idle_inst = 1'd1;
            decode_info_o.flush_inst = 1'd0;//TODO check
            decode_info_o.alu_inst = 1'd1;
        end
        // DBAR
        32'b00111000011100100???????????????: begin
            decode_info_o.alu_inst = 1'd1; // TODO: check
            decode_info_o.dbar_inst = 1'd1;
            decode_info_o.flush_inst = 1'd1;
        end
        // IBAR
        32'b00111000011100101???????????????: begin
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.ibar_inst = 1'd1;
            decode_info_o.flush_inst = 1'd1;
        end
        32'b0000000000000000011000??????????: begin
            decode_info_o.rdcnt_inst = 1'd1;
            decode_info_o.flush_inst = 1'd1;
            if (ins_i[9:5] == 5'b0) begin
                // RDCNTVL.W
                decode_info_o.rdcntvl_inst = 1'd1;
                decode_info_o.reg_type_w = `_REG_W_RD;
            end
            else begin
                // RDCNTID.W
                decode_info_o.rdcntid_inst = 1'd1;
                decode_info_o.reg_type_w = `_REG_W_RJ;
            end
            decode_info_o.alu_inst = 1'd1;
        end
        // RDCNTVH.W
        32'b0000000000000000011001??????????: begin
            decode_info_o.rdcnt_inst = 1'd1;
            decode_info_o.rdcntvh_inst = 1'd1;
            decode_info_o.flush_inst = 1'd1;
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_w = `_REG_W_RD;
        end
        /*==================== TLB指令 ====================*/
        // INVTLB
        32'b00000110010010011???????????????: begin
            decode_info_o.priv_inst = 1'd1;
            decode_info_o.invtlb_inst = 1'd1;
            decode_info_o.tlb_inst = 1'd1;
            decode_info_o.flush_inst = 1'd1;
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
        end
        // TLBSRCH
        32'b0000011001001000001010??????????: begin
            decode_info_o.priv_inst = 1'd1;
            decode_info_o.tlbsrch_inst = 1'd1;
            decode_info_o.tlb_inst = 1'd1;
            decode_info_o.flush_inst = 1'd1;
            decode_info_o.alu_inst = 1'd1;
        end
        // TLBBRD
        32'b0000011001001000001011??????????: begin
            decode_info_o.priv_inst = 1'd1;
            decode_info_o.tlbrd_inst = 1'd1;
            decode_info_o.tlb_inst = 1'd1;
            decode_info_o.flush_inst = 1'd1;
            decode_info_o.alu_inst = 1'd1;
        end
        // TLBBWR
        32'b0000011001001000001100??????????: begin
            decode_info_o.priv_inst = 1'd1;
            decode_info_o.tlbwr_inst = 1'd1;
            decode_info_o.tlb_inst = 1'd1;
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.flush_inst = 1'd1;
        end
        // TLBFILL
        32'b0000011001001000001101??????????: begin
            decode_info_o.priv_inst = 1'd1;
            decode_info_o.tlbfill_inst = 1'd1;
            decode_info_o.tlb_inst = 1'd1;
            decode_info_o.flush_inst = 1'd1;
            decode_info_o.alu_inst = 1'd1;
        end
        /*==================== Pre load 指令 ====================*/
        // PRELD
        32'b0010101011??????????????????????: begin
            // 修改
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_ZERO;
            decode_info_o.reg_type_r1 = `_REG_ZERO;
            decode_info_o.reg_type_w = `_REG_W_NONE;
            decode_info_o.alu_grand_op = `_GRAND_OP_INT;
            decode_info_o.alu_op = `_INT_ADD;
        end

        /*==================== 浮点指令 ====================*/
        /*
        // FADD.S
        32'b00000001000000001???????????????: begin
            decode_info_o.fpu_op = fpnew_pkg::ADD;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r1 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        // FSUB.S
        32'b00000001000000101???????????????: begin
            decode_info_o.fpu_op = fpnew_pkg::ADD; // TODO: ????????
            decode_info_o.fpu_mode = 1'd1;
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r1 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        // FMUL.S
        32'b00000001000001001???????????????: begin
            decode_info_o.fpu_op = fpnew_pkg::MUL;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        // FDIV.S
        32'b00000001000001101???????????????: begin
            decode_info_o.fpu_op = fpnew_pkg::DIV;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        // FMAX.S
        32'b00000001000010001???????????????: begin
            decode_info_o.fpu_op = fpnew_pkg::MINMAX;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.rnd_mode = {1'd1,fpnew_pkg::RTZ};
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        // FMIN.S
        32'b00000001000010101???????????????: begin
            decode_info_o.fpu_op = fpnew_pkg::MINMAX;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.rnd_mode = {1'd1,fpnew_pkg::RNE};
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        // FCOPYSIGN.S
        32'b00000001000100101???????????????: begin
            decode_info_o.fpu_op = fpnew_pkg::SGNJ;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.rnd_mode = {1'd1,fpnew_pkg::RNE};
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        */
        /*
        32'b0000000100010100000001??????????: begin
            decode_info_o.fpu_op = fpnew_pkg::SGNJ;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.rnd_mode = {1'd1,fpnew_pkg::RDN};
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        32'b0000000100010100000101??????????: begin
            decode_info_o.fpu_op = fpnew_pkg::SGNJ;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.rnd_mode = {1'd1,fpnew_pkg::RTZ};
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        // FCLASS.S
        32'b0000000100010100001101??????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fclass = 1'd1;
            decode_info_o.fbranch_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        32'b0000000100010100010001??????????: begin
            decode_info_o.fpu_op = fpnew_pkg::SQRT;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        32'b0000000100010100010101??????????: begin
            decode_info_o.fpu_op = fpnew_pkg::DIV;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_IMM;
            decode_info_o.reg_type_r1 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.imm_type = `_IMM_F1;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        // FMOV.S
        32'b0000000100010100100101??????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fw = 1'd1;
            decode_info_o.alu_grand_op = `_ALU_GTYPE_BW;
            decode_info_o.alu_op = `_ALU_STYPE_OR;
        end
        // MOVGR2FR.W
        32'b0000000100010100101001??????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fw = 1'd1;
            decode_info_o.alu_grand_op = `_ALU_GTYPE_BW;
            decode_info_o.alu_op = `_ALU_STYPE_OR;
        end
        // MOVFR2GR.S
        32'b0000000100010100101101??????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.alu_grand_op = `_ALU_GTYPE_BW;
            decode_info_o.alu_op = `_ALU_STYPE_OR;
        end
        // MOVGR2FCSR
        32'b0000000100010100110000??????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.gr2fcsr = 1'd1;
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.slot0 = 1'd1;
            decode_info_o.refetch = 1'd1;
            decode_info_o.alu_grand_op = `_ALU_GTYPE_BW;
            decode_info_o.alu_op = `_ALU_STYPE_OR;
        end
        // MOVFCSR2GR
        32'b0000000100010100110010??????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fcsr2gr = 1'd1;
            decode_info_o.alu_inst = 1'd1;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.slot0 = 1'd1;
            decode_info_o.refetch = 1'd1;
        end
        // MOVFR2CF
        32'b0000000100010100110100??????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.upd_fcc = 1'd1;
            decode_info_o.fbranch_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.fr0 = 1'd1;
        end
        // MOVCF2FR
        32'b0000000100010100110101??????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fbranch_inst = 1'd1;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fw = 1'd1;
        end
        // MOVGR2CF
        32'b0000000100010100110110??????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.upd_fcc = 1'd1;
            decode_info_o.fbranch_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
        end
        // MOVCF2GR
        32'b0000000100010100110111??????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fbranch_inst = 1'd1;
            decode_info_o.reg_type_w = `_REG_W_RD;
        end
        32'b0000000100011010000001??????????: begin
            decode_info_o.fpu_op = fpnew_pkg::F2I;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.rnd_mode = {1'd1,fpnew_pkg::RDN};
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        32'b0000000100011010010001??????????: begin
            decode_info_o.fpu_op = fpnew_pkg::F2I;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.rnd_mode = {1'd1,fpnew_pkg::RUP};
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        32'b0000000100011010100001??????????: begin
            decode_info_o.fpu_op = fpnew_pkg::F2I;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.rnd_mode = {1'd1,fpnew_pkg::RTZ};
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        32'b0000000100011010110001??????????: begin
            decode_info_o.fpu_op = fpnew_pkg::F2I;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.rnd_mode = {1'd1,fpnew_pkg::RNE};
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        32'b0000000100011011000001??????????: begin
            decode_info_o.fpu_op = fpnew_pkg::F2I;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        32'b0000000100011101000100??????????: begin
            decode_info_o.fpu_op = fpnew_pkg::I2F;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        // BCEQZ
        32'b010010????????????????00????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.bceqz = 1'd1;
            decode_info_o.fbranch_inst = 1'd1;
            decode_info_o.slot0 = 1'd1;
            decode_info_o.target_type = `_TARGET_REL;
            decode_info_o.cmp_type = `_CMP_E;
            decode_info_o.jump_inst = 1'd1;
        end
        // BCNEZ
        32'b010010????????????????01????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.bcnez = 1'd1;
            decode_info_o.fbranch_inst = 1'd1;
            decode_info_o.slot0 = 1'd1;
            decode_info_o.target_type = `_TARGET_REL;
            decode_info_o.cmp_type = `_CMP_E; // TODO: ??????
            decode_info_o.jump_inst = 1'd1;
        end
        // 浮点：FLD.S
        32'b0010101100??????????????????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.lsu_inst = 1'd1;
            decode_info_o.reg_type_r1 = `_REG_RJ;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S12;
            decode_info_o.fw = 1'd1;
            decode_info_o.mem_type = `_MEM_TYPE_WORD;
            decode_info_o.mem_read = 1'd1;
        end
        // 浮点：FST.S
        32'b0010101101??????????????????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.lsu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RD;
            decode_info_o.reg_type_r1 = `_REG_RJ;
            decode_info_o.addr_imm_type = `_ADDR_IMM_S12;
            decode_info_o.slot0 = 1'd1;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.mem_type = `_MEM_TYPE_WORD;
            decode_info_o.mem_write = 1'd1;
        end
        32'b000010000001????????????????????: begin
            decode_info_o.fpu_op = fpnew_pkg::FMADD;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fr2 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        32'b000010000101????????????????????: begin
            decode_info_o.fpu_op = fpnew_pkg::FMADD;
            decode_info_o.fpu_mode = 1'd1;
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fr2 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        32'b000010001001????????????????????: begin
            decode_info_o.fpu_op = fpnew_pkg::FNMSUB;
            decode_info_o.fpu_mode = 1'd1;
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fr2 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        32'b000010001101????????????????????: begin
            decode_info_o.fpu_op = fpnew_pkg::FNMSUB;
            decode_info_o.fpu_mode = 1'd0;
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fpu_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fr2 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        // FCMP.cond.S
        32'b000011000001????????????????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fcmp = 1'd1;
            decode_info_o.fbranch_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fr1 = 1'd1;
        end
        // FSEL
        32'b000011010000????????????????????: begin
            decode_info_o.fpd_inst = 1'd1;
            decode_info_o.fsel = 1'd1;
            decode_info_o.fbranch_inst = 1'd1;
            decode_info_o.reg_type_r0 = `_REG_RJ;
            decode_info_o.reg_type_r1 = `_REG_RK;
            decode_info_o.reg_type_w = `_REG_W_RD;
            decode_info_o.fr0 = 1'd1;
            decode_info_o.fr1 = 1'd1;
            decode_info_o.fw = 1'd1;
        end
        */
        default: begin
            decode_info_o.decode_err = 1'b1; // 修改
            decode_info_o.alu_inst = 1'b1;
        end
    endcase
end

endmodule
