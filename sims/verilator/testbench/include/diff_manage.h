#ifndef CHIPLAB_DIFF_MANAGE_H
#define CHIPLAB_DIFF_MANAGE_H

#include <verilated_save.h>
#include "difftest.h"

class DiffManage {
public:
    int init_difftest();

    int difftest_state();
    int do_step(vluint64_t& main_time);
    int check_end();

    ~DiffManage();
};

#endif //CHIPLAB_DIFF_MANAGE_H
