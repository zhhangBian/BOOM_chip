#include "define.h"

	.text
   	.global		reset_exception
#define EBASE_ADDR      0x08000400 # 0x00000400 ~ 0x00000600 virtual ebase entry
#define TLBR_BASE_ADDR  0x00000200 # 0x00000200 ~ 0x00000400 tlbrefill entry
#define TLB_READ_ADDR   0x00000600 # 0x00000600 ~ 0x00000640 
#define REG_INIT_ADDR   0x08000000 # 0x08000000 ~ 0x08000200 full
#define ILLEGAL_PC_ADDR 0x08000800 # virtual address 
# 0x00000a00 ~ 0x00000b00(not precise) are reg_init code, for run in vaddr(0x08000a00)


reset_exception:
#   CPU control state init
	csrrd		$r1, 0x20			        # get core-num to r1
	beq		    $r1, $r0, cache_init		# only core 0 execute following instrucition
    
slave_core_run:
	idle		0x0
1:	b			1b

cache_init:
    li.w    $r2, CACHE_WAY
    li.w    $r4, 0
    1:
    li.w    $r1, CACHE_IDX
    li.w    $r3, 0
    2:
    add.w   $r3, $r3, $r4
    cacop   0x0, $r3, 0x0  #icache 
    cacop   0x1, $r3, 0x0  #dcache
    cacop   0x2, $r3, 0x0  #scache
    addi.w  $r1, $r1, -1
    srli.w  $r3, $r3, CACHE_OFFSET
    addi.w  $r3, $r3, 1
    slli.w  $r3, $r3, CACHE_OFFSET
    blt     $r0, $r1, 2b

    addi.w  $r2, $r2, -1
    addi.w  $r4, $r4, 1
    blt     $r0, $r2, 1b


    # init tlb 
    invtlb  0, $r0, $r0

#   fill tlb 1c000 -> 1c000 (ppn:e000), just for boot, will be inv soon

    li.w    $r1, 0x0c000004 # tlbidx: NE=0 PS=12 index=64
    csrwr   $r1, 0x10 
    li.w    $r2, 0x1c000000 # tlbehi: vppn:1c000
    csrwr   $r2, 0x11 
    li.w    $r3, 0x01c00041 # tlbelo0: ppn:1c000 g=1 mat=00 plv=00 d=0 v=1
    csrwr   $r3, 0x12
    li.w    $r4, 0x00000040 # tlbelo1:  g=1 v=0
    csrwr   $r4, 0x13
    li.w    $r5, 0xf # asid
    csrwr   $r5, 0x18
    tlbwr


	csrwr	$r0, 0x1			# set PPLV=0, PIE=0
	
	csrwr	$r0, 0x6			# set EPC=0
	
	csrwr	$r0, 0x4			# set VInt=0



    # Set Ebase
    li.w    $r1, EBASE_ADDR
    csrwr   $r1, 0xc
    # set TLB Ebase
    li.w    $r1, TLBR_BASE_ADDR
    csrwr   $r1, 0x88

    # set ASID to 0xf
    li.w    $r1, 0xf
    csrwr   $r1, 0x18


# fill eentry to tlb
    li.w    $r1, TLB_READ_ADDR
    li.w    $r2, EBASE_ADDR
    st.w    $r2, $r1, 0x10
    dbar    0
    ld.w    $r2, $r1, 0
    csrwr   $r2, 0x10
    ld.w    $r2, $r1, 1<<4
    csrwr   $r2, 0x11 
    ld.w    $r2, $r1, 2<<4
    csrwr   $r2, 0x12
    ld.w    $r2, $r1, 3<<4
    csrwr   $r2, 0x13
    li.w    $r2, 0xf
    csrwr   $r2, 0x18
    tlbwr


    la.local $r1, tlb_refill       # current TLBR_BASE_ADDR
    li.w     $r2, TLBR_BASE_ADDR   # new TLBR_BASE_ADDR
    la.local $r4, tlb_refill_end

movetlbr:    
    ld.w     $r3, $r1, 0
    st.w     $r3, $r2, 0
    addi.w   $r1, $r1, 4
    addi.w   $r2, $r2, 4

    blt      $r1, $r4, movetlbr
    
    la.local $r1, eentry       # current Ebase
    li.w     $r2, 0x00000400   # EBASE_ADDR   
    la.local $r4, random_finish + 4

moveebase:
    ld.w    $r3, $r1, 0
    st.w    $r3, $r2, 0
    addi.w  $r1, $r1, 4
    addi.w  $r2, $r2, 4
    
    blt     $r1, $r4, moveebase

    la.local $r1, reg_init       # current REG_INIT_ADDR
    li.w     $r2, 0x00000a00   # new REG_INIT_ADDR
    la.local $r4, reg_init_end

movereginit:
    ld.w    $r3, $r1, 0
    st.w    $r3, $r2, 0
    addi.w  $r1, $r1, 4
    addi.w  $r2, $r2, 4
    
    blt     $r1, $r4, movereginit

    ori	    $r1, $r0, 0xb0
    csrwr	$r1, 0x0			# set PLV=0, IE=0, DA=0, PG=1, DATF=01, DATM=01

    li.w    $r1, 0x08000a00
	jirl    $r0, $r1, 0			# jump to reg_init 

reg_init:
    # invtlb  2, $r0, $r0 # inv the boot used tlb(index=1), trickily used g=1
    # inv boot tlb

    li.w    $r1, 0x8c000004 # tlbidx: NE=1 PS=12 index=64
    csrwr   $r1, 0x10 
    tlbwr

    # load init registers
    li.w    $r31, REG_INIT_ADDR
    ld.w    $r1 , $r31,  1<<4
    ld.w    $r2 , $r31,  2<<4
    ld.w    $r3 , $r31,  3<<4
    ld.w    $r4 , $r31,  4<<4
    ld.w    $r5 , $r31,  5<<4
    ld.w    $r6 , $r31,  6<<4
    ld.w    $r7 , $r31,  7<<4
    ld.w    $r8 , $r31,  8<<4
    ld.w    $r9 , $r31,  9<<4
    ld.w    $r10, $r31, 10<<4
    ld.w    $r11, $r31, 11<<4
    ld.w    $r12, $r31, 12<<4
    ld.w    $r13, $r31, 13<<4
    ld.w    $r14, $r31, 14<<4
    ld.w    $r15, $r31, 15<<4
    ld.w    $r16, $r31, 16<<4
    ld.w    $r17, $r31, 17<<4
    ld.w    $r18, $r31, 18<<4
    ld.w    $r19, $r31, 19<<4
    ld.w    $r20, $r31, 20<<4
    ld.w    $r20, $r31, 20<<4
    ld.w    $r21, $r31, 21<<4
    ld.w    $r22, $r31, 22<<4
    ld.w    $r23, $r31, 23<<4
    ld.w    $r24, $r31, 24<<4
    ld.w    $r25, $r31, 25<<4
    ld.w    $r26, $r31, 26<<4
    ld.w    $r27, $r31, 27<<4
    ld.w    $r28, $r31, 28<<4
    ld.w    $r29, $r31, 29<<4
    ld.w    $r30, $r31, 30<<4
    ld.w    $r31, $r31, 31<<4
# ertn to  begin test.
    ertn
reg_init_end:

    .global tlb_refill
tlb_refill:
    # in this test. Testbench will prepare the tlb related data.
    csrwr   $r1, 0x30
    csrwr   $r2, 0x31
    li.w    $r1, 0x00000008 # crmd:DATF=00 DATM=00
    csrwr   $r1, 0x0 
    li.w    $r1, TLB_READ_ADDR
    csrrd   $r2, 0x7
    st.w    $r2, $r1, 0x10
    dbar    0
    ld.w    $r2, $r1, 0
    csrwr   $r2, 0x10
    ld.w    $r2, $r1, 1<<4
    csrwr   $r2, 0x11 
    ld.w    $r2, $r1, 2<<4
    csrwr   $r2, 0x12
    ld.w    $r2, $r1, 3<<4
    csrwr   $r2, 0x13
    li.w      $r2, 0xf
    csrwr   $r2, 0x18
    tlbwr
    csrrd   $r2, 0x31
    csrrd   $r1, 0x30
    ertn
tlb_refill_end:

eentry:
    csrwr   $r1, 0x30
    csrwr   $r2, 0x31
    csrrd   $r1, 0x5
    srli.w  $r1, $r1, 16
    li.w    $r2, 0xb        # is syscall, go random_pass
    beq     $r1, $r2, random_pass
# test other excp?
# era+4, restore reg, ertn
    li.w    $r1, ILLEGAL_PC_ADDR
    csrrd   $r2, 0x6
    st.w    $r2, $r1, 0
    dbar    0
    ld.w    $r2, $r1, 0
    csrwr   $r2, 0x6 
    csrrd   $r2, 0x31
    csrrd   $r1, 0x30

    ertn
random_pass:
    li.w    $r4, 0x0
    la.local    $r1, random_finish
    csrwr   $r1, 0x6
    ertn
    beq     $r0, $r0, random_finish
random_finish:
    syscall 0x11
    idle    0