#include <asm.h>
#include <regdef.h>
#include <inst_test.h>

LEAF(n4_pgd_test)

    addi.w  s0, s0, 0x1 
    li.w     s2, 0x0
    //clear ti
    li.w     t0, 0x1 
    csrwr   t0, csr_ticlr 
    //make sure prl=0
    li.w     t0, 0x0
    li.w     t1, 0x3
    csrxchg t0, t1, csr_crmd 

    li.w     t0, 0x3af000
    csrwr   t0, csr_pgdl

    li.w     t0, 0xaaa000
    csrwr   t0, csr_pgdh

    li.w     t0, 0x8aaa0000
    csrwr   t0, csr_badv
    csrrd   t0, csr_pgd
    li.w     t1, 0xaaa000
    bne     t0, t1, inst_error

    li.w     t0, 0x0aaa0000
    csrwr   t0, csr_badv
    csrrd   t0, csr_pgd
    li.w     t1, 0x3af000
    bne     t0, t1, inst_error

###detect exception
    bne s2, zero, inst_error
###score +++
    addi.w  s3, s3, 1
###output (s0<<24)|s3 
inst_error:
    slli.w  t1, s0, 24 
    or      t0, t1, s3 
    st.w    t0, s1, 0 
    jirl    zero, ra, 0 
END(n4_pgd_test)

