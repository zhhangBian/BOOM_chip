#ifndef CHIPLAB_EMU_H
#define CHIPLAB_EMU_H

#include <verilated_save.h>
#include "cpu_tool.h"
#include "diff_manage.h"
#include "common.h"

#define CONFREG_UART_DATA       top->confreg_uart_data
#define CONFREG_UART_DISPLAY    top->write_uart_valid

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

    Emulator(Vtop *top, const char*path, const char* file_out, const char*uart_path, const char*file_in, const char*data_vlog);
    ~Emulator();

    /* do init work such as init_difftest, init_nemuproxy */
    void init_emu(vluint64_t* main_time);
    void init_random_vlog(const char *path, const char *file_in);

    /* difftest execute one step to compare dut and ref */
    int process();

    /* used by slice */
    void close();
};

#endif //CHIPLAB_EMU_H
