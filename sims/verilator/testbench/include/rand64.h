#ifndef CHIPLAB_RAND64_H
#define CHIPLAB_RAND64_H

#include "common.h"
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <cstring>
#include <string>

#define RAND_TLB_TABLE_ENTRY 16384
#define EBASE_ADDR    0x1c001000
#define TLB_READ_ADDR 0x1c002000
#define REG_INIT_ADDR 0x1c003000
#define EX_TLBR    0x3f
#define EX_SYSCALL 0x0b

#ifdef RAND32
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
    long long vpn_table[RAND_TLB_TABLE_ENTRY];
    long long pfn_table[RAND_TLB_TABLE_ENTRY];
    int       cca[RAND_TLB_TABLE_ENTRY];
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
    Tlb(){
        refill_index = 7;
        cca0 = 1;//todo gailv peizhi
        cca1 = 1;
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
        page_found = 0;
        for (i=0;i<RAND_TLB_TABLE_ENTRY;i++) {
            if ((((bad_vaddr>>12) & (tlb_mask>>12))>>(tlb_size - 11)) == (vpn_table[i] & (tlb_mask>>12))>>(tlb_size - 11)) {
                pfn0 = pfn_table[i]&0xfffffffffLL;
                we0  = vpn_table[i]>>36;
                cca0 = cca[i];
                refill_vpn = bad_vaddr;
                page_found += 1;
                break;
            }
        }
        for (j=i+1;j<RAND_TLB_TABLE_ENTRY;j++) {
            if ((((bad_vaddr>>12) & (tlb_mask>>12))>>(tlb_size - 11)) == (vpn_table[j] & (tlb_mask>>12))>>(tlb_size - 11)) {
                pfn1 = pfn_table[j]&0xfffffffffLL;
                we1  = vpn_table[j]>>36;
                cca1 = cca[j];
                page_found += 1;
                break;
            }
         }

        if (page_found == 0) {
            printf("TLB ENTRY NOT FOUND\n");
            return 1;
        }
        page0_odd = (vpn_table[i] >> (tlb_size - 12))& 1;
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
    FILE* result_flag;
    long long gr_ref[32];
    BinaryType* result_type;
    BinaryType* vpn;
    BinaryType* pfn;
    HexType*    pcs;
    HexType*    result_addrs;
    HexType*    value1;
    HexType*    instructions;
    HexType*    init_regs;
    StrType*    comments;
    Tlb*        tlb;
    int         cpu_ex;
    int         tlb_ex;
    int         last_split;
   
    Rand64(const char* path, const char* result_flag_path);

    ~Rand64();

    int init_all(){
        int error = 0;
        error |= init_gr_ref();
        error |= tlb_init();
        return error;
    }
    int init_gr_ref(){
        for (int i=0;i<32;i++) {
            if(!init_regs->read_next()) {
                gr_ref[i] = init_regs->data;
            }
            else {
                return 1;
            }
        }
        return 0;
    }
    int tlb_init(){
        int error=0;
        int i,j;
        printf("TLB INIT\n");
        printf("Max entry = %d\n",RAND_TLB_TABLE_ENTRY);
        srand(CACHE_SEED);
        for (i=0;i<RAND_TLB_TABLE_ENTRY;i++) {
            error |= vpn->read_next();
            error |= pfn->read_next();
            tlb->vpn_table[i] = vpn->data;
            tlb->pfn_table[i] = pfn->data;
            tlb->cca[i] = rand()%2;
        }
        
        if (error) {
            printf("TLB INIT Might be wrong\n"); 
            fprintf(result_flag, "RUN FAIL!\n");
            return 1;
        } else {
            error |= vpn->read_next();
        }
        tlb->tlb_size = vpn->data;
        printf("READ TLB ENTRY FINISHED\n");
        printf("READING TLB PAGE SIZE\n");
        switch(tlb->tlb_size) {
            case (12):
                tlb->tlb_mask = 0x0fffffffff000LL;
                break;
            case (13):
                tlb->tlb_mask = 0x0ffffffffe000LL;
                break;
            case (14):
                tlb->tlb_mask = 0x0ffffffffc000LL;
                break;
            case (15):
                tlb->tlb_mask = 0x0ffffffff8000LL;
                break;
            case (16):
                tlb->tlb_mask = 0x0ffffffff0000LL;
                break;
            default:
                tlb->tlb_mask = 0;
                printf("NO THIS SIZE\n");
                printf("i = %d,SIZE = %x\n",i,tlb->tlb_size);
                
        }
                printf("i = %d,SIZE = %x\n",i,tlb->tlb_size);

        int count;
        for (i=0;i<RAND_TLB_TABLE_ENTRY;i++) { 
            count = 0;
            for (j=i+1;j<RAND_TLB_TABLE_ENTRY;j++) {
                if ((tlb->pfn_table[j]&(tlb->tlb_mask>>12)) == (tlb->pfn_table[i]&(tlb->tlb_mask>>12))) {
                    tlb->cca[j] = tlb->cca[i];
                    count += 1;
                    if (count == 3)
                        break;
                }
            }
        }
        return 0;

    }
    int read_next_compare(){
        int error=0;
        error |= result_type->read_next();
        error |= pcs->read_next();
        error |= result_addrs->read_next();
        error |= value1->read_next();
        error |= instructions->read_next();
        error |= comments->read_next();
        return error;
    }
    int print(){
        printf("%llx\n",result_type->data);
        printf("%llx\n",vpn->data);
        printf("%llx\n",pfn->data);
        printf("%llx\n",pcs->data);
        printf("%llx\n",result_addrs->data);
        printf("%llx\n",value1->data);
        printf("%llx\n",instructions->data);
        return 0;
    }
    void print_ref() {
        for (int i=0;i<32;i++) {
            #ifdef RAND32
            printf("gr_ref[%02d] = %08llx\n",i,gr_ref[i]&0xffffffffll);
            #else
            printf("gr_ref[%02d] = %016llx\n",i,gr_ref[i]);
            #endif
        }
        //fr
        return;
    }
    void print_ref(long long *gr_rtl) {
         for (int i=0;i<32;i++) {
            #ifdef RAND32
            printf("gr_ref[%02d] = %08llx%010sgr_rtl[%02d] = %08llx\n",i,gr_ref[i]&0xffffffffll,"",i,gr_rtl[i]&0xffffffffll);
            #else
            printf("gr_ref[%02d] = %016llx%010sgr_rtl[%02d] = %016llx\n",i,gr_ref[i],"",i,gr_rtl[i]);
            #endif
        }

    }
    int compare(long long *gr_rtl) {
        for (int i=1;i<32;i++) {
            #ifdef RAND32
            if ((int)gr_rtl[i]!=(int)gr_ref[i]) {
            #else
            if (gr_rtl[i]!=gr_ref[i]) {
            #endif
            printf("gr_ref[%02d] = %016llx%010sgr_rtl[%02d] = %016llx\n",i,gr_ref[i],"",i,gr_rtl[i]);
            printf("Compare Fail\n");
            fprintf(result_flag, "RUN FAIL!\n");
                return 1;
            }
        }
        return 0;
    }
    int update(int commit_num, vluint64_t main_time) {
        if (!commit_num) {
            return 0;
        }
        printf("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
        //printf("++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
        for (int i=0;i<commit_num;i++) {
            if (read_next_compare()) {
                printf("Update Fail\n");
                fprintf(result_flag, "RUN FAIL!\n");
                return 1;
            }
            update_once(main_time);
        }
        printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
        printf("\n\n");
        return 0;
    }
    void update_once(vluint64_t main_time) {
    if (result_addrs->data == 0)
        return;
    printf("[%dns] Updating ref reg, instruction is %08x, pc is 0x%016x, result_type is 0x%0x\n",main_time,instructions->data,pcs->data,result_type->data);
    printf("Inst assembly is %s\n",comments->data);
        switch(result_type->data) {
            case 0:
                break;
            case 1:
                gr_ref[result_addrs->data] = value1->data;
                printf("Update Value = %016llx\n\n",value1->data);
                break;
            case 2:
                break;
            default:
                printf("other case\n");
                printf("result type=%llx\n\n",result_type->data);
                break;
        }
    }
    int tlb_refill_once(long long bad_vaddr) {
        return tlb->find_entry(bad_vaddr);
    }
};

#endif  // CHIPLAB_RAND64_H


