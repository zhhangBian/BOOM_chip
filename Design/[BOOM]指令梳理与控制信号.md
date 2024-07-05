# 指令梳理

## 算数指令（包含移位指令）

- 在执行单元中进行处理
- 信号包括：
  - 数据通路的选择
  - 数据来源的选择：设置多位宽的控制信号进行选择
    - rk
    - rj
    - 立即数
    - PC
  - ALU/MDU的控制信号

具体逻辑见下控制信号梳理中的ALU部分

## 访存指令

- 大部分访存指令在LSU中进行，可以在解码部分进行数据预取
- 部分指令需要在提交级进行处理（对Cache、TLB的维护指令）
- 对于一些预取指令，需要提前发向总线发送数据请求，加载数据
- 信号包括：
  - 数据ready
  - 数据阻塞
  - 访存地址为

## 跳转指令

- 分支预测
- 信号包括：
  - 是否为分支指令：送往BPU
  - 为立即数跳转/寄存器跳转
- 对于JIRL指令，是唯一的从寄存器中读地址的指令，可以单独做优化

## 异常/中断指令

- syscall
- break
- ertn：从中断中返回
- idle：停止取指（刷流水），直至外部中断发生

在提交级触发中断，写相应的CSR寄存器来进行相应的操作设置

## CSR指令

- `csrrd rd, csr_num`：将指定CSR的值写入到通用寄存器rd中
- `csrwr rd, csr_num`：将通用寄存器rd中的旧值写入到指定CSR中，同时将指定CSR的旧值更新到通用寄存器rd中

## TLB/Cache维护指令

目前感觉不做也不影响功能，且处理起来比较复杂，可以先不做

比赛评测不要求，启动系统中是否影响功能存疑

==需要做，预取不需要==

# 控制信号梳理

==握手信号、不同流水级的交互信号==

对于耦合关系的控制：

- 是由buffer在外控制数据的ready还是内置相应元件
- 输出有相应的ready信号，对于buffer数量的控制

![架构图](https://pigkiller-011955-1319328397.cos.ap-beijing.myqcloud.com/img/202407041637578.png)

## 全局控制信号

- flush：刷流水
  - 由提交级判断，发出信号
- 中断信号
  - 由前向后传递，打包在传递的控制信号流中
- 前后端进行交互信号
  - 前端
    - ready信号
    - mask信号

  - 后端
    - //

## BPU

BPU仅与ICache进行连接，需要在中间加入一个Skidbuffer，进行缓冲

与后续的SkidBuffer的握手信号：

- 输入的ready信号：SkidBuffer输出的可以接收信号的ready信号
- 输出的valid信号：输出给SkidBuffer的生成数据、数据有效的valid信号

## ICache

ICache前是Skidbuffer，后是FIFO，需要进行分别握手

并且，LSU-IQ也可能会访问ICache中的数据，也需要进行相应的握手（通过总线进行）

握手信号：

- // 与前面Skidbuffer的握手信号
- 输入的valid信号：前序Skidbuffer输出的PC有效信号，用于拿到PC
- 输出的ready信号：与Skidbuffer进行握手，可以接收PC
- // 与后面的FIFO的握手信号
- // 在wired中是`lsu_resp`前缀的信号
- 输出的数据有效valid：可以有有效的数据输出给FIFO
- 输入的接收ready信号：FIFO可以接收数据
- // 与LSU-IQ进行的握手：通过总线进行
- 输入的总线ready信号：LSU请求ready
- 输出的valid信号：ICache中数据有效，可以进行总线请求

## FIFO

所有的FIFO都是有同一结构的，由宏实现了泛型（在硬件中的不同类型即不同的数据打包类型）

握手信号：

- // 前面输入的组件
- 输入的数据有效valid
- 输出的相应ready：可以输入相应的数据
- // 后面输出的组件
- 输出的数据有效valid
- 输入的相应ready：FIFO可以输出相应的数据

## Decoder

主要控制信号：

- 输入的指令
- 输出的全部控制信号
  - 后续由所有原件进行汇总
- 输出给buffer的ready信号

握手信号：

- 不进行握手，纯粹的组合逻辑

可能用到的：

```systemverilog
decode_err_o = 1'b1;	// 用于指示指令是否为异常指令
ertn_inst = 1'd0;
priv_inst = 1'd0;
wait_inst = 1'd0;
syscall_inst = 1'd0;
break_inst = 1'd0;
csr_op_en = 1'd0;
csr_rdcnt = 2'd0;
tlbsrch_en = 1'd0;
tlbrd_en = 1'd0;
tlbwr_en = 1'd0;
tlbfill_en = 1'd0;
invtlb_en = 1'd0;
fpu_op = 4'd0;
fpu_mode = 1'd0;
rnd_mode = 4'd0;
fpd_inst = 1'd0;
fcsr_upd = 1'd0;
fcmp = 1'd0;
fcsr2gr = 1'd0;
gr2fcsr = 1'd0;
upd_fcc = 1'd0;
fsel = 1'd0;
fclass = 1'd0;
bceqz = 1'd0;
bcnez = 1'd0;
inst = inst_i;
alu_inst = 1'd0;
mul_inst = 1'd0;
div_inst = 1'd0;
lsu_inst = 1'd0;
fpu_inst = 1'd0;
fbranch_inst = 1'd0;
reg_type_r0 = `_REG_ZERO;
reg_type_r1 = `_REG_ZERO;
reg_type_w = `_REG_W_NONE;
imm_type = `_IMM_U5;
addr_imm_type = `_ADDR_IMM_S26;
slot0 = 1'd0;
refetch = 1'd0;
need_fa = 1'd0;
fr0 = 1'd0;
fr1 = 1'd0;
fr2 = 1'd0;
fw = 1'd0;
alu_grand_op = 3'd0;
alu_op = 3'd0;
target_type = 1'd0;
cmp_type = 4'd0;
jump_inst = 1'd0;
mem_type = 3'd0;
mem_write = 1'd0;
mem_read = 1'd0;
mem_cacop = 1'd0;
llsc_inst = 1'd0;
dbarrier = 1'd0;
```

## Pipereg

接在Decoder后面用作流水寄存器，用于暂存一部分数据

逻辑和Skidbuffer一致，但是不能直接导通，相当于一个需要握手信号的寄存器

握手信号：

- 输入的valid：前序原件数据是否有效
- 输出的ready：能否对前序原件响应
- 输出的valid：能否给后续原件有效数据
- 输入的ready：后续原件的响应

## Packer

作用为在流水寄存器和后续Rename前的FIFO起到一个对齐的作用

内置了一个SkidBuffer，积累两条指令再发射

握手信号：

- 即为普通的valid-ready
- 内部处理逻辑为判断指令的冲突与发射情况

## Rename

主要控制信号：

- 输入的ready信号
- 输入的mask信号
- 输入的物理寄存器id*4
- 输出的PRF中相应表项是否有效
- 输入的ROB指针
- 输入的ROB相应表项的信息：用于判断是否能够退休
- TODO：后续Dispatch的输入信号 or 直接在后续加上一个buffer
- 输出的重命名后的端口
- 连接数据通路传递的
- 输入的对原有重命名的撤销：
  - TODO：直接按照刷流水，直接抹掉整个RAT吗？

## Dispatch

> TODO：是否将Dispatch与IQ耦合

主要控制信号：

- ROB输入的唤醒信息
- 输入的ROB就绪信息
- 输入的CDB数据前递信息
- 输出到IQ的就绪信息
  - 指令
  - 控制信号
  - 数据
- 输出的背靠背唤醒信息
  - TODO：还不是很清楚原理
- 输出的发射信息
- 输出到ROB的数据预唤醒信息



## ROB

> 这里没有具体区分ROB和RAT的实现，在后续中可以拆分

主要控制信号：

- 输出的相应表项有效信息：与Rename核对
- 输入的流入的指令信息
  - PC
  - Rename后相应的寄存器id
- 输入的ready信号
- 输入的移动ROB指针信息
  - 在提交后后移指针
- 输入的ALU/MDU/LSU的旁路转发数据
  - 进行提前唤醒
- 输入的CDB提前唤醒信息
- 输入的commit查询的寄存器id*2
- 输出的commit有限信息*2
- 输出的ROB是否满/空状态信息
- 输出的ROB指针信息
- 输出给Dispatch的唤醒信息
  - 数据是否就绪
- 输出到CDB的数据、唤醒信息

## ALU

主要控制信号：

- 操作类型grand_op+op
- 操作数选择
- 数据准备好的ready信号
- 相应的输入数据
  - PC
  - rj
  - rk
  - 指令inst
- 输入输出的异常码

将数据源区分为如下，利用不同控制信号进行区分

- reg_rk
- reg_rj
- imm
- 0

不将PC视作一种数据类型，视作一种特定的操作

将操作分为如下类，在每个类下再定义分别的控制信号，不同类下的控制信号可重复：

- 逻辑操作（与、或之类）：bw_result
  - ~|
  - &
  - |
  - ^

- 与移位值相关（PCADDI也是）的操作：li_result
  - lui
  - pcaddi

- 与常规运算相关的操作（add，sub，slt）：int_result
  - add
  - sub
  - slt
  - sltu

- 移位操作：sft_result
  - `>>`
  - `<<`
  - `>>>`
  - `<<<`


先判断类型grand_op，再在每个类下进行判断op

## MDU

数据选择同ALU，操作数方面可进行简化

操作较为常规，直接给出相应op，进行计算即可

| 二进制码 | 操作       |
| -------- | ---------- |
| 000      | 无操作     |
| 001      | \*（mul）  |
| 010      | \*（mulh） |
| 011      | div        |
| 100      | mod        |

## LSU

主要控制信号：

- 外部指令的ready信号
- 输入的有关控制信号
  - 1
- 输入的数据：这里认为输入的数据是经过转发的正确数据
  - rj
- 输出的可以接收新指令的ready信号
- 输出的读取信号
- 输出的与CDB接口的信号
- 进行的Cache预取指令
  - 提前发出总线请求信号
  - ==可能的优化不大==

## Store Buffer

主要控制信号：

- 输入的外部ready信号
- 输入的相关数据、地址、读写类型（字、半字）
- 输入的写指令退休信号
  - 退休的指令id
- 输入的写指令无效信号
  - 无效的指令id
- 输出的完成当前写入的ready信号
- 输出的总线控制信号：完成真正的写

## Commit

主要控制信号：

- 输入的异常汇总信号
  - 常规异常
  - uncached
  - 外部中断
  - 访问CSR指令
- 输入的ALU/MDU/LSU完成ready信号
- 输入的指令PC
- 输入的ROB相关表项有效信号*2
- 输出的与ROB/SB的握手、有效信号
- 输出到ROB/ARF的更新信号
- 输出的ROB退休编号
- 输出到ROB的指针推移信号
- 输出到LSU的提交信号
- ==输出的FLUSH信号==
- 输出的CSR控制信号
- 输出到BPU的分支更新信号