import os
import sys
def parse_section(line,ignorable):
    if line.startswith('Contents of section '):
        name = line[len('Contents of section '):].split(':')[0]
        dumptype = 'Contents'
    elif line.startswith('Disassembly of section '):
        name = line[len('Disassembly of section '):].split(':')[0]
        dumptype = 'Disassembly'
    else:return None
    if ignorable(name):return 'ignore'
    return dumptype
def endian_change32(x):
    x = ((x>>16)&0x0000ffff)|((x&0x0000ffff)<<16)
    x = ((x>> 8)&0x00ff00ff)|((x&0x00ff00ff)<< 8)
    return x
def endian_change64(x):
    return (endian_change32(data>>32)&0xffffffff)|(endian_change32(data&0xffffffff)<<32)
get_data_word_le = lambda x:x
get_data_word_ge = endian_change32
ignorable_default=lambda name:name.startswith('.debug_') or name=='.comment'
def parse_asm(lines,endian='GE',ignorable=ignorable_default):
    get_data_word = {'LE':get_data_word_le,'GE':get_data_word_ge}[endian]
    datas = {}
    insts = {}
    cur = None
    funcs = []
    func_name = None
    func_start = None
    func_stop  = None
    func_same  = None
    fill_start = None
    dumptype = 'ignore'
    for line in lines:
        try:
            if line == '\t...\n':
                fill_start = func_stop&~0x3
                if fill_start not in datas:datas[fill_start] = 0
                continue
            elif line in {'\n'}:continue
            res = parse_section(line,ignorable)
            dumptype = dumptype if res is None else res
            if not res is None or dumptype=='ignore':fill_start = None
            elif dumptype=='Contents':
                line = line.strip()
                words = [word for word in line.split(' ')[:5] if word != '']
                addr = int(words[0],16)
                for i in range(len(words)-1):
                    datas[addr+(i<<2)] = get_data_word(int(words[1+i],16))
            elif dumptype=='Disassembly':
                if line.startswith('  '):
                    parts = line.split('\t')
                    addr = parts[0][:-1].strip()
                    data = parts[1].strip()
                    inst = parts[2].strip()
                    addr = int(addr,16)
                    if data == '':continue
                    datas[addr&~0x3] = int(data,16)
                    for inst_word in inst.split('.'):
                        if not inst_word.isidentifier():
                            break
                    else:
                        insts[addr&~0x3] = inst
                    fill_start= addr + 4
                    func_stop = addr
                    func_same = True
                    continue
                elif '>:' in line:
                    addr = int(line[:16],16)
                    if not fill_start is None and fill_start < addr:
                        for a in range(fill_start,addr,4):
                            if a not in datas:datas[a] = 0
                        fill_start = addr
                    if func_same:
                        funcs.append((func_name,func_start,func_stop))
                    func_name  = line.split('<')[1].split('>')[0]
                    func_start = addr
                    func_stop  = addr
                    func_same  = True
                    continue
                elif line.endswith('():\n'):continue
                else:raise ValueError(line)
            if func_same:funcs.append((func_name,func_start,func_stop))
            func_same = False
        except:
            #print('Line#%s#'%line)
            i = 1
    return insts,datas,funcs
def format_ram(datas,path,endian,align=3):
    fmtstr = '%0' + str(2<<align) + 'x'
    with open(path,'wt') as f:
        mem = sorted([item for item in datas.items()],key=lambda a:a[0])
        cur = 0
        merge_limit = 0x1000
        for addr,data in mem:
            if addr > cur + merge_limit:
                print('@%x'%(addr>>align),file=f)
                cur = addr
            while cur < addr:
                print('00'*(1<<align),file=f)
                cur += 1<<align
            assert cur == addr
            if endian!='LE':
                data = endian_change(data)
            print(fmtstr%data,file=f)
            cur += 1<<align
def merge_data32(data32,align):
    assert(align>=2)
    if align==2:return data32,{addr:0xffffffff for addr in data32}
    data64 = {}
    mask64 = {}
    offs_mask = (1<<align)-1
    for a in data32:
        if a &~offs_mask in data64:continue
        a &=~offs_mask
        mask = 0
        data = 0
        for i in range((1<<align)-4,-4,-4):
            mask<<=32
            data<<=32
            if a+i in data32:
                mask |= 0xffffffff
                data |= data32[a+i]
        mask64[a] = mask
        data64[a] = data
    return data64,mask64
def format_frange(funcs,path):
    with open(path,'wt') as f:
        for item in funcs:
            #print('%s %016x %016x'%item,file=f)
            print('%s %016x %016x', 0, 0, 0,file=f)
def get_dirs(path,selected):
    for root, dirs, files in os.walk(path):
        for f in files:
            if selected(f):
                yield root,os.path.join(root,f)
                break
def dump(args):
    for root,asm in get_dirs(args.prefix,lambda x:x == args.asm):
        print('Dumping',asm,file=sys.stderr)
        with open(asm,'rt') as f:
            lines = f.readlines()
        insts,datas,funcs = parse_asm(lines,endian=args.asm_endian)
        if args.ram != 'none':
            datas,masks = merge_data32(datas,args.ram_align)
            format_ram(datas,os.path.join(root,args.ram),endian=args.ram_endian,align=args.ram_align)
        if args.dump_f_range!='none':
            frange = os.path.join(root,args.dump_f_range)
if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("-p","--prefix",help='The prefix of path',default='./')
    parser.add_argument("--asm",help='Specifying the dumped source',default='test.s')
    parser.add_argument("--asm-endian",choices=['LE','GE'],default='GE')
    parser.add_argument("--ram",help='Name of ram file',default='axi_ram.dat')
    parser.add_argument("--ram-base",help='Base address of ram to generate',default='0')
    parser.add_argument("--ram-size",help='Maximum size of ram to generate',default='64')
    parser.add_argument("--ram-align",type=int,default='3')
    parser.add_argument("--ram-endian",default='LE')
    parser.add_argument("--ram-memset",action='append',default=[])
    parser.add_argument("--dump-f-range",default='none')
    args = parser.parse_args()
    dump(args)
    
