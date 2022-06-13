#include "asm.h"
#include "regdef.h"
#include "cpu_cde.h"

#define TEST_NUM 20

##s0, number
##s1, number adress 
##s2, exception use
##s3, score
##s4, exception pc
	.globl	_start
	.globl	start
	.globl	__main
_start:
start:
    li.w   t0, 0xffffffff
    addi.w t0, zero, -1
	b	locate

##avoid "j locate" not taken
    lu12i.w   t0, -0x80000
    addi.w    t1, t1, 1
    or        t2, t0, zero
    add.w     t3, t5, t6
    ld.w      t4, t0, 0

##avoid cpu run error
.org 0x0ec
    lu12i.w   t0, -0x80000
    addi.w    t1, t1, 1
    or        t2, t0, zero
    add.w     t3, t5, t6
    ld.w      t4, t0, 0
.org 0x100
test_finish:
    addi.w    t0, t0, 1
    LI        (t2, UART_ADDR)
    st.w      zero, t2, 0
    b         1f
.org 0x130
1:
    syscall 0x11

##avoid cpu run error
    lu12i.w   t0, -0x80000
    addi.w    t1, t1, 1
    or        t2, t0, zero
    add.w     t3, t5, t6
    ld.w      t4, t0, 0
/*
 *  exception handle
 */
.org 0x380
1:  
    addi.w    t0, t0, 1
    b         1b


locate:

    LI (a0, LED_RG1_ADDR)
    LI (a1, LED_RG0_ADDR)
    LI (a2, LED_ADDR)
    LI (s1, NUM_ADDR)

    LI (t1, 0x0002)
    LI (t2, 0x0001)
    LI (t3, 0x0000ffff)
    lu12i.w   s3, 0
    NOP4

    st.w      t1, a0, 0
    st.w      t2, a1, 0
    st.w      t3, a2, 0
    st.w      s3, s1, 0
    lu12i.w   s0, 0
    NOP4
inst_test:
    bl n1_lu12i_w_test    #lu12i.w
    bl idle_1s
    
    bl n2_add_w_test   #add.w
    bl idle_1s
    
    bl n3_addi_w_test  #add.w
    bl idle_1s
    
    bl n4_sub_w_test   #sub.w
    bl idle_1s
    
    bl n5_slt_test    #slt
    bl idle_1s
    
    bl n6_sltu_test   #sltu
    bl idle_1s
    
    bl n7_and_test    #and
    bl idle_1s
    
    bl n8_or_test     #or
    bl idle_1s
    
    bl n9_xor_test    #xor
    bl idle_1s
    
    bl n10_nor_test   #nor
    bl idle_1s
    
    bl n11_slli_w_test   #slli.w
    bl idle_1s
    
    bl n12_srli_w_test   #srli.w
    bl idle_1s
    
    bl n13_srai_w_test   #srai.w
    bl idle_1s
    
    bl n14_ld_w_test    #ld.w
    bl idle_1s
    
    bl n15_st_w_test    #st.w
    bl idle_1s
    
    bl n16_beq_test   #beq
    bl idle_1s
    
    bl n17_bne_test   #bne
    bl idle_1s
    
    bl n18_bl_test   #bl
    bl idle_1s
    
    bl n19_jirl_test    #jirl
    bl idle_1s
    
    bl n20_b_test    #b
    bl idle_1s

test_end:
    LI  (s0, TEST_NUM)
    NOP4
    beq s0, s3, 1f

    LI (a0, LED_ADDR)
	  LI (a1, LED_RG1_ADDR)
    LI (a2, LED_RG0_ADDR)
	
    LI (t1, 0x0002)
    NOP4
    
	  st.w    zero, a0, 0
    st.w    t1, a1, 0
    st.w    t1, a2, 0
    li.w    a0, 0x1
    b  2f

1:
    LI (t1, 0x0001)
    LI (a0, LED_RG1_ADDR)
	  LI (a1, LED_RG0_ADDR)
    NOP4
    st.w    t1, a0, 0
    st.w    t1, a1, 0
    li.w    a0, 0

2:
	//LI (t1, 0xff)
	//LI (t0, UART_ADDR)
	//sw t1, 0(t0)

	  bl      test_finish

idle_1s:
    #ifdef RUN_SIMU
    jirl    zero, ra, 0
    #endif
    LI (t0,SW_INTER_ADDR)
    LI (t1, 0xaaaa)

    #initial t3
    ld.w    t2, t0, 0   #switch_interleave: {switch[7],1'b0, switch[6],1'b0...switch[0],1'b0}
    NOP4
    xor     t2, t2, t1
    NOP4
    slli.w  t3, t2, 9     #t3 = switch interleave << 9
    NOP4
    addi.w  t3, t3, 1
    NOP4

sub1:  
    addi.w  t3, t3, -1

    #select min{t3, switch_interleave}
    ld.w    t2, t0, 0   #switch_interleave: {switch[7],1'b0, switch[6],1'b0...switch[0],1'b0}
    NOP4
    xor     t2, t2, t1
    NOP4
    slli.w  t2, t2, 9     #switch interleave << 9
    NOP4
    sltu    t4, t3, t2
    NOP4
    bne     t4, zero, 1f 
    addi.w  t3, t2, 0
    NOP4
1:
    bne     t3, zero, sub1
    jirl    zero, ra, 0
