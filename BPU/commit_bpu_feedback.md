1. better classification
指示分支指令本身的信息的参数
- is_br - 是不是分支指令
- br_type - 是什么类型的分支指令
    - 2'b00: BR_NORMAL
    - 2'b01: BR_B
    - 2'b10: BR_RET
    - 2'b11: BR_CALL
    - 
    - 非零： 无条件跳转。
    - 2'b?1: 无条件跳转，目标确定。