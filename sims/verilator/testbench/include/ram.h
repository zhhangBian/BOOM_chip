#ifndef CHIPLAB_RAM_H
#define CHIPLAB_RAM_H

#include "common.h"
#include "cpu_tool.h"
#include "devices.h"
#include "rand64.h"
#include "uart.h"
#include <vector>
#include <tuple>

using std::vector;
using std::tuple;

class RamSection {
public:
    vluint64_t  tag;
    unsigned char* data;
};

class CpuRam: CpuTool {
public:
    FILE* mem_out;
    char mem_out_path[128];
    static const int tbwd = 8;
    static const int pgwd = 20;
    static const int tbsz = 1<<tbwd;
    static const int pgsz = 1<<pgwd;
    static const vluint64_t tbmk = ~((1<<(tbwd+pgwd))-1);
    vector<RamSection> mem[tbsz];
    vector<RamSection>::iterator cur[tbsz];
    Rand64* rand64;
    CpuDevices dev;

    bool ram_read_mark = false;
    int debug = 0;

    int dead_clk = 0;
    
    int read_valid;
    vluint64_t read_addr ;
    inline int find(vluint64_t ptr){
        vluint64_t idx = (ptr>>pgwd)&(tbsz-1);
        vluint64_t tag = ptr&tbmk;
        return find(tag,idx);
    }
    inline void jump(vluint64_t ptr){
        vluint64_t idx = (ptr>>pgwd)&(tbsz-1);
        vluint64_t tag = ptr&tbmk;
        jump(tag,idx);
    }
    int find(vluint64_t tag,vluint64_t idx){
        // when no page is found, return 1
        vector<RamSection>& pages = mem[idx];
        if(pages.begin() == pages.end())return 1;
        vector<RamSection>::iterator& t = cur[idx];
        if(t == pages.end()){
            t = pages.end() - 1;
        }
        else if(tag > t->tag){
            do{
                t++;
                if(t == pages.end())
                    return 1;
            } while(tag > t->tag);
            return t->tag != tag;
        }
        while(t != pages.begin() && tag < t->tag)
            t--;
        return t->tag != tag;
    }
    void jump(vluint64_t tag,vluint64_t idx){
        int miss = find(tag,idx);
        if(!miss)return;
        unsigned char* data = (unsigned char*)malloc(pgsz);
        memset(data,0,pgsz);
        int k = cur[idx] - mem[idx].begin();
        RamSection sec{.tag=tag,.data=data};
        if((k + 1 == mem[idx].size() && tag > cur[idx]->tag) || k == mem[idx].size()){
            mem[idx].push_back(sec);
            cur[idx] = mem[idx].end() - 1;
            assert(cur[idx]->tag == tag);
        }
        else {
            k += (tag > cur[idx]->tag);
            mem[idx].insert(mem[idx].begin() + k,sec);
            if (mem[idx][k+1].tag <= mem[idx][k].tag) {
                printf("tag = %ld\n", tag);
                printf("mem[%d][%d].tag = %ld\n", idx, k+1, mem[idx][k+1].tag);
                printf("mem[%d][%d].tag = %ld\n", idx, k, mem[idx][k].tag);
                printf("mem[%d].size = %d\n", idx, mem[idx].size());
                exit(1);
            }
            assert(k==0||mem[idx][k].tag > mem[idx][k-1].tag);
            cur[idx] = mem[idx].begin() + k;
        }
    }

    CpuRam(Vtop* top,Rand64* rand64,vluint64_t main_time,struct UART_STA *uart_status,const char*mem_path);
    ~CpuRam();

    inline vluint64_t conv_hex2int64(const char* buf,const int width){
        vluint64_t data = 0,h = 0;
        for(int i=0;i<width;i+=1){
            h = ('a'<=buf[i])?buf[i]-'a'+10:buf[i]-'0';
            data =(data<<4)|h;
        }
        return data;
    }

    unsigned read32(vluint64_t a){
        vluint64_t tag = a&tbmk;
        vluint64_t idx = (a>>pgwd)&(tbsz-1);
        
        int miss = find(tag,idx);
        #ifdef READ_MISS_CHECK
        if(miss){
            fprintf(stderr,"Read Miss For Addr%lx.\n",a);
        }
        #endif
        unsigned val = miss?0:((unsigned*)cur[idx]->data)[(a&(pgsz-1))>>2];
        return val;
    }
    vluint64_t read64(vluint64_t a){
        vluint64_t tag = a&tbmk;
        vluint64_t idx = (a>>pgwd)&(tbsz-1);
        int miss = find(tag,idx); 
        #ifdef READ_MISS_CHECK
        if(miss){
            fprintf(stderr,"Read Miss For Addr%lx.\n",a);
        }
        #endif
        vluint64_t val = miss?0:((vluint64_t*)cur[idx]->data)[(a&(pgsz-1))>>3];
        return val;
    }
    inline vluint64_t encwm32(const unsigned e) const {
        vluint64_t m = 0;
        if((e&0xf)==0xf)m|=0xffffffff;
        else if(e&0xf){
            m|= (e&0x1)?0x000000ff:0;
            m|= (e&0x2)?0x0000ff00:0;
            m|= (e&0x4)?0x00ff0000:0;
            m|= (e&0x8)?0xff000000:0;
        }
        return m;
    }
    inline vluint64_t encwm64(const unsigned e) const {
        return encwm32(e)|(encwm32(e>>4)<<32);
    }
    void write64(vluint64_t a,vluint64_t m,vluint64_t d){
        vluint64_t tag = a&tbmk;
        vluint64_t idx = (a>>pgwd)&(tbsz-1);
        jump(tag,idx);
        assert(tag==cur[idx]->tag);
        vluint64_t& data = ((vluint64_t*)cur[idx]->data)[(a&(pgsz-1))>>3];
        //printf("write 64\n");
        //printf("addr = %016lx\n",a);
        //printf("d    = %016lx\ndata = %016lx\nm    = %016lx\n",d,data,m);
        data = d&m|data&~m;
        //printf("data = %016lx\n",data);
    }
    void write32(vluint64_t a,vluint64_t m,unsigned d){
        vluint64_t tag = a&tbmk;
        vluint64_t idx = (a>>pgwd)&(tbsz-1);
        jump(tag,idx);
        assert(tag==cur[idx]->tag);
        unsigned& data = ((unsigned*)cur[idx]->data)[(a&(pgsz-1))>>2];
        data = d&m|data&~m;
        //printf("write 32\n");
    }
    inline void write4B(vluint64_t a,vluint64_t m,unsigned d){write32(a,encwm32(m),d);}
    inline void write8B(vluint64_t a,vluint64_t m,vluint64_t d){write64(a,encwm64(m),d);}
    inline void write16B(vluint64_t a,vluint64_t m,unsigned* d){
        write32(a   ,encwm32(m    ),d[0]);
        write32(a+ 4,encwm32(m>> 4),d[1]);
        write32(a+ 8,encwm32(m>> 8),d[2]);
        write32(a+12,encwm32(m>>12),d[3]);
    }
    inline void read16B(vluint64_t a,unsigned* d){
        d[0] = read32(a   );
        d[1] = read32(a+ 4);
        d[2] = read32(a+ 8);
        d[3] = read32(a+12);
    }
    int process(vluint64_t main_time){

        #ifdef RAND_TEST
        if (process_rand(main_time)) {
            return 1;
        }
        if(read_valid){
            if (!special_read()) {
                process_read(main_time,read_addr,top->ram_rdata);
            }
            read_valid = 0;
        }
        #else 
        if (read_valid){
            process_read(main_time,read_addr,top->ram_rdata);
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
        if(read_valid){
            if ((top->ram_raddr & 0xff000000) == 0x1c000000) {
                read_addr = (top->ram_raddr);
            }
            else 
                #ifdef RUN_FUNC
                read_addr  = (top->ram_raddr);
                #else
                read_addr  = (top->ram_raddr&0x07ffffff);
                #endif
            ram_read_mark = true;
        }
        if(top->ram_wen){
            #ifdef MEM_TRACE
            fprintf(mem_out, "[%010dns] mem wr: pc = %08x, addr = %08x, data = %08x\n", main_time, top->debug0_wb_pc, top->ram_waddr&0x7ffffff, top->ram_wdata);
            #endif 
            #ifdef RUN_FUNC
            return process_write(main_time,(top->ram_waddr),top->ram_wen,top->ram_wdata);
            #else
            return process_write(main_time,(top->ram_waddr&0x7ffffff),top->ram_wen,top->ram_wdata);
            #endif
            //return process_write(main_time,(top->ram_waddr),top->ram_wen,top->ram_wdata);
            //return process_write128(main_time,top->ram_waddr&~0xf,top->ram_wen,top->ram_wdata);
        }
        return 0;
    }

	int breakpoint_save(vluint64_t main_time, const char* brk_file_name, struct UART_STA *uart_status){ 
		FILE* brk_file;
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
		for(int idx=0; idx<tbsz; idx+=1) {
			vector<RamSection>::iterator e = mem[idx].end();
			vector<RamSection>::iterator j = mem[idx].begin();
			if (j == e)
				continue;
			fprintf(brk_file, "@idx %d\n", idx);
			for (; j!=e; j+=1) {
				fprintf(brk_file, "@tag %ld\n", (unsigned long)j->tag);
				for (int data_idx=0; data_idx<pgsz; data_idx++){
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

	int breakpoint_restore(vluint64_t main_time,  const char* brk_file_name, struct UART_STA *uart_status) {
		FILE* brk_file;
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
		unsigned char* data;
		while(fscanf(brk_file, "%s %ld\n", &tmp1, &tmp_data) != EOF) {
			if (tmp1[1] == 'i') {
				//fscanf(brk_file, "dx %d\n", &idx);
                //printf("@idx %ld\n", tmp_data);
				idx = (int)tmp_data;
				fscanf(brk_file, "@tag %ld\n", &tag);
                //printf("@tag %ld\n", tag);
				//printf("idx is %d\ntag is %ld\n", idx, tag);
				data = (unsigned char*)malloc(pgsz);
				for (int p=0; p<pgsz; p++) {
					fscanf(brk_file, "%02x\n", &rd_data);
                    //printf("%02x\n", rd_data);
					data[p] = rd_data;
				}
				RamSection sec1{.tag=tag, .data=data};
				mem[idx].push_back(sec1);
			}
			else if (tmp1[1] == 't') {
				//fscanf(brk_file, "ag %ld\n", &tag);
				//fscanf(brk_file, "@tag %ld\n", &tag);
				tag = tmp_data;
				//printf("tag is %ld\n", tag);
				data = (unsigned char*)malloc(pgsz);
				for (int p=0; p<pgsz; p++) {
					fscanf(brk_file, "%02x\n", &rd_data);
                    //printf("%02x\n", rd_data);
					data[p] = rd_data;
				}
				RamSection sec2{.tag=tag, .data=data};
				mem[idx].push_back(sec2);
			}
		}

        for(int idx=0;idx<tbsz;idx+=1){
            cur[idx] = mem[idx].end();
        }

        fclose(brk_file);

		return 1;
	}

    #ifdef RAND_TEST
    int process_rand(vluint64_t main_time) {
        int cpu_ex = top->rand_test_bus[RAND_BUS_CPU_EX];
        int eret   = top->rand_test_bus[RAND_BUS_ERET];
        int excode = top->rand_test_bus[RAND_BUS_EXCODE];
        int commit_num     = top->rand_test_bus[RAND_BUS_COMMIT_NUM];
        int cmt_last_split = top->rand_test_bus[RAND_BUS_CMT_LAST_SPLIT];
        int cpu_ex_next = rand64->cpu_ex;
        int tlb_ex_next = rand64->tlb_ex;
        #ifdef RAND32
        long long bad_vaddr = (long long)top->rand_test_bus[RAND_BUS_BADVADDR];
        #else 
        long long bad_vaddr = (long long)top->rand_test_bus[RAND_BUS_BADVADDR] | ((long long)top->rand_test_bus[RAND_BUS_BADVADDR+1]<<32);
        #endif
        long long gr_rtl[32];

        // get gr value from rtl
        gr_rtl[0] = 0;
        for (int i=1;i<32;i++) {
            #ifdef RAND32
            gr_rtl[i] = (long long)top->rand_test_bus[i+RAND_BUS_GR_RTL];
            #else
            gr_rtl[i] = (long long)top->rand_test_bus[2*i+RAND_BUS_GR_RTL] + ((long long)top->rand_test_bus[2*i+1]<<32+RAND_BUS_GR_RTL);
            #endif
            //printf("gr rt[%02d] = %08llx\n",i,gr_rtl[i]);
        }
        
        if (rand64->tlb_ex) {
            printf("=========================================================\n");
            printf("rand64 c++ version tlb refill start\n");
            printf("Looking for this address: %llx\n",bad_vaddr);
            if (rand64->tlb_refill_once(bad_vaddr)) {
                printf("Error when tlb refill\n");
                fprintf(rand64->result_flag, "RUN FAIL!\n");
                return 1;
            }
            int local_num = rand64->tlb->v0 + rand64->tlb->v1;
            printf("Found %d entry\n",local_num);
            tlb_ex_next = 0;
            printf("=========================================================\n");
        }
        // skip check if under cpu_ex or the last commit is splitted
        // Note. multiple issue core might commit several value with a new ex occured in one clock.
        if (!rand64->cpu_ex&&!rand64->last_split) {
            if(rand64->compare(gr_rtl)) {
                printf("REGSTER NOT MATCH!!!\n");
                fprintf(rand64->result_flag, "RUN FAIL!\n");
                rand64->print_ref(gr_rtl);
                return 1;
            }
        }

        if (eret) {
            cpu_ex_next = 0;
            tlb_ex_next = 0;
            printf("\nBegin compare\n\n");
        } else if (cpu_ex) {
            printf("CPU EX\n");
            printf("Main time = %d\n",main_time);
            cpu_ex_next = 1;
            if (excode == EX_SYSCALL) {
                printf("SYSCALL DETECTED\n");
                printf("Rand TEST END\n");
                fprintf(rand64->result_flag, "RUN PASS!\n");
                return 1;
            } else if (excode == EX_TLBR) {
                printf("TLB EX\n");
                tlb_ex_next = 1;
            }
            else {
                printf("CPU unexpect EX\n");
                printf("Random Test End\n");
                fprintf(rand64->result_flag, "RUN FAIL!\n");
                return 1;
            }
        }

        if (!rand64->cpu_ex&&!eret) {
            rand64->update(commit_num, main_time);
        }

        rand64->cpu_ex = cpu_ex_next;
        rand64->tlb_ex = tlb_ex_next;
        rand64->last_split = cmt_last_split;
             
        if(commit_num == 0){
            dead_clk++; 
        }
        else{
            dead_clk = 0;
        }

        if(dead_clk > 10000){
            printf("CPU status no change for 10000 clocks, simulation must exist error!!!!\n");
            printf("Random Test End\n");
            fprintf(rand64->result_flag, "RUN FAIL!\n");
            return 1;
        }
    
        return 0;
    }
    #endif
    int special_read() {
        #ifdef RAND_TEST
        unsigned long long base,offset;
        unsigned long long tlb_index;
        unsigned long long tlb_hi;
        unsigned long long tlb_lo0;
        unsigned long long tlb_lo1;
        #ifdef RAND32
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
            #ifdef RAND32
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
    void process_read64_same(vluint64_t data, unsigned* d) {
        d[0] = (int)(data & 0x00ffffffffLL);
        d[1] = (int)(data >> 32);
        d[2] = (int)(data & 0x00ffffffffLL);
        d[3] = (int)(data >> 32);
    }
    //64
    void process_read64_same(vluint64_t data, vluint64_t &d) {
        d = data;
    }
    //128
    void process_read32_same(vluint64_t data, unsigned* d) {
        d[0] = (int)(data & 0x00ffffffffLL);
        d[1] = (int)(data & 0x00ffffffffLL);
        d[2] = (int)(data & 0x00ffffffffLL);
        d[3] = (int)(data & 0x00ffffffffLL);
    }
    //64
    void process_read32_same(vluint64_t data, vluint64_t &d) {
        d = (data & 0x00ffffffffLL) | (data<<32);
    }
    //32
    void process_read32_same(vluint64_t data, unsigned int &d) {
        d = (int)(data & 0x00ffffffffLL);
    }

    void process_read128(vluint64_t main_time,vluint64_t a,unsigned* d){
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

    int process_write128(vluint64_t main_time,vluint64_t a,vluint64_t m,unsigned* d){
        if(simu_dev && dev.in_space(0,a))return dev.write(main_time,a,d[0]);
        else write16B(a,m,d);
        return 0;
    }
    // 128/256
    void process_read(vluint64_t main_time,vluint64_t a,unsigned* d){
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
    void process_read(vluint64_t main_time,vluint64_t a,vluint64_t &d){
        a = a & ~0x7;
        if(simu_dev && dev.in_space(debug,a)){
            d = (vluint64_t)dev.read(main_time,a);
            fprintf(stderr,"Confreg Catch!\n");
        }
        else d = read64(a);
    }

    void process_read(vluint64_t main_time,vluint64_t a,unsigned int &d){
        a = a & ~0x3;
        if(simu_dev && dev.in_space(debug,a)){
            d = (int)dev.read(main_time,a);
            fprintf(stderr,"Confreg Catch!\n");
        }
        else d = (int)read32(a);

        
    }

    int process_write(vluint64_t main_time,vluint64_t a,vluint64_t m,unsigned* d){
        a = a &~0xf;
        if(simu_dev && dev.in_space(0,a))return dev.write(main_time,a,d[0]);
        else write16B(a,m,d);
        return 0;
    }

    int process_write(vluint64_t main_time,vluint64_t a,vluint64_t m,vluint64_t d){
        a = a &~0x7;
        //printf("wen = %08x\n",m);
        //printf("addr = %016lx\n",a);
        //printf("d = %016lx\n",d);
        if(simu_dev && dev.in_space(0,a))return dev.write(main_time,a,d);
        else write8B(a,m,d);
        return 0;
    }

    int process_write(vluint64_t main_time,vluint64_t a,vluint64_t m,unsigned int d){
        a = a &~0x3;
        if(simu_dev && dev.in_space(0,a))return dev.write(main_time,a,d);
        else write4B(a,m,d);
        return 0;
    }

};

#endif  // CHIPLAB_RAM_H