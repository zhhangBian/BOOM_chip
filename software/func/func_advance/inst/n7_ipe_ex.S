#include <asm.h>
#include <regdef.h>
#include <inst_test.h>

LEAF(n7_ipe_ex_test)

    addi.w  s0, s0, 1 
    //clear ti
    li.w     t0, 0x1 
    csrwr   t0, csr_ticlr 
    //init usr mode
    li.w     t0, 0xb
    csrwr   t0, csr_crmd

    lu12i.w s7, 0x70 
    li.w     t5, 0x3

    li.w     t0, 0xd0000 
    li.w     s2, 0x7
    st.w    s2, t0, 0 
 
###ex test
###1 
    la.local s4, 1f 
    li.w     t8, 0xfff000
    li.w     t7, 0xfff000
1:  
    csrrd   t7, csr_era  
    bne     s2, s7, inst_error 
    bne     t8, t7, inst_error 

###2 
    li.w     s2, 0x07
    la.local s4, 1f 
    li.w     t8, 0xffffffff
    li.w     t7, 0xffffffff
1:  
    csrwr   t7, csr_era  
    bne     s2, s7, inst_error 
    bne     t7, t8, inst_error  

###3 
    li.w     s2, 0x07
    la.local s4, 1f 
    li.w     t8, 0xffff1111
    li.w     t7, 0xffff1111
    li.w     t2, 0xffffffff
1:  
    csrxchg t8, t2, csr_era  
    bne     s2, s7, inst_error 
    bne     t8, t7, inst_error  

###4
    li.w     s2, 0x07
    la.local s4, 1f 
    li.w     t0, 0x80000000
1:  
    cacop   0x0,  t0, 0x10   
    bne     s2, s7, inst_error 

###5
    li.w     s2, 0x07
    la.local s4, 1f 
1:  
    tlbsrch
    bne     s2, s7, inst_error 

###6
    li.w     s2, 0x07
    la.local s4, 1f 
1:  
    tlbsrch
    bne     s2, s7, inst_error 

###7
    li.w     s2, 0x07
    la.local s4, 1f 
1:  
    tlbrd
    bne     s2, s7, inst_error 

###8
    li.w     s2, 0x07
    la.local s4, 1f 
1:  
    tlbfill
    bne     s2, s7, inst_error 

###9
    li.w     s2, 0x07
    la.local s4, 1f 
1:  
    tlbfill
    bne     s2, s7, inst_error 

###10
    li.w     s2, 0x07
    la.local s4, 1f 
    li.w     t0, 0x10 
    li.w     t1, 0x80000000
1:  
    invtlb  0,  t0, t1
    bne     s2, s7, inst_error 

###11
    li.w     s2, 0x07
    la.local s4, 1f 
1:  
    ertn
    bne     s2, s7, inst_error 

###12
    li.w     s2, 0x07
    la.local s4, 1f 
1:  
    idle    0
    bne     s2, s7, inst_error 

###score +++
    addi.w  s3, s3, 1
###output (s0<<24)|s3 
inst_error:
###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
 
    csrwr   zero, csr_era    ##verify whether is in kernel mode

    slli.w  t1, s0, 24 
    or      t0, t1, s3 
    st.w    t0, s1, 0 
    jirl    zero, ra, 0 
END(n7_ipe_ex_test)

