## BPU 信号梳理

### 一、各个部件表项梳理

### 二、predict_info 信号梳理

跳转目标 PC 可能为：
1. (NORMAL && taken) | CALL -> BTB
2. NONE | (NORMAL && !taken) -> PC + 4/8
3. RET -> RAS

### 三、correct_info 信号梳理

分支预测更新的可能原因有：
- 目标地址预测失误。
- need_update 或 update。
- taken 判断失误(不需要)

此外修正信息还需要提供正确的信息，包括：
1. 分支指令类型（NONE, NORMAL, CALL, RET）
2. 是否跳转（1, 0）
3. 是否是无条件跳转（B, BL, JIRL）
4. 历史
5. 饱和计数器

correct_info 需要修正四个地方：BTB, BHT, PHT, RAS.

#### 1. BTB

BTB 的更新的条件有：
1. 目标地址预测失误
2. 指令类型识别错误

更新内容为 correct_info.target_pc

#### 2. BHT

BHT 的更新条件有：
1. commit 级遇到了分支指令就要根据 taken 更新 BHT

更新内容需要分类：
1. 指令类型预测错误（或tag miss）

#### 3. PHT

PHT 的更新条件有：
1. commit 级遇到了分支指令就要根据 taken 更新 PHT

#### 4. RAS

RAS 的更新条件有：
1. 后端遇到了 BL 指令，则压栈。
2. 后端遇到了 JIRL 指令，则出栈。

此外， g_flush 信号的效果应该为：将 PC 设置为 redirPC 。（从某种角度上来说是不是不需要 redir 信号了？）