#!/bin/bash

GCC_BIN=../../toolchains/loongarch32r-linux-gnusf*/bin/
CFLAGS="-nostdlib -static -nostdinc -fno-builtin"
LFLAGS="-L../../toolchains/system_newlib/ -Wl,-T../../toolchains/system_newlib/pmon.ld -lc -lm -lg -lpmon -lgcc" 

#${GCC_BIN}/loongarch32r-linux-gnusf-gcc -c $1 -o main.o
#${GCC_BIN}/loongarch32r-linux-gnusf-gcc ${CFLAGS} main.o -o main.elf ${LFLAGS}

${GCC_BIN}/loongarch32r-linux-gnusf-gcc ${CFLAGS} $1 -o main.elf -I$(dirname $GCC_BIN)/lib/gcc/loongarch32r-linux-gnusf/8.3.0/include -I../../toolchains/system_newlib/loongarch32-unknown-elf/include ${LFLAGS}

${GCC_BIN}/loongarch32r-linux-gnusf-objdump -alD main.elf > test.s 
${GCC_BIN}/loongarch32r-linux-gnusf-objcopy -O binary -j .start -j .main main.elf main.bin
${GCC_BIN}/loongarch32r-linux-gnusf-objcopy -O binary -j .rodata -j .data -j .sdata -j .init_array -j .got main.elf main.data

mkdir -p obj 
mv main.elf ./obj/
mv test.s    ./obj/
mv main.bin  ./obj/
mv main.data ./obj/
gcc ./convert.c -o convert
mv ./convert ./obj/ 
cd ./obj 
./convert 
cd -


