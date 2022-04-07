#ifndef CHIPLAB_COMMON_H
#define CHIPLAB_COMMON_H

#ifndef NUM_CORES
#define NUM_CORES 1
#endif

#ifndef FIRST_INST_ADDRESS
#define FIRST_INST_ADDRESS 0x1c000000
#endif

/* nemu memory size */
#define EMU_RAM_SIZE (4 * 1024 * 1024 * 1024UL) // 4 GB

#include <verilated_save.h>
#include "Vsimu_top.h"
typedef Vsimu_top Vtop;

#endif //CHIPLAB_COMMON_H
