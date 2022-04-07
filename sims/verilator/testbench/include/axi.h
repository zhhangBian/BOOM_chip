#ifndef CHIPLAB_AXI_H
#define CHIPLAB_AXI_H

#include "cpu_tool.h"
#include "ram.h"

class CpuAxi:public CpuTool
{
public:
    CpuRam* ram;
    CpuDevices dev;
    static const int burst_fixed = 0;
    static const int burst_incr  = 1;
    static const int burst_wrap  = 2;
    static const int latency = 12;

    CpuAxi(Vtop* top,CpuRam* ram): CpuTool(top) {
        this->ram = ram;
        //axi-read
        top->arready = 1;
        top->rid = 0;
        for (int i = 0; i < 4; i += 1)top->rdata[i] = 0;
        top->rresp = 0;
        top->rlast = 0;
        top->rvalid = 0;
        //axi-write
        top->awready = 1;
        top->wready = 1;
        top->bid = 0;
        top->bresp = 0;
        top->bvalid = 0;
    }

    void read(vluint64_t main_time,vluint64_t a) {
        top->rvalid = 1;
        if (simu_dev && dev.in_space(0, a)) {
            top->rdata[0] = dev.read(main_time, a);
            top->rdata[1] = 0;
            top->rdata[2] = 0;
            top->rdata[3] = 0;
            return;
        }
        top->rdata[0] = ram->read32(a);
        top->rdata[1] = ram->read32(a + 4);
        top->rdata[2] = ram->read32(a + 8);
        top->rdata[3] = ram->read32(a + 12);
        // rlast rid
    }

    void write(vluint64_t main_time,vluint64_t a,vluint64_t m,unsigned* d) {
        if (simu_dev && dev.in_space(0, main_time)) {
            dev.write(main_time, a, d[0]);
            return;
        }
        ram->write4B(a, m & 0xf, d[0]);
        ram->write4B(a, (m >> 4) & 0xf, d[1]);
        ram->write4B(a, (m >> 8) & 0xf, d[2]);
        ram->write4B(a, (m >> 12) & 0xf, d[3]);
    }

    int process(vluint64_t& main_time) {
        static int rid = 0;
        static int rn = 0;
        static int rc = 0;
        static int rs = 0;
        static vluint64_t ra[16] = {};
        static vluint64_t rt = 0;
        static int dor = 0;

        top->arready = rs == 0;
        if (dor) {
            top->rid = rid;
            top->rlast = rc >= rn;
            rc += 1;
            read(main_time, ra[rc]);
        }
        if (top->rvalid && top->rready && top->rlast) {
            rs = 0;
        }
        if (rs != 0 && rt + latency > main_time && (top->rready || !top->rvalid)) {
            dor = 1;
        }
        if (top->arready && top->arvalid) {
            rid = top->arid;
            rn = top->arlen;
            rc = 0;
            rt = main_time;
            rs = 1;
            compute_burst(top->arburst, rn, top->araddr, ra);
        }

        static int wid = 0;
        static int wn = 0;
        static int wc = 0;
        static int ws = 0;
        static vluint64_t wa[16] = {};
        static vluint64_t wt = 0;
        static int dow = 0;
        top->awready = ws == 0;
        if (top->bready) {
            top->bvalid = 0;
        }
        if (dow) {
            top->bid = wid;
            top->bvalid = 1;
            dow = 0;
        }
        if (top->awready && top->awvalid) {
            wid = top->awid;
            wn = top->awlen;
            wc = 0;
            wt = main_time;
            ws = 1;
            compute_burst(top->awburst, wn, top->awaddr, wa);
        }
        if (top->wready && top->wvalid) {
            write(main_time, wa[wc], top->wstrb, top->wdata);
            wc += 1;
            if (top->wlast) {
                ws = 0;
                dow = 1;
            }
        }
        return 0;
    }

    int compute_burst(int burst,int n,vluint64_t axaddr,vluint64_t *a) {
        if (burst == burst_fixed) {
            for (int i = 0; i < n; i += 1) {
                a[i] = axaddr;
            }
        } else if (burst == burst_incr) {
            for (int i = 0; i < n; i += 1) {
                a[i] = axaddr + (i << 4);
            }
        } else if (burst == burst_wrap) {
            int mod = axaddr % n;
            vluint64_t base = axaddr - mod;
            for (int i = mod; i < n; i += 1) {
                a[i - mod] = base + i;
            }
            for (int i = 0; i < mod; i += 1) {
                a[i + n - mod] = base + i;
            }
        } else return 1;
        return 0;
    }
};

#endif  // CHIPLAB_AXI_H