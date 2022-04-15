#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n63_tlbsrch_test)
    addi.w s0, s0 ,0x1
	li.w     s2, 0x0

###tlb hit: G=0
    TEST_TLBP(0x000000aa, 0x2, 0x0c000001)
###tlb hit: G=1
    TEST_TLBP(0x000000ff, 0x20, 0x0c00001f)
###tlb miss: no matching asid
    TEST_TLBP_NOMATCHING(0x000003f0, 0x2)
###tlb miss: no matching VPN
    TEST_TLBP_NOMATCHING(0x000000aa, 0xff)

###detect exception
    bne s2, zero, inst_error
###score ++
    addi.w s3, s3, 1
###output (s0<<24)|s3
inst_error:  
    slli.w t1, s0, 24
    or t0, t1, s3 
    st.w t0, s1, 0x0
    jirl zero, ra, 0x0
END(n63_tlbsrch_test)
