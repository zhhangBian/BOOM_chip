PRECC=loongarch32r-linux-gnusf-

CC=$(PRECC)gcc
LD=$(PRECC)ld
OBJCOPY=$(PRECC)objcopy
OBJDUMP=$(PRECC)objdump

SRCS= rand_boot.S
OBJS=${patsubst %.S,%.o,${SRCS}}
AFLAGS= -fno-pic -pipe
CFLAGS= -fno-pic -pipe
LDFLAGS= -static -T ld.script


TARGET=rand_boot


all: 
	make clean
	make other
other:convert dep $(TARGET)

.S.o:
	$(CC) $(AFLAGS) -c $< -o $@

$(TARGET):$(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $@
	$(OBJCOPY) -O binary -j .data $@ $(TARGET).data
	$(OBJCOPY) -O binary -R .data $@ $(TARGET).bin
	./convert
	mkdir obj
	$(OBJDUMP) -ald $(TARGET) > obj/$(TARGET).s

convert: convert.c
	gcc -o convert $<

dep: make.dep.o

make.dep.o:$(SRCS)
	$(CC) -MM $(SRCS) > make.dep.o
clean:
	rm -rf *.o *.vlog $(TARGET) $(TARGET).bin $(TARGET).data obj convert

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

