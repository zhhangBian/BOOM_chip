#!/bin/bash

#compile start.S.bak

CFLAGS="-nostdlib -mlong-calls -static -nostdinc -fno-builtin"
LFLAGS="-L../../toolchains/system_newlib/ -Wl,-T../../toolchains/system_newlib/pmon.ld -lc -lm -lg -lpmon -lgcc"

KERNEL_ENTRY_INFO=`../../toolchains/loongarch32r-linux-gnusf-*/bin/loongarch32r-linux-gnusf-readelf -s vmlinux | grep kernel_entry`
KERNEL_ENTRY_ADDRESS=`echo ${KERNEL_ENTRY_INFO: 8: 8}`

loongarch32r-linux-gnusf-gcc -DKERNEL_ENTRY_ADDRESS=0x${KERNEL_ENTRY_ADDRESS} -c start.S -o start.o

loongarch32r-linux-gnusf-objdump -d start.o > start.s
loongarch32r-linux-gnusf-objdump -d vmlinux > test.s 

loongarch32r-linux-gnusf-objcopy -O binary -j .text start.o start.bin 

loongarch32r-linux-gnusf-objcopy -O binary -j .text -j __ex_table -j .notes -j .rodata -j __param -j .sdata \
                                                     -j __modver -j .data -j .data..page_aligned -j .init.text -j .init.data \
                                                     -j .exit.text vmlinux vmlinux.bin

mkdir -p obj 
mv test.s      ./obj/
mv start.s     ./obj/
mv start.bin   ./obj/
cp init_8f.txt ./obj/
cp init_5f.txt ./obj/
mv vmlinux.bin ./obj/
rm start.o
gcc ./convert.c -o convert
mv ./convert ./obj/ 
cd ./obj 
./convert 



