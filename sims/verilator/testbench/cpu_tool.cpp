#include "cpu_tool.h"

int CpuTool::simu_quiet = 0;
int CpuTool::simu_user = 0;
int CpuTool::simu_dev  = 1;
int CpuTool::simu_wait = 0;
int CpuTool::simu_bus_delay = 0;
int CpuTool::simu_bus_delay_random_seed = 0x5500ff;

int CpuTool::time_limit = 30000;
int CpuTool::time_check = 0;

int CpuTool::save_bp_time = 0;
int CpuTool::restore_bp_time = 0;

int CpuTool::dump_pc_trace = 0;
int CpuTool::dump_rf_trace = 0;
int CpuTool::comp_pc_trace = 0;
int CpuTool::comp_rf_trace = 0;

int64_t CpuTool::dump_delay = 0;
int CpuTool::dump_waveform = 0;

int CpuTool::rf_trace_no_repeat = 0;

unsigned int CpuTool::end_pc = 0;

const char ram_file_default[] = "ram.dat";
const char data_vlog_file_default[] = "data.vlog";
const char rand_path_default[] = "RES/res2020_mulh_0/";
const char simu_trace_file_default[] = "./simu_trace.txt";
const char mem_trace_file_default[] = "./mem_trace.txt";
const char golden_trace_file_default[] = "./golden_trace.txt";
const char uart_output_file_default[] = "./uart_output.txt";
const char null_file[] = " ";
const char* CpuTool::ram_file = ram_file_default;
const char* CpuTool::data_vlog_file = data_vlog_file_default;
const char* CpuTool::rand_path = rand_path_default;
const char* CpuTool::simu_trace_file = simu_trace_file_default;
const char* CpuTool::mem_trace_file = mem_trace_file_default;
const char* CpuTool::uart_output_file = uart_output_file_default;
const char* CpuTool::golden_trace_file = golden_trace_file_default;
const char* CpuTool::ram_save_bp_file = null_file;
const char* CpuTool::top_save_bp_file = null_file;
const char* CpuTool::ram_restore_bp_file = null_file;
const char* CpuTool::top_restore_bp_file = null_file;

const char pc_trace_ifile_default[] = "pc_trace.gz";
const char pc_trace_ofile_default[] = "logs/pc_trace.gz";
const char rf_trace_ifile_default[] = "rf_trace.txt";
const char rf_trace_ofile_default[] = "logs/rf_trace.txt";

const char* CpuTool::pc_trace_ifile = pc_trace_ifile_default;
const char* CpuTool::pc_trace_ofile = pc_trace_ofile_default;
const char* CpuTool::rf_trace_ifile = rf_trace_ifile_default;
const char* CpuTool::rf_trace_ofile = rf_trace_ofile_default;

CpuTool::CpuTool(Vtop* top) {
    this->top = top;
}

extern char* difftest_ref_so;

void CpuTool::parse_args(int argc, char **argv, char **env) {
#define PARSE_FLAG(val,label) if(strcmp(argv[i],label)==0){val = i+1>=argc || strcmp(argv[i+1],"0")!=0;}
#define PARSE_STR(val,label) if(i+1<argc && strcmp(argv[i],label)==0){val = argv[i+1];}
#define PARSE_INT(val,label) if(i+1<argc && strcmp(argv[i],label)==0){sscanf(argv[i+1],"%d",&val);}
#define PARSE_HEX(val,label) if(i+1<argc && strcmp(argv[i],label)==0){sscanf(argv[i+1],"%x",&val);}
    for(int i=1;i<argc;i+=1){
        PARSE_FLAG(simu_quiet,"--simu-quiet" )
        PARSE_FLAG(simu_user ,"--simu-user")
        PARSE_FLAG(simu_dev  ,"--simu-dev"   )
        PARSE_FLAG(simu_wait ,"--simu-wait"  )
        PARSE_FLAG(simu_bus_delay ,"--simu-bus-delay")
        PARSE_INT(simu_bus_delay_random_seed, "--simu-bus-delay-random-seed")

        PARSE_INT (time_limit,"--time-limit")
        PARSE_FLAG(time_check,"--time-check")

        PARSE_INT(save_bp_time,"--save-bp-time")
        PARSE_STR(ram_save_bp_file,"--ram-save-bp-file")
        PARSE_STR(top_save_bp_file,"--top-save-bp-file")
        PARSE_STR(difftest_ref_so, "--diff")
        PARSE_INT(restore_bp_time,"--restore-bp-time")
        PARSE_STR(ram_restore_bp_file,"--ram-restore-bp-file")
        PARSE_STR(top_restore_bp_file,"--top-restore-bp-file")

        PARSE_FLAG(dump_pc_trace,"--dump-pc-trace")
        PARSE_FLAG(dump_rf_trace,"--dump-rf-trace")
        PARSE_FLAG(comp_pc_trace,"--comp-pc-trace")
        PARSE_FLAG(comp_rf_trace,"--comp-rf-trace")

        PARSE_INT (dump_delay,"--dump-delay")
        PARSE_INT (dump_waveform,"--dump-waveform")

        PARSE_FLAG(rf_trace_no_repeat,"--rf-trace-no-repeat")

        PARSE_STR (ram_file,"--ram")
        PARSE_STR (data_vlog_file,"--data-vlog")
        PARSE_STR (rand_path,"--rand-path")

        PARSE_STR (pc_trace_ofile,"--pc-trace-o")
        PARSE_STR (rf_trace_ofile,"--rf-trace-o")
        PARSE_STR (pc_trace_ifile,"--pc-trace-i")
        PARSE_STR (rf_trace_ifile,"--rf-trace-i")

        PARSE_STR (simu_trace_file,"--simu_trace")
        PARSE_STR (mem_trace_file, "--mem_trace")
        PARSE_STR (uart_output_file, "--uart_output")
        PARSE_STR (golden_trace_file,"--golden_trace")

        PARSE_HEX (end_pc,"--end-pc")
    }
#undef PARSE_INT
#undef PARSE_STR
#undef PARSE_FLAG
#undef PARSE_HEX
}
