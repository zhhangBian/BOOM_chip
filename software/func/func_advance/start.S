#include "asm.h"
#include "regdef.h"
#include "cpu_cde.h"

#define lab3    0 
#define lab6    0 
#define lab7    0 
#define lab8    0 
#define lab9    0 
#define lab14   0  
#define lab16   0
#define advance 1

#define cacop_enable 1

#ifdef ENABLE_TRACE 
#define TEST_NUM (lab3*20 + lab6*16 + lab7*10 + lab8*1 + lab9*9 + lab14*12 + lab16*0 + advance*3)
#else
#define TEST_NUM (lab3*20 + lab6*16 + lab7*10 + lab8*1 + lab9*13 + lab14*13 + lab16*6 + advance*8)
#endif

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
    li.w    t0, 0xffffffff
    addi.w t0, zero, -1
    ori    $r1,$r0,0x28
    csrwr  $r1,0x0
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
.org 0x8000   //0x1c008000
1:  
    csrrd t0, csr_crmd
    li.w   t0, 0xd0000
    ld.w  t1, t0, 0 
    li.w   t0, 0x1 
    beq   t1, t0, syscall_ex  #syscall  
    li.w   t0, 0x2 
    beq   t1, t0, brk_ex      #break 
    li.w   t0, 0x3 
    beq   t1, t0, ine_ex      #reserved inst 
    li.w   t0, 0x4 
    beq   t1, t0, int_ex      #interrupt 
    li.w   t0, 0x5 
    beq   t1, t0, adef_ex     #adef 
    li.w   t0, 0x6 
    beq   t1, t0, ale_ex      #ale 
    li.w   t0, 0x7 
    beq   t1, t0, ipe_ex      #ipe
    li.w   t0, 0x8
    beq   t1, t0, ld_page_invalid
    li.w   t0, 0x9
    beq   t1, t0, st_page_invalid
    li.w   t0, 0xa
    beq   t1, t0, tlb_prl_error
    li.w   t0, 0xb
    beq   t1, t0, tlb_page_modified_error
    li.w   t0, 0xc
    beq   t1, t0, fetch_page_invalid
    li.w   t0, 0xd
    beq   t1, t0, tlb_adem_error
    li.w   t0, 0xe
    beq   t1, t0, tlb_adef_error
    li.w   t0, 0xf
    beq   t1, t0, syscall_ex_special //syscall used for jumping from the user mode to the kernel mode
    li.w   t0, 0x10
    beq   t1, t0, adem_ex     #adem
	b     test_end
        
ipe_ex:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x000e0000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    lu12i.w  s2, 0x70 
    b        ex_finish  

adem_ex:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x00480000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_badv 
    bne      t0, s5, ex_finish
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    lu12i.w  s2, 0x70 
    b        ex_finish  


syscall_ex_special: 
    csrwr  zero, csr_prmd 
    csrrd  t1, csr_era 
    addi.w t1, t1, 0x4 
    csrwr  t1, csr_era 
    ertn

syscall_ex:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x000b0000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    lu12i.w  s2, 0x10 
    b        ex_finish  

brk_ex: 
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x000c0000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    lu12i.w  s2, 0x20 
    b        ex_finish  

ine_ex:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x000d0000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    lu12i.w  s2, 0x30 
    b        ex_finish 

int_ex:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x00000000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    li.w      t1, 0x1 
    csrwr    t1, csr_ticlr 
    bne      t1, zero, ex_finish 
    li.w      t1, 0x0 
    li.w      t0, 0x3 
    csrxchg  t1, t0, csr_estat 
    csrrd    t1, csr_estat
    li.w      t0, 0x1fff 
    and      t0, t0, t1 
    bne      t0, zero, ex_finish 
    lu12i.w  s2, 0x40 
    b        ex_finish 

adef_ex:
    add.w    s2, zero, zero
    csrwr    s5, csr_era
    bne      s4, s5, ex_finish 
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x00080000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    lu12i.w  s2, 0x50 
    b        ex_finish  

ale_ex:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x00090000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    lu12i.w  s2, 0x60 
    b        ex_finish  
    
ld_page_invalid:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x00010000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish
    csrrd    t0, csr_tlbehi
    bne      t0, s8, ex_finish
    lu12i.w  s2, 0x1
    b        ex_finish  
    
st_page_invalid:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x00020000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish
    csrrd    t0, csr_tlbehi
    bne      t0, s8, ex_finish
    lu12i.w  s2, 0x2
    b        ex_finish  
    
tlb_prl_error:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x00070000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish
    csrrd    t0, csr_tlbehi
    bne      t0, s8, ex_finish
    lu12i.w  s2, 0x7
    b        ex_finish  
    
tlb_page_modified_error:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x00040000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t5, t0, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish
    csrrd    t0, csr_tlbehi
    bne      t0, s8, ex_finish
    lu12i.w  s2, 0x4
    b        ex_finish  
     
fetch_page_invalid:
    add.w    s2, zero, zero
    li.w      t0, 0xffffffff
    csrrd    t0, csr_era 
    bne      s8, t0, ex_finish 
    addi.w   t0, s4, 0x0
    csrwr    t0, csr_era
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x00030000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t5, t0, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish
    csrrd    t0, csr_tlbehi
    bne      t0, s8, ex_finish
    lu12i.w  s2, 0x3
    b        ex_finish  

tlb_adem_error:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x00480000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish 
#ifndef ENABLE_TRACE
    csrrd    t0, csr_tlbehi
    bne      t0, zero, ex_finish 
#endif
    lu12i.w  s2, 0x81
    b        ex_finish  
     
tlb_adef_error:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s8, t0, ex_finish 
    addi.w   t0, s4, 0x0
    csrwr    t0, csr_era
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x00080000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t5, t0, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish 
#ifndef ENABLE_TRACE
    csrrd    t0, csr_tlbehi
    bne      t0, zero, ex_finish 
#endif
    lu12i.w  s2, 0x80
    b        ex_finish  

.org TLBREBASE   //TLBREBASE
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    csrrd    t0, csr_estat 
    li.w      t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w      t1, 0x003f0000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    li.w      t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w      t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish
    csrrd    t0, csr_tlbehi
    bne      t0, s8, ex_finish
    lu12i.w  s2, 0xe
    b        ex_finish  
 
ex_finish:
    add.w    zero, zero, zero
    csrrd    t1, csr_era 
    addi.w   t1, t1, 0x4 
    csrwr    t1, csr_era 
    addi.w   t1, s2, 0x0
    bne      s2, zero, ex_ret
    lu12i.w  s2, 0xffff 
ex_ret:
    ertn

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
#if cacop_enable 
    csrwr     zero, csr_dmw0 
    csrwr     zero, csr_dmw1
    li.w       t0, 0x19
    csrwr     t0, csr_dmw0     //data and inst cacop 
    li.w       t0, 0xAA000009 
    csrwr     t0, csr_dmw1     //io addr 
    li.w       t0, 0x10  
    li.w       t1, 0x18 
    csrxchg   t0, t1, csr_crmd 
#endif
############################
###lab3 test
#if lab3
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
    
#endif
############################
############################
###lab6 test
#if lab6
#bl n21_pcaddi_test    #pcaddi
#bl idle_1s
    
    bl n22_pcaddu12i_test   #pcaddu12i
    bl idle_1s
    
#bl n23_andn_test    #andn
#bl idle_1s
    
    bl n24_slti_test   #slti
    bl idle_1s
    
    bl n25_sltui_test  #sltui
    bl idle_1s
    
    bl n26_andi_test   #andi
    bl idle_1s
    
    bl n27_ori_test    #ori
    bl idle_1s
    
    bl n28_xori_test   #xori
    bl idle_1s
    
    bl n29_sll_w_test   #sll.w
    bl idle_1s
    
    bl n30_sra_w_test   #sra.w
    bl idle_1s
    
    bl n31_srl_w_test   #srl.w
    bl idle_1s
    
    bl n32_div_w_test    #div.w
    bl idle_1s
    
    bl n33_div_wu_test   #div.wu
    bl idle_1s
    
    bl n34_mul_w_test   #mul.w
    bl idle_1s
    
    bl n35_mulh_w_test  #mulh.w
    bl idle_1s
    
    bl n36_mulh_wu_test   #mulh.wu
    bl idle_1s
    
#bl n37_orn_test   #orn
#bl idle_1s
    
    bl n38_mod_w_test   #mod.w
    bl idle_1s
    
    bl n39_mod_wu_test   #mod.wu
    bl idle_1s
    
#endif
############################
############################
###lab7 test
#if lab7
    bl n40_blt_test          #blt
    bl idle_1s
    
    bl n41_bge_test       #bge
    bl idle_1s
    
    bl n42_bltu_test       #bltu
    bl idle_1s
    
    bl n43_bgeu_test       #bgeu
    bl idle_1s
    
    bl n44_ld_b_test       #ld.b
    bl idle_1s
    
    bl n45_ld_h_test     #ld.h
    bl idle_1s
    
    bl n46_ld_bu_test     #ld.bu
    bl idle_1s
    
    bl n47_ld_hu_test       #ld.hu
    bl idle_1s
    
    bl n48_st_b_test       #st.b
    bl idle_1s
    
    bl n49_st_h_test    #st.h
    bl idle_1s
    
#endif
############################
############################
###lab8 test
#if lab8 
lab8_csr_init:
    csrwr     zero, csr_prmd 
    csrwr     zero, csr_era 
    csrwr     zero, csr_eentry 

    li.wt0, 0x1c008000 
    csrwr t0, csr_eentry 

    bl n50_syscall_ex_test       #syscall
    bl idle_1s
#endif 
############################
############################
###lab9 test 
#if lab9 
lab9_csr_init:
    csrwr     zero, csr_prmd 
    csrwr     zero, csr_era 
    csrwr     zero, csr_eentry 
    csrwr     zero, csr_badv 
    csrwr     zero, csr_save0 
    csrwr     zero, csr_save1
    csrwr     zero, csr_save2 
    csrwr     zero, csr_save3 
    csrwr     zero, csr_tcfg

    li.wt0, 0x1c008000 
    csrwr t0, csr_eentry

    bl n51_brk_ex_test         #brk ex 
    bl idle_1s 

    bl n52_ti_ex_test          #timer int ex 
    bl idle_1s 

#ifndef ENABLE_TRACE
    bl n53_ine_ex_test         #ine ex 
    bl idle_1s  
#endif

#ifndef ENABLE_TRACE
    bl n54_soft_int_ex_test    #soft int ex 
    bl idle_1s 
#endif

    bl n55_adef_ex_test         #adef ex 
    bl idle_1s  

    bl n56_ale_ld_w_ex_test     #ld.w ale ex 
    bl idle_1s 

    bl n57_ale_ld_h_ex_test     #ld.h ale ex 
    bl idle_1s 

    bl n58_ale_ld_hu_ex_test    #ld.hu ale ex 
    bl idle_1s 
    
    bl n59_ale_st_h_ex_test      #st.h ale ex 
    bl idle_1s 

    bl n60_ale_st_w_ex_test      #st.w ale ex 
    bl idle_1s 

    bl n61_ti_ex_idle_test      #timer int ex with idle 
    bl idle_1s  

#ifndef ENABLE_TRACE
    bl n62_rdcnt_test          #rdcntvl.w and rdcntvh.w test 
    bl idle_1s 
#endif

#ifndef ENABLE_TRACE
    bl n63_atomic_ins_test      #ll.w and sc.w test 
    bl idle_1s 
#endif
#endif

#if lab14
lab14_csr_init:
    csrwr     zero, csr_prmd 
    csrwr     zero, csr_era 
    csrwr     zero, csr_eentry 
    csrwr     zero, csr_badv 
    csrwr     zero, csr_save0 
    csrwr     zero, csr_save1
    csrwr     zero, csr_save2 
    csrwr     zero, csr_save3 
    csrwr     zero, csr_tcfg
    csrwr     zero, csr_tlbidx
    csrwr     zero, csr_tlbehi 
    csrwr     zero, csr_tlbelo0
    csrwr     zero, csr_tlbelo1 
    csrwr     zero, csr_asid 

#if cacop_enable 
    li.w       t0, 0x8 
    li.w       t1, 0x18 
    csrxchg   t0, t1, csr_crmd
    csrwr     zero, csr_dmw0 
    csrwr     zero, csr_dmw1
    li.w       t0, 0x19
    csrwr     t0, csr_dmw0     //data and inst cacop 
    li.w       t0, 0xAA000009 
    csrwr     t0, csr_dmw1     //io addr 
    li.w       t0, 0x10  
    li.w       t1, 0x18 
    csrxchg   t0, t1, csr_crmd 
#endif 

    li.w     t0, 0x0 
    li.w     t1, 0x3 
    csrxchg t0, t1, csr_crmd 
    bl n0_tlb_initialization

    bl n11_tlbrd_tlbwr_test
    bl idle_1s

#ifndef ENABLE_TRACE
    bl n0_tlb_initialization
    bl n11_tlbfill_test
    bl idle_1s 
#endif

    bl n0_tlb_initialization
    bl n12_tlbsrch_test
    bl idle_1s

    bl n0_tlb_initialization
    bl n13_invtlb_0x0_test
    bl idle_1s

    bl n0_tlb_initialization
    bl n13_invtlb_0x1_test
    bl idle_1s

    bl n0_tlb_initialization
    bl n13_invtlb_0x2_test
    bl idle_1s

    bl n0_tlb_initialization
    bl n13_invtlb_0x3_test
    bl idle_1s

    bl n0_tlb_initialization
    bl n13_invtlb_0x4_test
    bl idle_1s

    bl n0_tlb_initialization
    bl n13_invtlb_0x5_test
    bl idle_1s

    bl n0_tlb_initialization
    bl n13_invtlb_0x6_test
    bl idle_1s

    bl n0_tlb_initialization
    bl n13_invtlb_inv_op_test
    bl idle_1s
 
    bl n15_tlb_4MB
    bl idle_1s

    bl n14_tlb_ex_test
    bl idle_1s 

#if 0
    bl n16_dmw_test
    bl idle_1s
#endif
#endif 

#if lab16 
lab16_csr_init: 
    csrwr     zero, csr_prmd 
    csrwr     zero, csr_era 
    csrwr     zero, csr_eentry 
    csrwr     zero, csr_badv 
    csrwr     zero, csr_save0 
    csrwr     zero, csr_save1
    csrwr     zero, csr_save2 
    csrwr     zero, csr_save3 
    csrwr     zero, csr_tcfg
    csrwr     zero, csr_tlbidx
    csrwr     zero, csr_tlbehi 
    csrwr     zero, csr_tlbelo0
    csrwr     zero, csr_tlbelo1 
    csrwr     zero, csr_asid 

cacop_disable:
    li.w       t0, 0x8 
    li.w       t1, 0x18 
    csrxchg   t0, t1, csr_crmd
    csrwr     zero, csr_dmw0 
    csrwr     zero, csr_dmw1  

#ifndef ENABLE_TRACE  
    bl n1_icacop_op0
    bl idle_1s

    bl n2_dcacop_op0
    bl idle_1s

    bl n3_icacop_op1
    bl idle_1s

    bl n4_dcacop_op1
    bl idle_1s

    bl n5_icacop_op2
    bl idle_1s

    bl n6_dcacop_op2 
    bl idle_1s

    bl n7_cache_writeback
#endif
    bl idle_1s
#endif 

#if advance

    li.w   t0, 0x1c008000
    csrwr t0, csr_eentry
    li.w   t1, 0x1c000000 + TLBREBASE
    csrwr t1, csr_tlbrentry

#ifndef ENABLE_TRACE  
    bl n1_preld_test
    bl idle_1s

    bl n2_dbar_test
    bl idle_1s

    bl n3_ibar_test
    bl idle_1s
#endif

    bl n4_pgd_test
    bl idle_1s

    bl n5_adef_ex_test
    bl idle_1s

    bl n6_adem_ex_test
    bl idle_1s

#ifndef ENABLE_TRACE  
    bl n7_ipe_ex_test
    bl idle_1s

    bl n8_csr_rw_test
    bl idle_1s
#endif

#endif

test_end:
    LI  (s0, TEST_NUM)
    NOP4
    beq s0, s3, 1f
    nop

    LI (a0, LED_ADDR)
	  LI (a1, LED_RG1_ADDR)
    LI (a2, LED_RG0_ADDR)
	
    LI (t1, 0x0002)
    NOP4
    
	  st.w    zero, a0, 0
    st.w    t1, a1, 0
    st.w    t1, a2, 0
    b  2f
    nop
1:
    LI (t1, 0x0001)
    LI (a0, LED_RG1_ADDR)
	  LI (a1, LED_RG0_ADDR)
    NOP4
    st.w    t1, a0, 0
    st.w    t1, a1, 0

2:
	//LI (t1, 0xff)
	//LI (t0, UART_ADDR)
	//sw t1, 0(t0)

	bl test_finish

idle_1s:
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
