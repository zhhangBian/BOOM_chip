#include "ram.h"

inline static vluint64_t conv_hex2int64(const char *buf, const int width) {
    vluint64_t data = 0, h = 0;
    for (int i = 0; i < width; i += 1) {
        h = ('a' <= buf[i]) ? buf[i] - 'a' + 10 : buf[i] - '0';
        data = (data << 4) | h;
    }
    return data;
}

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
        //breakpoint_save(main_time, "/media/desi/E266FD5F66FD34BF/loongson/work/chiplab_alpha/chiplab/sims/verilator/run_prog/test.file", uart_status);
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

int CpuRam::find(vluint64_t tag, vluint64_t idx) {
    // when no page is found, return 1
    vector<RamSection> &pages = mem[idx];
    if (pages.begin() == pages.end())return 1;
    vector<RamSection>::iterator &t = cur[idx];
    if (t == pages.end()) {
        t = pages.end() - 1;
    } else if (tag > t->tag) {
        do {
            t++;
            if (t == pages.end())
                return 1;
        } while (tag > t->tag);
        return t->tag != tag;
    }
    while (t != pages.begin() && tag < t->tag)
        t--;
    return t->tag != tag;
}

void CpuRam::jump(vluint64_t tag, vluint64_t idx) {
    int miss = find(tag, idx);
    if (!miss)return;
    unsigned char *data = (unsigned char *) malloc(pgsz);
    memset(data, 0, pgsz);
    int k = cur[idx] - mem[idx].begin();
    RamSection sec{.tag=tag, .data=data};
    if ((k + 1 == mem[idx].size() && tag > cur[idx]->tag) || k == mem[idx].size()) {
        mem[idx].push_back(sec);
        cur[idx] = mem[idx].end() - 1;
        assert(cur[idx]->tag == tag);
    } else {
        k += (tag > cur[idx]->tag);
        mem[idx].insert(mem[idx].begin() + k, sec);
        if (mem[idx][k + 1].tag <= mem[idx][k].tag) {
            printf("tag = %ld\n", tag);
            printf("mem[%d][%d].tag = %ld\n", idx, k + 1, mem[idx][k + 1].tag);
            printf("mem[%d][%d].tag = %ld\n", idx, k, mem[idx][k].tag);
            printf("mem[%d].size = %d\n", idx, mem[idx].size());
            exit(1);
        }
        assert(k == 0 || mem[idx][k].tag > mem[idx][k - 1].tag);
        cur[idx] = mem[idx].begin() + k;
    }
}

unsigned CpuRam::read32(vluint64_t a) {
    vluint64_t tag = a & tbmk;
    vluint64_t idx = (a >> pgwd) & (tbsz - 1);

    int miss = find(tag, idx);
#ifdef READ_MISS_CHECK
    if(miss){
            fprintf(stderr,"Read Miss For Addr%lx.\n",a);
        }
#endif
    unsigned val = miss ? 0 : ((unsigned *) cur[idx]->data)[(a & (pgsz - 1)) >> 2];
    return val;
}

vluint64_t CpuRam::read64(vluint64_t a) {
    vluint64_t tag = a & tbmk;
    vluint64_t idx = (a >> pgwd) & (tbsz - 1);
    int miss = find(tag, idx);
#ifdef READ_MISS_CHECK
    if(miss){
            fprintf(stderr,"Read Miss For Addr%lx.\n",a);
        }
#endif
    vluint64_t val = miss ? 0 : ((vluint64_t *) cur[idx]->data)[(a & (pgsz - 1)) >> 3];
    return val;
}

void CpuRam::write64(vluint64_t a, vluint64_t m, vluint64_t d) {
    vluint64_t tag = a & tbmk;
    vluint64_t idx = (a >> pgwd) & (tbsz - 1);
    jump(tag, idx);
    assert(tag == cur[idx]->tag);
    vluint64_t &data = ((vluint64_t *) cur[idx]->data)[(a & (pgsz - 1)) >> 3];
    //printf("write 64\n");
    //printf("addr = %016lx\n",a);
    //printf("d    = %016lx\ndata = %016lx\nm    = %016lx\n",d,data,m);
    data = d & m | data & ~m;
    //printf("data = %016lx\n",data);
}

void CpuRam::write32(vluint64_t a, vluint64_t m, unsigned d) {
    vluint64_t tag = a & tbmk;
    vluint64_t idx = (a >> pgwd) & (tbsz - 1);
    jump(tag, idx);
    assert(tag == cur[idx]->tag);
    unsigned &data = ((unsigned *) cur[idx]->data)[(a & (pgsz - 1)) >> 2];
    data = d & m | data & ~m;
    //printf("write 32\n");
}

int CpuRam::process(vluint64_t main_time) {

#ifdef RAND_TEST
        
 
    if (top->ram_wen && (top->ram_waddr == 0x1c002010)) {
        if (process_rand(main_time,(int)top->ram_wdata)) {
                return 1;
            }
    }
    if(read_valid){
        if (!special_read()) {
            process_read(main_time,read_addr,top->ram_rdata);
        }
        read_valid = 0;
    }
#else
    if (read_valid) {
        process_read(main_time, read_addr, top->ram_rdata);
        read_valid = 0;
    }
#endif
#ifdef MEM_TRACE
    if (ram_read_mark) {
           fprintf(mem_out, "[%010dns] mem rd: pc = %08x, addr = %08x, data = %08x\n", main_time, top->debug0_wb_pc, read_addr, top->ram_rdata);
           ram_read_mark = false;
        }
#endif

    read_valid = top->ram_ren;
    if (read_valid) {
        if ((top->ram_raddr & 0xff000000) == 0x1c000000) {
            read_addr = (top->ram_raddr);
        } else
#ifdef RUN_FUNC
            read_addr  = (top->ram_raddr);
#else
            read_addr = (top->ram_raddr & 0x07ffffff);
#endif
        ram_read_mark = true;
    }
    if (top->ram_wen) {
#ifdef MEM_TRACE
        fprintf(mem_out, "[%010dns] mem wr: pc = %08x, addr = %08x, data = %08x\n", main_time, top->debug0_wb_pc, top->ram_waddr&0x7ffffff, top->ram_wdata);
#endif
#ifdef RUN_FUNC
        return process_write(main_time,(top->ram_waddr),top->ram_wen,top->ram_wdata);
#else
        return process_write(main_time, (top->ram_waddr & 0x7ffffff), top->ram_wen, top->ram_wdata);
#endif
        //return process_write(main_time,(top->ram_waddr),top->ram_wen,top->ram_wdata);
        //return process_write128(main_time,top->ram_waddr&~0xf,top->ram_wen,top->ram_wdata);
    }
    return 0;
}

int CpuRam::breakpoint_save(vluint64_t main_time, const char *brk_file_name, struct UART_STA *uart_status) {
    FILE *brk_file;
    //int counter = 0;
    if ((brk_file = fopen(brk_file_name, "w")) == NULL) {
        printf("ram save breakpoint file open error!\n");
        exit(0);
    }

    fprintf(brk_file, "@main_time %ldns\n", main_time);
    printf("save ram break ponit %ldns to %s\n", main_time, brk_file_name);

    //save uart status
    fprintf(brk_file, "@uart_config %d\n", uart_status->uart_config);
    if (uart_status->uart_div_set == true)
        fprintf(brk_file, "@uart_div_set y\n");
    else
        fprintf(brk_file, "@uart_div_set n\n");

    if (uart_status->div_reinit == true)
        fprintf(brk_file, "@div_reinit y\n");
    else
        fprintf(brk_file, "@div_reinit n\n");

    fprintf(brk_file, "@div_val_1 %d\n", uart_status->div_val_1);
    fprintf(brk_file, "@div_val_2 %d\n", uart_status->div_val_2);
    fprintf(brk_file, "@div_val_3 %d\n", uart_status->div_val_3);

    //save ram
    for (int idx = 0; idx < tbsz; idx += 1) {
        vector<RamSection>::iterator e = mem[idx].end();
        vector<RamSection>::iterator j = mem[idx].begin();
        if (j == e)
            continue;
        fprintf(brk_file, "@idx %d\n", idx);
        for (; j != e; j += 1) {
            fprintf(brk_file, "@tag %ld\n", (unsigned long) j->tag);
            for (int data_idx = 0; data_idx < pgsz; data_idx++) {
                //use for debug
                /*
                if (counter == 0) {
                   fprintf(brk_file, "%1x%02x%05x:\n", j->tag, idx, data_idx);
                   counter = 4;
                }
                */
                fprintf(brk_file, "%02x\n", j->data[data_idx]);
                //counter -= 1;
            }
        }
    }
    fflush(brk_file);
    fclose(brk_file);
    return 1;
}

int CpuRam::breakpoint_restore(vluint64_t main_time, const char *brk_file_name, struct UART_STA *uart_status) {
    FILE *brk_file;
    if ((brk_file = fopen(brk_file_name, "r")) == NULL) {
        printf("ram restore breakpoint file open error!");
        exit(0);
    }

    unsigned long brk_point_main_time;
    if (fscanf(brk_file, "@main_time %ldns\n", &brk_point_main_time) == EOF) {
        printf("break point file format error at main_time!\n");
        exit(0);
    }

    if (brk_point_main_time != main_time) {
        printf("ram break point file not match!\n");
        exit(0);
    }
    printf("restore ram break point %ldns from %s\n", main_time, brk_file_name);

    //restore uart status
    char flag_tmp;
    fscanf(brk_file, "@uart_config %d\n", &uart_status->uart_config);
    fscanf(brk_file, "@uart_div_set %c\n", &flag_tmp);
    if (flag_tmp == 'y')
        uart_status->uart_div_set = true;
    else
        uart_status->uart_div_set = false;

    fscanf(brk_file, "@div_reinit %c\n", &flag_tmp);
    if (flag_tmp == 'y')
        uart_status->div_reinit = true;
    else
        uart_status->div_reinit = false;

    fscanf(brk_file, "@div_val_1 %d\n", &uart_status->div_val_1);
    fscanf(brk_file, "@div_val_2 %d\n", &uart_status->div_val_2);
    fscanf(brk_file, "@div_val_3 %d\n", &uart_status->div_val_3);

    //restore ram
    int idx;
    unsigned long tag;
    char rd_data;
    char tmp1[10];
    unsigned long tmp_data;
    unsigned char *data;
    while (fscanf(brk_file, "%s %ld\n", &tmp1, &tmp_data) != EOF) {
        if (tmp1[1] == 'i') {
            //fscanf(brk_file, "dx %d\n", &idx);
            //printf("@idx %ld\n", tmp_data);
            idx = (int) tmp_data;
            fscanf(brk_file, "@tag %ld\n", &tag);
            //printf("@tag %ld\n", tag);
            //printf("idx is %d\ntag is %ld\n", idx, tag);
            data = (unsigned char *) malloc(pgsz);
            for (int p = 0; p < pgsz; p++) {
                fscanf(brk_file, "%02x\n", &rd_data);
                //printf("%02x\n", rd_data);
                data[p] = rd_data;
            }
            RamSection sec1{.tag=tag, .data=data};
            mem[idx].push_back(sec1);
        } else if (tmp1[1] == 't') {
            //fscanf(brk_file, "ag %ld\n", &tag);
            //fscanf(brk_file, "@tag %ld\n", &tag);
            tag = tmp_data;
            //printf("tag is %ld\n", tag);
            data = (unsigned char *) malloc(pgsz);
            for (int p = 0; p < pgsz; p++) {
                fscanf(brk_file, "%02x\n", &rd_data);
                //printf("%02x\n", rd_data);
                data[p] = rd_data;
            }
            RamSection sec2{.tag=tag, .data=data};
            mem[idx].push_back(sec2);
        }
    }

    for (int idx = 0; idx < tbsz; idx += 1) {
        cur[idx] = mem[idx].end();
    }

    fclose(brk_file);
    return 1;
}

int CpuRam::special_read() {
#ifdef RAND_TEST
    unsigned long long base,offset;
        unsigned long long tlb_index;
        unsigned long long tlb_hi;
        unsigned long long tlb_lo0;
        unsigned long long tlb_lo1;
        #ifdef LA32
        offset = (read_addr & 0x1ff) >> 3;
        #else
        offset = (read_addr & 0x1ff) >> 4;
        #endif
        base   = read_addr & ~0x1ff;
        tlb_index = rand64->tlb->refill_index + (rand64->tlb->tlb_size << 24);
        //printf("tlb size = %llx\n",rand64->tlb->tlb_size);
        //printf("tlb size = %llx\n",rand64->tlb->tlb_size<<24);
        tlb_hi    = rand64->tlb->refill_vpn & ~0x1fff;
        tlb_lo0   = (rand64->tlb->pfn0<<8) + (rand64->tlb->cca0<<4) + (rand64->tlb->we0<<1)  + rand64->tlb->v0;
        tlb_lo1   = (rand64->tlb->pfn1<<8) + (rand64->tlb->cca1<<4) + (rand64->tlb->we1<<1)  + rand64->tlb->v1;
        if (base == (REG_INIT_ADDR&~0x1ff)) {
            #ifdef LA32
            process_read32_same(rand64->gr_ref[offset],top->ram_rdata);
            printf("Read 32 same\n");
            printf("speical read addr = %016llx\n",read_addr);
            printf("offset = %d\n",offset);
            printf("value     = %016llx\n",rand64->gr_ref[offset]);
            printf("ram rdata = %016llx\n",top->ram_rdata);
            #else
            process_read64_same(rand64->gr_ref[offset],top->ram_rdata);
            #endif
            //printf("base = %016llx offset = %016llx\n",base,offset);
            return 1;
        }
        int tlb_addr_matched = 0;
        if (base == (TLB_READ_ADDR&~0x1ff)){
            switch(offset)  {
                case(0):
                    //process_read64_same(tlb_index,top->ram_rdata);
                    process_read32_same(tlb_index,top->ram_rdata);
                    tlb_addr_matched = 1;

                   printf("tlb index = %016llx\n",tlb_index);
                   printf("tlb_hi    = %016llx\n",tlb_hi);
                   printf("tlb_lo0   = %016llx\n",tlb_lo0);
                   printf("tlb_lo1   = %016llx\n",tlb_lo1);
                   break;


                case(1):
                    //process_read64_same(tlb_hi,top->ram_rdata);
                    process_read32_same(tlb_hi,top->ram_rdata);
                    tlb_addr_matched = 1;
                    break;
                case(2):
                    //process_read64_same(tlb_lo0,top->ram_rdata);
                    process_read32_same(tlb_lo0,top->ram_rdata);
                    tlb_addr_matched = 1;
                    break;
                case(3):
                    //process_read64_same(tlb_lo1,top->ram_rdata);
                    process_read32_same(tlb_lo1,top->ram_rdata);
                    tlb_addr_matched = 1;
                    break;
                default:
                    printf("SHOULD NOT USE THIS ADDR AS NORMAL READ!!!\n");
            }
            //printf("base = %016llx offset = %016llx\n",base,offset);
        }
        return tlb_addr_matched;
#else
    return 0;
#endif
}

//128/256
void CpuRam::process_read64_same(vluint64_t data, unsigned* d) {
    d[0] = (int)(data & 0x00ffffffffLL);
    d[1] = (int)(data >> 32);
    d[2] = (int)(data & 0x00ffffffffLL);
    d[3] = (int)(data >> 32);
}
//64
void CpuRam::process_read64_same(vluint64_t data, vluint64_t &d) {
    d = data;
}
//128
void CpuRam::process_read32_same(vluint64_t data, unsigned* d) {
    d[0] = (int)(data & 0x00ffffffffLL);
    d[1] = (int)(data & 0x00ffffffffLL);
    d[2] = (int)(data & 0x00ffffffffLL);
    d[3] = (int)(data & 0x00ffffffffLL);
}
//64
void CpuRam::process_read32_same(vluint64_t data, vluint64_t &d) {
    d = (data & 0x00ffffffffLL) | (data<<32);
}
//32
void CpuRam::process_read32_same(vluint64_t data, unsigned int &d) {
    d = (int)(data & 0x00ffffffffLL);
}

void CpuRam::process_read128(vluint64_t main_time,vluint64_t a,unsigned* d){
    if(debug == 1) {
        fprintf(stderr,"Read Catch! %x,%d\n",a,simu_dev);
    }
    if(simu_dev && dev.in_space(debug,a)){
        d[0] = dev.read(main_time,a);
        d[1] = d[2] = d[3] = 0;
        fprintf(stderr,"Confreg Catch!\n");
    }
    else read16B(a,d);

    debug =0;
}

int CpuRam::process_write128(vluint64_t main_time,vluint64_t a,vluint64_t m,unsigned* d){
    if(simu_dev && dev.in_space(0,a))return dev.write(main_time,a,d[0]);
    else write16B(a,m,d);
    return 0;
}
// 128/256
void CpuRam::process_read(vluint64_t main_time,vluint64_t a,unsigned* d){
    a = a&~0xf;
    if(debug == 1) {
        fprintf(stderr,"Read Catch! %x,%d\n",a,simu_dev);
    }
    if(simu_dev && dev.in_space(debug,a)){
        d[0] = dev.read(main_time,a);
        d[1] = d[2] = d[3] = 0;
        fprintf(stderr,"Confreg Catch!\n");
    }
    else read16B(a,d);
    debug =0;
}

//64
void CpuRam::process_read(vluint64_t main_time,vluint64_t a,vluint64_t &d){
    a = a & ~0x7;
    if(simu_dev && dev.in_space(debug,a)){
        d = (vluint64_t)dev.read(main_time,a);
        fprintf(stderr,"Confreg Catch!\n");
    }
    else d = read64(a);
}

void CpuRam::process_read(vluint64_t main_time,vluint64_t a,unsigned int &d){
    a = a & ~0x3;
    if(simu_dev && dev.in_space(debug,a)){
        d = (int)dev.read(main_time,a);
        fprintf(stderr,"Confreg Catch!\n");
    }
    else d = (int)read32(a);


}

int CpuRam::process_write(vluint64_t main_time,vluint64_t a,vluint64_t m,unsigned* d){
    a = a &~0xf;
    if(simu_dev && dev.in_space(0,a))return dev.write(main_time,a,d[0]);
    else write16B(a,m,d);
    return 0;
}

int CpuRam::process_write(vluint64_t main_time,vluint64_t a,vluint64_t m,vluint64_t d){
    a = a &~0x7;
    //printf("wen = %08x\n",m);
    //printf("addr = %016lx\n",a);
    //printf("d = %016lx\n",d);
    if(simu_dev && dev.in_space(0,a))return dev.write(main_time,a,d);
    else write8B(a,m,d);
    return 0;
}

int CpuRam::process_write(vluint64_t main_time,vluint64_t a,vluint64_t m,unsigned int d){
    a = a &~0x3;
    if(simu_dev && dev.in_space(0,a))return dev.write(main_time,a,d);
    else write4B(a,m,d);
    return 0;
}

int CpuRam::read_random_vlog(){
    printf("Start load data vlog\n");
    FILE* data_vlog = fopen(this->data_vlog_file,"rt");
    assert(data_vlog!=nullptr);
    vluint64_t addr;
    int byte_num,data;
    char line[65];
    while(fgets(line,65,data_vlog)!=NULL){
        sscanf(line,"%llx %x  %x\n",&addr, &byte_num,&data);
        int data_temp = data;
        if (byte_num == 1) {
            int wen = 1<<(addr%4);
            data_temp = data_temp&0xff;
            data_temp = data_temp<<24 | data_temp<<16 | data_temp<<8 | data_temp;
            //printf("Wrint one byte %llx %x\n",addr,data_temp&0xff);
            //printf("%llx %x %x\n",addr%~0x3,wen,data_temp);
            write4B(addr&~0x3,wen,data_temp);
        } else {
            for (int i=0;i<byte_num;i++) {
                int wen = 1<<(addr%4);
                data_temp = data_temp&0xff;
                data_temp = data_temp<<24 | data_temp<<16 | data_temp<<8 | data_temp;
                write4B(addr&~0x3,wen,data_temp);
                data_temp = data>>(8*((i+1)%4));
                addr = addr+1;
            }
        }
    }
    printf("Finish load data vlog\n");
    return 0;
}
CpuRam::~CpuRam() {
    if (mem_out) {
        fclose(mem_out);
    }
    for (int idx = 0; idx < tbsz; idx += 1) {
        vector<RamSection>::iterator e = mem[idx].end();
        for (vector<RamSection>::iterator j = mem[idx].begin(); j != e; j += 1) {
            free(j->data);
            j->data = nullptr;
        }
    }
}
