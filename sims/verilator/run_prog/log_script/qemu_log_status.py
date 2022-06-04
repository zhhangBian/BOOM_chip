
class Status:
    sample = '''pc=0x*
GPR00: r0 * ra * tp * sp *
GPR04: a0 * a1 * a2 * a3 *
GPR08: a4 * a5 * a6 * a7 *
GPR12: t0 * t1 * t2 * t3 *
GPR16: t4 * t5 * t6 * t7 *
GPR20: t8 *  x * fp * s0 *
GPR24: s1 * s2 * s3 * s4 *
GPR28: s5 * s6 * s7 * s8 *
    CSR_ERA 0x* CSR_TLBRENTRY 0x*
    CSR_CRMD 0x* CSR_PRMD 0x*
    CSR_ECTL 0x* CSR_ESTAT 0x*'''
    sample_words = [line.split('*') for line in sample.split('\n')]
    length = len(sample_words)
    def __init__(self,line,trace):
        base = len(self.sample_words[0][0])
        self.pc = int(line[base:base+8],16)
        self.rf = []
        for i in range(1,9):
            base = 0
            line = next(trace)
            for j in range(len(self.sample_words[i])-1):
                word = self.sample_words[i][j]
                base+=len(word)
                val = line[base:base+8]
                base+= 8
                val = int(val,16)
                self.rf.append(val)
        for i in range(9,len(self.sample_words)):
            line = next(trace)
    def diff(self,prev):
        return (prev.pc,{i:self.rf[i] for i in range(len(self.rf)) if self.rf[i]!=prev.rf[i]})
    def display(self,file):
        print('%08x'%self.pc,file=file)
        for i in range(32):
            print('%08x'%self.rf[i],file=file)
