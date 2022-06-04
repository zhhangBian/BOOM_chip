#ifndef CHIPLAB_GOLDEN_TRACE_H
#define CHIPLAB_GOLDEN_TRACE_H

#include "common.h"
#include "cpu_tool.h"
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <cstring>
#include <string>

#define CONFREG_NUM_REG         top->num_data
#define CONFREG_OPEN_TRACE      top->open_trace
#define CONFREG_NUM_MONITOR     top->num_monitor
//#define CONFREG_UART_DISPLAY  top->confreg_uart_valid
#define CONFREG_UART_DATA       top->confreg_uart_data  
#define CONFREG_UART_DISPLAY    top->write_uart_valid  
#ifdef RUN_FUNC
#define END_PC 0x1c000100 
#elif defined RUN_C
#define END_PC 0x0 
#endif 

class GoldenTrace:CpuTool
{
    public:
    long long data;
    FILE* trace_out;
    FILE* uart_out;
    char simu_out_path[128]; 
    char golden_trace_path[128]; 
    char uart_out_path[128];
    FILE *golden_trace_in; 
    uint32_t trace_cmp_flag, ref_wb_pc, ref_wb_rf_wnum, ref_wb_rf_wdata, change_num;
    uint32_t sec_ref_wb_rf_wnum, sec_ref_wb_rf_wdata;
    bool right_fir_reg, right_sec_reg, two_change_error;
    bool two_delay;
    bool no_change_flag; 
    bool uart_print;
    long long reg[32];
    //confreg
    int confreg_num;
    int confreg_num_r;
    bool sim_over;
    bool sim_over_from_option;
    int error_count;
    int dead_clock;
	unsigned long trace_next_start = 0;
	int prefix_end;
	unsigned long tail_base = 0;

    GoldenTrace(Vtop * top,const char*path,const char* file_out,const char*uart_path,const char*file_in):CpuTool(top){ 
        sprintf(simu_out_path,"./%s%s",path,file_out); 
		#ifdef SLICE_SIMU_TRACE
		int simu_out_path_index = 0;
		char suffix[80];
		int suffix_index = 0;
		while (simu_out_path[simu_out_path_index] != '\0') {
			simu_out_path_index++; 
		}
		prefix_end = simu_out_path_index;
		sprintf(suffix, ".%ldns-%ldns", trace_next_start, trace_next_start+TRACE_SLICE_SIZE);
		while (suffix[suffix_index] != '\0') {
			simu_out_path[simu_out_path_index] = suffix[suffix_index];
			simu_out_path_index++;
			suffix_index++;
		}
		simu_out_path[simu_out_path_index] = '\0';
		trace_next_start += TRACE_SLICE_SIZE;
		#endif

        if ((trace_out = fopen(simu_out_path, "w")) == NULL) {
            printf("simu_trace.txt open error!!!!\n");
            fprintf(trace_out, "simu_trace.txt open error!!!!\n");
            exit(0);
        } 

        sprintf(uart_out_path, "./%s%s",path,uart_path);
        if ((uart_out = fopen(uart_out_path, "w")) == NULL) {
        //if ((uart_out = fopen("/media/dashuai/E266FD5F66FD34BF/loongson/work/chiplab_alpha/chiplab/sims/verilator/run_prog/uart.txt", "w")) == NULL) {
            printf("uart.txt open error!!!!\n");
            fprintf(trace_out, "uart.txt open error!!!!\n");
            exit(0);
        }
        #ifdef TRACE_COMP
        open_trace(path,file_in);
        #endif
        for (int i=0;i<32;i++) {
            reg[i] = 0;
        }
        error_count = 0;
        confreg_num = 0;
        confreg_num_r = 0;
        sim_over = false;
        sim_over_from_option = false;
        dead_clock = 0;
        top->__SYM__switch = 0xff;
        top->btn_key_row   = 0;
        top->btn_step      = 3;
        
    }
    int open_trace(const char*path,const char* file_in){
        int error=0;
        golden_trace_in = NULL; 
        sprintf(golden_trace_path,"./%s%s",path,file_in);
        if ((golden_trace_in = fopen(golden_trace_path, "r")) == NULL) {
            printf("golden_trace.txt open error!!!!\n");
            fprintf(trace_out, "golden_trace.txt open error!!!!\n");
            exit(0);
        }
        right_fir_reg = false;
        right_sec_reg=false;
        two_change_error = false;
        two_delay = false;
        no_change_flag = false;
        update_once();
        return error;
    }
    int update_once(){
        if (!two_delay) {
            fscanf(golden_trace_in, "%x %x %x %x %x", &trace_cmp_flag, &ref_wb_pc, &change_num, &ref_wb_rf_wnum, &ref_wb_rf_wdata);
            if (change_num == 2){
                fscanf(golden_trace_in, "%x %x", &sec_ref_wb_rf_wnum, &sec_ref_wb_rf_wdata);
                right_fir_reg = true;
                right_sec_reg = true;
                two_delay = true;
                two_change_error = false;
            }
            fscanf(golden_trace_in, "\n");
        } else {
            two_delay = false;
        }
        return 0;

    }

	void close(void) {
		if (trace_out) {
			fclose(trace_out);
		}
		int i;
		//clear simu_out_path string
		for (i=prefix_end; i<128; i++) {
			simu_out_path[i] = 0;
		}
	}

    int process(vluint64_t main_time){
	
		#ifdef TAIL_SIMU_TRACE
			if (tail_base + TRACE_TAIL_SIZE <= main_time) {
				tail_base += TRACE_TAIL_SIZE;
				if (trace_out) {
					fclose(trace_out);
				}

    		    if ((trace_out = fopen(simu_out_path, "w")) == NULL) {
    		        printf("simu_trace.txt open error!!!!\n");
    		        fprintf(trace_out, "simu_trace.txt open error!!!!\n");
    		        exit(0);
    		    } 
			}
		#endif

		#ifdef SLICE_SIMU_TRACE
			#ifdef TAIL_SIMU_TRACE
				if (tail_base + TRACE_TAIL_SIZE <= main_time)
					tail_base += TRACE_TAIL_SIZE;

				if (trace_next_start <= main_time) {
					close();
					char suffix[80];
					int simu_out_path_index = prefix_end;
					int suffix_index = 0;
					sprintf(suffix, ".%ldns-%ldns", trace_next_start - tail_base, trace_next_start + TRACE_SLICE_SIZE - tail_base);
					while(suffix[suffix_index] != '\0') {
						simu_out_path[simu_out_path_index] = suffix[suffix_index];
						simu_out_path_index++;
						suffix_index++;
					}
					simu_out_path[simu_out_path_index] = '\0';
					trace_next_start += TRACE_SLICE_SIZE;
    		    	if ((trace_out = fopen(simu_out_path, "w")) == NULL) {
    		    	    printf("simu_trace.txt open error!!!!\n");
    		    	    fprintf(trace_out, "simu_trace.txt open error!!!!\n");
    		    	    exit(0);
    		    	} 
				}
			#else
				if (trace_next_start <= main_time) {
					close();
					char suffix[80];
					int simu_out_path_index = prefix_end;
					int suffix_index = 0;
					sprintf(suffix, ".%ldns-%ldns", trace_next_start, trace_next_start+TRACE_SLICE_SIZE);
					while(suffix[suffix_index] != '\0') {
						simu_out_path[simu_out_path_index] = suffix[suffix_index];
						simu_out_path_index++;
						suffix_index++;
					}
					simu_out_path[simu_out_path_index] = '\0';
					trace_next_start += TRACE_SLICE_SIZE;
    		    	if ((trace_out = fopen(simu_out_path, "w")) == NULL) {
    		    	    printf("simu_trace.txt open error!!!!\n");
    		    	    fprintf(trace_out, "simu_trace.txt open error!!!!\n");
    		    	    exit(0);
    		    	} 
				}
			#endif
		#endif

        if (top->debug0_wb_rf_wen != 0 && top->debug0_wb_rf_wnum != 0) { 
            #ifdef OUTPUT_PC_INFO 
            #ifdef PRINT_CLK_TIME
            printf("[%010dns] mycpu : pc = %08x,  reg = %02d, val = %08x\n", main_time, top->debug0_wb_pc, top->debug0_wb_rf_wnum, top->debug0_wb_rf_wdata); 
            #else
            printf("mycpu : pc = %08x,  reg = %02d, val = %08x\n", top->debug0_wb_pc, top->debug0_wb_rf_wnum, top->debug0_wb_rf_wdata); 
            #endif
            #endif 
        	
			#ifdef SIMU_TRACE
            #ifdef PRINT_CLK_TIME
            fprintf(trace_out, "[%010dns] mycpu : pc = %08x,  reg = %02d, val = %08x\n", main_time, top->debug0_wb_pc, top->debug0_wb_rf_wnum, top->debug0_wb_rf_wdata); 
            #else 
            fprintf(trace_out, "mycpu : pc = %08x,  reg = %02d, val = %08x\n", top->debug0_wb_pc, top->debug0_wb_rf_wnum, top->debug0_wb_rf_wdata); 
            #endif 
			#endif

            if (top->debug0_wb_pc==END_PC) 
                sim_over = true;
            if (end_pc != 0) {
                if (end_pc == top->debug0_wb_pc)
                    sim_over_from_option = true;
            }
            if (reg[top->debug0_wb_rf_wnum] == top->debug0_wb_rf_wdata) {
                #ifdef TRACE_COMP
                no_change_flag = true;
                //dead_clock += 1;
                #endif
            }
            else { 
                #ifdef TRACE_COMP
                no_change_flag = false; 
                #endif
                reg[top->debug0_wb_rf_wnum] = top->debug0_wb_rf_wdata;
                //dead_clock = 0;
            }
        }

        //trace
        #ifdef TRACE_COMP
        //compare mycpu log and ref log 
        if (top->debug0_wb_rf_wen != 0 && top->debug0_wb_rf_wnum != 0 && !no_change_flag && trace_cmp_flag) { 
            if (change_num == 1) {
                if ((ref_wb_pc != top->debug0_wb_pc) || (ref_wb_rf_wnum != top->debug0_wb_rf_wnum) || (ref_wb_rf_wdata != top->debug0_wb_rf_wdata)) {
                    printf("====================================================================\n");
                    printf("ERROR !!!\n");
                    printf("reference : pc = %x, reg = %d, val = %x\n", ref_wb_pc, ref_wb_rf_wnum, ref_wb_rf_wdata);
                    printf("====================================================================\n"); 
                    printf("Main time = %d\n",main_time);
                    fprintf(trace_out, "====================================================================\n");
                    fprintf(trace_out, "ERROR !!!\n");
                    fprintf(trace_out, "reference : pc = %x, reg = %d, val = %x\n", ref_wb_pc, ref_wb_rf_wnum, ref_wb_rf_wdata);
                    fprintf(trace_out, "====================================================================\n"); 
                    fprintf(trace_out,"Main time = %d\n",main_time);
                    return 1;
                } 
            } else if (change_num == 2) {
                if (ref_wb_pc != top->debug0_wb_pc)
                    two_change_error = true;
                if ((ref_wb_rf_wnum != top->debug0_wb_rf_wnum) || (ref_wb_rf_wdata != top->debug0_wb_rf_wdata)) {
                    if (right_fir_reg == true) {
                        right_fir_reg = false;
                    } else {
                        two_change_error = true;
                    }
                }
                if ((sec_ref_wb_rf_wnum != top->debug0_wb_rf_wnum) || (sec_ref_wb_rf_wdata != top->debug0_wb_rf_wdata)) {
                    if (right_sec_reg == true) {
                        right_sec_reg = false;
                    } else {
                        two_change_error = true;
                    }
                }
                if (!right_fir_reg && !right_sec_reg) {
                    two_change_error = true;
                } 
                if (two_change_error) {
                    printf("====================================================================\n");
                    printf("ERROR !!!\n");
                    printf("reference : pc = %x, reg = %d, val = %x, reg = %d, val = %x\n", ref_wb_pc, ref_wb_rf_wnum, ref_wb_rf_wdata, sec_ref_wb_rf_wnum, sec_ref_wb_rf_wdata);
                    printf("====================================================================\n"); 
                    fprintf(trace_out, "====================================================================\n");
                    fprintf(trace_out, "ERROR !!!\n");
                    fprintf(trace_out, "reference : pc = %x, reg = %d, val = %x, reg = %d, val = %x\n", ref_wb_pc, ref_wb_rf_wnum, ref_wb_rf_wdata, sec_ref_wb_rf_wnum, sec_ref_wb_rf_wdata);
                    fprintf(trace_out, "====================================================================\n"); 
                    return 1;
                }
            } else {
                printf("ERROR !!!!! info:simulation environment can not deal with reg changing num 3\n");
                return 1;
            }
   
            update_once();
        }
        #endif

    // 2CMT
        #ifdef CPU_2CMT
        if (top->debug1_wb_rf_wen != 0 && top->debug1_wb_rf_wnum != 0) { 
            #ifdef OUTPUT_PC_INFO
            #ifdef PRINT_CLK_TIME 
            printf("[%010dns] mycpu : pc = %08x,  reg = %02d, val = %08x\n", main_time,top->debug1_wb_pc, top->debug1_wb_rf_wnum, top->debug1_wb_rf_wdata);
			#else
            printf("mycpu : pc = %08x,  reg = %02d, val = %08x\n", top->debug1_wb_pc, top->debug1_wb_rf_wnum, top->debug1_wb_rf_wdata);
			#endif
			#endif

			#ifdef SIMU_TRACE
			#ifdef PRINT_CLK_TIME
            fprintf(trace_out, "[%010dns] mycpu : pc = %08x,  reg = %02d, val = %08x\n", main_time, top->debug1_wb_pc, top->debug1_wb_rf_wnum, top->debug1_wb_rf_wdata); 
			#else
            fprintf(trace_out, "mycpu : pc = %08x,  reg = %02d, val = %08x\n", top->debug1_wb_pc, top->debug1_wb_rf_wnum, top->debug1_wb_rf_wdata);  
			#endif
            #endif

            if (top->debug1_wb_pc==END_PC) 
                sim_over = true;
            if (end_pc != 0) {
                if (end_pc == top->debug1_wb_pc)
                    sim_over_from_option = true;
            }
            if (reg[top->debug1_wb_rf_wnum] == top->debug1_wb_rf_wdata) {
                #ifdef TRACE_COMP
                no_change_flag = true;
                #endif
                //dead_clock += 1;
            }
            else { 
                #ifdef TRACE_COMP
                no_change_flag = false; 
                #endif
                reg[top->debug1_wb_rf_wnum] = top->debug1_wb_rf_wdata;
                //dead_clock = 0;
            }
        }

        //trace
        #ifdef TRACE_COMP
        //compare mycpu log and ref log 
        if (top->debug1_wb_rf_wen != 0 && top->debug1_wb_rf_wnum != 0 && !no_change_flag && trace_cmp_flag) { 
            if (change_num == 1) {
                if ((ref_wb_pc != top->debug1_wb_pc) || (ref_wb_rf_wnum != top->debug1_wb_rf_wnum) || (ref_wb_rf_wdata != top->debug1_wb_rf_wdata)) {
                    printf("====================================================================\n");
                    printf("ERROR !!!\n");
                    printf("reference : pc = %08x, reg = %02d, val = %08x\n", ref_wb_pc, ref_wb_rf_wnum, ref_wb_rf_wdata);
                    printf("====================================================================\n"); 
                    printf("Main time = %d\n",main_time);
                    fprintf(trace_out, "====================================================================\n");
                    fprintf(trace_out, "ERROR !!!\n");
                    fprintf(trace_out, "reference : pc = %08x, reg = %02d, val = %08x\n", ref_wb_pc, ref_wb_rf_wnum, ref_wb_rf_wdata);
                    fprintf(trace_out, "====================================================================\n"); 
                    fprintf(trace_out, "Main time = %d\n",main_time);
                    return 1;
                } 
            } else if (change_num == 2) {
                if (ref_wb_pc != top->debug1_wb_pc)
                    two_change_error = true;
                if ((ref_wb_rf_wnum != top->debug1_wb_rf_wnum) || (ref_wb_rf_wdata != top->debug1_wb_rf_wdata)) {
                    if (right_fir_reg == true) {
                        right_fir_reg = false;
                    } else {
                        two_change_error = true;
                    }
                }
                if ((sec_ref_wb_rf_wnum != top->debug1_wb_rf_wnum) || (sec_ref_wb_rf_wdata != top->debug1_wb_rf_wdata)) {
                    if (right_sec_reg == true) {
                        right_sec_reg = false;
                    } else {
                        two_change_error = true;
                    }
                }
                if (!right_fir_reg && !right_sec_reg) {
                    two_change_error = true;
                } 
                if (two_change_error) {
                    printf("====================================================================\n");
                    printf("ERROR !!!\n");
                    printf("reference : pc = %08x, reg = %02d, val = %08x, reg = %02d, val = %08x\n", ref_wb_pc, ref_wb_rf_wnum, ref_wb_rf_wdata, sec_ref_wb_rf_wnum, sec_ref_wb_rf_wdata);
                    printf("====================================================================\n"); 
                    fprintf(trace_out, "====================================================================\n");
                    fprintf(trace_out, "ERROR !!!\n");
                    fprintf(trace_out, "reference : pc = %08x, reg = %02d, val = %08x, reg = %02d, val = %08x\n", ref_wb_pc, ref_wb_rf_wnum, ref_wb_rf_wdata, sec_ref_wb_rf_wnum, sec_ref_wb_rf_wdata);
                    fprintf(trace_out, "====================================================================\n"); 
                    return 1;
                }
            } else {
                printf("ERROR !!!!! info:simulation environment can not deal with reg changing num 3\n");
                return 1;
            }
   
            update_once();
        }
        #endif
        #endif

        confreg_num = CONFREG_NUM_REG;
        if ((confreg_num != confreg_num_r) && CONFREG_NUM_MONITOR) {
            //printf("high is %d; low is %d\n", (confreg_num&0xff000000) >> 24, (confreg_num&0xff));
            if ((confreg_num&0xff) != (confreg_num_r&0xff) + 1) {
                printf("Error(%d)!! occurred in number %d Functional test Point\n", error_count, (confreg_num&0xff000000) >> 24);
                fprintf(trace_out, "Error(%d)!! occurred in number %d Functional test Point\n", error_count, (confreg_num&0xff000000) >> 24);
                error_count += 1;
            }
            else if ((confreg_num&0xff000000) >> 24 != ((confreg_num_r&0xff000000) >> 24) + 1) {
                printf("Error(%d)!!! Unknown, Functional Test Point numbers are unequal!\n", error_count);
                fprintf(trace_out, "Error(%d)!!! Unknown, Functional Test Point numbers are unequal!\n", error_count);
                error_count += 1;
            }
            else {
                printf("Number %d Functional Test Point PASS!!!\n", (confreg_num&0xff000000) >> 24);
                fprintf(trace_out, "Number %d Functional Test Point PASS!!!\n", (confreg_num&0xff000000) >> 24);
            }
        }
        confreg_num_r = confreg_num;

        //uart print  
        /*
        if (CONFREG_UART_DISPLAY) {
            if (CONFREG_UART_DATA == 0xff) {
                printf("test end!!\n");
                fprintf(trace_out, "test end!!\n");
                return 1;
            }
            else {
                //printf("%c", CONFREG_UART_DATA);
                //fprintf(trace_out, "%c", CONFREG_UART_DATA); 
                fprintf(uart_out, "%c", CONFREG_UART_DATA); 
            }
        }
        */ 

        if (CONFREG_UART_DISPLAY) {
            uart_print = true;
        } 

        if (uart_print) {
            if (CONFREG_UART_DATA == 0xff) {
                printf("test end!!\n");
                fprintf(trace_out, "test end!!\n");
                return 1;
            }
            else {
                //printf("%c", CONFREG_UART_DATA);
                //fprintf(trace_out, "%c", CONFREG_UART_DATA);  
                #ifdef OUTPUT_UART_INFO
                printf("%c", CONFREG_UART_DATA); 
                #endif
                fprintf(uart_out, "%c", CONFREG_UART_DATA); 
            } 
            uart_print = false;
        }

        if (sim_over == true) {
            printf("==============================================================\n");
            printf("test end!!\n");
            fprintf(trace_out, "==============================================================\n");
            fprintf(trace_out, "test end!!\n");

            if (error_count != 0) {
                printf("Fail!!! Total %d errors!\n", error_count);
                fprintf(trace_out, "Fail!!! Total %d errors!\n", error_count);
                return 1;
            }
            else {
                printf("============================PASS!============================\n");
                fprintf(trace_out, "============================PASS!============================\n");
                return 1;
            }
        }

        if (sim_over_from_option == true) {
            printf("======== simu over at pc 0x%08x ========\n", end_pc);
            return 1;
        }

        //simulation dead situation  
    
        #ifndef CPU_2CMT 
        if (top->debug0_wb_rf_wen == 0) {
        #else
        if (top->debug0_wb_rf_wen == 0 && top->debug1_wb_rf_wen == 0) { 
        #endif
            dead_clock += 1;
        }
        else {
            dead_clock = 0;
        }

        if (dead_clock > 10000) {
            printf("CPU status no change for 10000 clocks, simulation must exist error!!!!\n");
            return 1;
        }




    return 0;

    }
};

#endif  // CHIPLAB_GOLDEN_TRACE_H
