# Chiplab用户手册 
## 前言
chiplab项目致力于构建基于LoongArch32 Reduced的soc敏捷开发平台。该项目还处于初始的状态，如发现问题请在issues提出。
## 目录结构
.   
├── chip  
│　　└── soc_demo   
│　　　　　├── loongson   
│　　　　　├── Baixin   
│　　　　　└── sim   
├── fpga   
│　　└── loongson   
│　　└── Baixin   
├── IP   
│　　├── AMBA    
│　　├── APB_DEV    
│　　　　　├── URT   
│　　　　　└── NAND   
│　　├── AXI_DELAY_RAND    
│　　├── AXI_SRAM_BRIDGE    
│　　├── BRIDGE    
│　　├── DMA    
│　　├── SPI    
│　　├── MAC    
│　　├── CONFREG   
│　　├── myCPU  
│　　└── xilinx_ip   
├── scripts   
├── sims   
│　　└── verilator   
│　　　　　├── run_func   
│　　　　　├── run_random   
│　　　　　└── testbench   
├── software   
│　　├── coremark   
│　　├── dhrystone  
│　　├── func   
│　　├── linux   
│　　├── random_boot   
│　　├── random_res   
│　　└── generic   
└── toolchains    
　　　├── loongarch32r-linux-gnusf-\*  
　　　├── nemu   
　　　└── system_newlib

## 使用方法
### toolchains预下载
详情请参考`toolchains/README.md`，对各个目录进行介绍。
- `loongarch32r-linux-gnusf-*` : `gcc`工具链。
- `nemu` : 模拟器。`la32-nemu-interpreter-so`拷贝至该目录即可。
- `system_newlib` : `newlib` C库，用于编译裸机C程序。内容包括`libc.a libg.a libm.a libpmon.a pmon.ld start.o`，`newlib.tar`解压后，将这些文件拷贝至该目录下即可。

### 依赖安装
以Ubuntu (Windows 10+ 请基于WSL**2**)为例:

```
sudo apt install verilator gtkwave #verilator version 4.108+ (loongarch64 4.222+)    
```

### 实验步骤

#### 参数设置
设置CHIPLAB_HOME系统变量  
```
export CHIPLAB_HOME="your own chiplab pwd address"
```
#### 替换myCPU
`IP/myCPU`中存放的是处理器核代码，对外的接口和核顶层模块名称固定。该环境默认处理器核已实现`AXI`总线。
```
module core_top(
    input           aclk,
    input           aresetn,
    input    [ 7:0] intrpt, 
    //AXI interface 
    //read reqest
    output   [ 3:0] arid,
    output   [31:0] araddr,
    output   [ 7:0] arlen,
    output   [ 2:0] arsize,
    output   [ 1:0] arburst,
    output   [ 1:0] arlock,
    output   [ 3:0] arcache,
    output   [ 2:0] arprot,
    output          arvalid,
    input           arready,
    //read back
    input    [ 3:0] rid,
    input    [31:0] rdata,
    input    [ 1:0] rresp,
    input           rlast,
    input           rvalid,
    output          rready,
    //write request
    output   [ 3:0] awid,
    output   [31:0] awaddr,
    output   [ 7:0] awlen,
    output   [ 2:0] awsize,
    output   [ 1:0] awburst,
    output   [ 1:0] awlock,
    output   [ 3:0] awcache,
    output   [ 2:0] awprot,
    output          awvalid,
    input           awready,
    //write data
    output   [ 3:0] wid,
    output   [31:0] wdata,
    output   [ 3:0] wstrb,
    output          wlast,
    output          wvalid,
    input           wready,
    //write back
    input    [ 3:0] bid,
    input    [ 1:0] bresp,
    input           bvalid,
    output          bready,
    //debug info
    output [31:0] debug0_wb_pc,
    output [ 3:0] debug0_wb_rf_wen,
    output [ 4:0] debug0_wb_rf_wnum,
    output [31:0] debug0_wb_rf_wdata
    #ifdef CPU_2CMT
    ,
    output [31:0] debug1_wb_pc,
    output [ 3:0] debug1_wb_rf_wen,
    output [ 4:0] debug1_wb_rf_wnum,
    output [31:0] debug1_wb_rf_wdata
    #endif
);
```
#### 仿真
仿真的工作目录位于`sims/verilator/run_*`，当前仅支持`verilator`。
- `run_func` : 该工作目录下可运行`func`测试用例、`dhrystone`、`coremark`性能测试程序、`linux`以及自定义C程序。
- `run_random` : 该工作目录下可进行随机指令序列测试。 

具体使用方法请参考[verilator仿真环境说明](https://chiplab.readthedocs.io/zh/latest/Simulation/verilator.html)。
     
#### 综合、下板
该步骤的工作目录位于`fpga`，当前支持龙芯实验箱及百芯板。目前该内容仅用于在板上启动内核。    
演示可使用`myCPU`单发射五级流水。
使用vivado打开龙芯实验箱或者百芯目录下`system_run/system_run.xpr`工程，添加处理器核代码后，开始综合。   
板上内核启动方法。`flash`加载`pmon`，通过网口加载内核代码。   
具体流程：   
下载`pmon`源码编译出`gzrom.bin`或者直接下载，烧写至`flash`。    
连接串口，配置为`115200 8N1`。   
后续步骤同龙芯杯大赛中的`FPGA_soc_test`流程。     
在本地搭建`tftp`服务器，配置`IP`为`10.90.50.43`。   
启动`pmon`后，配置网络`”ifconfig dmfe0 10.90.50.44`。    
加载内核`load tftp://10.90.50.43/vmlinux`。     
启动内核`g`。   

内核`busybox`中可尝试运行`unixbench`。    
```
./ub.sh
cd pgms
./context1 10
```

内核暂不提供源码，仅提供两个二进制文件，分别用于综合和仿真。    
`pmon`提供源码，可使用编译后的`gzrom.zip`，或者到`pmon_archlab`中进行重新编译。具体流程：
```
cd zloader.ls1b
make cfg
make tgt=rom
```
当前内核及`pmon`仅适配`myCPU`处理器核。 

---
### LA32-NEMU
为帮助用户在仿真环境下调试内核，我们将会提供`difftest`环境，目前已完成[NEMU](https://gitee.com/wwt_panache/la32-nemu)的移植。
使用方法请参考[difftest说明](https://chiplab.readthedocs.io/zh/latest/Simulation/difftest.html)。

---
### 工具下载链接
http://114.242.206.180:24989/nextcloud/index.php/s/7xXTPkWg6Jn5KLW

---

### 常见问题
机器内存不够，建议关闭一些应用。
#### testbench无法编译
错误提示
```
g++: error: /usr/local/share/verilator/include/verilated.cpp: No such file or directory
g++: error: /usr/local/share/verilator/include/verilated_vcd_c.cpp: No such file or directory
```
根据verilator库文件所安装的位置，需要调整`sims/verilator/run/Makefile`内的`VERILATOR_HOME`变量。当机器上存在多个版本的verilator时，注意配置成相对应的库路径。

---
### 交流群
 [slack交流群](https://join.slack.com/t/chiplabworkspace/shared_invite/zt-v1927dwg-qqnHNTcAeko7QsUsdCRoPA)
