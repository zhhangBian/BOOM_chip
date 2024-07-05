通过对发射队列条目信号的整理，进一步梳理发射，wkup和cdb转发的逻辑

## 输入的信息：

```asm
input rst_n;
input clk;
```

* 当前指令的指令地址、寄存器编号和数据信息:

  ```asm
  input [31:0]       pc;
  input              instr_valid;
  input [5:0]        dest_rob_id;
  input [4:0]        dest_arf_id;
  input [1:0][5:0]   src_rob_id;
  input [1:0][31:0]  data;
  input [1:0]        data_valid; //如果指令有效但是不用这个寄存器的话要输入valid
  input [?:0]        exc_info;
  input              special_info;
  ```

* 来自CDB的信息:

  ```asm
  input [1:0][5:0]   cdb_rob_id;
  input [1:0][31:0]  cdb_data;
  input [1:0]        cdb_valid;
  ```

* 来自wake_up的信息(唤醒):

  ```asm
  input [2:0][5:0]   wkup_rob_id;
  input [2:0][31:0]  wkup_data;
  input [2:0]        wkup_valid;
  ```

* （背靠背唤醒后，转发过来的数据):

  ```asm
  input [31:0]       wkup_forward;
  input [5:0]        wkup_forward_src;
  input              wkup_forward_valid;
  //统一把转发看成是存入，只不过如果恰好被选中有一个内部转发
  ```

* 来自iq仲裁器的信息:

  ```asm
  input              sel;
  ```

# 内部存储的信息：

```asm
logic [31:0] pc;
logic        entry_valid;
logic [5:0]  dest_rob_id;
logic [4:0]  dest_arf_id;
logic [5:0]  src1_rob_id;
logic [5:0]  src2_rob_id; 
logic [31:0] data1;
logic [31:0] data2;
logic        data1_valid;
logic        data2_valid;
logic        wkup; //表示是被背靠背唤醒的
logic [5:0]  wkup_src;
logic [?:0]  exc_info;
special_info_t special_info;
```


# 输出的信息：
* 给iq仲裁
  :

  ```asm
  input              sel;
  ```

* 给FU:

  ```asm
  output [31:0]       pc;
  output              entry_valid;//也给dispatch
  output [5:0]        dest_rob_id;
  output [4:0]        dest_arf_id;
  output [1:0][5:0]   src_rob_id;
  output [1:0][31:0]  data;
  output [?:0]        exc_info;
  output              special_info;
  //上面这些输出被拿去执行以后也交给每一个iq条目来背靠背唤醒
  ```

  
