#include <sys/mman.h>
#include <stdlib.h>
#include "emu.h"

FILE* trace_out;
FILE* uart_out;

/* ram to nemu */
static uint8_t *ram;
static long img_size = 0;
void *get_img_start() { return &ram[0]; }

static unsigned long trace_next_start = 0;
static int prefix_end;
static unsigned long tail_base = 0;

std::chrono::nanoseconds diff_nano_seconds = std::chrono::nanoseconds(0);

static vluint64_t hex2int64(const char *buf, const int width) {
    vluint64_t data = 0, h = 0;
    for (int i = 0; i < width; i += 1) {
        h = ('a' <= buf[i]) ? buf[i] - 'a' + 10 : buf[i] - '0';
        data = (data << 4) | h;
    }
    return data;
}

Emulator::Emulator(Vtop *top, const char *path, const char *file_out, const char *uart_path, const char *file_in, const char *data_vlog): CpuTool(top), trapCode(STATE_RUNNING) {
    dm = new DiffManage();

    sprintf(simu_out_path, "./%s%s", path, file_out);

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
        exit(1);
    }

    sprintf(uart_out_path, "./%s%s", path, uart_path);
    if ((uart_out = fopen(uart_out_path, "w")) == NULL) {
        printf("uart.txt open error!!!!\n");
        fprintf(trace_out, "uart.txt open error!!!!\n");
        if (trace_out) fclose(trace_out);
        exit(1);
    }

    init_ram(path, file_in);
    #ifdef RAND_TEST
    init_random_vlog(path, data_vlog);
    #endif
}

void Emulator::init_emu(vluint64_t* main_time) {
    this->main_time = main_time;
    dm->init_difftest();
}

void Emulator::init_ram(const char *path, const char *file_in) {
    sprintf(img, "./%s%s", path, file_in);
    assert(img != NULL);
    printf("The image is %s\n", img);

    /* initialize memory using Linux mmap */
    printf("Using simulated %luMB RAM\n", EMU_RAM_SIZE / (1024 * 1024));
    ram = (uint8_t *) mmap(NULL, EMU_RAM_SIZE, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
    if (ram == (uint8_t *) MAP_FAILED) {
        printf("Cound not mmap 0x%lx bytes\n", EMU_RAM_SIZE);
        assert(0);
    }

    int ret = 0;
    if (!strcmp(img + (strlen(img) - 4), ".dat")) { // file extension: .dat
        FILE *fp = fopen(img, "rt");
        assert(fp != nullptr);
        char buf[32];
        int cnt = 0;
        char tmp_buf[8] = {0};
        vluint64_t ptr = 0;
        while (fscanf(fp, "%32s", buf) != EOF) {
            if (buf[0] == '@') {
                /*
                if(cnt != 0) {
                    ram[ptr] = hex2int64(tmp_buf, 8);
                    cnt = 0;
                }
                */
                sscanf(buf + 1, "%lx", &ptr);
                //ptr = ptr/4;
            } else {
                /*
               if (cnt != 3) {
                    tmp_buf[6-2*cnt] = buf[0];
                    tmp_buf[7-2*cnt] = buf[1];
                    cnt += 1;
               }
               else {
                    tmp_buf[6-2*cnt] = buf[0];
                    tmp_buf[7-2*cnt] = buf[1];
                    cnt = 0;
                    ram[ptr] = hex2int64(tmp_buf, 8);
                    printf("addr: %lx\n data: %lx\n", ptr*4, ram[ptr]);
                    ptr += 1;
               }
               */
                ram[ptr] = hex2int64(buf, 2);
                ptr += 1;
            }
        }
        if (cnt != 0) {
            //ram[ptr] = hex2int64(tmp_buf, 8);
            ram[ptr] = hex2int64(buf, 2);
        }
        fclose(fp);
    } else if (!strcmp(img + (strlen(img) - 4), ".bin")) {  // file extension: .dat
        FILE *fp = fopen(img, "rb");
        if (fp == NULL) {
            printf("Can not open '%s'\n", img);
            assert(0);
        }

        fseek(fp, 0, SEEK_END);
        img_size = ftell(fp);
        if (img_size > EMU_RAM_SIZE) {
            img_size = EMU_RAM_SIZE;
        }

        fseek(fp, 0, SEEK_SET);
        ret = fread(ram, img_size, 1, fp);

        assert(ret == 1);
        fclose(fp);
    } else {
        printf("%s file format is not supported. You should use file format like xxx.dat or xxx.bin.\n", img);
        exit(1);
    }
}
void Emulator::init_random_vlog(const char *path, const char *file_in) {
    sprintf(img, "./%s%s", path, file_in);
    assert(img != NULL);
    printf("Data vlog is %s\n", img);
    FILE *data_vlog = fopen(img, "rt");
    
    vluint64_t addr;
    int byte_num,data;
    char line[65];
    while(fgets(line,65,data_vlog)!=NULL){
        sscanf(line,"%llx %x  %x\n",&addr, &byte_num,&data);
        int data_temp = data;
        if (byte_num == 1) {
            ram[addr] = (char) data;
        } else {
            for (int i=0;i<byte_num;i++) {
                data_temp = data_temp&0xff;
                ram[addr+i] = (char)data_temp;
                data_temp = data>>(8*((i+1)%4));
            }
        }
    }
}

void Emulator::close() {
    if (trace_out) {
        fclose(trace_out);
    }
    int i;
    //clear simu_out_path string
    for (i = prefix_end; i < 128; i++) {
        simu_out_path[i] = 0;
    }
}

int Emulator::process() {
#ifdef TAIL_SIMU_TRACE
    if (tail_base + TRACE_TAIL_SIZE <= *main_time) {
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
				if (tail_base + TRACE_TAIL_SIZE <= *main_time)
					tail_base += TRACE_TAIL_SIZE;

				if (trace_next_start <= *main_time) {
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
				if (trace_next_start <= *main_time) {
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

    //UART OUTPUT
    if (CONFREG_UART_DISPLAY) {
        #ifdef OUTPUT_UART_INFO
        printf("%c", CONFREG_UART_DATA);
        #endif
        fprintf(uart_out, "%c", CONFREG_UART_DATA);
    }
    trapCode = dm->difftest_state();
    if (trapCode != STATE_RUNNING) {
        printf("trapeCode = %d\n", trapCode);
        return 0;
    }
    auto start = std::chrono::steady_clock::now();
    trapCode = dm->do_step(*main_time);
    auto end = std::chrono::steady_clock::now();
    diff_nano_seconds += std::chrono::nanoseconds(end-start);
    switch (trapCode) {
        case STATE_RUNNING:
            return 0;
        case STATE_END:
            return status_test_end;
        case STATE_TIME_LIMIT:
            return status_time_limit;
        default:
            return status_trace_err;
    }
}

Emulator::~Emulator() {
    fclose(trace_out);
    fclose(uart_out);
    delete dm;
    dm = NULL;
}
