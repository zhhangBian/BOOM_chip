'''Examples:
    python qemu_log_split.py qemu.log --rf qemu_rf.log --mem qemu_mem.log 
'''
import os
import sys
def _wrap_stream(lines):
    for line in lines:yield line
    while True:yield None
class Parser:
    def __init__(self):pass
    asm_brlink_names = {'bl','jirl'}
    asm_branch_names = {'b','bne','beq','bge','blt','bgeu','bltu','beqz','bnez'}
    asm_rdtime_names = {'rdtimeh.w','rdtimel.w','rdtime.d'}
    asm_uncare_names = asm_branch_names|asm_rdtime_names
    def parse_asm(self,asm,endian):
        lines = open(asm,'rt').readlines()
        self.insts,self.datas,self.funcs = parse_asm(lines,endian)
        
        self.asm_brlinks = set()
        self.asm_uncared = set()
        self.asm_syscall = set()
        for loc,name in self.insts.items():
            if name == 'syscall':
                self.asm_syscall.add(loc)
            elif name in self.asm_brlink_names:
                self.asm_brlinks.add(loc)
                self.asm_uncared.add(loc)
            elif name in self.asm_uncare_names:self.asm_uncared.add(loc)
        return self
    def parse_log(self,path):
        self.cpu_tracing = []
        self.cpu_syscall = []
        self.mem_tracing = []
        self.mem_initial,self.mem_written = merge_data32(self.datas,3)
        self.mem_current = self.mem_initial.copy()
        self.mem_syscall = []
        with open(path,'rt') as f:
            lines = f.readlines()
            trace = _wrap_stream(lines)
            line = next(trace)
            assert line.startswith('pc=0x')
            self.reginit = Status(line,trace)
            self.rf_last = self.reginit
            line = next(trace)
            while not line is None:
                if line.startswith('[cpu '):self.parse_log_mem(line,trace)
                else:self.parse_log_cpu(line,trace)
                line = next(trace)
        return True
    mem_op_codes   = {
        'LDval'  :0x003,'SDval'  :0x103,
        'LDC1val':0x023,'SDC1val':0x123,
        'LLval'  :0x042,'SCval'  :0x142,
        'LWval'  :0x002,'LWUval':0x012,'SWval':0x102,
        'LHval'  :0x001,'LHUval':0x011,'SHval':0x101,
        'LBval'  :0x000,'LBUval':0x010,'SBval':0x100}
    def parse_log_mem(self,line,trace):
        words = line.split(' ')
        pc   = int(words[5][2:-1],16)
        addr = int(words[7],16)
        data = int(words[10],16)
        op   = words[9]
        code = self.mem_op_codes[op]
        mask = (1<<(8<<(code&0xf)))-1
        # pc addr data mask op
        self.mem_tracing.append((pc,addr,data,code))
        
        addr64 = addr&~0x7
        method = self.parse_log_mem_ld if op[0] == 'L' else self.parse_log_mem_st
        offset = (addr&0x7)<<3
        mask64 = 0xffffffffffffffff
        mask <<= offset
        data <<= offset
        method(addr64,data&mask64,mask&mask64)
        mask>>=64
        if mask:
            data>>=64
            method(addr64,data&mask64,mask&mask64)
        
        
    def parse_log_mem_ld(self,addr,data,mask):
        v = self.mem_current.get(addr,0)
        w = self.mem_written.get(addr,0)
        if (v&w&mask) != (data&w&mask):raise ValueError('Unconsistent memory load detected.')
        if mask&~w:
            self.mem_written[addr] = mask|w
            self.mem_write64(self.mem_current,addr,data,mask)
            if len(self.mem_syscall)==0:
                # some values are loaded in stack, not defined in ELF file
                self.mem_write64(self.mem_initial,addr,data,mask)
            elif (v&mask)!=(data&mask):
                # after a syscall, values in memory could be changed by OS
                if addr not in self.mem_syscall[-1]:
                    self.mem_syscall[-1][addr] = (data,mask)
                else:
                    prev_data,prev_mask = self.mem_syscall[-1][addr]
                    next_data = prev_data&prev_mask|data&mask&~w&~prev_mask
                    next_mask = prev_mask|mask&~w
                    if next_mask&~prev_mask:self.mem_syscall[-1][addr] = (next_data,next_mask)
    def parse_log_mem_st(self,addr,data,mask):
        self.mem_written[addr] = mask|self.mem_written.get(addr,0)
        self.mem_write64(self.mem_current,addr,data,mask)
    def mem_write64(self,mem,addr,data,mask):
        mem[addr] = data&mask|mem.get(addr,0)&~mask
    def parse_log_cpu(self,line,trace):
        status = Status(line,trace)
        pc,diff = status.diff(self.rf_last)
        if pc in self.asm_syscall:
            self.cpu_syscall.append((pc,status))
            self.mem_syscall.append({})
            self.mem_writing = {}
        care = 0 if pc in self.asm_uncared else 1
        if pc in self.asm_brlinks and 1 in diff:
            self.cpu_tracing.append((0,pc,{1:pc+4}))
            if pc+4 == diff[1]:del diff[1]
            care = 0
        if len(diff)>0:  
            self.cpu_tracing.append((care,pc,diff))
        self.rf_last = status 
    def dump_reginit(self,path):
        if path == 'none' or self.reginit is None:return
        with open(path,'wt') as f:
            self.reginit.display(file=f)
    def dump_rftrace(self,path):
        if path == 'none':return
        with open(path,'wt') as f:
            for care,pc,diff in self.cpu_tracing:
                print('1 %08x %d '%(pc,len(diff)) + ' '.join('%02x %08x'%(i,v) for i,v in diff.items()),file=f)
                #print('%d %08x %d '%(care,pc,len(diff)) + ' '.join('%02x %08x'%(i,v) for i,v in diff.items()),file=f)
    def dump_syscall(self,path):
        if path == 'none':return
        with open(path,'wt') as f:
            for i in range(len(self.cpu_syscall)):
                pc , status = self.cpu_syscall[i]
                mem_changes = self.mem_syscall[i]
                print('%016x %016x %d'%(pc,status.pc,len(mem_changes)),file=f)
                for i in range(0,32,4):print('%016x %016x %016x %016x'%tuple(status.rf[i:i+4]),file=f)
                for addr,v in mem_changes.items():
                    data,mask = v
                    print('%016x %016x %016x'%(addr,data,mask),file=f)
    def dump_raminit(self,path,endian):
        if path == 'none':return
        format_ram(self.mem_initial,path,endian)
    def dump_f_range(self,path):
        if path == 'none':return
        format_frange(self.funcs,path)
def parse_and_dump(args):
    p = Parser()
    p.parse_asm(args.asm,args.asm_endian)
    p.dump_f_range(args.dump_f_range)
    p.parse_log(args.log)
    p.dump_reginit(args.dump_reginit)
    p.dump_rftrace(args.dump_rftrace)
    p.dump_syscall(args.dump_syscall)
    p.dump_raminit(args.dump_raminit,args.ram_endian)
if __name__ == '__main__':
    from qemu_log_status import Status
    from parse_asm import parse_asm,format_ram,format_frange,merge_data32
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--asm')
    parser.add_argument('--asm-endian',default='GE')
    parser.add_argument('--log',default='qemu.log')
    parser.add_argument('--dump-f-range',default='f_range.txt')
    parser.add_argument('--dump-reginit',default='reginit.txt')
    parser.add_argument('--dump-syscall',default='syscall.txt')
    parser.add_argument('--dump-raminit',default='ram64.dat')
    parser.add_argument('--dump-rftrace',default='rf_trace.txt')
    parser.add_argument('--ram-endian',default='LE')
    
    args = parser.parse_args()
    
    parse_and_dump(args)
else:
    from .qemu_log_status import Status
    from .parse_asm import parse_asm,format_ram,format_frange,merge_data32
