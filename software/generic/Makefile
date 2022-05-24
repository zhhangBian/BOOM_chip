include ../../../sims/verilator/run_func/config-software.mak

#all: haha libinst.a raw
all: raw libinst.a haha

GCC_BIN=../../../toolchains/loongarch32r-linux-gnusf*/bin

script:
	./script.sh

start:
	@mkdir -p obj
ifeq ('${TRACE_COMP}', 'y')
	${GCC_BIN}/loongarch32r-linux-gnusf-gcc \
		-Iinclude -nostdinc -nostdlib -D_KERNEL  -fno-builtin -D__loongarch32\
		-DMEMSTART=0x10000000 -DMEMSIZE=0x04000 -DCPU_COUNT_PER_US=1000     \
		-DENABLE_TRACE -S start.S > obj/start.s 
else
	${GCC_BIN}/loongarch32r-linux-gnusf-gcc \
		-Iinclude -nostdinc -nostdlib -D_KERNEL -fno-builtin -D__loongarch32\
		-DMEMSTART=0x10000000 -DMEMSIZE=0x04000 -DCPU_COUNT_PER_US=1000     \
		-S start.S > obj/start.s 
endif

haha:
	${GCC_BIN}/loongarch32r-linux-gnusf-as -mabi=ilp32 obj/start.s -o obj/start.o

libinst.a:
	make -C inst $@

raw:
	make -C obj $@ -f ../inst/Makefile

clean:
	rm -f *.o *.a 
	rm start.s
	rm -rf obj
	make -C inst clean 

clean_no_obj:
	rm -f *.o *.a 
	rm obj/start.s
	make -C inst clean 

reset:
	make clean
	rm -f bin.lds convert

help:
	@echo "################################################################"
	@echo "### help for compiling func"
	@echo "################################################################"
	@echo "### options:"
	@echo "###     make      : get compiled result, which is saved in ./obj"
	@echo "###     make clean: remove *.o, *.a, and ./obj"
	@echo "###     make reset: "make clean" and remove convert, bin.lds"
	@echo "###     make help : show help information"
	@echo "###############################################################"

