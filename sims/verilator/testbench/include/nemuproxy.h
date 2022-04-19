#ifndef CHIPLAB_NEMUPROXY_H
#define CHIPLAB_NEMUPROXY_H

#include <stdio.h>
#include <stdint.h>

struct la32_timer {
    // for stable_counter
    uint32_t counter_id;
    uint32_t stable_counter_l;
    uint32_t stable_counter_h;
    // for TVAL csr
    uint32_t time_val;
};

typedef uint64_t paddr_t;
typedef uint64_t vaddr_t;

class NemuProxy {
private:
    void* handle = NULL;
public:
    /* coreid is be used to distinguish multi-core */
    NemuProxy(int coreid);
    ~NemuProxy();

    void (*memcpy)(paddr_t nemu_addr, void* dut_buf, size_t n, bool direction);
    void (*regcpy)(void* dut, bool direction, bool do_csr);
    void (*csrcpy)(void* dut, bool direction);
    void (*uarchstatus_cpy)(void* dut, bool direction);
    int (*store_commit)(uint64_t saddr, uint64_t sdata);
    void (*exec)(uint64_t n);
    vaddr_t (*guided_exec)(void* disambiguate_para);
    void (*raise_intr)(uint64_t no);
    void (*isa_reg_display)();
    void (*tlbfill_index_set)(uint32_t index);
    void (*timercpy)(void* dut);
    void (*estat_sync)(uint32_t index, uint32_t mask);
    int  (*check_end)();
};

#define check_and_assert(func)                \
    do {                                      \
        if (!func) {                          \
            printf("ERROR: %s\n", dlerror()); \
            assert(func);                     \
        }                                     \
    } while (0);

#endif //CHIPLAB_NEMUPROXY_H
