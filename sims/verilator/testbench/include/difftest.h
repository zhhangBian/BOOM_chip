#ifndef CHIPLAB_DIFFTEST_H
#define CHIPLAB_DIFFTEST_H

#include <stdint.h>
#include <verilated_save.h>
#include "common.h"
#include "nemuproxy.h"

#define DIFF_PROXY NemuProxy

/* max commit width */
#define DIFFTEST_COMMIT_WIDTH 6

/* commit inst history length */
#define DEBUG_INST_TRACE_SIZE 32
/* commit inst group history length */
#define DEBUG_GROUP_TRACE_SIZE 16

#ifdef RUN_FUNC
#define END_PC 0x1c000130
#elif defined RUN_C
#define END_PC 0x123
#elif defined RAND_TEST
#define END_PC 0x9c005000
#else
#define END_PC 0x123
#endif

enum {
    STATE_RUNNING = 0,
    STATE_END,
    STATE_TIME_LIMIT,
    STATE_ABORT
};

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
enum { REF_TO_DUT, DUT_TO_REF };
enum { REF_TO_DIFFTEST, DUT_TO_DIFFTEST };
enum { DIFF_TO_REF_GR = 0, DIFF_TO_REF_ALL};
enum { REF_TO_DIFF_GR = 0, REF_TO_DIFF_ALL};

enum retire_inst_type { RET_NORMAL = 0, RET_INT, RET_EXC };

typedef struct {
    uint8_t valid = 0;
    uint8_t code;
    uint32_t pc;
    uint64_t cycleCnt = 0;
    uint64_t instrCnt = 0;
} trap_event_t;

typedef struct {
    uint8_t excp_valid = 0;
    uint8_t eret       = 0;
    uint32_t interrupt = 0;
    uint32_t exception = 0;
    uint32_t exceptionPC = 0;
    uint32_t exceptionIst = 0;
} excp_event_t;

typedef struct {
    uint8_t valid = 0;
    uint32_t pc;
    uint32_t inst;
    uint8_t skip;
    uint8_t is_TLBFILL;
    uint8_t TLBFILL_index;
    uint8_t is_CNTinst;
    uint64_t timer_64_value;
    uint8_t wen;
    uint8_t wdest;
    uint32_t wdata;
    uint8_t csr_rstat;
    uint32_t csr_data;
} instr_commit_t;

typedef struct {
    uint32_t gpr[32];
} arch_greg_state_t;

typedef struct __attribute__((packed)) {
    uint32_t crmd;
    uint32_t prmd;
    uint32_t euen;
    uint32_t ecfg;
    uint32_t era, badv, eentry;
    uint32_t tlbidx, tlbehi, tlbelo0, tlbelo1;
    uint32_t asid, pgdl, pgdh;
    uint32_t save0, save1, save2, save3;
    uint32_t tid, tcfg, tval; // ticlr;
    uint32_t llbctl, tlbrentry, dmw0, dmw1;
    uint32_t estat;
    uint32_t this_pc;
} arch_csr_state_t;

typedef struct {
    uint8_t  valid = 0;
    uint64_t paddr;
    uint64_t vaddr;
    uint64_t data;
} store_event_t;

typedef struct {
    uint8_t valid = 0;
    uint64_t paddr;
    uint64_t vaddr;
} load_event_t;

typedef struct {
    trap_event_t trap;
    excp_event_t excp;
    instr_commit_t commit[DIFFTEST_COMMIT_WIDTH];
    arch_greg_state_t regs;
    arch_csr_state_t csr;
    store_event_t store[DIFFTEST_COMMIT_WIDTH];
    load_event_t load[DIFFTEST_COMMIT_WIDTH];
} difftest_core_state_t;

class DiffState {
public:
    void record_group(uint64_t pc, uint64_t count) {
        retire_group_pc_queue[retire_group_pointer] = pc;
        retire_group_cnt_queue[retire_group_pointer] = count;
        retire_group_pointer = (retire_group_pointer + 1) % DEBUG_GROUP_TRACE_SIZE;
    }

    void record_inst(uint64_t pc, uint32_t inst, uint8_t wen, uint8_t wdest, uint64_t wdata, bool skip) {
        retire_inst_pc_queue[retire_inst_pointer] = pc;
        retire_inst_inst_queue[retire_inst_pointer] = inst;
        retire_inst_wen_queue[retire_inst_pointer] = wen;
        retire_inst_wdst_queue[retire_inst_pointer] = wdest;
        retire_inst_wdata_queue[retire_inst_pointer] = wdata;
        retire_inst_skip_queue[retire_inst_pointer] = skip;
        retire_inst_type_queue[retire_inst_pointer] = RET_NORMAL;
        retire_inst_pointer = (retire_inst_pointer + 1) % DEBUG_INST_TRACE_SIZE;
    }

private:
    int retire_inst_pointer = 0;
    uint64_t retire_inst_pc_queue[DEBUG_INST_TRACE_SIZE] = {0};
    uint32_t retire_inst_inst_queue[DEBUG_INST_TRACE_SIZE] = {0};
    uint64_t retire_inst_wen_queue[DEBUG_INST_TRACE_SIZE] = {0};
    uint32_t retire_inst_wdst_queue[DEBUG_INST_TRACE_SIZE] = {0};
    uint64_t retire_inst_wdata_queue[DEBUG_INST_TRACE_SIZE] = {0};
    uint32_t retire_inst_type_queue[DEBUG_INST_TRACE_SIZE] = {0};
    bool retire_inst_skip_queue[DEBUG_INST_TRACE_SIZE] = {0};

    int retire_group_pointer = 0;
    uint64_t retire_group_pc_queue[DEBUG_GROUP_TRACE_SIZE] = {0};
    uint32_t retire_group_cnt_queue[DEBUG_GROUP_TRACE_SIZE] = {0};
};

class Difftest {
private:
    /* coreid is be used to distinguish multi-core */
    int coreid;

    /* dut/ref core info */
    difftest_core_state_t dut;
    difftest_core_state_t ref;
    uint32_t *dut_regs_ptr = (uint32_t *)&dut.regs;
    uint32_t *ref_regs_ptr = (uint32_t *)&ref.regs;

    DiffState *state = NULL;
    /* reference */
    DIFF_PROXY *proxy = NULL;

    /* the index of instructions per commit */
    uint32_t idx_commit = 0;

    /* indicate whether simulation is ended */
    bool sim_over = false;

    /* control whether to compare between duf and ref */
    bool progress = false;

    /* copy dut initialized state to ref when instruction is the first instruction */
    void do_first_instr_commit();

    /* nemu execute one instruction */
    void do_instr_commit(int index);

public:

    /* Trigger a difftest checking produre */
    int step(vluint64_t& main_time);

    /* Print dut core state info */
    void display();

    /* Difftest public APIs for dut: called from DPI-C functions (or testbench)
     * These functions generally do nothing but copy the information to core_state.
     */
    inline trap_event_t *get_trap_event() {
        return &(dut.trap);
    }
    inline excp_event_t *get_excp_event() {
        return &(dut.excp);
    }
    inline instr_commit_t *get_instr_commit(uint8_t index) {
        return &(dut.commit[index]);
    }
    inline arch_csr_state_t *get_csr_state() {
        return &(dut.csr);
    }
    inline arch_greg_state_t *get_greg_state() {
        return &(dut.regs);
    }

    inline store_event_t *get_store_event(uint8_t index) {
        return &(dut.store[index]);
    }
    inline load_event_t *get_load_event(uint8_t index) {
        return &(dut.load[index]);
    }

    inline bool get_trap_valid() const {
        return dut.trap.valid;
    }
    inline int get_trap_code() const {
        return dut.trap.code;
    }
    inline int get_proxy_check_end() const {
        return proxy->check_end();
    }

    Difftest(int coreid);
    ~Difftest();
};


#endif //CHIPLAB_DIFFTEST_H
