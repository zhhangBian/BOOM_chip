#include "devices.h"

CpuDevices::CpuDevices() : CpuTool(nullptr) {
    timer_base = 0;
}

unsigned CpuDevices::read(vluint64_t main_time, vluint64_t a) {
    unsigned offs = a & mask;
    if (offs == offs_time)return (main_time >> 1) + timer_base;
    return 0;
}

int CpuDevices::write(vluint64_t main_time, vluint64_t a, vluint64_t d) {
    unsigned offs = a & mask;
    if (offs == offs_uart) {
        printf("%c", (char) d);
        return d & 0xff ? 0 : status_uart_exit;
    } else if (offs == offs_time) {
        timer_base = d - (main_time >> 1);
    }
    return 0;
}
