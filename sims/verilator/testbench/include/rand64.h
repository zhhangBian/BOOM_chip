#ifndef CHIPLAB_RAND64_H
#define CHIPLAB_RAND64_H

#include "common.h"
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <cstring>
#include <string>
#include <vector>
#include <unordered_map>

#define RAND_TLB_TABLE_ENTRY 16384
#define TLB_READ_ADDR 0x00000600
#define REG_INIT_ADDR 0x00000000
#define ILLEGAL_PC_ADDR 0x00000800
#define RESERVE_PAGE_ADDR 0x08000000
#define TLB_WAYBIT 2
#define TLB_SETBIT 2
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
    unsigned long long refill_vpn;
    unsigned long long refill_index;

    std::unordered_map<long long, std::pair<long long, long long> > tlb_4k, tlb_4m;
    int size;
    long long lo0, lo1;

    Tlb(int tlb_entrys){
        tlb_entry_num = tlb_entrys;
        refill_index = 0;

    }
    int find_entry(long long bad_vaddr){
        refill_vpn = bad_vaddr;
        unsigned long long vpn4k = (bad_vaddr >> 13) & 0x7ffff;
        auto res4k = tlb_4k.find(vpn4k);
        if(res4k != tlb_4k.end()){
            printf("tlb 4k find:VPPN=%05llx, lo0=%08llx, lo1=%08llx\n", res4k->first, res4k->second.first, res4k->second.second);
            lo0 = res4k->second.first;
            lo1 = res4k->second.second;
            refill_vpn = vpn4k;
            size = 12;
            refill_index += 1;
            return 0;
        }
        unsigned long long vpn4m = (bad_vaddr >> 22) & 0x3ff;
        auto res4m = tlb_4m.find(vpn4m);
        if(res4m != tlb_4m.end()){
            printf("tlb 4m find:VPPN=%05llx, lo0=%08llx, lo1=%08llx\n", res4m->first, res4m->second.first, res4m->second.second);
            lo0 = res4m->second.first;
            lo1 = res4m->second.second;
            refill_vpn = vpn4m;
            size = 21;
            refill_index += 1;
            return 0;
        }
        printf("TLB not found!\n");
        return 1;
    }

 
};

class IllegalPC{
public:
    std::vector<long long> pc;
    std::vector<long long> next;
    size_t index;
    long long next_pc;
    bool valid, error;
    IllegalPC(int count){
        pc.reserve(count);
        next.reserve(count);
        error = valid = false;
        index = 0;
    }
    int find_next(long long epc){
        //since this is short, O(n) search should be acceptable
        valid = true;
        if(index < pc.size() && (pc[index] & 0xffffffffLL) == (epc & 0xffffffffLL)){
                next_pc = next[index];
                index++;
                printf("got next pc: %llx\n",next_pc);
                return 0;
        }
        printf("illegal pc not found, use PC + 4\n");
        next_pc = epc + 4;
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
    BinaryType* tlb_attr;
    HexType*    pcs;
    HexType*    result_addrs;
    HexType*    value1;
    HexType*    instructions;
    HexType*    init_regs;
    HexType*    illegal_pc;
    HexType*    illegal_pc_next;
    StrType*    comments;
	HexNormalType*	parameters;
    Tlb*        tlb;
    IllegalPC*  ipc;
    int         cpu_ex;
    int         tlb_ex;
    int         last_split;
    int         tlb_entry_num;
    int         illegal_pc_num;
   
    Rand64(const char* path);
    ~Rand64();

    int init_all();
    int init_gr_ref();
    int tlb_init();
    int illegal_pc_init();

    int read_next_compare();

    int print();
    void print_ref();
    void print_ref(long long *gr_rtl);

    int compare(long long *gr_rtl);

    int update(int commit_num, vluint64_t main_time);
    void update_once(vluint64_t main_time);

    int tlb_refill_once(long long bad_vaddr);

    int find_illegal_next_pc(long long epc);
};

#endif  // CHIPLAB_RAND64_H


