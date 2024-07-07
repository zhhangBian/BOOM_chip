`include "a_defines.svh"

// TEMP!!! 结构体定义：后面放入头文件中
typedef struct packed {
    // static info
    logic [1 : 0] type;
    logic [4 : 0] areg;  // 目的寄存器
    logic [31: 0] pc;    // 指令地址
    logic         issue; // 是否被分配到ROB
} dispatch_rob_pkg_t;

typedef struct packed {
    logic [31: 0] w_data;
    logic [4 : 0] w_areg;
    logic         w_reg;
    logic         w_mem;
} commit_rob_pkg_t;

module rob #(
) (
    input clk,
    input rst_n,
    input dispatch_rob_pkg_t [1 : 0] dispatch_info_i,

);

///////////////////////////////////////////////////////////////////////////////////////
// P级行为：
// 1. 分配ROB表项，并将指令控制信息和有效信息写入ROB；
// 2. 从PRF中尝试读出所需数据，例如源操作数，以及是否使用PRF中的数据；
///////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////
// C级行为：
// 1. 根据指令是否有效，决定是否需要将数据写入ROB对应表项中PRF；
// 2. 取出ROB最旧的且有效的表项，并将其中数据写入ARF中，或者将数据由SB写入Cache中；
///////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////
// E级行为：
// 1. 将执行完成的结果以CDB写入ROB对应表项中；
///////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////
// 规格说明： ROB 共 64 项
// 指   针： 两个头指针对应最新的两项，两个尾指针对应最旧的两项，每次选择退休的指令为最旧的指令
// 指令信息： 指令类型(TYPE)、写入的目的寄存器(AREG)、对应PC地址
// 有效信息： 指令是否已经被执行完毕(COMPLETE)
// 数据信息： 指令产生的数据(DATA)
// 控制信息： 指令产生的控制信号(CTRL)
///////////////////////////////////////////////////////////////////////////////////////

/*
指令信息表项： | TYPE(1:0) | AREG(4:0) | PC(31:0) |
有效信息表项： | COMPLETE(0:0) |
数据信息表项： | DATA(31:0) |
控制信息表项： | EXCEPTION | BPU FAIL | 
*/

// 头指针 & 尾指针
logic [`ROB_WIDTH - 1 : 0] head_ptr0,   head_ptr1,   tail_ptr0,   tail_ptr1;
reg   [`ROB_WIDTH - 1 : 0] head_ptr0_q, head_ptr1_q, tail_ptr0_q, tail_ptr1_q;

// ff
always_ff @(posedge clk) begin
    if (!rst_n || flush_i) begin
        head_ptr0_q <= '0;
        head_ptr1_q <= '1;
        tail_ptr0_q <= '0;
        tail_ptr1_q <= '1;
    end else begin
        head_ptr0_q <= head_ptr0;
        head_ptr1_q <= head_ptr1;
        tail_ptr0_q <= tail_ptr0;
        tail_ptr1_q <= tail_ptr1;
    end
end
// comb
assign head_ptr0 = head_ptr0_q + dispatch_info_i[0].issue + dispatch_info_i[1].issue;
assign head_ptr1 = head_ptr1_q + dispatch_info_i[0].issue + dispatch_info_i[1].issue;
assign tail_ptr0 = tail_ptr0_q + dispatch_info_i[0].issue + dispatch_info_i[1].issue;
assign tail_ptr1 = tail_ptr1_q + dispatch_info_i[0].issue + dispatch_info_i[1].issue;

// 指令信息表项
typedef struct packed {
    logic [1 : 0] type;
    logic [4 : 0] areg;
    logic [31: 0] pc;
} rob_inst_t;

// 有效信息表项
typedef struct packed {
    logic complete;
} rob_valid_t;

// 数据信息表项
typedef struct packed {
    logic [31: 0] data;
} rob_data_t;

// 控制信息表项
typedef struct packed {
    // 异常控制信号流，其他控制信号流，后续补充
    logic exception;
    logic bpu_fail;
} rob_ctrl_t;

// 寄存器堆用bank做



endmodule