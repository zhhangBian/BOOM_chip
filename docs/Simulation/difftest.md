# DIFFTEST 使用说明

DIFFTEST 框架基于ysyx提供的oscpu开发框架修改：https://github.com/OpenXiangShan/difftest.

DIFFTEST的比对对象是两个核，一个是用户设计的核，一个是参考核。 比对原理是设计核在每提交一条指令的同时使参考核执行相同的指令，之后比对所有的通用寄存器和csr寄存器的值，如果完全相同则认为设计核执行正确。 同时， DIFFTEST比对机制也实现了对于store指令的比对，一旦store指令中的物理地址和存储数据与参考核不同，也会立即暂停仿真，以此来尽早定位错误。

DIFFTEST使用的参考核为经过移植的la32r-nemu, 在本仓库中只需要使用动态链接文件(`toolchains/nemu/la32r-nemu-interpreter-so`)即可进行difftest，相关的说明和源代码请见代码仓库：[NEMU](https://gitee.com/wwt_panache/la32r-nemu)，编译好的la32r-nemu的动态链接文件也可以在该仓库的发行版中下载。

## DPIC 接口说明

DPIC涉及到的文件及相关内容介绍见下：

- `difftest.v`中定义了所有dpic相关的 verilog module 信息，这些 module 中会调用c函数用来传输信号。这些 module 会被设计核实例化用来传输信号。
- `mycpu_top.v`中实例化了`difftest.v`中定义的 module。
- `interface.h`是c函数的实现，c函数将设计核的信号赋值给difftest中的变量。

数据流传递方向可简单地认为是`mycpu_top.v`->`difftest.v`->`interface.h`->`difftest.cpp`

使用者需要将`mycpu_top.v`中相关 verilog module 例化信号接到自己核中相应的信号上，下面简单地介绍一下各个信号的作用，**为了满足在指令提交的时刻该指令产生的影响恰好生效，部分信号需要 delay 一拍再传递**， 详细使用案例可参考本仓库中`IP/myCPU/mycpu_top.v`。

1. `DifftestInstrCommit` 指令提交信息

    - `clock`           : 全局时钟
    - `coreid`          : 核id，目前只支持单核，直接传入0即可
    - `index`           : 指令提交索引，该index用来区别多指令提交，从0开始计数。difftest支持任意宽度的指令提交，其比对粒度与提交宽度一致。如果设计的提交宽度大于6，那么需要使用者手动修改 `sims/verilator/testbench/include/difftest.h` 中的宏定义 `DIFFTEST_COMMIT_WIDTH`。
    - `valid`           : 提交有效信号，该信号拉高时，指令提交
    - `pc`              : 当前提交指令的pc
    - `instr`           : 当前提交指令的指令码
    - `skip`            : 跳过当前指令的比对，目前没有实现，直接传入0即可
    - `is_TLBFILL`      : tlbfill指令使能，当前指令为tlbfill指令时，该信号拉高
    - `TLBFILL_index`   : tlbfill指令对应的tlb表项索引
    - `is_CNTinst`      : 与计时器相关的指令，提交指令为rdcntv{l/h}.w 或 rdcntid 时该位拉高
    - `timer_64_value`  : 当前指令读出的64位计数器值(StableCounter)
    - `wen`             : 提交指令通用寄存器写使能
    - `wdest`           : 提交指令写通用寄存器索引
    - `wdata`           : 提交指令写通用寄存器数据
    - `csr_rstat`       : 当提交指令为csrrd、csrwr、csrxchg，同时该指令对应的csr寄存器为estat寄存器时该位拉高
    - `csr_data`        : 当`csr_rstat == 1`时，当前指令读取到的csr寄存器(estat)的值

2. `DifftestExcpEvent` 指令中的异常信息

    - `clock`           : 全局时钟
    - `coreid`          : 核id，目前只支持单核，直接传入0即可
    - `excp_valid`      : 当前指令如果有例外(包括外部中断)要处理，该位为1   
    - `eret`            : 当前指令为`eret`指令时，该位为1         
    - `intrNo`          : csr寄存器中csr_estat[12:2]
    - `cause`           : estat.ecode
    - `exceptionPC`     : 出现例外的指令pc
    - `exceptionInst`   : 出现例外的指令码

3. `DifftestTrapEvent` 该模块目前并未使用，直接将其中的valid信号接0

    - `clock`           : 全局时钟
    - `coreid`          : 核id，目前只支持单核，直接传入0即可
    - `valid`           : 0
    - `code`            : 
    - `pc`              : 
    - `cycleCnt`        : 
    - `instrCnt`        : 

4. `DifftestStoreEvent` store指令信息

    - `clock`           : 全局时钟
    - `coreid`          : 核id，目前只支持单核，直接传入0即可
    - `index`           : 指令提交索引，该index用来区别多发射，从0开始计数。
    - `valid`           : store有效信号， 接法可参照 {4'b0, llbit && sc_w, st_w, st_h, st_b}
    - `storePAddr`      : store指令对应的物理地址
    - `storeVAddr`      : store指令对应的虚拟地址
    - `storeData`       : store指令对应的数据

如果使用者不想开启store指令信息比对，手动在`sims/verilator/testbench/difftest.cpp : 175`中注释掉相关代码再编译运行即可。

5. `DifftestLoadEvent` load指令信息

    - `clock`           : 全局时钟
    - `coreid`          : 核id，目前只支持单核，直接传入0即可
    - `index`           : 指令提交索引，该index用来区别多发射，从0开始计数。
    - `valid`           : load有效信号， 接法可参照 {2'b0, ll_w, ld_w, ld_hu, ld_h, ld_bu, ld_b}
    - `paddr`           : load指令对应的物理地址
    - `vaddr`           : load指令对应的虚拟地址

6. `DifftestCSRRegState` csr寄存器信息

    - csr寄存器堆的值

7. `DifftestGRegState` 通用寄存器信息

    - 通用寄存器堆堆值

## 其他说明

目前该框架会比对所有的通用寄存器和csr寄存器的值，如果用户希望只比对某些csr寄存器的值，可通过修改`sims/verilator/testbench/difftest.cpp`中的`compare_mask`数组来开关对应csr寄存器的比对使能，`1`即为开启比对，`0`即为关闭比对。`compare_mask`数组中每一项对应的csr寄存器与`reg_name`数组中的csr寄存器一一对应。被关闭比对的csr寄存器在比对时值会变成0。其中，我们强烈建议关闭`estat`寄存器的比对。
