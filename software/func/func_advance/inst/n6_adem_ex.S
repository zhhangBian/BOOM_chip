#include <asm.h>
#include <regdef.h>
#include <inst_test.h>

LEAF(n6_adem_ex_test)

    addi.w  s0, s0, 1 
    
    //let DA=1, PG=0
    li.w     t0, 0x08
    li.w     t1, 0x18
    csrxchg t0, t1, csr_crmd 
 
    //indicate the adem excp
    li.w     t0, 0xd0000 
    li.w     s2, 0x10
    st.w    s2, t0, 0 
    //clear ti
    li.w     t0, 0x1 
    csrwr   t0, csr_ticlr 
    lu12i.w s7, 0x70 
    li.w     t5, 0x3 

###ex test 
###1 
    li.w      s5, 0x800d1110 
    li.w      t4, 0xffff3333 
    st.w     t4, s5, 0

    invtlb   0, zero, zero

    li.w      t0, 0x3 //switch to the user mode
    li.w      t1, 0x7 
    csrxchg  t0, t1, csr_crmd 

    la.local s4, 1f 
    li.w      t0, 0xf8f83f3f
1:   
    st.w     t0, s5, 0 
    bne      s2, s7, inst_error 

###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    li.w      t0, 0xd0000 
    li.w      s2, 0x10
    st.w     s2, t0, 0 

    ld.w     t2, s5, 0 
    bne      t2, t4, inst_error 

###2
    li.w      s2, 0x7
    li.w      s5, 0x800d1114 
    li.w      t4, 0xff33ff33
    st.w     t4, s5, 0 
    li.w      t0, 0x3
    li.w      t1, 0x7 
    invtlb   0, zero, zero
    csrxchg  t0, t1, csr_crmd //switch to the user mode

    la.local s4, 1f 
1:  
    ld.w     t3, s5, 0 
    bne      s2, s7, inst_error 
    beq      t3, t4, inst_error

###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    li.w      t0, 0xd0000 
    li.w      s2, 0x10
    st.w     s2, t0, 0 

    invtlb   0, zero, zero

###3
    li.w      s2, 0x7 
    li.w      s5, 0x800d1118
    li.w      t4, 0xfffff222 
    st.h     t4, s5, 0
    li.w      t0, 0x3
    li.w      t1, 0x7 
    invtlb   0, zero, zero
    csrxchg  t0, t1, csr_crmd //switch to the user mode

    la.local s4, 1f 
    li.w      t0, 0x3f3f
1:   
    st.h     t0, s5, 0 
    bne      s2, s7, inst_error 

###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    li.w      t0, 0xd0000 
    li.w      s2, 0x10
    st.w     s2, t0, 0 

    invtlb   0, zero, zero
    ld.h     t2, s5, 0 
    bne      t2, t4, inst_error 

###4
    li.w      s2, 0x7
    li.w      s5, 0x800d111c 
    li.w      t4, 0x1f33
    st.h     t4, s5, 0 
    li.w      t0, 0x3
    li.w      t1, 0x7 
    invtlb   0, zero, zero
    csrxchg  t0, t1, csr_crmd //switch to the user mode

    la.local s4, 1f 
1:  
    ld.h     t3, s5, 0 
    bne      s2, s7, inst_error 
    beq      t3, t4, inst_error


###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    li.w      t0, 0xd0000 
    li.w      s2, 0x10
    st.w     s2, t0, 0 

    invtlb   0, zero, zero

###5
    li.w      s2, 0x7
    li.w      s5, 0x800d1110 
    li.w      t4, 0xfff3
    st.h     t4, s5, 0 
    li.w      t0, 0x3
    li.w      t1, 0x7 
    invtlb   0, zero, zero
    csrxchg  t0, t1, csr_crmd //switch to the user mode
    la.local s4, 1f 
1:  
    ld.hu    t3, s5, 0 
    bne      s2, s7, inst_error 
    beq      t3, t4, inst_error

###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    li.w      t0, 0xd0000 
    li.w      s2, 0x10
    st.w     s2, t0, 0 

    invtlb   0, zero, zero

###6
    li.w      s2, 0x7 
    li.w      s5, 0x800d1114
    li.w      t4, 0xfffffff2 
    st.b     t4, s5, 0
    li.w      t0, 0x3
    li.w      t1, 0x7 
    invtlb   0, zero, zero
    csrxchg  t0, t1, csr_crmd //switch to the user mode

    la.local s4, 1f 
    li.w      t0, 0x7f
1:   
    st.b     t0, s5, 0 
    bne      s2, s7, inst_error 

###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    li.w      t0, 0xd0000 
    li.w      s2, 0x10
    st.w     s2, t0, 0 

    ld.b     t2, s5, 0 
    bne      t2, t4, inst_error 

###7
    li.w      s2, 0x7
    li.w      s5, 0x800d1118
    li.w      t4, 0x13
    st.b     t4, s5, 0 
    li.w      t0, 0x3
    li.w      t1, 0x7 
    invtlb   0, zero, zero
    csrxchg  t0, t1, csr_crmd //switch to the user mode
    la.local s4, 1f 
1:  
    ld.b     t3, s5, 0 
    bne      s2, s7, inst_error 
    beq      t3, t4, inst_error

###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    li.w      t0, 0xd0000 
    li.w      t1, 0x10
    st.w     t1, t0, 0 

    invtlb   0, zero, zero

###8
    li.w      s2, 0x7
    li.w      s5, 0x800d111c
    li.w      t4, 0x83
    st.b     t4, s5, 0 
    li.w      t0, 0x3
    li.w      t1, 0x7 
    csrxchg  t0, t1, csr_crmd //switch to the user mode
    invtlb   0, zero, zero
    la.local s4, 1f 
1:  
    ld.bu    t3, s5, 0 
    bne      s2, s7, inst_error 
    beq      t3, t4, inst_error

###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    li.w      t0, 0xd0000 
    li.w      t1, 0x10
    st.w     t1, t0, 0 

    invtlb   0, zero, zero

###9 used for test exception priority ALE > ADEM
    li.w     t0, 0xd0000 
    li.w     s2, 0x6
    st.w    s2, t0, 0 
    lu12i.w s7, 0x60 

    li.w      t0, 0x3
    li.w      t1, 0x7 
    invtlb   0, zero, zero
    csrxchg  t0, t1, csr_crmd //switch to the user mode

    li.w      s5, 0x800d1111   
    la.local s4, 1f 
    li.w      t0, 0xf8f83f3f
1:   
    st.w     t0, s5, 0 
    bne      s2, s7, inst_error 

###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    li.w      t0, 0xd0000 
    li.w      t1, 0x10
    st.w     t1, t0, 0 

    invtlb   0, zero, zero

###10 used for test exception priority adem > tlb 
###configure DMW make sure inst fetch is right 
    li.w      t0, 0x9 
    csrwr    t0, csr_dmw0 
    csrwr    zero, csr_dmw1
    invtlb   0, zero, zero

    li.w      t0, 0xd0000 
    li.w      s2, 0x10
    st.w     s2, t0, 0 
    lu12i.w  s7, 0x70 

    li.w      s5, 0x800d1110 
    li.w      t4, 0xfff444f 
    st.w     t4, s5, 0 

    //switch to user mode and open pg
    li.w      t0, 0xb3
    csrwr    t0, csr_crmd 

    la.local s4, 1f 
    li.w      t0, 0xf888ffff 
    li.w      s5, 0x800d1110 
1:  
    st.w     t0, s5, 0
    bne      s2, s7, inst_error 

###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    li.w      t0, 0xd0000 
    li.w      t1, 0x10
    st.w     t1, t0, 0 

    //let DA=1, PG=0
    li.w      t0, 0x8  
    csrwr    t0, csr_crmd
    
    ld.w     t2, s5, 0 
    bne      t2, t4, inst_error

###score +++
    addi.w  s3, s3, 1
###output (s0<<24)|s3 
inst_error:
###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    //let DA=1, PG=0
    li.w     t0, 0x8  
    csrwr   t0, csr_crmd
 
    slli.w  t1, s0, 24 
    or      t0, t1, s3 
    st.w    t0, s1, 0 
    jirl    zero, ra, 0 
END(n6_adem_ex_test)
