/***************************************************************************************
* Copyright (c) 2020-2021 Institute of Computing Technology, Chinese Academy of Sciences
* Copyright (c) 2020-2021 Peng Cheng Laboratory
*
* XiangShan is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

`define DIFFTEST_DPIC_FUNC_NAME(name) \
  v_difftest_``name

`define DIFFTEST_DPIC_FUNC_DECL(name) \
  import "DPI-C" function void `DIFFTEST_DPIC_FUNC_NAME(name)

`define DIFFTEST_MOD_NAME(name)    \
  Difftest``name

`define DIFFTEST_MOD_DECL(name)    \
  module `DIFFTEST_MOD_NAME(name)

`define DIFFTEST_MOD_DPIC_CALL_BEGIN(name) \
  always @(posedge clock) begin            \
    `DIFFTEST_DPIC_FUNC_NAME(name)

`define DIFFTEST_MOD_DPIC_CALL_BEGIN_WITH_EN(enable, name) \
  always @(posedge clock) begin                            \
    if (enable) begin                                      \
      `DIFFTEST_DPIC_FUNC_NAME(name)

`define DIFFTEST_MOD_DPIC_CALL_END(name) \
  ; end

`define DIFFTEST_MOD_DPIC_CALL_END_WITH_EN(name) \
  ; end end

`define DPIC_ARG_BIT  input bit
`define DPIC_ARG_BYTE input byte
`define DPIC_ARG_INT  input int
`define DPIC_ARG_LONG input longint

// DifftestInstrCommit
`DIFFTEST_DPIC_FUNC_DECL(InstrCommit) (
    `DPIC_ARG_BYTE coreid,
    `DPIC_ARG_BYTE index,
    `DPIC_ARG_BIT  valid,
    `DPIC_ARG_LONG pc,
    `DPIC_ARG_INT  instr,
    `DPIC_ARG_BIT  skip,
    `DPIC_ARG_BIT  is_TLBFILL,
    `DPIC_ARG_BYTE TLBFILL_index,
    `DPIC_ARG_BIT  is_CNTinst,
    `DPIC_ARG_LONG timer_64_value,
    `DPIC_ARG_BIT  wen,
    `DPIC_ARG_BYTE wdest,
    `DPIC_ARG_LONG wdata,
    `DPIC_ARG_BIT  csr_rstat,
    `DPIC_ARG_INT  csr_data
);
`DIFFTEST_MOD_DECL(InstrCommit)(
    input        clock,
    input [ 7:0] coreid,
    input [ 7:0] index,
    input        valid,
    input [63:0] pc,
    input [31:0] instr,
    input        skip,
    input        is_TLBFILL,
    input [ 4:0] TLBFILL_index,
    input        is_CNTinst,
    input [63:0] timer_64_value,
    input        wen,
    input [ 7:0] wdest,
    input [63:0] wdata,
    input        csr_rstat,
    input [31:0] csr_data
);
    `DIFFTEST_MOD_DPIC_CALL_BEGIN_WITH_EN(valid, InstrCommit) (
        coreid, index,
        valid, pc, instr, skip, is_TLBFILL, TLBFILL_index, is_CNTinst, timer_64_value, wen, wdest, wdata, csr_rstat, csr_data
        ) `DIFFTEST_MOD_DPIC_CALL_END_WITH_EN(InstrCommit)
endmodule

// DifftestExcpEvent
`DIFFTEST_DPIC_FUNC_DECL(ExcpEvent) (
    `DPIC_ARG_BYTE coreid,
    `DPIC_ARG_BYTE excp_valid,
    `DPIC_ARG_BIT  eret,
    `DPIC_ARG_INT  intrNo,
    `DPIC_ARG_INT  cause,
    `DPIC_ARG_LONG exceptionPC,
    `DPIC_ARG_INT exceptionInst
);
`DIFFTEST_MOD_DECL(ExcpEvent) (
    input        clock,
    input [ 7:0] coreid,
    input        excp_valid,
    input        eret,
    input [31:0] intrNo,
    input [31:0] cause,
    input [63:0] exceptionPC,
    input [31:0] exceptionInst
);
    `DIFFTEST_MOD_DPIC_CALL_BEGIN(ExcpEvent) (
        coreid, excp_valid, eret, intrNo, cause, exceptionPC, exceptionInst
        ) `DIFFTEST_MOD_DPIC_CALL_END(ExcpEvent)
endmodule

// DifftesTrapEvent
`DIFFTEST_DPIC_FUNC_DECL(TrapEvent) (
    `DPIC_ARG_BYTE coreid,
    `DPIC_ARG_BIT  valid,
    `DPIC_ARG_BYTE code,
    `DPIC_ARG_LONG pc,
    `DPIC_ARG_LONG cycleCnt,
    `DPIC_ARG_LONG instrCnt
);
`DIFFTEST_MOD_DECL(TrapEvent)(
    input        clock,
    input [ 7:0] coreid,
    input        valid,
    input [ 2:0] code,
    input [63:0] pc,
    input [63:0] cycleCnt,
    input [63:0] instrCnt
);
    `DIFFTEST_MOD_DPIC_CALL_BEGIN(TrapEvent) (
        coreid, valid, {5'd0, code}, pc, cycleCnt, instrCnt
        ) `DIFFTEST_MOD_DPIC_CALL_END(TrapEvent)
endmodule

// DifftestStoreEvent
`DIFFTEST_DPIC_FUNC_DECL(StoreEvent) (
    `DPIC_ARG_BYTE coreid,
    `DPIC_ARG_BYTE index,
    `DPIC_ARG_BYTE valid,
    `DPIC_ARG_LONG storePAddr,
    `DPIC_ARG_LONG storeVAddr,
    `DPIC_ARG_LONG storeData
);
`DIFFTEST_MOD_DECL(StoreEvent)(
    input        clock,
    input [ 7:0] coreid,
    input [ 7:0] index,
    input [ 7:0] valid,
    input [63:0] storePAddr,
    input [63:0] storeVAddr,
    input [63:0] storeData
);
    `DIFFTEST_MOD_DPIC_CALL_BEGIN(StoreEvent) (
        coreid, index, valid, storePAddr, storeVAddr, storeData
        )
    `DIFFTEST_MOD_DPIC_CALL_END(StoreEvent)
endmodule

// DifftestLoadEvent
`DIFFTEST_DPIC_FUNC_DECL(LoadEvent) (
    `DPIC_ARG_BYTE coreid,
    `DPIC_ARG_BYTE index,
    `DPIC_ARG_BYTE valid,
    `DPIC_ARG_LONG paddr,
    `DPIC_ARG_LONG vaddr
);
`DIFFTEST_MOD_DECL(LoadEvent)(
    input        clock,
    input [ 7:0] coreid,
    input [ 7:0] index,
    input [ 7:0] valid,
    input [63:0] paddr,
    input [63:0] vaddr
);
    `DIFFTEST_MOD_DPIC_CALL_BEGIN(LoadEvent) (
        coreid, index, valid, paddr, vaddr
        ) `DIFFTEST_MOD_DPIC_CALL_END(LoadEvent)
endmodule

// DifftestCSRRegState
`DIFFTEST_DPIC_FUNC_DECL(CSRRegState) (
    `DPIC_ARG_BYTE coreid,
    `DPIC_ARG_LONG crmd,
    `DPIC_ARG_LONG prmd,
    `DPIC_ARG_LONG euen,
    `DPIC_ARG_LONG ecfg,
    `DPIC_ARG_LONG estat,
    `DPIC_ARG_LONG era,
    `DPIC_ARG_LONG badv,
    `DPIC_ARG_LONG eentry,
    `DPIC_ARG_LONG tlbidx,
    `DPIC_ARG_LONG tlbehi,
    `DPIC_ARG_LONG tlbelo0,
    `DPIC_ARG_LONG tlbelo1,
    `DPIC_ARG_LONG asid,
    `DPIC_ARG_LONG pgdl,
    `DPIC_ARG_LONG pgdh,
    `DPIC_ARG_LONG save0,
    `DPIC_ARG_LONG save1,
    `DPIC_ARG_LONG save2,
    `DPIC_ARG_LONG save3,
    `DPIC_ARG_LONG tid,
    `DPIC_ARG_LONG tcfg,
    `DPIC_ARG_LONG tval,
    `DPIC_ARG_LONG ticlr,
    `DPIC_ARG_LONG llbctl,
    `DPIC_ARG_LONG tlbrentry,
    `DPIC_ARG_LONG dmw0,
    `DPIC_ARG_LONG dmw1
);
`DIFFTEST_MOD_DECL(CSRRegState)(
    input        clock,
    input [ 7:0] coreid,
    input [63:0] crmd,
    input [63:0] prmd,
    input [63:0] euen,
    input [63:0] ecfg,
    input [63:0] estat,
    input [63:0] era,
    input [63:0] badv,
    input [63:0] eentry,
    input [63:0] tlbidx,
    input [63:0] tlbehi,
    input [63:0] tlbelo0,
    input [63:0] tlbelo1,
    input [63:0] asid,
    input [63:0] pgdl,
    input [63:0] pgdh,
    input [63:0] save0,
    input [63:0] save1,
    input [63:0] save2,
    input [63:0] save3,
    input [63:0] tid,
    input [63:0] tcfg,
    input [63:0] tval,
    input [63:0] ticlr,
    input [63:0] llbctl,
    input [63:0] tlbrentry,
    input [63:0] dmw0,
    input [63:0] dmw1
);
    `DIFFTEST_MOD_DPIC_CALL_BEGIN(CSRRegState) (
        coreid, crmd, prmd, euen, ecfg, estat, era, badv, eentry,
        tlbidx, tlbehi, tlbelo0, tlbelo1, asid, pgdl, pgdh, save0,
        save1, save2, save3, tid, tcfg, tval, ticlr, llbctl, tlbrentry,
        dmw0, dmw1
        ) `DIFFTEST_MOD_DPIC_CALL_END(CSRRegState)
endmodule

// DifftestGRegState
`DIFFTEST_DPIC_FUNC_DECL(GRegState) (
    `DPIC_ARG_BYTE coreid,
    `DPIC_ARG_LONG gpr_0,
    `DPIC_ARG_LONG gpr_1,
    `DPIC_ARG_LONG gpr_2,
    `DPIC_ARG_LONG gpr_3,
    `DPIC_ARG_LONG gpr_4,
    `DPIC_ARG_LONG gpr_5,
    `DPIC_ARG_LONG gpr_6,
    `DPIC_ARG_LONG gpr_7,
    `DPIC_ARG_LONG gpr_8,
    `DPIC_ARG_LONG gpr_9,
    `DPIC_ARG_LONG gpr_10,
    `DPIC_ARG_LONG gpr_11,
    `DPIC_ARG_LONG gpr_12,
    `DPIC_ARG_LONG gpr_13,
    `DPIC_ARG_LONG gpr_14,
    `DPIC_ARG_LONG gpr_15,
    `DPIC_ARG_LONG gpr_16,
    `DPIC_ARG_LONG gpr_17,
    `DPIC_ARG_LONG gpr_18,
    `DPIC_ARG_LONG gpr_19,
    `DPIC_ARG_LONG gpr_20,
    `DPIC_ARG_LONG gpr_21,
    `DPIC_ARG_LONG gpr_22,
    `DPIC_ARG_LONG gpr_23,
    `DPIC_ARG_LONG gpr_24,
    `DPIC_ARG_LONG gpr_25,
    `DPIC_ARG_LONG gpr_26,
    `DPIC_ARG_LONG gpr_27,
    `DPIC_ARG_LONG gpr_28,
    `DPIC_ARG_LONG gpr_29,
    `DPIC_ARG_LONG gpr_30,
    `DPIC_ARG_LONG gpr_31
);
`DIFFTEST_MOD_DECL(GRegState)(
    input         clock,
    input [ 7:0]  coreid,
    input [63:0]  gpr_0,
    input [63:0]  gpr_1,
    input [63:0]  gpr_2,
    input [63:0]  gpr_3,
    input [63:0]  gpr_4,
    input [63:0]  gpr_5,
    input [63:0]  gpr_6,
    input [63:0]  gpr_7,
    input [63:0]  gpr_8,
    input [63:0]  gpr_9,
    input [63:0]  gpr_10,
    input [63:0]  gpr_11,
    input [63:0]  gpr_12,
    input [63:0]  gpr_13,
    input [63:0]  gpr_14,
    input [63:0]  gpr_15,
    input [63:0]  gpr_16,
    input [63:0]  gpr_17,
    input [63:0]  gpr_18,
    input [63:0]  gpr_19,
    input [63:0]  gpr_20,
    input [63:0]  gpr_21,
    input [63:0]  gpr_22,
    input [63:0]  gpr_23,
    input [63:0]  gpr_24,
    input [63:0]  gpr_25,
    input [63:0]  gpr_26,
    input [63:0]  gpr_27,
    input [63:0]  gpr_28,
    input [63:0]  gpr_29,
    input [63:0]  gpr_30,
    input [63:0]  gpr_31
);
    `DIFFTEST_MOD_DPIC_CALL_BEGIN(GRegState) (
        coreid,
        gpr_0,  gpr_1,  gpr_2,  gpr_3,  gpr_4,  gpr_5,  gpr_6,  gpr_7,
        gpr_8,  gpr_9,  gpr_10, gpr_11, gpr_12, gpr_13, gpr_14, gpr_15,
        gpr_16, gpr_17, gpr_18, gpr_19, gpr_20, gpr_21, gpr_22, gpr_23,
        gpr_24, gpr_25, gpr_26, gpr_27, gpr_28, gpr_29, gpr_30, gpr_31
        ) `DIFFTEST_MOD_DPIC_CALL_END(GRegState)
endmodule
