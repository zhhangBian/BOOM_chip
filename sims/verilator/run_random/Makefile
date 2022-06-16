include config-random.mak

VERILATOR_HOME1=/usr/share/verilator
VERILATOR_HOME2=/usr/local/share/verilator
ifeq ($(VERILATOR_HOME1), $(wildcard $(VERILATOR_HOME1)))
VERILATOR_HOME=$(VERILATOR_HOME1)
else ifeq ($(VERILATOR_HOME2), $(wildcard $(VERILATOR_HOME2)))
VERILATOR_HOME=$(VERILATOR_HOME2)
else
#add your verilator include path to this var, then delete this line.
VERILATOR_HOME=/home/yangzhaoxin/opt/verilator/share/verilator
#$(error Please install verilator or config the installed path here.)
endif


VERILATOR_VLTSTD=$(VERILATOR_HOME)

ifeq ($(shell which verilator),)
$(error Did not find Verilator in PATH. Make sure all requirements are installed)
endif

#configure options
# Change the options below for your testbench
#LA32=y
#multithread
#THREAD=1
#move to config-random.mak

OBJ_DIR = ./obj_dir
#add your verilator include path to this var, then delete this line.
INCLUDE = -I${VERILATOR_HOME}/include 
INCLUDE+= -I$(VERILATOR_HOME)/include/vltstd
VERILATED_SRC = ${VERILATOR_HOME}/include/verilated.cpp ${VERILATOR_HOME}/include/verilated_threads.cpp
VCD_SRC = ${VERILATOR_HOME}/include/verilated_vcd_c.cpp
FST_SRC = ${VERILATOR_HOME}/include/verilated_fst_c.cpp
SAVE_SRC = ${VERILATOR_HOME}/include/verilated_save.cpp
ALL_LIB = ${OBJ_DIR}/*__ALL.a
TESTBENCH_SRC = ../testbench
TESTBENCH_INCLUDE = ../testbench/include
SIMU_TOP = ../testbench
SIMU_INCLUDE =$(TOP_SOC_SRC)
SIMU_TOP_NAME=simu_top
DIFFTEST=difftest
INCLUDE += -I${TESTBENCH_INCLUDE}
INCLUDE += -I${OBJ_DIR}

RANDTEST=y
RUN_RANDOM=RES/random0

comma=,
empty= 
space=${empty} 

all:random check_result
random:link
	$(MAKE) -j verilator
	$(MAKE) testbench
	$(MAKE) simulation_run_random

link:config-generator.mak
config-generator.mak:
	ln -sf ../../../chip/config-generator.mak ./

include ../../../chip/config-generator.mak 

ifeq ('${MYCPU}', 'y') 
VERILATOR_INCLUDE += -y ${MYCPU_SRC} 
VERILATOR_SRC += ${MYCPU_SRC}/*.v
endif

ifeq ('${BRIDGE}', 'y') 
VERILATOR_INCLUDE += -y ${BRIDGE_SRC} 
VERILATOR_SRC += ${BRIDGE_SRC}/*.v
endif

ifeq ('${CONFREG}', 'y') 
VERILATOR_INCLUDE += -y ${CONFREG_SRC} 
VERILATOR_SRC += ${CONFREG_SRC}/confreg_sim.v
endif 

ifeq ('${AXI_RAND}', 'y') 
VERILATOR_INCLUDE += -y ${AXI_RAND_SRC} 
VERILATOR_SRC += ${AXI_RAND_SRC}/*.v
endif 

ifeq ('${AXI_SRAM}', 'y') 
VERILATOR_INCLUDE += -y ${AXI_SRAM_SRC} 
VERILATOR_SRC += ${AXI_SRAM_SRC}/*.v
endif 

VERILATOR_INCLUDE += -y ${AMBA_SRC}
VERILATOR_SRC += ${AMBA_SRC}/axi2apb.v ${AMBA_SRC}/axi_mux_sim.v
VERILATOR_INCLUDE += -y ${APB_DEV_SRC}
VERILATOR_SRC += ${APB_DEV_SRC}/apb_dev_top.v ${APB_DEV_SRC}/apb_mux2.v
VERILATOR_INCLUDE += -y ${UART_SRC}
VERILATOR_SRC += ${UART_SRC}/*.v
VERILATOR_INCLUDE += -y ${NAND_SRC}
VERILATOR_SRC += ${NAND_SRC}/*.v

CFLAGS += -std=c++11
CFLAGS += -DSLICE_SIZE=${SLICE_SIZE}

ifeq ('${RANDTEST}', 'y')
CFLAGS += -DRAND_TEST 
VFLAGS += -DRAND_TEST 
endif 

ifeq ('${LA32}', 'y')
CFLAGS += -DLA32 
endif 

ifeq ('${CPU_2CMT}', 'y')
VFLAGS += -DCPU_2CMT 
CFLAGS += -DCPU_2CMT 
endif 


ifeq ('$(AXI64)', 'y')
CFLAGS += -DAXI64
VFLAGS += -DAXI64
endif

ifeq ('$(AXI128)', 'y')
CFLAGS += -DAXI128
VFLAGS += -DAXI128
endif

ifeq ('${DUMP_VCD}', 'y') 
CFLAGS += -DDUMP_VCD 
WAVEFILE = vcd 
WAVEOPTION = 
endif
 
ifeq ('${DUMP_FST}', 'y') 
CFLAGS += -DDUMP_FST 
WAVEFILE = fst 
WAVEOPTION = --trace-fst
endif

ifeq ('${SLICE_WAVEFORM}', 'y') 
CFLAGS += -DSLICE_WAVEFORM
endif  

ifeq ('${TRACE_COMP}', 'y')
CFLAGS += -DTRACE_COMP
endif 

ifeq ('${SIMU_TRACE}', 'y')
CFLAGS += -DSIMU_TRACE 
endif 

ifeq ('${MEM_TRACE}', 'y')
CFLAGS += -DMEM_TRACE 
endif 

VERILATOR_INCLUDE += -y ${SIMU_TOP} 
ALL_VERILATOR_SRC += ${SIMU_TOP}/*.v

VERILATOR_INCLUDE += -y ${SIMU_INCLUDE} 
ALL_VERILATOR_SRC += ${SIMU_INCLUDE}/*.v

RUN_TIME = $(shell date +"%y-%m-%d-%H-%M-%S")

verilator:${VERILATOR_SRC} 
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	@echo "COMPILING verilog..."
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	verilator ${VERILATOR_INCLUDE} ${WAVEOPTION} --threads ${THREAD} -O3 -Wno-fatal -DSIMU -DSIMULATION=1 -Wall --trace -cc ${VFLAGS} ${SIMU_TOP_NAME}.v ${DIFFTEST}.v ${VERILATOR_SRC}
	$(MAKE) -C ${OBJ_DIR} -f "V${SIMU_TOP_NAME}.mk"

testbench:${TESTBENCH_SRC}/*.cpp 
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	@echo "COMPILING testbench..."
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	g++ -O3 -pthread -DVL_THREADED -DCACHE_SEED=${CACHE_SEED} -DRESET_VAL=${RESET_VAL} -DRESET_SEED=${RESET_SEED} ${CFLAGS} ${INCLUDE} ${VERILATED_SRC} ${VCD_SRC} ${FST_SRC} ${SAVE_SRC} $? ${ALL_LIB} -o output -lz -ldl

simulation_run_random:
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	@echo "RUN simulation..."
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	make all -C ../../../software/random_boot/ ./Makefile || exit "$$?"
	make prepare -C ./run_random -f ./Makefile || exit "$$?"
	make all -C ./run_random -f ./Makefile || exit "$$?"
check_result:
	@echo "Check random result"
	grep -Hs PASS  log/*/run.log > log/pass.log || true
	grep -Hs wrong log/*/run.log > log/fail.log || true
	mkdir -p log/$(RUN_TIME)/ && mv log/*.log log/$(RUN_TIME)
clean:
	rm -f output & rm -rf obj_dir &	\
	make clean -C ./run_random -f ./Makefile
	make clean -C ../../../software/random_boot/ ./Makefile
	rm -rf ./tmp 
	rm -rf log/*

clean_all:
	rm -f output
	rm -rf obj_dir 
	rm -rf log/*
	rm -rf obj 
	rm -f config-generator.mak 
	rm -f config.log
	make clean -C ./run_random -f ./Makefile
	make clean -C ../../../software/random_boot/ ./Makefile

