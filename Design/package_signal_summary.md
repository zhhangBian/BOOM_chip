```system verilog
typedef struct packed {
    logic [31:0]        pc;
    logic [ 1:0]        mask;
    predict_info_t [1:0]predict_infos;
} b_f_pkg_t;

typedef struct packed {
    logic [1:0][31:0]   insts;
    logic [31:0]        pc;
    logic [ 1:0]        mask;
    predict_info_t [1:0]predict_infos;
} f_d_pkg_t;

typedef struct packed {
    arf_table_t  arf_table; // 读写地址寄存器表
    logic  [1 :0]  r_valid; // 前端发射出来的指令有效
    logic  [1 :0]  w_reg;
    logic  [1 :0]  w_mem;
    logic  [3 :0]  reg_need; // 指令需要的寄存器
    // else controller signals
    logic  [1 :0][31:0] pc ; // 指令地址
    logic  [3 :0]   use_imm; // 指令是否使用立即数
    logic  [1 :0][31:0]   data_imm; // 数据立即数
    logic  [1 :0][31:0]   addr_imm; // 地址立即数
    // 指令类型
    logic  [1 :0]     alu_type; // 指令类型
    logic  [1 :0]     mdu_type;
    logic  [1 :0]     lsu_type;
} d_r_pkg_t;

typedef struct packed {
    logic  [1 :0]     alu_type; // 指令类型
    logic  [1 :0]     mdu_type;
    logic  [1 :0]     lsu_type;
    logic  [1 :0][`ARF_WIDTH - 1:0] areg;
    logic  [1 :0][`ROB_WIDTH - 1:0] preg;
    logic  [3 :0][`ROB_WIDTH - 1:0] src_preg;
    logic  [3 :0][31:0] arf_data;
    logic  [1 :0][31:0] pc ; // 指令地址
    logic  [1 :0]       r_valid;
    logic  [1 :0]       w_reg;
    logic  [1 :0]       w_mem;
    logic  [1 :0]       check;
    logic  [3 :0]       use_imm; // 指令是否使用立即数
    logic  [3 :0]       data_valid; // 对应数据是否为有效，要么不需要使用该数据，要么已经准备好
    logic  [1 :0][31:0] data_imm; // 立即数
} r_p_pkg_t;

typedef struct packed {
    logic    [3 :0][31:0] data; // 四个源操作数
    rob_id_t [3 :0]       preg; // 四个源操作数对应的preg id
    logic    [3 :0]       data_valid; //四个源操作数是否已经有效
    logic    [1 :0]       inst_choose;//选择送进来的哪条指令[1:0]分别对应传进来的两条指令
    // 控制信号，包括：
    // alu计算类型，jump类型
    // mdu计算类型
    // lsu类型
    // 异常信号
    // FU之前的一切异常信号
} p_i_pkg_t;

typedef struct packed {
    logic   is_uncached;
    logic  [3:0]  strb;
    logic  [3:0] rmask;     // 需要读的字节
    inv_parm_e   cacop;
    logic         dbar;     // 显式 dbar
    logic         llsc;     // LL 指令，需要写权限
    rob_id_t       wid;     // 写回地址
    logic      msigned;     // 有符号拓展
    logic  [1:0] msize;     // 访存大小-1
    logic [31:0] vaddr;     // 虚拟地址
    logic [31:0] wdata;     // 写数据
} iq_lsu_pkg_t;
```

## Dispatch 级需要的信号信号

```verilog
logic  [1 :0]     alu_type; // 计算类型
logic  [1 :0]     mdu_type; // 乘除类型
logic  [1 :0]     lsu_type; // 存储指令类型
logic  [1 :0][`ARF_WIDTH - 1:0] areg; // 写入的逻辑寄存器号
logic  [1 :0][`ROB_WIDTH - 1:0] preg; // 写入的物理寄存器号
logic  [3 :0][`ROB_WIDTH - 1:0] src_preg; // 需要的源物理寄存器号
logic  [3 :0][31:0] arf_data; // 逻辑寄存器中读取出的结果
logic  [1 :0][31:0] pc ; // 指令地址
logic  [1 :0]       r_valid; // 指令是否有效
logic  [1 :0]       w_reg; // 是否写寄存器
logic  [1 :0]       w_mem; // 是否读寄存器
logic  [1 :0]       check; // Tier ID
logic  [3 :0]       use_imm; // 指令是否使用立即数
logic  [3 :0]       data_valid; // 对应数据是否为有效，要么不需要使用该数据，要么已经准备好
logic  [1 :0][31:0] data_imm; // 立即数
```