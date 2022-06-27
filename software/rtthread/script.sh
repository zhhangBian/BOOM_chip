#!/bin/bash

#compile start.S.bak

CFLAGS="-nostdlib -mlong-calls -static -nostdinc -fno-builtin"
LFLAGS="-L../../toolchains/system_newlib/ -Wl,-T../../toolchains/system_newlib/pmon.ld -lc -lm -lg -lpmon -lgcc"


loongarch32r-linux-gnusf-gcc -DKERNEL_ENTRY_ADDRESS=0x80300000 -c start.S -o start.o

loongarch32r-linux-gnusf-objdump -d start.o > start.s
loongarch32r-linux-gnusf-objdump -d rtthread.elf > rtthread.s 

loongarch32r-linux-gnusf-objcopy -O binary -j .text start.o start.bin 

loongarch32r-linux-gnusf-objcopy -O binary -j .text -j __ex_table -j .notes -j .rodata -j __param -j .sdata \
                                                     -j __modver -j .data -j .data..page_aligned -j .init.text -j .init.data \
                                                     -j .exit.text rtthread.elf rtthread.bin

mkdir -p obj 
mv rtthread.s      ./obj/
mv start.s     ./obj/
mv start.bin   ./obj/
cp init_8f.txt ./obj/
cp init_5f.txt ./obj/
mv rtthread.bin ./obj/
rm start.o
gcc ./convert.c -o convert
mv ./convert ./obj/ 
cd ./obj 
./convert 



