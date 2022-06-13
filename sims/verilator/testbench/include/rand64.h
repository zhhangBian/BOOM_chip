#ifndef CHIPLAB_RAND64_H
#define CHIPLAB_RAND64_H

#include "common.h"
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <cstring>
#include <string>
#include <vector>

#define RAND_TLB_TABLE_ENTRY 16384
#define EBASE_ADDR    0x1c001000
#define TLB_READ_ADDR 0x1c002000
#define REG_INIT_ADDR 0x1c003000
#define EX_TLBR    0x3f
#define EX_SYSCALL 0x0b
#define MASK(page_size) 	(0xffffffffffffffff<<page_size)

#ifdef LA32
// #define RAND_BUS_GR_RTL         0
// #define RAND_BUS_CPU_EX         1024
// #define RAND_BUS_ERET           1056
// #define RAND_BUS_EXCODE         1088
// #define RAND_BUS_EPC            1200
// #define RAND_BUS_BADVADDR       1232
// #define RAND_BUS_CMT_LAST_SPLIT 1264
// #define RAND_BUS_COMMIT_NUM     1296

#define RAND_BUS_GR_RTL         0
#define RAND_BUS_CPU_EX         32
#define RAND_BUS_ERET           33
#define RAND_BUS_EXCODE         34
#define RAND_BUS_EPC            35
#define RAND_BUS_BADVADDR       36
#define RAND_BUS_CMT_LAST_SPLIT 37
#define RAND_BUS_COMMIT_NUM     38
#else
#define RAND_BUS_CPU_EX         64
#define RAND_BUS_ERET           65
#define RAND_BUS_EXCODE         66
#define RAND_BUS_COMMIT_NUM     72
#define RAND_BUS_CMT_LAST_SPLIT 71
#define RAND_BUS_BADVADDR       69
#define RAND_BUS_GR_RTL         0
#endif

/*
class Rand64
{
public:
    ResultType *result_type;
};
*/

class BinaryType {
public:
    long long data;
    FILE* f;
    char testpath[128]; 
    BinaryType(const char* path,const char* file_name){
        sprintf(testpath,"./%s%s.res",path,file_name);
        printf("%s\n",testpath);
        f = fopen(testpath,"rt");
        data  = 0;
    }
    int read_next(){
        char line[65];
        if (!fgets(line,65,f))
            return 1;

        if (line[0]=='@'){
            if (!fgets(line,65,f))
                return 1;
        }
        char* temp;
        data = strtol(line,&temp,2);
        return 0;
    }
};

class HexType {
public:
    long long data;
    FILE* f;
    char testpath[128]; 
    HexType(const char* path,const char* file_name){
        sprintf(testpath,"./%s%s.res",path,file_name);
        printf("%s\n",testpath);
        f     = fopen(testpath,"rt");
        data  = 0;
    }
    int read_next(){
        char line[32];

        if (!fgets(line,32,f))
            return 1;

        if (line[0]=='@'){
            if (!fgets(line,32,f))
                return 1;
        }
        long long temp[8];
        sscanf(line,"%llx %llx %llx %llx %llx %llx %llx %llx \n",&temp[0],&temp[1],&temp[2],&temp[3],&temp[4],&temp[5],&temp[6],&temp[7]);
        data = temp[0] + (temp[1]<<8) + (temp[2]<<16) + (temp[3]<<24) + (temp[4]<<32) + (temp[5]<<40) + (temp[6]<<48) + (temp[7]<<56);
        return 0;
    }
};

class HexNormalType
{
public:
    long long data;
    FILE* f;
    char testpath[128]; 
    HexNormalType(const char* path,const char* file_name){
        sprintf(testpath,"./%s%s.res",path,file_name);
        printf("%s\n",testpath);
        f     = fopen(testpath,"rt");
        data  = 0;
    }
    int read_next(){
        char line[65];

        if (!fgets(line,65,f))
            return 1;

        if (line[0]=='@'){
            if (!fgets(line,65,f))
                return 1;
        }
        char* temp;
        data = strtoll(line,&temp,16);
        return 0;
    }
};
class StrType {
public:
    char data[128];
    FILE* f;
    char testpath[128]; 
    StrType(const char* path,const char* file_name){
        sprintf(testpath,"./%s%s.res",path,file_name);
        printf("%s\n",testpath);
        f     = fopen(testpath,"rt");
        strcpy(data,"");
    }
    int read_next(){
        if (!fgets(data,128,f))
            return 1;
        return 0;
    }
};

class Tlb {
public:
    int tlb_entry_num;
    std::vector<long long> vpn_table;
    std::vector<long long> pfn_table;
    std::vector<int      > cca      ;
    std::vector<int      > page_size;
    unsigned long long tlb_size;
    unsigned long long tlb_mask;
    unsigned long long refill_vpn;
    unsigned long long refill_index;
    unsigned long long pfn0;
    unsigned long long pfn1;
    unsigned int       cca0;
    unsigned int       cca1;
    unsigned int       we0;
    unsigned int       we1;
    unsigned int       v0;
    unsigned int       v1;
    Tlb(int tlb_entrys){
        tlb_entry_num = tlb_entrys;
        refill_index = 7;
        cca0 = 1;//todo gailv peizhi
        cca1 = 1;
        vpn_table.reserve(tlb_entrys);
        pfn_table.reserve(tlb_entrys);
        cca.reserve(tlb_entrys);
        page_size.reserve(tlb_entrys);

    }
    int find_entry(long long bad_vaddr){
        int i,j;
        int page_found;
        unsigned long long pfn0;
        unsigned long long pfn1;
        unsigned int  cca0;
        unsigned int  cca1;
        unsigned long long       we0;
        unsigned long long       we1;
        int page0_odd;
        int page_big = 0;
        page_found = 0;
        long long mask_temp = 0xfffffffff;
        for (i=0;i<tlb_entry_num;i++) {
            //if ((((bad_vaddr>>12) & (tlb_mask>>12))>>(tlb_size - 11)) == (vpn_table[i] & (tlb_mask>>12))>>(tlb_size - 11)) {
            if (page_size[i]==12) {
                if ((((bad_vaddr>>12) & (MASK(page_size[i]-12)))>>(page_size[i] - 11)) == (vpn_table[i] & mask_temp & (MASK(page_size[i]-12)))>>(page_size[i] - 11)) {
                    pfn0 = pfn_table[i]&0xfffffffffLL;
                    we0  = vpn_table[i]>>36;
                    cca0 = cca[i];
                    refill_vpn = bad_vaddr;
                    page_found += 1;
                    tlb_size = page_size[i];
                    break;
                }
            } else {
                if ((((bad_vaddr>>12) & (MASK(page_size[i]-12)))>>(page_size[i] - 12)) == (vpn_table[i] & mask_temp & (MASK(page_size[i]-12)))>>(page_size[i] - 12)) {
                    pfn0 = pfn_table[i]&0xfffffffffLL;
                    we0  = vpn_table[i]>>36;
                    cca0 = cca[i];
                    refill_vpn = bad_vaddr;
                    page_found += 1;
                    tlb_size = page_size[i] - 1;
                    page_big = 1;
                    printf("Find a big page. Seperate to two pages\n");
                    break;
                    }
                }
        }
        if (!page_big) {
            for (j=i+1;j<tlb_entry_num;j++) {
                if (page_size[j] == page_size[i]) {
                    //if ((((bad_vaddr>>12) & (tlb_mask>>12))>>(tlb_size - 11)) == (vpn_table[j] & (tlb_mask>>12))>>(tlb_size - 11)) {
                    if ((((bad_vaddr>>12) & (MASK(page_size[i]-12)))>>(page_size[i] - 11)) == (vpn_table[j] & mask_temp & (MASK(page_size[i]-12)))>>(page_size[i] - 11)) {
                        pfn1 = pfn_table[j]&0xfffffffffLL;
                        we1  = vpn_table[j]>>36;
                        cca1 = cca[j];
                        page_found += 1;
                        break;
                    }
                }
            }
        }

        if (page_found == 0) {
            printf("TLB ENTRY NOT FOUND\n");
            return 1;
        }

        if (page_big) {
            this->pfn0 = pfn0;
            this->we0         = we0;
            this->cca0        = cca0;
            this->v0          = 1;

            this->pfn1 = pfn0 + (1<<(page_size[i]-13));
            this->we1         = we0;
            this->cca1        = cca0;
            this->v1          = 1;
            refill_index += 1;
            refill_index &= 0x7;
            return 0;
        }

        //4KB page found. Need to check one or two entry.
        page0_odd = (vpn_table[i] >> (page_size[i] - 12))& 1;
        if (page_found == 1) {
            if (page0_odd) {
                this->pfn0 = 0;
                this->we0         = 0;
                this->cca0        = 0;
                this->v0          = 0;

                this->pfn1 = pfn0;
                this->we1         = we0;
                this->cca1        = cca0;
                this->v1          = 1;
            }
            else {
                this->pfn1 = 0;
                this->we1         = 0;
                this->cca1        = 0;
                this->v1          = 0;

                this->pfn0 = pfn0;
                this->we0         = we0;
                this->cca0        = cca0;
                this->v0          = 1;
            }
        } else {
            if (page0_odd) {
                this->pfn0        = pfn1;
                this->we0         = we1;
                this->cca0        = cca1;
                this->v0          = 1;

                this->pfn1 = pfn0;
                this->we1         = we0;
                this->cca1        = cca0;
                this->v1          = 1;
            }
            else {
                this->pfn1 = pfn1;
                this->we1         = we1;
                this->cca1        = cca1;
                this->v1          = 1;

                this->pfn0 = pfn0;
                this->we0         = we0;
                this->cca0        = cca0;
                this->v0          = 1;
            }
        }
    refill_index += 1;
    refill_index &= 0x7;
    return 0;
    }

 
};

class Rand64 {
public:
    char testpath[128];
    char flagpath[128];
    long long gr_ref[32];
    BinaryType* result_type;
    BinaryType* vpn;
    BinaryType* pfn;
    BinaryType* cca;
    BinaryType* page_size;
    HexType*    pcs;
    HexType*    result_addrs;
    HexType*    value1;
    HexType*    instructions;
    HexType*    init_regs;
    StrType*    comments;
	HexNormalType*	parameters;
    Tlb*        tlb;
    int         cpu_ex;
    int         tlb_ex;
    int         last_split;
    int         tlb_entry_num;
   
    Rand64(const char* path);
    ~Rand64();

    int init_all();
    int init_gr_ref();
    int tlb_init();

    int read_next_compare();

    int print();
    void print_ref();
    void print_ref(long long *gr_rtl);

    int compare(long long *gr_rtl);

    int update(int commit_num, vluint64_t main_time);
    void update_once(vluint64_t main_time);

    int tlb_refill_once(long long bad_vaddr);
};

#endif  // CHIPLAB_RAND64_H


