#include "regdef.h"
.text
_boot:
#init_uart
li.w       t1, 0x1fe001e0 
#WRITE(li.wne,OFS_FIFO,FIFO_ENABLE|FIFO_RCV_RST|FIFO_XMT_RST|FIFO_TRIGGER_4);
li.w       t2, 0x47   
st.b     t2, t1, 2
#WRITE(li.wne,OFS_LINE_CONTROL, 0x80);
li.w       t2, 0x80
st.b     t2, t1, 3
#WRITE(li.wne,OFS_DIVISOR_LSB, divisor & 0xff);
li.w       t2, 0x1 
st.b     t2, t1, 0 
#WRITE(li.wne,OFS_DIVISOR_MSB, (divisor & 0xff00) >> 8); 
li.w       t2, 0x0 
st.b     t2, t1, 1 
#WRITE(li.wne,OFS_DATA_FORMAT, data | parity | stop);
li.w       t2, 0x3 
st.b     t2, t1, 3
#WRITE(li.wne,OFS_MODEM_CONTROL,0);
li.w       t2, 0x0 
st.b     t2, t1, 4 

#read test   useless
li.w       t3, 16 
test_loop:
ld.b     t2, t1, 5 
andi     t2, t2, 0x1 
beq      t2, zero, test_loop_end 
read_loop:
ld.b     t2, t1, 5
andi     t2, t2, 0x1 
beq      t2, zero, read_loop 
ld.b     t2, t1, 0 

addi.w   t3, t3, -1 
bne      t3, zero, test_loop
test_loop_end:
#read test useless 

#write test 
li.w       t4, 0x61
li.w       t3, 10
#while ((READ(li.wne,OFS_LINE_STATUS) & 0x20) == 0);
write_loop1:
ld.b     t2, t1, 5 
andi     t2, t2, 0x20 
beq      t2, zero, write_loop1 
#WRITE(li.wne,OFS_SEND_BUFFER, byte);
st.b     t4, t1, 0 
addi.w   t4, t4, 1 
addi.w   t3, t3, -1 
bne      t3, zero, write_loop1 
#write test print abcdefj

#write test 
li.w       t5, 0x0a #\n 
bl       print_char
li.w       t5, 0x75 #u
bl       print_char 
li.w       t5, 0x61 #a
bl       print_char 
li.w       t5, 0x72 #r
bl       print_char 
li.w       t5, 0x74 #t
bl       print_char 
li.w       t5, 0x20 #
bl       print_char 
li.w       t5, 0x77 #w
bl       print_char 
li.w       t5, 0x6f #o
bl       print_char  
li.w       t5, 0x72 #r
bl       print_char 
li.w       t5, 0x6b #k
bl       print_char 
li.w       t5, 0x21 #!
bl       print_char 
li.w       t5, 0x0a #\n 
bl       print_char
#write test print uart work! 

li.w      $r12, 0x80000001 
csrwr   $r12, 0x180 
li.w      $r12, 0x00000001
csrwr   $r12 , 0x181
li.w      $r12, 0x10 
li.w      $r13, 0x18 
csrxchg $r12, $r13, 0x0
li.w      $r12, KERNEL_ENTRY_ADDRESS 
li.w      $r4 , 0x00000002
li.w      $r5 , 0xa5f00000
li.w      $r6 , 0xa5f00080
jirl    $r0, $r12, 0     #jump to kernel entry 

print_char:
loop:
ld.b    t2, t1, 5
andi    t2, t2, 0x20 
beq     t2, zero, loop 
st.b    t5, t1, 0 
jirl    zero, ra, 0
