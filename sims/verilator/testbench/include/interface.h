#ifndef CHIPLAB_INTERFACE_H
#define CHIPLAB_INTERFACE_H

#include "difftest.h"
#include "stdint.h"

/**
 * Headers for Verilog DPI-C difftest interface
 * These hearders are called to copy signals of dut
 */
#define DIFFTEST_DPIC_FUNC_NAME(name) \
    v_difftest_##name

#define DIFFTEST_DPIC_FUNC_DECL(name) \
    extern "C" void DIFFTEST_DPIC_FUNC_NAME(name)

#define DPIC_ARG_BIT  uint8_t
#define DPIC_ARG_BYTE char
#define DPIC_ARG_INT  int
#define DPIC_ARG_LONG long long

// v_difftest_InstrCommit
#define INTERFACE_INSTR_COMMIT           \
  DIFFTEST_DPIC_FUNC_DECL(InstrCommit) ( \
    DPIC_ARG_BYTE coreid,                \
    DPIC_ARG_BYTE index,                 \
    DPIC_ARG_BIT  valid,                 \
    DPIC_ARG_LONG pc,                    \
    DPIC_ARG_INT  instr,                 \
    DPIC_ARG_BIT  skip,                  \
    DPIC_ARG_BIT  is_TLBFILL,            \
    DPIC_ARG_BYTE TLBFILL_index,         \
    DPIC_ARG_BIT  is_CNTinst,            \
    DPIC_ARG_LONG timer_64_value,        \
    DPIC_ARG_BIT  wen,                   \
    DPIC_ARG_BYTE wdest,                 \
    DPIC_ARG_LONG wdata,                 \
    DPIC_ARG_BIT  csr_rstat,             \
    DPIC_ARG_INT  csr_data               \
  )

// v_difftest_ExcpEvent
#define INTERFACE_EXCP_EVENT             \
  DIFFTEST_DPIC_FUNC_DECL(ExcpEvent) (   \
    DPIC_ARG_BYTE coreid,                \
    DPIC_ARG_BYTE excp_valid,            \
    DPIC_ARG_BIT  eret,                  \
    DPIC_ARG_INT  intrNo,                \
    DPIC_ARG_INT  cause,                 \
    DPIC_ARG_LONG exceptionPC,           \
    DPIC_ARG_INT  exceptionInst          \
  )

// v_difftest_TrapEvent
#define INTERFACE_TRAP_EVENT             \
  DIFFTEST_DPIC_FUNC_DECL(TrapEvent) (   \
    DPIC_ARG_BYTE coreid,                \
    DPIC_ARG_BIT  valid,                 \
    DPIC_ARG_BYTE code,                  \
    DPIC_ARG_LONG pc,                    \
    DPIC_ARG_LONG cycleCnt,              \
    DPIC_ARG_LONG instrCnt               \
  )

// v_difftest_StoreEvent
#define INTERFACE_STORE_EVENT            \
  DIFFTEST_DPIC_FUNC_DECL(StoreEvent) (  \
    DPIC_ARG_BYTE coreid,                \
    DPIC_ARG_BYTE index,                 \
    DPIC_ARG_BYTE valid,                 \
    DPIC_ARG_LONG storePAddr,            \
    DPIC_ARG_LONG storeVAddr,            \
    DPIC_ARG_LONG storeData              \
  )

// v_difftest_LoadEvent
#define INTERFACE_LOAD_EVENT             \
  DIFFTEST_DPIC_FUNC_DECL(LoadEvent) (   \
    DPIC_ARG_BYTE coreid,                \
    DPIC_ARG_BYTE index,                 \
    DPIC_ARG_BYTE valid,                 \
    DPIC_ARG_LONG paddr,                 \
    DPIC_ARG_LONG vaddr                  \
  )

// v_difftest_CSRState
#define INTERFACE_CSRREG_STATE           \
  DIFFTEST_DPIC_FUNC_DECL(CSRRegState) ( \
    DPIC_ARG_BYTE coreid,               \
    DPIC_ARG_LONG crmd,                 \
    DPIC_ARG_LONG prmd,                 \
    DPIC_ARG_LONG euen,                 \
    DPIC_ARG_LONG ecfg,                 \
    DPIC_ARG_LONG estat,                \
    DPIC_ARG_LONG era,                  \
    DPIC_ARG_LONG badv,                 \
    DPIC_ARG_LONG eentry,               \
    DPIC_ARG_LONG tlbidx,               \
    DPIC_ARG_LONG tlbehi,               \
    DPIC_ARG_LONG tlbelo0,              \
    DPIC_ARG_LONG tlbelo1,              \
    DPIC_ARG_LONG asid,                 \
    DPIC_ARG_LONG pgdl,                 \
    DPIC_ARG_LONG pgdh,                 \
    DPIC_ARG_LONG save0,                \
    DPIC_ARG_LONG save1,                \
    DPIC_ARG_LONG save2,                \
    DPIC_ARG_LONG save3,                \
    DPIC_ARG_LONG tid,                  \
    DPIC_ARG_LONG tcfg,                 \
    DPIC_ARG_LONG tval,                 \
    DPIC_ARG_LONG ticlr,                \
    DPIC_ARG_LONG llbctl,               \
    DPIC_ARG_LONG tlbrentry,            \
    DPIC_ARG_LONG dmw0,                 \
    DPIC_ARG_LONG dmw1                  \
  )

// v_difftest_GRegState
#define INTERFACE_GREG_STATE \
    DIFFTEST_DPIC_FUNC_DECL(GRegState) (     \
        DPIC_ARG_BYTE coreid,                \
        DPIC_ARG_LONG gpr_0,                 \
        DPIC_ARG_LONG gpr_1,                 \
        DPIC_ARG_LONG gpr_2,                 \
        DPIC_ARG_LONG gpr_3,                 \
        DPIC_ARG_LONG gpr_4,                 \
        DPIC_ARG_LONG gpr_5,                 \
        DPIC_ARG_LONG gpr_6,                 \
        DPIC_ARG_LONG gpr_7,                 \
        DPIC_ARG_LONG gpr_8,                 \
        DPIC_ARG_LONG gpr_9,                 \
        DPIC_ARG_LONG gpr_10,                \
        DPIC_ARG_LONG gpr_11,                \
        DPIC_ARG_LONG gpr_12,                \
        DPIC_ARG_LONG gpr_13,                \
        DPIC_ARG_LONG gpr_14,                \
        DPIC_ARG_LONG gpr_15,                \
        DPIC_ARG_LONG gpr_16,                \
        DPIC_ARG_LONG gpr_17,                \
        DPIC_ARG_LONG gpr_18,                \
        DPIC_ARG_LONG gpr_19,                \
        DPIC_ARG_LONG gpr_20,                \
        DPIC_ARG_LONG gpr_21,                \
        DPIC_ARG_LONG gpr_22,                \
        DPIC_ARG_LONG gpr_23,                \
        DPIC_ARG_LONG gpr_24,                \
        DPIC_ARG_LONG gpr_25,                \
        DPIC_ARG_LONG gpr_26,                \
        DPIC_ARG_LONG gpr_27,                \
        DPIC_ARG_LONG gpr_28,                \
        DPIC_ARG_LONG gpr_29,                \
        DPIC_ARG_LONG gpr_30,                \
        DPIC_ARG_LONG gpr_31                 \
    )

INTERFACE_INSTR_COMMIT;
INTERFACE_EXCP_EVENT;
INTERFACE_TRAP_EVENT;
INTERFACE_STORE_EVENT;
INTERFACE_LOAD_EVENT;
INTERFACE_CSRREG_STATE;
INTERFACE_GREG_STATE;

#endif //CHIPLAB_INTERFACE_H
