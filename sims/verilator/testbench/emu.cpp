#include <sys/mman.h>
#include <stdlib.h>
#include "emu.h"

FILE* trace_out;
FILE* uart_out;

static uint8_t *ram;
static long img_size = 0;

void *get_img_start() { return &ram[0]; }

static vluint64_t hex2int64(const char *buf, const int width) {
    vluint64_t data = 0, h = 0;
    for (int i = 0; i < width; i += 1) {
        h = ('a' <= buf[i]) ? buf[i] - 'a' + 10 : buf[i] - '0';
        data = (data << 4) | h;
    }
    return data;
}

Emulator::Emulator(Vtop *top, const char *path, const char *file_out, const char *uart_path, const char *file_in): CpuTool(top), trapCode(STATE_RUNNING) {
    dm = new DiffManage();

    sprintf(simu_out_path, "./%s%s", path, file_out);
    printf("simu out path == %s\n", simu_out_path);
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

int Emulator::process() {
    trapCode = dm->difftest_state();
    if (trapCode != STATE_RUNNING) {
        printf("trapeCode = %d\n", trapCode);
        return 0;
    }
    trapCode = dm->do_step(*main_time);
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