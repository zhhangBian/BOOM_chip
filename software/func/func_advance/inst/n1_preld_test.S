#include <asm.h>
#include <regdef.h>
#include <inst_test.h>

LEAF(n1_preld_test)

    la.local t7, start
start:
    addi.w  s0, s0, 0x1 
    li.w     s2, 0x0
    //clear ti
    li.w     t0, 0x1 
    csrwr   t0, csr_ticlr 
    
# set up the inst DMW, let the MAT=00(Strongly-Ordered UnCached)
    li.w       t1, 0xe0000000
    and       t1, t7, t1
    srli.w    t2, t1, 0x4
    li.w       t3, 0x1
    or        t1, t1, t2
    or        t1, t1, t3
    csrwr     t1, csr_dmw1
    invtlb    0x0, zero, zero

    li.w       t7, 0xd0100000
# set up the inst DMW, let the MAT=00(Strongly-Ordered UnCached)
    li.w       t1, 0xe0000000
    and       t1, t7, t1
    srli.w    t2, t1, 0x4
    li.w       t3, 0x1
    or        t1, t1, t2
    or        t1, t1, t3
    csrwr     t1, csr_dmw0
    invtlb    0x0, zero, zero

    //let DA=0, PG=1, prl=0
    li.w     t0, 0x10
    li.w     t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    li.w     t0, 0xd0100000
    li.w     t1, 0xffffffff
    st.w    t1, t0, 0x0

# load the data in addr 0xd0100000 for 4 times and mearsure the average access time

    rdcntvl.w   t0
    li.w     t3, 0xd0100000
    ld.w    t2, t3, 0x0
    rdcntvl.w   t1
    sub.w   t4, t1, t0

    rdcntvl.w   t0
    li.w     t3, 0xd0100000
    ld.w    t2, t3, 0x0
    rdcntvl.w   t1
    sub.w   t5, t1, t0

    rdcntvl.w   t0
    li.w     t3, 0xd0100000
    ld.w    t2, t3, 0x0
    rdcntvl.w   t1
    sub.w   t6, t1, t0

    rdcntvl.w   t0
    li.w     t3, 0xd0100000
    ld.w    t2, t3, 0x0
    rdcntvl.w   t1
    sub.w   t7, t1, t0

    add.w   t0, t4, t5
    add.w   t0, t0, t6
    add.w   t0, t0, t7
    li.w     t1, 0x4
    div.w   t7, t0, t1

    li.w       t0, 0xd0100000
# set up the inst DMW, let the MAT=01(Coherent Cached)
    li.w       t1, 0xe0000000
    and       t1, t0, t1
    srli.w    t2, t1, 0x4
    li.w       t3, 0x11
    or        t1, t1, t2
    or        t1, t1, t3
    csrwr     t1, csr_dmw0
    invtlb    0x0, zero, zero   

# pre-load the data in addr 0xd0100000
    li.w       t0, 0xd0100000
    cacop     0x11, t0, 0x0
    preld     0x0, t0, 0x0

    rdcntvl.w   t0
    li.w     t3, 0xd0100000
    ld.w    t2, t3, 0x0
    rdcntvl.w   t1
    sub.w   t4, t1, t0

    //let DA=1, PG=0, prl=0
    li.w     t0, 0x8
    li.w     t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    csrwr     zero, csr_dmw0
    csrwr     zero, csr_dmw1
    invtlb    0x0, zero, zero

# correct situation: t4 < t7
    blt     t7, t4, inst_error

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
END(n1_preld_test)

