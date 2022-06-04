# verilator仿真环境说明
`prog`和`random`运行环境分别位于`run_prog`和`run_random`，进入目录进行相应的工作。
## Quick Start
以下为一个简单的仿真例程，方便用户快速上手仿真过程。在进行仿真之前，用户需安装好verilator、gtkware以及nemu。
```
cd $CHIPLAB_HOME/sims/verilator/run_prog #进入验证程序仿真目录中
./configure.sh --run func/func_lab16     #以仿真运行的程序func_lab16为例子生成对应的Makefile
make                                     #开始编译。若没有编译出错，会自动进行仿真。
cd $CHIPLAB_HOME/sims/verilator/run_prog/log/func/func_lab16_log
gtkwave simu_trace.vcd                   #查看仿真波形
```


详细说明，请参考[verilator仿真环境说明](https://chiplab.readthedocs.io/en/latest/Simulation/verilator.html)。
