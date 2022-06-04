#ifndef CHIPLAB_TESTBENCH_H
#define CHIPLAB_TESTBENCH_H

#include <verilated_fst_c.h> 
#include <verilated_vcd_c.h>
#include <verilated_threads.h>
#include <verilated_save.h>
#include "common.h"
#include "ram.h"
#include "time_limit.h"
#include "rand64.h"
#include "emu.h"

class CpuTestbench:CpuTool {
public:
    Emulator *emu;
    CpuRam* ram;
    CpuTimeLimit* time_limit;
    Rand64* rand64; 
    UARTSIM* uart;
    #ifdef DUMP_VCD
    VerilatedVcdC	*m_trace; 
    #endif 
    #ifdef DUMP_FST 
    VerilatedFstC	*m_trace;
    #endif

    /* control information to satisfy different waveform generation requirements */
    unsigned long dump_next_start;
	unsigned long tail_base;
	char break_once = 0;

	/* uart */
    unsigned int uart_config = 16;
    bool uart_div_set = false;
    bool div_reinit = false;
    unsigned int div_val_1 = 0;
    unsigned int div_val_2 = 0;
    unsigned int div_val_3 = 0;

    /*  */
    void save_model(vluint64_t main_time, const char* top_filename);
    void restore_model(vluint64_t* main_time, const char* top_filename);

    CpuTestbench(int argc, char** argv, char** env, vluint64_t* main_time);
    ~CpuTestbench();

    /* called after simulation is over to display exit cause */
    void display_exit_cause(vluint64_t& main_time,int emask);

    /* simulate [significant function] */
    void simulate(vluint64_t& main_time);

    /* open waveform file */
    virtual	void opentrace(const char *wavename);

    /* Close a trace file */
    virtual void close(void);

    /* Time passes */
    inline int eval(vluint64_t& main_time) {
        top->eval();
        char waveform_name[128];
        if(m_trace != NULL) {
            #ifdef SLICE_WAVEFORM 
				#ifdef TAIL_WAVEFORM
					if (main_time >= tail_base+WAVEFORM_TAIL_SIZE) {
						tail_base += WAVEFORM_TAIL_SIZE;
					}
                	if(main_time >= dump_next_start) {
                	    close();
                	    dump_next_start += WAVEFORM_SLICE_SIZE; 
                	    #ifdef DUMP_VCD
                	    sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.vcd", main_time - tail_base, dump_next_start - tail_base);
                	    #endif
                	    #ifdef DUMP_FST
                	    sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.fst", main_time - tail_base, dump_next_start - tail_base);
                	    #endif
                	    opentrace(waveform_name);
                	}
				#else
                	if(main_time >= dump_next_start) {
                	    close();
                	    dump_next_start += WAVEFORM_SLICE_SIZE; 
                	    #ifdef DUMP_VCD
                	    sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.vcd", main_time, dump_next_start);
                	    #endif
                	    #ifdef DUMP_FST
                	    sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.fst", main_time, dump_next_start);
                	    #endif
                	    opentrace(waveform_name);
                	}
				#endif
            #endif
			#ifdef TAIL_WAVEFORM
			if (main_time >= tail_base+WAVEFORM_TAIL_SIZE) {
				tail_base += WAVEFORM_TAIL_SIZE;
				close();
                #ifdef DUMP_VCD 
                opentrace("./logs/simu_trace.vcd");
                #endif 
                #ifdef DUMP_FST
                opentrace("./logs/simu_trace.fst"); 
                #endif 
			}
            #endif
            m_trace->dump(main_time);
        } else if (main_time >= dump_delay && dump_waveform) {
            #ifdef SLICE_WAVEFORM 
            	#ifdef TAIL_WAVEFORM
                	dump_next_start = dump_delay+WAVEFORM_SLICE_SIZE;
					tail_base = dump_delay;
                	#ifdef DUMP_VCD
                	sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.vcd", dump_delay - tail_base, dump_next_start - tail_base);
                	#endif
                	#ifdef DUMP_FST
                	sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.fst", dump_delay - tail_base, dump_next_start - tail_base);
                	#endif
                	opentrace(waveform_name);
				#else
                	dump_next_start = dump_delay+WAVEFORM_SLICE_SIZE;
                	#ifdef DUMP_VCD
                	sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.vcd", dump_delay, dump_next_start);
                	#endif
                	#ifdef DUMP_FST
                	sprintf(waveform_name, "./logs/simu_trace_%ldns_%ldns.fst", dump_delay, dump_next_start);
                	#endif
                	opentrace(waveform_name);
				#endif
			#else
				tail_base = dump_delay;
                #ifdef DUMP_VCD 
                opentrace("./logs/simu_trace.vcd");
                #endif 
                #ifdef DUMP_FST
                opentrace("./logs/simu_trace.fst"); 
                #endif 
            #endif
            printf("Dump Start at %d ns\n",main_time,dump_delay);
            m_trace->dump(main_time);
        }
        return Verilated::gotFinish();
    }

};

#endif  // CHIPLAB_TESTBENCH_H
