# “龙芯杯”第七届全国大学生计算机系统能力培养大赛 - 初赛设计报告
——北京航空航天大学 2 队 - BOOM

## 目录
- 一、CPU 内核设计
  - 1.1 总体设计
    - 1.1.1 前端 Frontend
    - 1.1.2 后端 Backend
    - 1.1.3 访存 Memory
  - 1.2 分支预测 Branch Predict
  - 1.3 取指 Inst Fetch
  - 1.4 译码 Decoder
  - 1.5 寄存器重命名 Rename
  - 1.6 分发 Dispatch
  - 1.7 发射 Issue
  - 1.8 执行 Execute
    - 1.8.1 算术逻辑指令 ALU
    - 1.8.2 乘除指令 MDU
    - 1.8.3 访存指令 LSU
  - 1.9 转发 CDB
  - 1.10 重排序 Re-ordered
  - 1.11 提交 Commit
- 二、SoC 与外设实现
  - ???
- 三、系统软件支持
  - ???

## 一、CPU 内核设计

### 1.1 总体设计

![Overview](images/Structure.png)

### 1.2 分支预测 Branch Predict

![BPU](images/BPU.jpg)

### 1.3 取指 Inst Fetch

### 1.4 译码 Decoder

### 1.5 寄存器重命名 Rename

### 1.6 分发 Dispatch

### 1.7 发射 Issue

### 1.8 执行 Execute

#### 1.8.1 算术逻辑指令 ALU
    
#### 1.8.2 乘除指令 MDU

#### 1.8.3 访存指令 LSU

### 1.9 转发 & 唤醒 CDB

![wkup_forward](images/wkup_forward.png)

### 1.10 重排序 Re-ordered

### 1.11 提交 Commit



## 二、SoC 与外设实现

## 三、系统软件支持