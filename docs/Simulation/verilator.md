# verilator仿真环境说明
运行环境包括`run_prog`和`run_random`。    
`run_prog`用于运行以下测试程序：   
- func：共81个功能测试点，验证处理器核设计是否与指令手册一致。
- coremark/dhrystone：性能测试程序。
- my_program：用户自定义裸机C程序。
- linux：内核，仿真环境下可通过终端与用户交互。   

`run_random`用于运行随机指令序列。序列中存在数量庞大，随机排列的指令，能够覆盖部分边角情况。初始化完成后，序列中的指令可连续执行，由生成器保证序列可连续执行不会中断以及提供页表项完成虚实地址映射。	    
仿真环境下运行程序都可通过difftest框架，实现处理器运行结果同nemu模拟器运行结果的实时比对，nemu作为金标准。能够帮助用户发现出错的第一现场，便于调试。

## SoC参数配置
chip目录在未来会赋予SoC顶层代码自动生成的能力，体现敏捷开发的思想。但目前仍处于初始的状态，仅提供少数宏定义，对SoC中的部分参数进行简单调整，以适配处理器核的配置。
- `chip/config-generator.mak`
	- `AXI64` : 设置为`y`表示SoC中AXI协议数据位宽为64btis 
	- `AXI128` : 设置为`y`表示SoC中AXI协议数据位宽为128btis，`AXI64`和`AXI128`至多配置一个`y`，都置为`n`表示`AXI32`，AXI协议数据位宽为32bits
	- `CPU_2CMT` : 设置为`y`，表示处理器核每周期可至多提交2条指令，设置为`n`，表示处理器核每周期提交1条指令。
	- 其他参数 : 用于指示所使用的IP模块，以及IP所处的位置。在当前SoC固定无法修改的情况下，这部分参数不需要调整。    

## Quick Start
以下为一个简单的仿真例程，方便用户快速上手仿真过程。在进行仿真之前，用户需安装好verilator、gtkware以及nemu。
```
cd $CHIPLAB_HOME/sims/verilator/run_prog #进入验证程序仿真目录中
./configure.sh --run func/func_lab16     #以仿真运行的程序func_lab16为例子生成对应的Makefile
make                                     #开始编译。若没有编译出错，会自动进行仿真。
```
当需要输出波形时，需要修改Makefile_run中以下参数
```
DUMP_WAVEFORM=1
```
重新运行以下命令
```
make run
cd $CHIPLAB_HOME/sims/verilator/run_prog/log/func/func_lab16_log
gtkwave simu_trace.fst                   #查看仿真波形
```
上述简单仿真过程完成之后，用户可根据自己的需要，配置相应的仿真参数。对于仿真参数的说明，请参考以下章节。
## LA32R-NEMU
为帮助用户在仿真环境下调试内核，我们提供了`difftest`环境，
使用方法请参考[DIFFTEST说明](https://chiplab.readthedocs.io/zh/latest/Simulation/difftest.html)。
## prog环境
### 编译参数配置
```
./configure.sh --help
```
选择运行的`software`以及对各项功能进行配置，`--run`必选，其他可选。`func`测试用例所测试的内容记录在`software/func/*`对应文件夹下的`README`中，该文件也对`func`中的一些选项进行了说明。   
编译参数配置更改后需要重新执行整个编译运行流程才能生效。   
- `--run software` : 选择仿真运行的程序。目前只支持单次仿真选择一个测试程序。测试程序清单可通过./configure.sh --help查看
- `--disable-trace-comp` : 关闭使用NEMU进行的`trace`比对功能，默认开启 
- `--disable-simu-trace` : 关闭`trace log`记录，适用于内核的长时间仿真，`simu_trace.txt`可能会占用较大的存储空间，默认开启
- `--enable-mem-trace` : 打开访存信息记录，在`mem_trace.txt`保存取指、数据访问`load/store`的地址、数据信息。
- `--disable-read-miss` : 关闭`read miss`警告，`C++`模拟的`ram`在核访问未初始化的内容时，会报该地址的`read miss`，默认开启
- `--disable-clk-time` : 在`simu_trace.txt`中关闭仿真时间的打印，适用于将`simu_trace.txt`进行`diff`的场景，默认开启
- `--output-pc-info` : 在当前终端输出每条指令提交的信息，默认开启
- `--output-uart-info` : 在当前终端输出假串口以及真串口的输出，默认关闭
- `--output-nothing` : 在当前终端不输出任何信息，默认关闭
- `--threads` : 开启多个线程进行仿真，但当前testbench暂时无法很好的适配多线程的运行环境，不建议开启
- `--reset-val` : `reset`信号置起时，`rtl`未初始化的寄存器，`verilator`不会呈现出`x`，而是会自行初始化。赋值`0`初始化为`0`；赋值`1`初始化为`1`；赋值`2`初始化为随机值。早期设计阶段，可以固定为某个值，而当设计比较稳定，可以设置为随机值，进行比较完备的验证
- `--reset-random-seed` : 当`reset-val`设为`2`时，该选项选择对应的随机种子
- `--dump-vcd` : 生成`vcd`格式的波形文件，该格式未进行任何的压缩，会占用较大的存储空间，且`gtkwave`打开较慢，默认关闭
- `--dump-fst` : 生成`fst`格式的波形文件，该格式会进行一定的压缩，`gtkwave`打开较快，但会导致仿真速度下降，默认开启
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
- `DUMP_WAVEFORM` : 是否生成波形
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
- `make simulation_run_prog`   : 开始func仿真

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
make verilator testbench simulation_run_prog
```
仿真过程会生成两个比较关键的文件夹，分别是`obj`和`log`，内容包括：
- `obj`
    - `main.elf` : software elf文件
    - `test.s` : 反汇编文件
- `log`
    - `simu_trace.txt` : 仿真过程输出信息的备份
    - `mem_trace.txt`  : 仿真过程访存信息的备份
    - `simu_trace.fst` : 仿真波形文件
    - `uart_output.txt` : 假串口输出`log`
    - `uart_output.txt.real` : 真串口输出`log`

以上文件都可用于调试自己的处理器核设计，波形文件可以通过`gtkwave`打开。
```
gtkwave simu_trace.fst

```     
如果仿真过程中被`ctrl-c`强制结束，仅`simu_trace.txt`会保存在`tmp`目录下，波形文件、串口输出的`log`会丢失。为避免该情况，可估算运行时间，并配置`Makefile_run`中的`TIME_LIMIT`选项。
## random环境
### 连接DIFFTEST相关信号
为帮助用户在仿真环境下调试处理器，我们提供了'difftest'环境.
使用方法请参考[DIFFTEST使用说明](https://chiplab.readthedocs.io/zh/latest/Simulation/difftest.html)，完成DIFFTEST相关信号的适配。
若不进行适配，请关闭DIFFTEST比对功能后，再进行随机指令序列测试。修改`$(CHIPLAB_HOME)/sims/verilator/run_random/config-random.mak`
```
TRACE_COMP=n
```
### 准备测试用例
下载相关随机res文件压缩包，[下载地址](http://114.242.206.180:24989/nextcloud/index.php/s/qRGrWZK6c2KtAJ9)。	
`random_res_*.tar.bz2`其中的数字表示拥有几组随机指令序列，一组随机指令序列拥有30万条指令	
压缩包中的随机指令序列包括`RES_cluster_*`和`RES_jump_*`表示不同的生成倾向。`jump`类倾向于同一类指令重复，而`cluster`类为多类型指令混合。		
解压后将`random_res_*`内的文件夹`RES_cluster_*`或者`RES_jump_*`拷贝至`$(CHIPLAB_HOME)/software/random_res/`下。		
该文件夹由用户自行创建，对于`random_res`下的所有文件，`run_random`都会对其进行处理，因此建议放入适量的随机指令序列，同时该目录下不可放置其他无关内容。  
### 编译参数配置
```
config-random.mak
```
部分选项与`run_prog`环境下`./configure.sh`中的选项具有相同的含义，不同的内容有
- `CACHE_SEED` : 为对`cache`进行完备的测试，随机环境下，`tlb`的存储访问类型（MAT）也进行随机的配置，该选项配置随机种子。
- `LA32` : `y`配置为32位架构，`n`配置为64位架构。

### 运行参数配置
```
Makefile_run
```
- `DUMP_DELAY` : 波形起始时间
- `DUMP_WAVEFORM` : 是否生成波形
- `TIME_LIMIT` : 仿真时间限制 (设零无限制)	

### 编译运行
```
make
```
即可开始随机验证，运行`software/random_res`目录下所存的所有随机指令序列。    
所有随机序列测试成功或失败的信息存放在`sims/verilator/run_random/log/*-result.txt`中   
每个随机序列具体的测试信息存放在`$(CHIPLAB_HOME)/sims/verilator/run_random/log/$(TESTCASE)`下.         
- `run.log` :             当前case执行随机的输出结果.
- `simu_trace.fst` :      当前case所生成波形
以上文件都可用于调试自己的处理器核设计，波形文件可以通过`gtkwave`打开。       

```
gtkwave simu_trace.fst
```       

#### 单个随机指令序列运行方法
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
随机启动代码位于`software/random_boot`的`rand_boot.S`中。对处理器状态进行初始化，`eret`指令之后开始执行随机指令序列，并且开始比对。    
随机指令序列仅允许触发`tlb refill`例外，`tlb refill`例外的处理程序位于`rand_boot.S`中。当触发`tlb refill`例外时，由`testbench`获取出错虚地址，并查询随机指令序列中提供的页表项，填写到固定地址，再由例外处理程序填充到处理器核的`tlb`中。    
随机指令序列使用大小页。	    
随机测试用例文件夹中存有`*.res`文件，用于构成随机验证环境。同时，随机指令序列也给出了正确的执行路径以及执行结果。当运行出错时，一方面可以同作为金标准的`nemu`进行对比分析，另一方面也可以从`*.res`文件获取正确的运行结果并进行分析。以下对较为关键的`*.res`文件进行介绍。
- `comment.res` : 随机指令序列中的汇编指令。`instruction.res/address.res/pc.res/result_type.res/value1.res`五个文件每行与该文件每行的指令对应。   
- `instruction.res` : 随机指令的二进制。
- `address.res` : 随机指令修改的通用寄存器号。 
- `value1.res` : 随机指令修改的通用寄存器的值。
- `pc.res` : 随机指令的虚地址。   
- `result_type.res` :  为`1`表示随机指令修改通用寄存器，为`0`则表示不修改。  
- `page.res` : 页表项的虚地址。   
- `pfn.res` : 页表项的物理地址。 
- `cca.res` : 页表项的存储访问类型。
- `page_size.res` : 页表项的页大小。`page.res/pfn.res/cca.res/page_size.res`四个文件每行描述一个页表项，当处理器核在处理`tlb`出错时，可查询四个文件观察页表填充是否正确。  
- `init.res.res` : 通用寄存器初始值。
    
查看波形时，可观察顶层`simu_top.v`的几个`ram*`信号，判断AXI总线发出的请求及传输的数据是否正确。
