#include <asm.h>
#include <regdef.h>
#include <inst_test.h>

LEAF(n2_dbar_test)

    addi.w  s0, s0, 0x1 
    li.w     s2, 0x0
    //clear ti
    li.w     t0, 0x1 
    csrwr   t0, csr_ticlr 
    //make sure prl=0
    li.w     t0, 0x0
    li.w     t1, 0x3
    csrxchg t0, t1, csr_crmd 

    li.w     t0, 0xd0100
    li.w     t1, 0xffffffff
    st.w    t1, t0, 0x0

    li.w     t0, 0xd0104
    li.w     t1, 0xffffffff
    st.w    t1, t0, 0x0

    li.w     t0, 0xd0108
    li.w     t1, 0xffffffff
    st.w    t1, t0, 0x0

    li.w     t0, 0xd0100
    ld.w    t1, t0, 0x0

    li.w     t0, 0xd0104
    ld.w    t1, t0, 0x0

    li.w     t0, 0xd0108
    ld.w    t1, t0, 0x0

    dbar    0x0
    add.w   zero, zero, zero

    li.w     t0, 0xd0108
    ld.w    t1, t0, 0x0

    li.w     t0, 0xd0108
    li.w     t1, 0xffffffff
    st.w    t1, t0, 0x0

    dbar    0x0

    li.w     t0, 0xd0100
    li.w     t1, 0xffffffff
    st.w    t1, t0, 0x0

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
END(n2_dbar_test)

