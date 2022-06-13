#include <sys/time.h>
#include "testbench.h"

CpuTestbench::CpuTestbench(int argc, char **argv, char **env, vluint64_t *main_time) : CpuTool(nullptr) {
    m_trace = NULL;
    this->parse_args(argc, argv, env);
    rand64 = new Rand64(rand_path);
    top = new Vtop;
    struct UART_STA uart_status;
    if (restore_bp_time != 0) {
        restore_model(main_time, top_restore_bp_file);
        if (restore_bp_time != *main_time) {
            printf("Warning: restore_bp_time is not equal with %s's main_time\n", top_restore_bp_file);
        }
    }
    emu = new Emulator(top, "./", simu_trace_file, uart_output_file, ram_file, data_vlog_file);
    ram = new CpuRam(top, rand64, *main_time, &uart_status, mem_trace_file);
    if (restore_bp_time != 0) {
        uart_config = uart_status.uart_config;
        uart_div_set = uart_status.uart_div_set;
        div_reinit = uart_status.div_reinit;
        div_val_1 = uart_status.div_val_1;
        div_val_2 = uart_status.div_val_2;
        div_val_3 = uart_status.div_val_3;
    }
    //printf("uart_config is %d\n", uart_config);
    //printf("uart_div_set is %d\n", uart_div_set);
    //printf("div_reinit is %d\n", div_reinit);
    //printf("div_val_1 id %d\n", div_val_1);
    //printf("div_val_2 id %d\n", div_val_2);
    //printf("div_val_3 id %d\n", div_val_3);
    time_limit = new CpuTimeLimit();
    uart = new UARTSIM(0, uart_output_file); //output to terminal
    //uart->setup(0x000010); //param set
    //uart->setup(288); //param set
    uart->setup(uart_config);
}

void CpuTestbench::save_model(vluint64_t main_time, const char *top_filename) {
#ifndef RAND_TEST
    VerilatedSave os;
    os.open(top_filename);
    os << main_time;
    os << *top;
    printf("save top model break point %ldns to %s\n", main_time, top_filename);
#endif
}

void CpuTestbench::restore_model(vluint64_t *main_time, const char *top_filename) {
#ifndef RAND_TEST
    VerilatedRestore os;
    os.open(top_filename);
    os >> *main_time;
    os >> *top;
    printf("restore top model break point %ldns from %s\n", *main_time, top_filename);
#endif
}

void CpuTestbench::display_exit_cause(vluint64_t& main_time,int emask) {
    if(simu_quiet)return;
    fprintf(stderr,"\n");
    fprintf(stderr,"Terminated at %lu ns.\n",main_time);
    if(emask&status_exit) {
        fprintf(stderr,"Test exit.\n");
        if(emask&status_time_limit){
            fprintf(stderr,"Time limit exceeded.\n");
        }
        if(emask&status_test_end) {
            fprintf(stderr,"Reached test end PC.\n");
        }
    }
    if(emask&status_trace_err) {
        fprintf(stderr,"%s Error(Code:0x%x)\n",
                (emask&status_trace_err_pc)?
                (emask&status_trace_err_rf)?"Both":"Path":
                (emask&status_trace_err_rf)?"Data":"Perf"
                ,emask);
    }
    if(emask&status_unhandled) {
        fprintf(stderr,"Reached unhandled situation.\n");
    }
}

long long inst_total = 0;

void CpuTestbench::simulate(vluint64_t& main_time) {
    if(!simu_quiet)fprintf(stderr,"Verilator Simulation Start.\n");
    int emask = status_call_finish;
    vluint8_t& clock = top->aclk;
    vluint8_t& reset = top->aresetn;
    long long clock_total = 0;
    int p_config;
    static const int reset_valid = 0;

    /* calculate the time of simulation */
    struct timeval start;
    struct timeval end;
    double timer;
    gettimeofday(&start, NULL);


#define EVAL ((clock=!clock),main_time+=1,this->eval(main_time))

    if (restore_bp_time == 0) {
        reset = reset_valid;
        clock = 0;
        //top->enable_delay = simu_bus_delay;
        //top->random_seed = simu_bus_delay_random_seed;
        //printf("random seed is %d\n", simu_bus_delay_random_seed);
        for(int i=0;i<10;i+=1){if(EVAL)break;}
    }
    clock = 0;
    top->enable_delay = simu_bus_delay;
    top->random_seed = simu_bus_delay_random_seed;

    emu->init_emu(&main_time);

    if(!EVAL) {
        reset = !reset_valid;
        emask = 0;
    #ifdef RAND_TEST
        int init_error = rand64->init_all();
        if (init_error) {
            printf("RAND TEST INIT FAILED\n");
            return ;
        }
	ram->read_random_vlog();
    #endif
        printf("Start\n");
        while(true){
            // Simulate until exit
            if ((main_time <= (save_bp_time+1) && main_time >= (save_bp_time-1)) && (break_once == 0)) {
                if (main_time != save_bp_time) {
                    printf("Warning: real break point main time is %ld\n", main_time);
                }

                struct UART_STA uart_status;
                uart_status.uart_config = uart_config;
                uart_status.uart_div_set = uart_div_set;
                uart_status.div_reinit = div_reinit;
                uart_status.div_val_1 = div_val_1;
                uart_status.div_val_2 = div_val_2;
                uart_status.div_val_3 = div_val_3;

                ram->breakpoint_save(main_time, ram_save_bp_file, &uart_status);
                save_model(main_time, top_save_bp_file);
                printf("save break point over!\n");
                break_once = 1;
            }
            emask|= ram->process(main_time);
            //uart receive
            top->uart_rx = (*uart)(top->uart_tx);
            //uart reconfig
            if(top->uart_ctr_bus[UART_BUS_ENAB] && top->uart_ctr_bus[UART_BUS_RW]) {
                switch(top->uart_ctr_bus[UART_BUS_ADDR]) {
                    case 0:
                        if(uart_div_set == true) {
                            div_val_1 = top->uart_ctr_bus[UART_BUS_DATAI];
                            div_reinit = true;
                        }
                        break;
                    case 1:
                        if(uart_div_set == true) {
                            div_val_2 = top->uart_ctr_bus[UART_BUS_DATAI] << 8;
                            div_reinit = true;
                        }
                        break;
                    case 2:
                        if(uart_div_set == true) {
                            div_val_3 = top->uart_ctr_bus[UART_BUS_DATAI] << 16;
                            div_reinit = true;
                        }
                        break;
                    case 3:
                        if(uart_div_set == false && (top->uart_ctr_bus[UART_BUS_DATAI] & 0x80) == 0x80) {
                            uart_div_set = true;
                        }
                        else if(uart_div_set == true && (top->uart_ctr_bus[UART_BUS_DATAI] & 0x80) == 0) {
                            if (div_reinit == true) {
                                uart_config = (uart_config & 0xff000000) | ((div_val_1 + div_val_2 + div_val_3) * 16);
                                div_val_1 = 0;
                                div_val_2 = 0;
                                div_val_3 = 0;
                                div_reinit = false;
                            }
                            uart_div_set = false;
                        }
                        switch (top->uart_ctr_bus[UART_BUS_DATAI] & 0x30) {
                            case 0x00:
                                p_config = 0x0;
                                break;
                            case 0x10:
                                p_config = 0x1;
                                break;
                            case 0x20:
                                p_config = 0x3;
                                break;
                            case 0x30:
                                p_config = 0x2;
                                break;
                            default:
                                p_config = 0x0;
                        }
                        uart_config = (uart_config & 0x00ffffff) | ((3 - (top->uart_ctr_bus[UART_BUS_DATAI] & 0x3)) << 28)
                                      | ((top->uart_ctr_bus[UART_BUS_DATAI] & 0x4) << 25)
                                      | ((top->uart_ctr_bus[UART_BUS_DATAI] & 0x8) << 23)
                                      | (p_config << 24);
                        /*
                        //set bit
                        uart_config = (uart_config & 0x0fffffff) | ((3 - (top->datai & 0x3)) << 28);
                        //set stop
                        uart_config = (uart_config & 0xf7ffffff) | ((top->datai & 0x4) << 25);
                        //set parity
                        uart_config = (uart_config & 0xfbffffff) | ((top->datai & 0x8) << 23);
                        //set fixdp and evenp
                        uart_config = (uart_config & 0xfcffffff) | (p_config << 24);
                        */
                        //debug
                        //printf("uart datai is %x\n", top->uart_ctr_bus[UART_BUS_DATAI]);
                        //printf("uart config is %x\n", uart_config);
                        uart->setup(uart_config);
                        break;
                }
            }
            if(EVAL)break;
            emask |= time_limit->process(main_time);
            emask |= emu->process();
    #ifdef TRACE_COMP
            emask |= emu->dm->check_end();
    #endif
            if(EVAL)break;
            if(emask)break;
            clock_total += 1;
        }
    }
    printf("total clock is %lld\n", clock_total);
    gettimeofday(&end, NULL);
    timer = (double)(1000000 * (end.tv_sec - start.tv_sec) + end.tv_usec - start.tv_usec) / 1000000;

    printf("\n==============================================================\n");
    printf("total clock \t\tis %lld\n", clock_total);
    printf("total instruction \tis %lld\n", inst_total);
    printf("instruction per cycle\tis %lf\n", (double) inst_total / clock_total);
    printf("simulation time \tis %lf s\n", timer);
    printf("==============================================================\n");

    EVAL;
#undef EVAL
    display_exit_cause(main_time,emask);
    close();
}

void CpuTestbench::opentrace(const char *wavename) {
    if (!m_trace) {
    #ifdef DUMP_VCD
        m_trace = new VerilatedVcdC;
    #endif
    #ifdef DUMP_FST
        m_trace = new VerilatedFstC;
    #endif
        top->trace(m_trace, 99);
        m_trace->open(wavename);
    }
}

void CpuTestbench::close(void) {
    if (m_trace) {
        m_trace->flush();
        m_trace->close();
        m_trace = NULL;
    }
}

CpuTestbench::~CpuTestbench() {
    // Final model cleanup
    top->final();
    //  Coverage analysis (since test passed)
#if VM_COVERAGE
    Verilated::mkdir("logs");
    VerilatedCov::write("logs/coverage.dat");
#endif
    // Destroy model
    delete time_limit;
    time_limit = nullptr;
    delete ram;
    ram = nullptr;
    delete top;
    top = nullptr;
}
