#ifndef CHIPLAB_TIME_LIMIT_H
#define CHIPLAB_TIME_LIMIT_H

#include "cpu_tool.h"

class CpuTimeLimit:public CpuTool
{
public:
    vluint64_t time_max;

    CpuTimeLimit();

    int process(vluint64_t& main_time);
};

#endif  // CHIPLAB_TIME_LIMIT_H