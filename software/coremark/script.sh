#!/bin/sh


make compile PORT_DIR=barebones \
XLFLAGS="-I./ -I./barebones/ \
-nostdlib -static -nostdinc -fno-builtin \
-L../../toolchains/system_newlib/ -Wl,-T../../toolchains/system_newlib/pmon.ld -lc -lm -lg -lpmon -lgcc" \
XCFLAGS="-static -Ofast -funroll-all-loops -Ibarebones -I. -DPERFORMANCE_RUN=1 -DITERATIONS=1 -c" 

make link PORT_DIR=barebones \
XLFLAGS="-I./ -I./barebones/ \
-nostdlib -static -nostdinc -fno-builtin \
-L../../toolchains/system_newlib/ -Wl,-T../../toolchains/system_newlib/pmon.ld -lc -lm -lg -lpmon -lgcc" \
XCFLAGS="-static -Ofast -funroll-all-loops -Ibarebones -I. -DPERFORMANCE_RUN=1 -DITERATIONS=1 -c"  

mv coremark.bin main.elf 
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
make clean

