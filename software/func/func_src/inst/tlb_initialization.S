#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(tlb_initialization)
    
#    addi.w s0, s0 ,1
#    li.w   s2, 0x0

    li.w  t0, 0x0c000000            #index
    li.w  t2, 8<<13
    li.w  t3, 1<<13
    add.w t1, t2, t3                #VPN

    li.w  t2, 0x000000aa 
    csrwr t2, csr_asid

    invtlb  0, zero, zero

###TLB item 1 
    FILL_TLB(0x0034ab00, 0x00ffab00) 
###TLB item 2
    FILL_TLB(0x0035ab00, 0x0100ab00)
###TLB item 3
    FILL_TLB(0x0036ab00, 0x0101ab00)
###TLB item 4
    FILL_TLB(0x0037ab00, 0x0102ab00)
####TLB item 5
#    FILL_TLB(0x0038ab00, 0x0103ab00)
####TLB item 6
#    FILL_TLB(0x0039ab00, 0x0104ab00)
####TLB item 7
#    FILL_TLB(0x003aab00, 0x00ffab00)
####TLB item 8
#    FILL_TLB(0x0134ab00, 0x01ffab00)
####TLB item 9
#    FILL_TLB(0x0234ab00, 0x02ffab00)
####TLB item 10
#    FILL_TLB(0x0334ab00, 0x03ffab00)

    li.w  t2, 0x000000ab
    csrwr t2, csr_asid

###TLB item 5
    FILL_TLB(0x0038ab00, 0x0103ab00)
###TLB item 6
    FILL_TLB(0x0039ab00, 0x0104ab00)
###TLB item 7 
    FILL_TLB(0x003aab00, 0x00ffab00)
###TLB item 8
    FILL_TLB(0x0134ab00, 0x01ffab00)
####TLB item 15
#    FILL_TLB(0x0834ab00, 0x08ffab00)
####TLB item 16
#    FILL_TLB(0x0934ab00, 0x09ffab00)
####TLB item 17
#    FILL_TLB(0x0a34ab00, 0x0affab00)
####TLB item 18
#    FILL_TLB(0x0b34ab00, 0x0bffab00)
####TLB item 19
#    FILL_TLB(0x0c34ab00, 0x0cffab00)
####TLB item 20
#    FILL_TLB(0x0d34ab00, 0x0dffab00)
	
    li.w  t2, 0x000000ac
    csrwr t2, csr_asid

###TLB item 9
    FILL_TLB(0x0e34ab00, 0x0effab00)
###TLB item 10
    FILL_TLB(0x0f34ab00, 0x0fffab00)
###TLB item 11
    FILL_TLB(0x034ab100, 0x0ffab100)
###TLB item 12
    FILL_TLB(0x034ab200, 0x0ffab200)
####TLB item 25
#    FILL_TLB(0x034ab300, 0x0ffab300)
####TLB item 26
#    FILL_TLB(0x034ab400, 0x0ffab400)
####TLB item 27
#    FILL_TLB(0x034ab500, 0x0ffab500)
####TLB item 28
#    FILL_TLB(0x034ab600, 0x0ffab600)
####TLB item 29
#    FILL_TLB(0x034ab700, 0x0ffab700)
####TLB item 30
#    FILL_TLB(0x034ab800, 0x0ffab800)
	
    li.w  t2, 0x000000ad
    csrwr t2, csr_asid

###TLB item 13 G=1
    FILL_TLB(0x034ab940, 0x0ffab940)
###TLB item 14 G=1
    FILL_TLB(0x034aba40, 0x0ffaba40)
###TLB item 15 G=1
    FILL_TLB(0x034ab740, 0x0ffab740)
###TLB item 16 G=1
    FILL_TLB(0x034ab840, 0x0ffab840)

###clear tlb csr reg 
    csrwr  zero, csr_tlbehi
    csrwr  zero, csr_tlbelo0
    csrwr  zero, csr_tlbelo1 
    csrwr  zero, csr_tlbidx

###detect exception
#    bne s2, zero, inst_error
###score ++
#    addi.w s3, s3, 1
###output (s0<<24)|s3
#inst_error:  
#    slli.w t1, s0, 24
#    or t0, t1, s3 
#    st.w t0, s1, 0x0
    jirl zero, ra, 0x0

END(tlb_initialization)
