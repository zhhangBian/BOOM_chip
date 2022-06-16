#ifndef CHIPLAB_CPU_TOOL_H
#define CHIPLAB_CPU_TOOL_H

#include "common.h"

class CpuTool {
public:
    Vtop* top;
    static const int status_cause        = 0xff;
    static const int status_trace_err    = 0x700;
    static const int status_trace_err_rf = 0x100;
    static const int status_trace_err_pc = 0x200;
    static const int status_perf_err     = 0x400;

    static const int status_exit         = 0x1f000;
    static const int status_call_finish  = 0x1000;
    static const int status_uart_exit    = 0x2000;
    static const int status_test_end     = 0x4000;
    static const int status_time_limit   = 0x8000;
    static const int status_test_wait    = 0x10000;

    static const int status_unhandled = 0x60000;
    static const int status_unhandled_ex_code = 0x20000;
    static const int status_unhandled_syscall = 0x40000;

    static int simu_quiet;
    static int simu_user;
    static int simu_dev;
    static int simu_wait;
    static int simu_bus_delay;
    static int simu_bus_delay_random_seed;

    static int save_bp_time;
    static int restore_bp_time;
    const static char* ram_save_bp_file;
    const static char* top_save_bp_file;
    const static char* ram_restore_bp_file;
    const static char* top_restore_bp_file;

    static unsigned int end_pc;

    static int time_limit;
    static int time_check;

    static int dump_pc_trace;
    static int dump_rf_trace;
    static int rf_trace_no_repeat;
    static int comp_pc_trace;
    static int comp_rf_trace;
    static int64_t dump_delay;
    static int dump_waveform;
    const static char* ram_file;
    const static char* data_vlog_file;
    const static char* rand_path;
    const static char* result_flag_path;
    const static char* pc_trace_ifile;
    const static char* pc_trace_ofile;
    const static char* rf_trace_ifile;
    const static char* rf_trace_ofile;
    const static char* simu_trace_file;
    const static char* mem_trace_file;
    const static char* uart_output_file;
    const static char* img_bin_file;
    const static char* golden_trace_file;

    CpuTool(Vtop* top);

    void parse_args(int argc, char** argv, char** env);
};

#endif //CHIPLAB_CPU_TOOL_H
