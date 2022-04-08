#include "time_limit.h"

CpuTimeLimit::CpuTimeLimit() : CpuTool(nullptr) {
    time_max = time_limit;
}

int CpuTimeLimit::process(vluint64_t &main_time) {
    if (time_limit == 0 || main_time <= time_max)return 0;
    if (!time_check)return status_time_limit;
    fprintf(stderr, "\nReached time %llu\n", (unsigned long long) time_max);
    char cont = 'U';
    while (true) {
        fprintf(stderr, "continue?(Y(es)/C(ount)/N(o))\n");
        cont = getchar();
        if (cont == 'Y' || cont == 'C' || cont == 'N')break;
    }
    if (cont == 'Y')time_max += time_limit;
    else if (cont == 'C') {
        int delta = 0;
        int rnum = 0;
        while (delta <= 0)rnum = scanf("%d", &delta);
        time_max += delta;
    }
    return (cont == 'N') ? status_time_limit : 0;
}