# verilator仿真环境说明
`func`和`random`运行环境分别位于`run_func`和`run_random`，进入目录进行相应的工作。
## SOC参数配置
- `config-generator.mak`
	- `AXI64` 
	- `AXI128` : `AXI`选项都置为`n`表示`AXI32`
	- `CPU_2CMT` : 双发射    

## Quick Start
以下为一个简单的仿真例程，方便用户快速上手仿真过程。在进行仿真之前，用户需安装好verilator、gtkware以及qemu。
```
cd $CHIPLAB_HOME/sims/verilator/run_func #进入func仿真目录中
./configure.sh --run func/func_lab3      #以仿真运行的程序func_lab3为例子生成对应的Makefile
make                                     #开始编译。若没有编译出错，会自动进行仿真。
cd $CHIPLAB_HOME/sims/verilator/run_func/log/func/func_lab3_log
gtkwave simu_trace.vcd                   #查看仿真波形
```
上述简单仿真过程完成之后，用户可根据自己的需要，配置相应的仿真参数。对于仿真参数的说明，请参考以下章节。
## func环境
### 编译参数配置
```
./configure.sh --help
```
选择运行的`software`以及对各项功能进行配置，`--run`必选，其他可选。`func`测试用例所测试的内容记录在`software/func/*`对应文件夹下的`README`中，该文件也对`func`中的一些选项进行了说明。   
编译参数配置更改后需要重新执行整个编译运行流程才能生效。   
`qemu`中存在一些内容无法与核保持一致，因此测试项无法在`trace`比对功能开启的时候进行测试。完整的测试在`--disable-trace-comp`开启时才会进行，具体的测试项在`README`中说明。     
目前的`trace`比对功能仅在`func`下支持，运行其他测试用例时需要关闭。     
- `--run software` : 选择仿真运行的程序，一次仿真执行多个程序的功能有缺陷
- `--disable-trace-comp` : 关闭`trace`比对功能 
- `--disable-simu-trace` : 关闭`trace log`记录，适用于内核的长时间仿真，`simu_trace.txt`可能会占用较大的存储空间
- `--disable-read-miss` : 关闭`read miss`警告，`C++`模拟的`ram`在核访问未初始化的内容时，会报该地址的`read miss`
- `--disable-clk-time` : 在`simu_trace.txt`中关闭仿真时间的打印，适用于将`simu_trace.txt`进行`diff`的场景
- `--output-pc-info` : 在当前终端输出每条指令提交的信息
- `--output-uart-info` : 在当前终端输出假串口以及真串口的输出
- `--threads` : 开启多个线程进行仿真，多线程开启不一定会获得更高的性能
- `--reset-val` : `reset`信号置起时，`rtl`未初始化的寄存器，`verilator`不会呈现出`x`，而是会自行初始化。赋值`0`初始化为`0`；赋值`1`初始化为`1`；赋值`2`初始化为随机值。早期设计阶段，可以固定为某个值，而当设计比较稳定，可以设置为随机值，进行比较完备的验证
- `--reset-random-seed` : 当`reset-val`设为`2`时，该选项选择对应的随机种子
- `--dump-vcd` : 生成`vcd`格式的波形文件，该格式未进行任何的压缩，会占用较大的存储空间，且`gtkwave`打开较慢
- `--dump-fst` : 生成`fst`格式的波形文件，该格式会进行一定的压缩，`gtkwave`打开较快，但会导致仿真速度下降
- `--slice-waveform` : 对波形文件进行切分，存储在多个文件中，用于解决波形堆积在一个文件，导致打开极慢的问题
- `--waveform-slice-size` : 波形文件切分的单位，以仿真时间衡量
- `--slice-simu-trace` : 对`simu_trace.txt`进行切分，同样解决`trace`堆积在一个文件，`vim`打开及文本处理都极慢的问题
- `--trace-slice-size` : `simu_trace.txt`切分的单位
- `--tail-waveform` : 仅保留末尾部分的波形文件，适用于运行内核时，希望保留出错位置的信息
- `--waveform-tail-size` : 波形所保留的末尾部分的大小，以仿真时间衡量
- `--tail-simu-trace` : 仅保留末尾部分的`trace`
- `--trace-tail-size` : `trace`所保留的末尾部分的大小

### 运行参数配置
```
Makefile_run
```
运行参数在该文件中进行配置，参数更改后仅需重新开始仿真即可生效，即`make`中的最后一个流程。
- `DUMP_DELAY` : 波形起始时间
- `DUMP_TRACE` : 是否生成波形
- `TIME_LIMIT` : 仿真时间限制 (设零无限制)	     
- `BUS_DELAY` : 总线是否引入随机延迟
- `BUS_DELAY_RANDOM_SEED` : 总线延迟随机种子
- `SAVE_BP_TIME` : 断点保存仿真时间，断点产生后仿真仍继续进行（设零不进行断点保存）
- `RAM_SAVE_BP_FILE` : 断点保存内存信息文件
- `TOP_SAVE_BP_FIEL` : 断点保存`RTL`状态文件
- `RESTORE_BP_TIME` : 断点恢复仿真时间（设零不进行断点恢复）
- `RAM_RESTORE_BP_FILE` : 断点恢复内存信息文件
- `TOP_RESTORE_BP_FIEL` : 断点恢复`RTL`状态文件

### 编译运行
```
make
```
即可开始仿真的整个流程，包括：
- `make verilator` : verilator编译verilog代码
- `make testbench` : 编译testbench（C++）
- `make soft_compile` : 编译software(func)
- `make golden_trace` : 生成golden trace作为参考(func)
- `make simulation_run_func`   : 开始func仿真

如若出现混乱，可以运行
```
make clean
```
清理`make`生成的内容，还可运行
```
make clean_all
```
清理`make`及`configure.sh`生成的内容。   
目前`Makefile`比较简陋，对于`software`无法进行是否修改过的判断，仅通过是否构建出对应`obj/*`文件进行判断，如果仅希望重新编译`software`，可删除对应的`obj/*`文件夹，然后`make`。注意不是删除`obj`目录。    
### func验证
实验过程中可以根据当前的进度，选择性的执行相应的流程。流程间存在依赖。一般来说对`myCPU`的`rtl`内容进行改动后，可以仅运行
```
make verilator testbench simulation_run_func
```
仿真过程会生成两个比较关键的文件夹，分别是`obj`和`log`，内容包括：
- `obj`
    - `main.elf` : software elf文件
    - `test.s` : 反汇编文件
- `log`
    - `golden_trace.txt` : 通过qemu模拟器生成的参考trace
    - `simu_trace.txt` : 仿真过程输出信息的备份
    - `simu_trace.vcd` : 仿真波形文件
    - `uart_output.txt` : 假串口输出`log`
    - `uart_output.txt.real` : 真串口输出`log`

以上文件都可用于调试自己的处理器核设计，波形文件可以通过`gtkwave`打开。
```
gtkwave simu_trace.vcd

```     
如果仿真过程中被`ctrl-c`强制结束，仅`simu_trace.txt`会保存在`tmp`目录下，波形文件、串口输出的`log`会丢失。为避免该情况，可估算运行时间，并配置`Makefile_run`中的`TIME_LIMIT`选项。
## random环境
### 修改simu_top
对`$(CHIPLAB_HOME)/sims/verilator/testbench/simu_top.v`中的define进行修改,使其适配myCPU.     
需要适配的信号说明如下:    
- `CORE0` :               myCPU顶层
- `GR_RTL` :              myCPU的标量定点通用寄存器堆
- `CR_BADVADDR` :         myCPU中的badvaddr csr寄存器
- `ROQ` :                 myCPU中提交寄存器修改的一级.五级流水中对应wb_stage
- `CMTBUS_VALID0` :       当前提交流级有效.分支指令,无写回指令等也需要，`eret`指令或例外需置零.
- `CMTBUS_CMTNUM0` :      当前提交级的一次提交完成了几条指令.如无指令融合和指令拆分,一般始终为`CMTBUS_VALID0`.
- `CMTBUS_VALID1` :       类似cmtbus_valid0,为适配双发射所使用.
- `CMTBUS_CMTNUM1` :      类似cmtbus_cmtnum0,为适配双发射所使用.
- `EXBUS_EX` :            提交级触发例外
- `EXBUS_ERET` :          提交级触发了ERET
- `EXBUS_EXCODE` :        提交级触发例外的excode
- `EXBUS_EPC` :           提交级触发例外的EPC

其余信号如FIX ROQ CSR均为减少以上信号重复书写所定义.如不适合myCPU可以删除,保证上述信号连接正确即可.如果随机验证没有正常进入比对指令运行结果的状态，大概率为`simu_top`信号的配置问题。
### 准备测试用例
下载相关随机res文件压缩包，将解压后`content`内的文件夹放入`$(CHIPLAB_HOME)/software/random_res/`下。该目录下不可放置其他无关内容。  
### 编译参数配置
```
config-random.mak
```
部分选项与`run_func`环境下`./configure.sh`中的选项具有相同的含义，不同的内容有
- `CACHE_SEED` : 为对`cache`进行完备的测试，随机环境下，`tlb`的`cache`属性也进行随机的配置，该选项配置随机种子。
- `RAND32` : 配置随机测试位数。

### 运行参数配置
```
Makefile_run
```
- `DUMP_DELAY` : 波形起始时间
- `DUMP_TRACE` : 是否生成波形
- `TIME_LIMIT` : 仿真时间限制 (设零无限制)	

### 编译运行
```
make
```
即可开始随机验证。
所有随机序列测试成功或失败的信息存放在`sims/verilator/run_random/log/*-result.txt`中   
每个随机序列具体的测试信息存放在`$(CHIPLAB_HOME)/sims/verilator/run_random/log/$(TESTCASE)`下.         
- `run.log` :             当前case执行随机的输出结果.
- `simu_trace.vcd` :      当前case所生成波形
以上文件都可用于调试自己的处理器核设计，波形文件可以通过`gtkwave`打开。       

```
gtkwave simu_trace.vcd
```     
#### 随机验证运行时的参数说明
可以在`$(CHIPLAB_HOME)/sims/verilator/run_random/Makefile_run`中对相应参数作为修改.
- `DUMP_TRACE` :          是否生成波形.
- `DUMP_DELAY` :          从具体时刻开始抓取波形
- `TIME_LIMIT` :          仿真最长时刻    

### 随机验证的使用说明
若需要跑具体某个随机测试用例,进入`$(CHIPLAB_HOME)/sims/verilator/run_random/run_random/`,执行:
```
make simulation_run_random -C $(TESTCASE) -f ../../Makefile_run CASENAME=$(TESTCASE)
```
或执行:
```
make ../../../../software/random_res/$(TESTCASE)
```
若此前没有执行过make random,请在`$(CHIPLAB_HOME)/sims/verilator/run_random/run_random/$(TESTCASE)/`下先执行:
```
make prepare
```
所有随机指令序列的测试结果记录在`log/result.txt`中。        
debug时请参考`$(TESTCASE)/comments.res`以及`$(TESTCASE)/logs/run.log`。          

### 随机验证调试帮助
随机启动代码位于`software/random_boot`的`rand_boot.S`中。   
随机测试用例文件夹中存有`*.res`文件，用于生成随机验证环境，这些文件也可用于调试。
- `comment.res` : 随机指令序列。   
- `inst.vlog` : 随机指令的二进制内容，及其存放的物理地址。    
- `page.res` : 填充页表项的虚地址。   
- `pfn.res` : 填充页表项的物理地址。   
- `pc.res` : 取指虚地址。   
    
查看波形时，可观察顶层`simu_top.v`的几个`ram*`信号，判断AXI总线发出的请求及传输的数据是否正确。
