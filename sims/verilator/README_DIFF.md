# DiFFTEST 使用说明

DIFFTEST的比对对象是两个核，一个是用户设计的核，一个是参考核。 比对原理是设计核在每执行一条指令的同时使参考核执行相同的指令，之后比对所有的通用寄存器和csr寄存器(除estat寄存器)的值，如果完全相同则认为设计核执行正确。 同时， DIFFTEST比对机制也实现了对于store指令的比对，一旦store指令中的物理地址和存储数据与参考核不同，也会立即暂停仿真，以此来尽早定位错误。

DIFFTEST使用的参考核为经过移植的la32-nemu, 在本仓库中只提供编译成功后的动态链接文件(`nemu/la32-nemu-interpreter-so`)，相关的说明和源代码请见代码仓库：[la32-nemu](https://gitee.com/wwt_panache/la32-nemu/tree/chiplab_diff/)

## DPIC 接口说明

DPIC涉及到的文件及相关内容介绍见下：

- `difftest.v`中定义了所有dpic相关的 verilog module 信息，这些 module 中会调用c函数用来传输信号。这些 module 会被设计核实例化用来传输信号。
- `mycpu_top.v`中实例化了`difftest.v`中定义的 module。
- `interface.h`是c函数的实现，c函数将设计核的信号赋值给difftest中的变量。

数据流传递方向可简单地认为是`mycpu_top.v`->`difftest.v`->`interface.h`

使用者需要将`mycpu_top.v`中相关 verilog module 例化信号接到自己核中相应的信号上，下面简单地介绍一下各个信号的作用，案例可参考本仓库中`IP/myCPU/mycpu_top.v`。

1. `DifftestInstrCommit` 指令提交信息

2. `DifftestExcpEvent` 指令中的异常信息

3. `DifftestTrapEvent`

4. `DifftestStoreEvent` store指令信息

5. `DifftestLoadEvent` load指令信息

6. `DifftestCSRRegState` csr寄存器信息

7. `DifftestGRegState` 通用寄存器信息

## 功能测试

**功能测试中所有功能测试模块均可正常执行[<font color='red'>TODO: 需要进行测试</font>]**。但为加快仿真速度，只对`func/func_lab16`中的`start.S`做了部分修改，并将原来的`start.S`保存为`start.S.bak`。