#ifndef CHIPLAB_RF_TRACE_H
#define CHIPLAN_RF_TRACE_H

#include "cpu_tool.h"
#include <zlib.h>
#include <cstring>

typedef struct RfTraceNode {
    vluint64_t pc;
    vluint64_t wa;
    vluint64_t wd;
}RfTraceNode;

class RfTraceBuffer {
public:
    int data_num;
    gzFile trace;
    FILE* trace_txt;
    static const int data_max = 3*4096;
    vluint64_t data[data_max];

    RfTraceBuffer(){
        trace     = nullptr;
        trace_txt = nullptr;
        data_num  = 0;
    }
    ~RfTraceBuffer(){
        dump();
        if(trace    !=nullptr)gzclose(trace    );trace     = nullptr;
        if(trace_txt!=nullptr) fclose(trace_txt);trace_txt = nullptr;
    }
    void dump(){
        if(data_num>0 && trace!=nullptr){
            gzwrite(trace,data,data_num<<3);
        }
        data_num = 0;
    }
    void push(vluint64_t wa,vluint64_t wd,vluint64_t pc){
        if(data_num >= data_max)dump();
        if(trace_txt!=nullptr)fprintf(trace_txt,"%016lx %02lx %016lx\n",pc,wa,wd);
        data[data_num  ] = pc;
        data[data_num+1] = wa;
        data[data_num+2] = wd;
        data_num += 3;
    }
    void open(const char* target){
        if(endswith(target,".gz"))trace = gzopen(target,"wb");
        else trace_txt = fopen(target,"wt");
    }
};

class CpuRfTrace:CpuTool
{
public:
    RfTraceBuffer buffer;
    gzFile cmp_trace;
    
    FILE* trace_txt;
    RfTraceNode cmp;
    int matched;
    vluint64_t gpr[32];
    CpuRfTrace(Vtop* top):CpuTool(top)
    {
        if(dump_rf_trace)buffer.open(rf_trace_ofile);
        cmp_trace = nullptr;
        trace_txt = nullptr;
        if(comp_rf_trace){
            if(endswith(rf_trace_ifile,".gz"))cmp_trace = gzopen(rf_trace_ifile,"rb");
            else trace_txt = fopen(rf_trace_ofile,"rt");
        }
        matched = 0;
        for(int i=0;i<32;i+=1)gpr[i] = 0;
    }
    ~CpuRfTrace()
    {
        if(cmp_trace    !=nullptr)gzclose(cmp_trace);cmp_trace=nullptr;
        if(trace_txt    !=nullptr)fclose(trace_txt    );trace_txt    =nullptr;
    }
    int load_next(){
        if(cmp_trace!=nullptr){
            int gzstate = gzread(cmp_trace,&cmp,24);
            if(gzstate!=Z_OK){
                gzclose(cmp_trace);cmp_trace = nullptr;
                printf("\n====All Trace Matched====\n");
                return 0;
            }
            matched += 1;
            return 1;
        }
        else if(trace_txt!=nullptr){
            int rnum = fscanf(trace_txt,"%ld %ld %ld",&cmp.pc,&cmp.wa,&cmp.wd);
            if(rnum<3){
                fclose(trace_txt);trace_txt = nullptr;
                printf("\n====All Trace Matched====\n");
                return 0;
            }
            matched += 1;
            return 1;
        }
        return 0;
    }
    void display_cmp_failed_start(vluint64_t wa,vluint64_t wd,vluint64_t pc){
        printf("Trace-matched failed.\n");
        printf("First %d entries matched.\n",matched);
        printf(">>>>result\n");
        printf("pc  :%016lx\n",pc);
        printf("dest:%02lx\n"  ,wa);
        printf("data:%016lx\n",wd);
    }
    void display_cmp_failed_end(){
        printf(">>>>answer\n");
        printf("pc  :%016lx\n",cmp.pc);
        printf("dest:%02lx\n"  ,cmp.wa);
        printf("data:%016lx\n",cmp.wd);
    }
    int process_one(vluint64_t wa,vluint64_t wd,vluint64_t pc){
        if(!comp_rf_trace && !dump_rf_trace)return 0;
        if((!rf_trace_no_repeat || gpr[wa]!=wd) && (wa != 0)){
            buffer.push(wa,wd,pc);
            gpr[wa] = wd;
        }
        if(cmp_trace!=nullptr){
            if(!load_next())return 0;
            int err = 0;
            err|=cmp.pc != pc;
            err|=cmp.wa != wa;
            err|=cmp.wd != wd;
            if(err){
                display_cmp_failed_start(wa,wd,pc);
                display_cmp_failed_end();
                return status_trace_err_rf;
            }
        }
        return 0;
    }
    int process(vluint64_t& main_time){
        int res = 0;
        #define DEBUG_RF(i) \
        if(top->debug##i##_wb_rf_wen)\
            if(res=process_one(top->debug##i##_wb_rf_wnum,top->debug##i##_wb_rf_wdata,top->debug##i##_wb_pc))\
                return res;
                /*
        DEBUG_RF(0)
        DEBUG_RF(1)
        */
        #undef DEBUG_RF
        return res;
    }
};

#endif  // CHIPLAN_RF_TRACE_H
