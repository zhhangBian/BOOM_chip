#ifndef CHIPLAB_DEVICES_H
#define CHIPLAB_DEVICES_H

#include "cpu_tool.h"

class CpuDevices:public CpuTool
{
public:
    int timer_base;
    static const vluint64_t device_space = 0x8fe00000llu;
    static const vluint64_t mask = 0xffffllu;
    static const int offs_uart = 0x1000;
    static const int offs_time = 0x5000;

    CpuDevices();

    unsigned read(vluint64_t main_time,vluint64_t a);
    int write(vluint64_t main_time,vluint64_t a,vluint64_t d);

    inline int in_space(int debug,vluint64_t addr){
        //if(debug ==1) fprintf(stderr,"%x,compare %x with %x\n",addr,addr&~mask,device_space);
        //vluint64_t i = (unsigned)(addr&~mask) == device_space;
        //if(debug ==1) fprintf(stderr,"compare result: %d\n",i);
        return (unsigned)(addr&~mask)==device_space;
    }
};

#endif  // CHIPLAB_DEVICES_H
