#include "ram.h"

CpuRam::CpuRam(Vtop *top, Rand64 *rand64, vluint64_t main_time, struct UART_STA *uart_status, const char *mem_path)
        : CpuTool(top) {

    sprintf(mem_out_path, "./%s", mem_path);
    if ((mem_out = fopen(mem_out_path, "w")) == NULL) {
        printf("mem_trace.txt open error!!!!\n");
        fprintf(mem_out, "mem_trace.txt open error!!!!\n");
        exit(0);
    }
    this->rand64 = rand64;
    if (restore_bp_time != 0) {
        breakpoint_restore(main_time, ram_restore_bp_file, uart_status);
        //breakpoint_save(main_time, "/media/desi/E266FD5F66FD34BF/loongson/work/chiplab_alpha/chiplab/sims/verilator/run_func/test.file", uart_status);
        //exit(0);
        if (restore_bp_time != main_time) {
            printf("Warning: restore_bp_time is not equal with %s's main_time\n", ram_restore_bp_file);
        }
        printf("restore break point over\n");
    } else {
        FILE *f = fopen(this->ram_file, "rt");
        assert(f != nullptr);
        char buf[32];
        vluint64_t ptr, data, h;
        for (int idx = 0; idx < tbsz; idx += 1) {
            cur[idx] = mem[idx].end();
        }
        int width = -1;
        int align = 0;
        while (fscanf(f, "%32s", buf) != EOF) {
            if (buf[0] == '@') {
                sscanf(buf + 1, "%lx", &ptr);
                if (width >= 0)ptr <<= align;
            } else {
                if (width < 0) {
                    width = 0;
                    while (buf[width] != '\n' && buf[width] != 0)width += 1;
                    while ((2llu << align) < width) align += 1;
                    ptr <<= align;
                    if ((2 << align) != width) {
                        fprintf(stderr, "Invalue RAM-Init File Format:Not Aligned\n");
                        assert(0);
                    }
                } else if (buf[width] != '\n' && buf[width] != 0) {
                    fprintf(stderr, "Invalue RAM-Init File Format:Volatile Width\n");
                    assert(0);
                }
                vluint64_t tag = ptr & tbmk;
                vluint64_t idx = (ptr >> pgwd) & (tbsz - 1);
                jump(tag, idx);
                if (align >= 3) {
                    for (int j = 0; j < width; j += 16) {
                        *(vluint64_t *) (cur[idx]->data + (ptr & (pgsz - 1))) = conv_hex2int64(buf + j, 16);
                    }
                } else {
                    vluint64_t data = conv_hex2int64(buf, width);
                    //fprintf(stderr,"set %lx:%lx(%s)\n",ptr,data,buf);
                    if (align == 2) { *(unsigned *) (cur[idx]->data + (ptr & (pgsz - 1))) = data; }
                    else if (align == 1) { *(short *) (cur[idx]->data + (ptr & (pgsz - 1))) = data; }
                    else { *(char *) (cur[idx]->data + (ptr & (pgsz - 1))) = data; }
                }
                ptr += 1 << align;
            }
        }
        fclose(f);
        f = nullptr;
        //debug = 1;
        //fprintf(stderr,"Test ram module start\n");
        //fprintf(stderr,"R 0x1c000000:%lx\n",read64(0x1c000000));
        //fprintf(stderr,"R 0x9c000000:%lx\n",read64(0x9c000000));
        //fprintf(stderr,"R 0x1c000000:%lx\n",read64(0x1c000000));
        //fprintf(stderr,"Test ram module end\n");
    }
}

CpuRam::~CpuRam() {
    if (mem_out) {
        fclose(mem_out);
    }
    for(int idx=0;idx<tbsz;idx+=1){
        vector<RamSection>::iterator e = mem[idx].end();
        for(vector<RamSection>::iterator j = mem[idx].begin();j!=e;j+=1){
            free(j->data);j->data = nullptr;
        }
    }
}