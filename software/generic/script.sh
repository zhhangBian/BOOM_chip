#!/bin/bash

GCC_BIN=../../../toolchains/loongarch32_gnu/install/bin

make start
make
$GCC_BIN/loongarch32-linux-gnu-ld obj/start.o obj/libinst.a -T bin.lds -o obj/main.elf
$GCC_BIN/loongarch32-linux-gnu-objcopy -O binary -j .text obj/main.elf obj/main.bin
$GCC_BIN/loongarch32-linux-gnu-objcopy -O binary -j .data obj/main.elf obj/main.data
#mv main.elf  ./obj/
#mv test.s    ./obj/
#mv main.bin  ./obj/
#mv main.data ./obj/
gcc ./convert.c -o obj/convert 
#mv ./convert ./obj/ 
cd ./obj
./convert 
rm -f ./convert
cd - 
make clean_no_obj
$GCC_BIN/loongarch32-linux-gnu-objdump -alD obj/main.elf > obj/test.s
