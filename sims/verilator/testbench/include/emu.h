#ifndef CHIPLAB_EMU_H
#define CHIPLAB_EMU_H

#include <verilated_save.h>
#include "cpu_tool.h"
#include "diff_manage.h"
#include "common.h"

class Emulator:CpuTool {
private:
    vluint64_t *main_time;
    int trapCode;

    /* init ram. The ram img will be mapped to NEMU. */
    void init_ram(const char*path, const char *file_in);

public:
    DiffManage* dm;

    /* input: ram img path */
    char img[128];
    /* output path */
    char simu_out_path[128];
    char uart_out_path[128];

    Emulator(Vtop *top, const char*path, const char* file_out, const char*uart_path, const char*file_in);
    ~Emulator();

    /* do init work such as init_difftest, init_nemuproxy */
    void init_emu(vluint64_t* main_time);

    /* difftest execute one step to compare dut and ref */
    int process();
};

#endif //CHIPLAB_EMU_H
