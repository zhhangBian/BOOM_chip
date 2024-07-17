## 例外

#### 入口和优先级

* TLB 重填例外的入口来自于 CSR.TLBRENTRY。除上述例外之外的所有普通例外入口相同，来自于 CSR.EENTRY。此时需要软件通过 CSR.ESTA 中的Ecode、IS 域的信息来判断具体的例外类型。
* 优先级：中断 > 取指 > 译码 > 执行
取指时 取地址错 > tlb错
执行的时候 要求地址对齐的访存指令因地址不对齐而产生的地址对齐错例外(ALE) > TLB 相关的例外

#### 异常的识别：

* 按照 Ecode EsubCode 例外代号 例外类型 格式
* 0x0 0 INT 中断
    * 一个核间中断，一个定时器中断，8个硬中断，2个软中断。分别记录在csr.estat.is[9:0]和csr.estat.is[12:11]，SWI0 的中断号等于 0，SWI1 的中断号等于 1，……，IPI 的中断号等于 12。/*cpu每个周期从外来的中断信号采样到csr.estat.is[12:11]和[9:2]*/
    * 识别：
       `int_vec = CSR.ESTAT.IS & CSR.ECFG.LIE;`
       当 CSR.CRMD.IE（全局使能） 且 |int_vec时，有中断。有中断时从指令流中选一条（比如选当前提交的一条）标记上中断例外，并响应。
* 0x1 0 PIL  load 操作页无效例外     //tlb
* 0x2 0 PIS  store 操作页无效例外    //tlb
* 0x3 0 PIF  取指操作页无效例外      //tlb
* 0x4 0 PME  页修改例外             //tlb
* 0x7 0 PPI  页特权等级不合规例外    //tlb
//识别：从tlb一路传过来的信号中可以拿到错误号码
* 0x8 0 ADEF 取指地址错例外         //pc不是4字节对齐，tlb前
      1 ADEM 访存指令地址错例外     //不会出现
* 0x9 0 ALE  地址非对齐例外         //访存指令地址不是自然对齐时（访存.w->4/.h->2字节对齐），tlb前（hit类型下 CACOP 指令可能触发 TLB 相关的例外。不过，由于 CACOP指令操作的对象是 Cache 行，所以这种情况下并不需要考虑地址对齐与否。）
//识别：上面两个尚未写，预计可以从取值/访存模块一路传过来的信号中拿到错误码
* 0xB 0 SYS 系统调用例外           //decoder有指示信号
* 0xC 0 BRK 断点例外               //decoder有指示信号
* 0xD 0 INE 指令不存在例外         //decoder有指示信号
* 0xE 0 IPE 指令特权等级错例外     //decoder会标记当前是不是csr指令、是不是cacop指令、是不是tlb的各种指令，如果在用户态执行了这些指令（查csr.crmd.plv），就报IPE例外（除了hit类cacop指令）
//识别：可以从decoder传过来的信号中找到标记当前的指令是不是特定指令的信号，识别到了分别触发例外进行处理即可。其中IPE触发的条件是：1.当前指令是特权指令（并且不是hit类的cacop）；2. csr.crmd.plv为3。
* 0xF 0 FPD 浮点指令未使能例外   //csr.euen.fep为0时执行浮点指令触发，但我们没实现浮点应该不管这个
* 0x12 0 FPE 基础浮点指令例外    //无
* 0x1A-0x3E 保留编码            //无
* 0x3F 0 TLBR TLB 重填例外      //tlb
//从tlb一路传过来的信号可以拿到错误码

#### 处理
处理内容包括：
1.（全部）将 CSR.CRMD 的 PLV、IE 分别存到 CSR.PRMD 的 PPLV、PIE 中，然后将 CSR.CRMD 的 PLV 置为 0，IE 置为 0；
2.（全部）将触发例外指令的 PC 值记录到 CSR.ERA 中；
3.（全部）将例外的ecode和esubcode写入csr.estat对应域中；
4.（当触发TLBR,ADEF,ALE,PIL,PIS,PIF,PME,PPI例外时），将出错的虚地址（ADEF为PC，TLBR为根据触发例外的地址，其他为访存地址）写入CSR.BADV中；
5.（当触发 TLB 重填例外、load 操作页无效例外、store 操作页无效例外、取指操作页无效例外、页写允许例外和页特权等级不合规例外时），触发例外的虚地址的[31:13]位被记录到CSR.TLBEHI.VPPN；
6.（全部）如果是0x3F 0 TLBR TLB 重填例外，跳到CSR.TLBRENTRY，其他跳转到例外入口CSR.EENTRY处取指；
7.（全部）刷掉流水线。