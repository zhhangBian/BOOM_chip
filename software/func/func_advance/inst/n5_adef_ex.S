#include <asm.h>
#include <regdef.h>
#include <inst_test.h>

LEAF(n5_adef_ex_test)
    addi.w  s0, s0, 1 

    //let DA=1, PG=0
    li.w     t0, 0x08
    csrwr   t0, csr_crmd 

    //clear TLB and dmw0/1
    csrwr   zero, csr_dmw0
    csrwr   zero, csr_dmw1
    invtlb  0x0, zero, zero

    //clear ti
    li.w     t0, 0x1 
    csrwr   t0, csr_ticlr 

    li.w     t0, 0xd0000 
    li.w     s2, 0x5
    st.w    s2, t0, 0 

    //init usr mode, let DA=1, PG=0
    li.w     t0, 0x0b
    li.w     t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    lu12i.w s7, 0x50 
    li.w     t5, 0x3 
    
##inst test
###1
    TEST_ADEF(0x800d0010) 
    li.w     t0, 0xd0000 
    ld.w    t1, t0, 0x0
    jirl    s5, s4, 0 
    bne     s2, s7, inst_error 

###2 
###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    li.w      t0, 0xd0000 
    li.w      s2, 0x5
    st.w     s2, t0, 0 

    li.w     s2, 0x5 
    li.w     t0, 0x3 
    csrwr   t0, csr_prmd //after ertn should be in user mode
    invtlb   0, zero, zero
    TEST_ADEF(0x800d0014) 
    csrwr   s6, csr_era 
    la.local  s5, 1f 
    ertn 
1:  
    bne     s2, s7, inst_error 

###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    li.w      t0, 0xd0000 
    li.w      s2, 0x5
    st.w     s2, t0, 0 
 
    invtlb   0, zero, zero
    li.w      t0, 0x4c0001e0 //inst jirl zero,t3,0 
    li.w      t1, 0x800d0010 
    st.w     t0, t1, 0 
    st.w     t0, t1, 4

###3 
    invtlb   0, zero, zero
    move     s2, zero 
    la.local t3, 1f 
    li.w      t0, 0x800d0010
    jirl     zero, t0, 0 
1:  
    bne      zero, s2, inst_error 
    
###4 
    invtlb   0, zero, zero
    move     s2, zero 
    la.local t3, 1f 
    li.w      t0, 0x800d0014 
    csrwr    t0, csr_era 
    csrwr    zero, csr_prmd //after ertn still in kernel mode
    ertn 
1:  
    bne      zero, s2, inst_error  

#BUG
#if 0
###verify exception priority 
### int > adef 
    lu12i.w  s7, 0x40
    li.w      t0, 0x7 
    csrwr    t0, csr_prmd 

    li.w      t0, 0x1fff 
    csrwr    t0, csr_ectl 
    TEST_ADEF(0x800d0010)
    csrwr    s6, csr_era
    move     s5, s4 
    la.local s6, 1f
    li.w      t0, 0x4 
    ori      t0, t0, 0x1 
    csrwr    t0, csr_tcfg 

    li.w      t0, 0x0f
    li.w      t1, 0x1f
    invtlb   0, zero, zero
    csrxchg  t0, t1, csr_crmd //switch to the user mode
1:   
    jirl     zero, s4, 0x0     //if exception priority exit error, this program should be in dead cycle.
             //this adef exception cycle should be ended by interrupt
    bne      s2, s7, inst_error 
#endif

###switch to kernel mode
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    li.w      t0, 0xd0000 
    li.w      s2, 0x5
    st.w     s2, t0, 0 
 
###configure DMW make sure inst fetch is right 
    li.w      t0, 0x9 
    csrwr    t0, csr_dmw0
    invtlb   0, zero, zero

###adef > tlb fetch inst 
    lu12i.w  s7, 0x50
    TEST_ADEF(0x800d0014) 
    invtlb   0, zero, zero
    //switch to user mode and open pg
    li.w      t0, 0x13     
    li.w      t1, 0x1f
    csrxchg  t0, t1,  csr_crmd 
    
    jirl     s5, s4, 0 
    bne      s2, s7, inst_error 

###score +++
    addi.w  s3, s3, 1
###output (s0<<24)|s3 
inst_error:
###switch to kernel mode and close pg 
    li.w      t0, 0xd0000
    li.w      t1, 0xf
    st.w     t1, t0, 0x0
    syscall  0x0
    //let DA=1, PG=0
    li.w      t0, 0x8  
    li.w      t1, 0x18
    csrxchg  t0, t1, csr_crmd
    invtlb   0, zero, zero

    slli.w  t1, s0, 24 
    or      t0, t1, s3 
    st.w    t0, s1, 0 
    jirl    zero, ra, 0 
END(n5_adef_ex_test)

