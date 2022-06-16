#include <sys/mman.h>
#include "difftest.h"

extern FILE* trace_out;
extern FILE* uart_out;

// not compare estat
static const int DIFFTEST_NR_GREG = sizeof(arch_greg_state_t) / sizeof(uint32_t);
static const int DIFFTEST_NR_CSRREG = sizeof(arch_csr_state_t) / sizeof(uint32_t);
static const int DIFFTEST_NR_REG = DIFFTEST_NR_GREG + DIFFTEST_NR_CSRREG;

static const char* reg_name[DIFFTEST_NR_REG] = {
        "r0",      "ra",     "tp",      "sp",      "a0",      "a1",     "a2",        "a3",        "a4",      "a5",
        "a6",      "a7",     "t0",      "t1",      "t2",      "t3",     "t4",        "t5",        "t6",      "t7",
        "t8",      " x",     "fp",      "s0",      "s1",      "s2",     "s3",        "s4",        "s5",      "s6",
        "s7",      "s8",
        "crmd",    "prmd",   "euen",    "ecfg",    "era",     "badv",   "eentry",    "tlbidx",    "tlbehi",  "tlbelo0",
        "tlbelo1", "asid",   "pgdl",    "pgdh",    "save0",   "save1",  "save2",     "save3",     "tid",     "tcfg",
        "tval",    "llbctl", "tlbrentry", "dmw0",  "dmw1",    "estat",   "this_pc"
};

static const char compare_mask[DIFFTEST_NR_CSRREG] = {
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
    1,  1,  1,  1,  1,  0,  1
};

#ifdef RAND_TEST
/* used only do rand test. compare only when flag is true */
static bool diff_flag = false;
#endif

static uint32_t estat_last;
static uint32_t estat_flag;
static uint32_t estat_mask;
static uint32_t estat_new;

static int dead_clock = 0;
extern long long inst_total;

int Difftest::step(vluint64_t &main_time) {
    progress = false;
    idx_commit = 0;
    int index = 0;

    if (!dut.excp.excp_valid) {
        while (idx_commit < DIFFTEST_COMMIT_WIDTH && dut.commit[idx_commit].valid) {
            inst_total += 1;
#ifndef TRACE_COMP
            dut.commit[idx_commit].valid = 0;
#endif
            if (dut.commit[idx_commit].wen) {
                dead_clock = 0;
#ifdef OUTPUT_PC_INFO
#ifdef PRINT_CLK_TIME
                printf("[%010dns] mycpu : pc = %08x,  reg = %02d, val = %08x\n", main_time, dut.commit[idx_commit].pc, dut.commit[idx_commit].wdest, dut.commit[idx_commit].wdata);
#else
                printf("mycpu : pc = %08x,  reg = %02d, val = %08x\n", dut.commit[idx_commit].pc, dut.commit[idx_commit].wdest, dut.commit[idx_commit].wdata);
#endif
#endif

#ifdef SIMU_TRACE
#ifdef PRINT_CLK_TIME
                fprintf(trace_out, "[%010dns] mycpu : pc = %08x,  reg = %02d, val = %08x\n", main_time, dut.commit[idx_commit].pc, dut.commit[idx_commit].wdest, dut.commit[idx_commit].wdata);
#else
                fprintf(trace_out, "mycpu : pc = %08x,  reg = %02d, val = %08x\n", dut.commit[idx_commit].pc, dut.commit[idx_commit].wdest, dut.commit[idx_commit].wdata);
#endif
                fflush(NULL);
#endif
            }
            idx_commit++;
        }
        if (idx_commit) idx_commit--;
    }

#ifdef DEAD_CLOCK_EN
    dead_clock++;
    if (dead_clock > DEAD_CLOCK_SIZE) {
        printf("CPU status no change for %d clocks, simulation must exist error!!!!\n", DEAD_CLOCK_SIZE);
        return STATE_TIME_LIMIT;
    }
#endif

#ifndef TRACE_COMP
    if (dut.commit[idx_commit].pc == END_PC || dut.excp.exceptionPC == END_PC) {
        sim_over = true;
    }
    if (sim_over) {
        printf("==============================================================\n");
        printf("test end!!\n");
        fprintf(trace_out, "==============================================================\n");
        fprintf(trace_out, "test end!!\n");
        return STATE_END;
    }
    return STATE_RUNNING;
#else
    /* pull down estat bit-by-bit */
    estat_flag = 0x00000004;
    estat_new = dut.csr.estat & 0x00001ffc;
    estat_mask = estat_new ^ estat_last;
    if (estat_mask) {
        for (int i = 0; i < 11; i++) {
            if ((estat_mask & estat_flag) && (estat_last & estat_flag)) {
                proxy->estat_sync(dut.csr.estat, estat_flag);
            }
            estat_flag = estat_flag << 1;
        }
    }
    estat_last = dut.csr.estat;

    dut.csr.this_pc = dut.commit[idx_commit].pc;

    /* exec the first instruction */
    do_first_instr_commit();

    /* sync estat to nemu */
    for (index = 0; index <= idx_commit; index++) {
        if (dut.commit[index].valid && dut.commit[index].csr_rstat) {
            proxy->estat_sync(dut.commit[index].csr_data, 0xffffffff);
        }
    }

    /* handle exception */
    if (dut.excp.excp_valid) {
        if (dut.excp.exception != 0) {     // not hard interrupt, nemu can detect itself
//            printf("receive exception 0x%x at pc 0x%x\n", dut.excp.exception, dut.excp.exceptionPC);
            proxy->exec(1);
        } else {    // hard interrupt, dut copy intr code to nemu
//            printf("excp pc : 0x%x\n", dut.excp.exceptionPC);
//            printf("cpu pc : 0x%x\n", dut.csr.this_pc);
//            printf("interrupt : 0x%x\n", dut.excp.interrupt);
            if (dut.excp.interrupt != 0) {
                proxy->raise_intr(dut.excp.interrupt);
            }
        }
    } else {    // nemu exec instruction
        for (index = 0; index <= idx_commit; index++) {
            if (index < DIFFTEST_COMMIT_WIDTH && dut.commit[index].valid) {
                do_instr_commit(index);
                dut.commit[index].valid = 0;
            }
        }
    }

#ifdef RAND_TEST
    if (!diff_flag) {
        if (dut.excp.eret) {
            diff_flag = true;
        }
        proxy->regcpy(dut_regs_ptr, DIFFTEST_TO_REF, DIFF_TO_REF_ALL);
        return STATE_RUNNING;
    }
#endif

    /* check simulation end */
    if (dut.commit[idx_commit].pc == END_PC || dut.excp.exceptionPC == END_PC) {
        sim_over = true;
    }
    if (sim_over) {
        printf("==============================================================\n");
        printf("test end!!\n");
        fprintf(trace_out, "==============================================================\n");
        fprintf(trace_out, "test end!!\n");
        return STATE_END;
    }

    /* Set 0 when not compare */
    if (!progress) {
        return STATE_RUNNING;
    }

    /* store difftest. valid = {4'b0, sc(llbit=1), stw, sth, stb} */
    for (index = 0; index <= idx_commit; index++) {
        if (dut.store[index].valid) {
            if (proxy->store_commit(dut.store[index].paddr, dut.store[index].data)) {
                printf("dut different at pc = 0x%08x, paddr = 0x%lx, vaddr = 0x%lx, data = 0x%lx\n", dut.commit[index].pc, dut.store[index].paddr, dut.store[index].vaddr, dut.store[index].data);
                fflush(NULL);
                display();
                return STATE_ABORT;
            }
        }
    }

    /* load address of peripherals */
    for (index = 0; index <= idx_commit; index++) {
        if (dut.load[index].valid && (dut.load[index].paddr & 0x00000000f8000000)) {
            proxy->regcpy(dut_regs_ptr, DIFFTEST_TO_REF, DIFF_TO_REF_GR);
        }
    }

    /* copy nemu result to ref_regs_ptr */
    proxy->regcpy(ref_regs_ptr, REF_TO_DUT, REF_TO_DIFF_ALL);
    if (idx_commit > 0) {
        state->record_group(dut.commit[0].pc, idx_commit);
    }

    ref.csr.tval = dut.csr.tval;
    for(int i = 0; i < DIFFTEST_NR_CSRREG; i++) {
        if (!compare_mask[i])
            dut_regs_ptr[DIFFTEST_NR_GREG + i] = ref_regs_ptr[DIFFTEST_NR_GREG + i] = 0;
    }

    /* compare */
    if (memcmp(dut_regs_ptr, ref_regs_ptr, DIFFTEST_NR_REG * sizeof(uint32_t))) {   // trace error print
        display();
        for (int i = 0; i < DIFFTEST_NR_REG; i ++) {
            if (dut_regs_ptr[i] != ref_regs_ptr[i]) {
                printf("i = %d\n", i);
                printf("%7s different at pc = 0x%010x, right= 0x%016x, wrong = 0x%016x\n",
                       reg_name[i], ref.csr.this_pc, ref_regs_ptr[i], dut_regs_ptr[i]);
            }
        }
        return STATE_ABORT;
    } else {
        return STATE_RUNNING;
    }
#endif
}

extern void *get_img_start();
void Difftest::do_first_instr_commit() {
    if (dut.commit[0].valid && dut.commit[0].pc == FIRST_INST_ADDRESS) {
        printf("The first instruction of core %d has commited. Difftest enabled.\n", coreid);

        proxy->memcpy(0x0, get_img_start(), EMU_RAM_SIZE, DIFFTEST_TO_REF);
        munmap(get_img_start(), EMU_RAM_SIZE);
        proxy->regcpy(dut_regs_ptr, DIFFTEST_TO_REF, DIFF_TO_REF_ALL);
    }
}

void Difftest::do_instr_commit(int i) {
    progress = true;

    /* store the writeback info to debug array */
    state->record_inst(dut.commit[i].pc, dut.commit[i].inst, dut.commit[i].wen, dut.commit[i].wdest, dut.commit[i].wdata, dut.commit[i].skip != 0);

    /* tlbfill */
    if (dut.commit[i].is_TLBFILL) {
        // printf("get a tlbfill inst from dut, give nemu an index: %d\n",dut.commit[i].TLBFILL_index);
        proxy->tlbfill_index_set(dut.commit[i].TLBFILL_index);
    }

    /* rdcntv{L/H}.w */
    if (dut.commit[i].is_CNTinst) {
        // printf("rdcntv / rdcntid indt from dut, copy result to nemu: %d\n",dut.commit[i].wdata);
        uint32_t timer_low, timer_high;
        timer_low = (uint32_t)((dut.commit[i].timer_64_value) & 0x00000000ffffffff);
        timer_high = (uint32_t)(((dut.commit[i].timer_64_value) & 0xffffffff00000000)>>32);
        struct la32_timer timer;
        timer.counter_id = dut.csr.tid;
        timer.stable_counter_l = timer_low;
        timer.stable_counter_h = timer_high;
        timer.time_val = dut.csr.tval;
        // printf("timer64: 0x%lx, low: 0x%x, high: 0x%x\n",dut.commit[i].timer_64_value,timer_low,timer_high);
        proxy->timercpy(&timer);
    }

    /* single step exec */
    proxy->exec(1);

    /* TODO: handle load instruction carefully for SMP */
    if (NUM_CORES > 1) {

    }
}

void Difftest::display() {
    printf("\n==============  DUT Regs  ==============\n");
    for (int i = 0; i < 32; i ++) {
        printf("%s(r%2d): 0x%08x ", reg_name[i], i, dut_regs_ptr[i]);
        if (i % 4 == 3) printf("\n");
    }
    printf("pc: 0x%08x\n", dut.csr.this_pc);
    printf("CRMD: 0x%08x,    PRMD: 0x%08x,   EUEN: 0x%08x\n", dut.csr.crmd, dut.csr.prmd, dut.csr.euen);
    printf("ECFG: 0x%08x,   ESTAT: 0x%08x,    ERA: 0x%08x\n", dut.csr.ecfg, dut.csr.estat, dut.csr.era);
    printf("BADV: 0x%08x,  EENTRY: 0x%08x, LLBCTL: 0x%08x\n", dut.csr.badv, dut.csr.eentry, dut.csr.llbctl);
    printf("cpu.ll_bit: %d\n", dut.csr.llbctl & 0x1);
    printf("INDEX: 0x%08x, TLBEHI: 0x%08x, TLBELO0: 0x%08x, TLBELO1: 0x%08x\n", dut.csr.tlbidx, dut.csr.tlbehi, dut.csr.tlbelo0, dut.csr.tlbelo1);
    printf("ASID: 0x%08x, TLBRENTRY: 0x%08x, DMW0: 0x%08x, DMW1: 0x%08x\n", dut.csr.asid, dut.csr.tlbrentry, dut.csr.dmw0, dut.csr.dmw1);
    printf("*******************************************************************************\n");
    fflush(stdout);

    printf("\n==============  REF Regs  ==============\n");
    proxy->isa_reg_display();
    fflush(stdout);
}

Difftest::Difftest(int coreid): coreid(coreid) {
    proxy = new DIFF_PROXY(coreid);
    state = new DiffState();
}

Difftest::~Difftest() {
    delete proxy;
    proxy = NULL;
    delete state;
    state = NULL;
}
