# Chiplab用户手册 
## 前言
chiplab项目致力于构建基于LoongArch32 Reduced的soc敏捷开发平台。如发现问题请在issues提出。
## 目录结构
.   
├── chip&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;SoC顶层。    
│　　└── soc_demo&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;SoC顶层代码实例。   
│　　　　　├── loongson&emsp;&emsp;&emsp;&ensp;龙芯实验箱SoC顶层代码。   
│　　　　　├── Baixin&emsp;&emsp;&emsp;&emsp;&emsp;&ensp;百芯开发板SoC顶层代码。   
│　　　　　└── sim&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;仿真SoC顶层代码   
├── fpga&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;综合工程。   
│　　└── loongson&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;龙芯实验箱综合工程。   
│　　└── Baixin&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;百芯开发板综合工程。   
├── IP&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&ensp;SoC IP。   
│　　├── AMBA&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;总线 IP。    
│　　├── APB_DEV&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;APB协议通信设备。    
│　　　　　├── URT&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&ensp;UART设备控制器。   
│　　　　　└── NAND&emsp;&emsp;&emsp;&emsp;&emsp;NAND设备控制器。   
│　　├── AXI_DELAY_RAND&emsp;&emsp;随机延迟注入。    
│　　├── AXI_SRAM_BRIDGE&emsp;&ensp;AXI协议 -> SRAM接口转换。    
│　　├── BRIDGE&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;1x2桥接模块。    
│　　├── DMA&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;DMA逻辑，用于设备作为master访问内存。    
│　　├── SPI&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&ensp;SPI Flash设备控制器。    
│　　├── MAC&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;MAC设备控制器。    
│　　├── CONFREG&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;用于访问开发板上数码管、拨码开关等外设以及特殊寄存器。   
│　　├── myCPU&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;处理器核逻辑。  
│　　└── xilinx_ip&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;Vivado平台所创建的IP。   
├── sims&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;运行仿真以及存放testbench源码。   
│　　└── verilator&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;以verilator仿真工具为基础。   
│　　　　　├── run_prog&emsp;&emsp;&emsp;&emsp;测试程序运行目录，包括func、性能测试程序、内核等。   
│　　　　　├── run_random&emsp;&emsp;&ensp;随机指令序列运行目录。   
│　　　　　└── testbench&emsp;&emsp;&emsp;&ensp;testbech源码，提供仿真运行、在线比对、设备模拟等功能。   
├── software&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&ensp;测试用例。   
│　　├── coremark&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&ensp;coremark性能测试程序。   
│　　├── dhrystone&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&ensp;dhrystone性能测试程序。  
│　　├── func&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;功能测试点，验证处理器核设计是否与指令手册一致。   
│　　├── linux&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&ensp;提供内核启动的支持。   
│　　├── random_boot&emsp;&emsp;&emsp;&emsp;&emsp;为随机指令序列的运行提供支持。   
│　　├── random_res&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;存放随机指令序列。   
│　　└── generic&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;通用的编译脚本。   
└── toolchains&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;chiplab运行所需工具。    
　　　├── loongarch32r-linux-gnusf-\*&emsp;&emsp;&emsp;gcc工具链。  
　　　├── nemu&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;nemu模拟器，用于在线实时比对。   
　　　└── system_newlib&emsp;&emsp;&emsp;&emsp;newlib C库，用于编译C程序。

## 使用方法
### toolchains工具下载
toolchains这个目录是存在的，只不过里面是空的，需要用户自行下载，详情请参考`toolchains/README.md`。

### 项目所需第三方工具安装
以Ubuntu (Windows 10+ 请基于WSL**2**)为例:
```
# 终端运行
sudo apt install verilator gtkwave #verilator version 4.224 (loongarch64 4.222+)    
```

### 实验步骤

#### 参数设置
设置CHIPLAB_HOME系统变量  
```
# 终端运行
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
- `run_prog` : 该工作目录下可运行`func`测试用例、`dhrystone`、`coremark`性能测试程序、`linux`以及自定义C程序。
- `run_random` : 该工作目录下可进行随机指令序列测试。 

具体使用方法请参考[verilator仿真环境说明](https://chiplab.readthedocs.io/zh/latest/Simulation/verilator.html)。
     
#### 综合
该步骤的工作目录位于`fpga`，当前支持龙芯实验箱及百芯开发板。  
使用vivado打开`loongson/system_run/system_run.xpr`或者`Baixin/system_run/system_run.xpr`工程文件，添加处理器核代码后，可直接开始综合。    
处理器核输入时钟频率默认为33MHz，可对`clk_pll_33`xilinx IP的输出时钟频率进行调整，修改处理器核的输入时钟频率。此外，还需将`chip/soc_demo/loongson/config.h`或者`chip/soc_demo/Baixin/config.h`文件中的`FREQ`宏定义修改为对应频率。
#### 板上启动内核
板上内核启动步骤包括：`flash`加载`pmon`，通过网口加载内核。   
内核由[龙芯教育/la32r-Linux](https://gitee.com/loongson-edu/la32r-Linux)仓库提供源码。    
pmon直接提供二进制文件。  [(下载地址)](http://114.242.206.180:24989/nextcloud/index.php/s/Ez3sNJBzCeoQ2Ct)    
具体流程请参考[pmon运行并load内核启动的方法](./FPGA_run_linux/linux_run.md)           
内核中可尝试运行`unixbench`。    
```
./ub.sh
cd pgms
./context1 10
```    
内核与处理器核部分硬件参数绑定，比如频率、Cache等。内核编译时需确保参数设置与处理器核设计统一。 

---

### 常见问题
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
