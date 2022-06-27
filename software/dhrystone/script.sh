#!/bin/bash

CFLAGS="-nostdlib -static -nostdinc -fno-builtin"
LFLAGS="-L../../toolchains/system_newlib/ -Wl,-T../../toolchains/system_newlib/pmon.ld -lc -lm -lg -lpmon -lgcc"

loongarch32r-linux-gnusf-gcc -c dry.c -o dry1.o
loongarch32r-linux-gnusf-gcc -DPASS2 ${CFLAGS} dry_no_include.c dry1.o -o main.elf ${LFLAGS}
#${CC} -c -DREG dry.c -o dry1.o
#${CC} -DPASS2 -DREG ${CFLAGS} dry_no_include.c dry1.o -o dry2nr ${LFLAGS}
#${CC} -c -O dry.c -o dry1.o 
#${CC} -DPASS2 -O ${CFLAGS} dry_no_include.c dry1.o -o dry2o ${LFLAGS} 

loongarch32r-linux-gnusf-objdump -alD main.elf > test.s 
loongarch32r-linux-gnusf-objcopy -O binary -j .start -j .main main.elf main.bin
loongarch32r-linux-gnusf-objcopy -O binary -j .rodata -j .data -j .sdata -j .init_array -j .got main.elf main.data

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



