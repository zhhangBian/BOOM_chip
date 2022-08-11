#include "define.h"

	.text
   	.global		reset_exception
#define EBASE_ADDR      0x9c004000
#define TLBR_BASE_ADDR  0x1c001000
#define TLB_READ_ADDR   0x1c002000
#define REG_INIT_ADDR   0x9c003000


reset_exception:
    #CPU control state init
	csrrd		$r1, 0x20			        # get core-num to r1
	bne		$r1, $r0, slave_core_run		# only core 0 execute following instrucition
    
    # Set coprocessor EN
    #ori			$r1, $r0, 0x2f
	#csrwr		$r1, 0x2			# enable all coprocessors' En

    #cache init
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


    # Set Win 0/Win 1
    # LA32
    # Win 0 is just for boot use
    li.w          $r2, 0x19
	csrwr		$r2, 0x180			# set DM Win0, uncached
	
    li.w          $r2, 0xa0000019
	csrwr		$r2, 0x181			# set DM Win1, cached

    ori			$r1, $r0, 0x30
	csrwr		$r1, 0x0			# set PLV=0, IE=0, DA=0, PG=1, DATF=1, DATM=0

    #tlbp
    #tlbp
    li.w          $r2, 0xa0000000
	la.local	$r1, next
	or			$r1, $r1, $r2
	jirl		$r0, $r1, 0			# jump to next inst through DM Win 0 to make sure all following inst fetch uncached


next:
    # set EPC=0
    csrwr   $r0, 0x6
	
    li.w          $r2, 0x80000009
	csrwr		$r2, 0x180			# set DM Win1, cached


    #ori			$r1, $r0, 0x30
	#csrwr		$r1, 0x0			# set PLV=0, IE=0, DA=0, PG=1, DACF=1, DACM=1

	csrwr		$r0, 0x1			# set PPLV=0, PIE=0
	
	csrwr		$r0, 0x6			# set EPC=0
	
	csrwr		$r0, 0x4			# set VInt=0

    #init tlb 
    invtlb 0, $r0, $r0

    # Set Ebase
    li.w     $r1, EBASE_ADDR
    csrwr   $r1, 0xc
    # set TLB Ebase
    li.w     $r1, TLBR_BASE_ADDR
    csrwr   $r1, 0x88

    # set ASID to 0xf
    li.w      $r1, 0xf
    csrwr   $r1, 0x18

    # load init registers
    li.w     $r31, REG_INIT_ADDR
    ld.w    $r1 , $r31,  1<<3
    ld.w    $r2 , $r31,  2<<3
    ld.w    $r3 , $r31,  3<<3
    ld.w    $r4 , $r31,  4<<3
    ld.w    $r5 , $r31,  5<<3
    ld.w    $r6 , $r31,  6<<3
    ld.w    $r7 , $r31,  7<<3
    ld.w    $r8 , $r31,  8<<3
    ld.w    $r9 , $r31,  9<<3
    ld.w    $r10, $r31, 10<<3
    ld.w    $r11, $r31, 11<<3
    ld.w    $r12, $r31, 12<<3
    ld.w    $r13, $r31, 13<<3
    ld.w    $r14, $r31, 14<<3
    ld.w    $r15, $r31, 15<<3
    ld.w    $r16, $r31, 16<<3
    ld.w    $r17, $r31, 17<<3
    ld.w    $r18, $r31, 18<<3
    ld.w    $r19, $r31, 19<<3
    ld.w    $r20, $r31, 20<<3
    ld.w    $r20, $r31, 20<<3
    ld.w    $r21, $r31, 21<<3
    ld.w    $r22, $r31, 22<<3
    ld.w    $r23, $r31, 23<<3
    ld.w    $r24, $r31, 24<<3
    ld.w    $r25, $r31, 25<<3
    ld.w    $r26, $r31, 26<<3
    ld.w    $r27, $r31, 27<<3
    ld.w    $r28, $r31, 28<<3
    ld.w    $r29, $r31, 29<<3
    ld.w    $r30, $r31, 30<<3
    ld.w    $r31, $r31, 31<<3
    # ertn. test begin
    ertn

slave_core_run:
	idle		0x0
1:	b			1b

    .org 0x1000
    .global tlb_refill
tlb_refill:
    # in this test. Testbench will prepare the tlb related data.
    csrwr   $r1, 0x30
    csrwr   $r2, 0x31
    li.w    $r1, TLB_READ_ADDR
    csrrd   $r2, 0x7
    st.w    $r2, $r1, 0x10
    dbar    0
    ld.w    $r2, $r1, 0
    csrwr   $r2, 0x10
    ld.w    $r2, $r1, 1<<3
    csrwr   $r2, 0x11
    ld.w    $r2, $r1, 2<<3
    csrwr   $r2, 0x12
    ld.w    $r2, $r1, 3<<3
    csrwr   $r2, 0x13
    li.w      $r2, 0xf
    csrwr   $r2, 0x18
    tlbfill
    csrrd   $r2, 0x31
    csrrd   $r1, 0x30
    ertn
    .org 0x4000
    csrwr   $r1, 0x30
    csrwr   $r2, 0x31
    csrrd   $r1, 0x5
    srli.w  $r1, $r1, 16
    li.w    $r2, 0xb
    beq     $r1, $r2, random_pass
    li.w    $r4, 0x1
    beq     $r0, $r0, random_finish
random_pass:
    li.w    $r4, 0x0
    li.w    $r1, 0x9c005000
    csrwr   $r1, 0x6
    ertn
    beq     $r0, $r0, random_finish
    .org 0x5000
random_finish:
    syscall 0x11
    idle    0

