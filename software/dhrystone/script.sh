#!/bin/bash

GCC_BIN=../../toolchains/loongarch32_gnu/install/bin/
CFLAGS="-nostdlib -mlong-calls -static -nostdinc -fno-builtin"
LFLAGS="-L../../toolchains/system_newlib/ -Wl,-T../../toolchains/system_newlib/pmon.ld -lc -lm -lg -lpmon -lgcc"

${GCC_BIN}/loongarch32-linux-gnu-gcc -c dry.c -o dry1.o
${GCC_BIN}/loongarch32-linux-gnu-gcc -DPASS2 ${CFLAGS} dry_no_include.c dry1.o -o main.elf ${LFLAGS}
#${CC} -c -DREG dry.c -o dry1.o
#${CC} -DPASS2 -DREG ${CFLAGS} dry_no_include.c dry1.o -o dry2nr ${LFLAGS}
#${CC} -c -O dry.c -o dry1.o 
#${CC} -DPASS2 -O ${CFLAGS} dry_no_include.c dry1.o -o dry2o ${LFLAGS} 

${GCC_BIN}/loongarch32-linux-gnu-objdump -alD main.elf > test.s 
${GCC_BIN}/loongarch32-linux-gnu-objcopy -O binary -j .start -j .main main.elf main.bin
${GCC_BIN}/loongarch32-linux-gnu-objcopy -O binary -j .rodata -j .data -j .sdata -j .init_array -j .got main.elf main.data

mkdir -p obj 
mv main.elf  ./obj/
mv test.s    ./obj/
mv main.bin  ./obj/
mv main.data ./obj/
gcc ./convert.c -o convert
mv ./convert ./obj/ 
cd ./obj 
./convert 
cd -
rm -f dry1.o



