obj_path = ./obj
inst_srcs = $(wildcard ./inst/*.S)


default: 
	make all
	make tidy

all:
	mkdir -p ${obj_path}
	make ${obj_path}/inst_ram.coe ${obj_path}/test.s

tidy: 
	rm -f ${obj_path}/convert ${obj_path}/main.bin ${obj_path}/main.data ${obj_path}/main.elf ${obj_path}/start.s ${obj_path}/start.o
	make -C inst clean 

${obj_path}/test.s: ${obj_path}/main.elf
	loongarch32r-linux-gnusf-objdump -alD ${obj_path}/main.elf > ${obj_path}/test.s

${obj_path}/libinst.a: ${inst_srcs}
	make -C inst libinst.a

${obj_path}/start.o: ${obj_path}/start.s
	loongarch32r-linux-gnusf-as -mabi=ilp32 ${obj_path}/start.s -o ${obj_path}/start.o

${obj_path}/inst_ram.coe ${obj_path}/inst_ram.mif: ${obj_path}/main.bin ${obj_path}/main.data ${obj_path}/convert
	cd ${obj_path} && ./convert 

${obj_path}/convert: convert.c
	gcc ./convert.c -o ${obj_path}/convert 

${obj_path}/main.bin: ${obj_path}/main.elf
	loongarch32r-linux-gnusf-objcopy -O binary -j .text ${obj_path}/main.elf ${obj_path}/main.bin
${obj_path}/main.data: ${obj_path}/main.elf
	loongarch32r-linux-gnusf-objcopy -O binary -j .data ${obj_path}/main.elf ${obj_path}/main.data

${obj_path}/main.elf: bin.lds ${obj_path}/libinst.a ${obj_path}/start.o
	loongarch32r-linux-gnusf-ld ${obj_path}/start.o ${obj_path}/libinst.a -T bin.lds -o ${obj_path}/main.elf

${obj_path}/start.s: start.S
	@mkdir -p ${obj_path}
	loongarch32r-linux-gnusf-gcc \
		-Iinclude -nostdinc -nostdlib -D_KERNEL -fno-builtin -D__loongarch32\
		-DMEMSTART=0x10000000 -DMEMSIZE=0x04000 -DCPU_COUNT_PER_US=1000     \
		-S start.S > ${obj_path}/start.s 

clean:
	rm -rf obj

help:
	@echo "################################################################"
	@echo "### help for compiling func"
	@echo "################################################################"
	@echo "### options:"
	@echo "###     make      : get compiled result, which is saved in ./obj"
	@echo "###     make clean: remove *.o, *.a, and ./obj"
	@echo "###     make help : show help information"
	@echo "###############################################################"

