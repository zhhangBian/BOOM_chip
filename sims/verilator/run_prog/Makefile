include config-software.mak

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

comma=,
empty= 
space=${empty} 
soft_list=$(subst ${comma},${space},${RUN_SOFTWARE})

all:env_test func 
func:compile 
	make soft 
	make run
compile:link 
	$(MAKE) -j8 verilator
	$(MAKE) -j8 testbench
soft:soft_compile 
	#+make golden_trace
run:simulation_run_prog

link:
	ln -sf ../../../chip/config-generator.mak ./
	echo ${soft_compile_list} 
	echo ${golden_trace_list}

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
CFLAGS += -DWAVEFORM_SLICE_SIZE=${WAVEFORM_SLICE_SIZE}
CFLAGS += -DTRACE_SLICE_SIZE=${TRACE_SLICE_SIZE}
CFLAGS += -DWAVEFORM_TAIL_SIZE=${WAVEFORM_TAIL_SIZE}
CFLAGS += -DTRACE_TAIL_SIZE=${TRACE_TAIL_SIZE}
CFLAGS += -DDEAD_CLOCK_SIZE=${DEAD_CLOCK_SIZE}

ifeq ('${RUN_C}', 'y')
CFLAGS += -DRUN_C
endif

ifeq ('${RUN_FUNC}', 'y')
CFLAGS += -DRUN_FUNC
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

ifeq ('${OUTPUT_PC_INFO}', 'y')
CFLAGS += -DOUTPUT_PC_INFO
endif

ifeq ('${OUTPUT_UART_INFO}', 'y')
CFLAGS += -DOUTPUT_UART_INFO
endif

ifeq ('${READ_MISS_CHECK}', 'y')
CFLAGS += -DREAD_MISS_CHECK
endif

ifeq ('${PRINT_CLK_TIME}', 'y')
CFLAGS += -DPRINT_CLK_TIME
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

ifeq ('${SLICE_SIMU_TRACE}', 'y') 
CFLAGS += -DSLICE_SIMU_TRACE
endif  

ifeq ('${TAIL_WAVEFORM}', 'y') 
CFLAGS += -DTAIL_WAVEFORM
endif  

ifeq ('${TAIL_SIMU_TRACE}', 'y') 
CFLAGS += -DTAIL_SIMU_TRACE
endif  

ifeq ('${DEAD_CLOCK_EN}', 'y')
CFLAGS += -DDEAD_CLOCK_EN
endif

ifeq ('${RANDTEST}', 'y')
CFLAGS += -DRAND_TEST 
VFLAGS += -DRAND_TEST 
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


VERILATOR_INCLUDE += -y ${SIMU_TOP} 
ALL_VERILATOR_SRC += ${SIMU_TOP}/*.v

VERILATOR_INCLUDE += -y ${SIMU_INCLUDE} 
ALL_VERILATOR_SRC += ${SIMU_INCLUDE}/*.v

soft_compile_list_tmp_1 = $(foreach soft, ${soft_list}, ${wildcard ./obj/${soft}_obj}) 
soft_compile_list_tmp_2 = $(foreach soft, ${soft_compile_list_tmp_1}, ${subst ./obj/,${empty},${soft}})
soft_compile_list_tmp_3 = $(foreach soft, ${soft_compile_list_tmp_2}, ${subst _obj,${empty},${soft}})
soft_compile_list = $(filter-out $(soft_compile_list_tmp_3), $(soft_list))

golden_trace_list_tmp_1 = $(foreach soft, ${soft_list}, ${wildcard ./log/${soft}_log/golden_trace.txt})
golden_trace_list_tmp_2 = $(foreach soft, ${golden_trace_list_tmp_1}, ${subst ./log/,${empty},${soft}})
golden_trace_list_tmp_3 = $(foreach soft, ${golden_trace_list_tmp_2}, ${subst _log/golden_trace.txt,${empty},${soft}})
golden_trace_list = $(filter-out $(golden_trace_list_tmp_3), $(soft_list))


env_test: guard-CHIPLAB_HOME 
	@echo "CHIPLAB_HOME=${CHIPLAB_HOME}"

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

verilator:${VERILATOR_SRC} 
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	@echo "COMPILING verilog..."
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	mkdir -p log
	mkdir -p ${OBJ_DIR}
	verilator ${VERILATOR_INCLUDE} ${WAVEOPTION} --savable --threads ${THREAD} -O3 -Wno-fatal -DSIMU -DSIMULATION=1 -Wall --trace -cc ${VFLAGS} ${SIMU_TOP_NAME}.v ${DIFFTEST}.v ${VERILATOR_SRC} 2>&1 | tee log/compile.log
	$(MAKE) -C ${OBJ_DIR} -f "V${SIMU_TOP_NAME}.mk" || exit "$$?"

testbench:${TESTBENCH_SRC}/*.cpp 
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	@echo "COMPILING testbench..."
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	g++ -O3 -pthread -DCACHE_SEED=0 -DVL_THREADED -DRESET_VAL=${RESET_VAL} -DRESET_SEED=${RESET_SEED} ${CFLAGS} ${INCLUDE} ${VERILATED_SRC} ${VCD_SRC} ${FST_SRC} ${SAVE_SRC} $? ${ALL_LIB} -o output -lz -ldl

soft_compile:
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	@echo "COMPILING func..."
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	@for soft in ${soft_compile_list}; \
	do 	\
	make -C ${CHIPLAB_HOME}/software/$${soft} || exit "$$?";\
	rm -rf ./obj/$${soft}_obj;	\
	mkdir -p ./obj/$${soft}_obj;  \
	mv ${CHIPLAB_HOME}/software/$${soft}/obj ./obj/$${soft}_obj;	\
	mkdir -p ./log/$${soft}_log;	\
	done 

golden_trace:
ifeq ('${TRACE_COMP}', 'y')
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	@echo "GETING golden trace..."
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	@for soft in ${golden_trace_list}; \
	do 	\
	mkdir -p tmp;	\
	./qemu_system_run.sh ./obj/$${soft}_obj/obj/main.elf;	\
	mv ./single.log ./tmp;	\
	cp ./obj/$${soft}_obj/obj/test.s ./tmp;	\
	cp ./log_script/* ./tmp;	\
	make golden_trace_make -C ./tmp -f ../Makefile_run;	\
	mkdir -p ./log/$${soft}_log;	\
	mv ./tmp/golden_trace.txt ./log/$${soft}_log/; \
	rm -rf ./tmp;    \
	done 
endif 

simulation_run_prog:
	@echo "============================================================================================================="
	@echo "============================================================================================================="
	@echo "RUN simulation..."
	@echo "============================================================================================================="
	@echo "============================================================================================================="
ifeq ('${TRACE_COMP}', 'y')
	@for soft in ${soft_list}; \
	do 	\
	mkdir -p tmp;	\
	cp ./log/$${soft}_log/golden_trace.txt ./tmp;	\
	cp ./obj/$${soft}_obj/obj/rom.vlog ./tmp;	\
	touch ./tmp/ram.dat;\
	cat ./tmp/rom.vlog > ./tmp/ram.dat;	\
	make simulation_run_prog -C ./tmp -f ../Makefile_run || exit "$$?";	\
	mv ./tmp/simu_trace.txt* ./log/$${soft}_log/;	\
	mv ./tmp/uart_output.txt ./log/$${soft}_log/;	\
	mv ./tmp/uart_output.txt.real ./log/$${soft}_log/;	\
	mv ./tmp/mem_trace.txt ./log/$${soft}_log/;         \
	mv ./tmp/logs/*.${WAVEFILE} ./log/$${soft}_log/;	\
	rm -rf ./tmp;    \
	done 
else 
	@for soft in ${soft_list}; \
	do 	\
	mkdir -p tmp;	\
	cp ./obj/$${soft}_obj/obj/rom.vlog ./tmp;	\
	touch ./tmp/ram.dat;\
	cat ./tmp/rom.vlog > ./tmp/ram.dat;	\
	make simulation_run_prog -C ./tmp -f ../Makefile_run || exit "$$?";	\
	mkdir -p ./log/$${soft}_log;	\
	mv ./tmp/simu_trace.txt* ./log/$${soft}_log/;	\
	mv ./tmp/uart_output.txt ./log/$${soft}_log/;	\
	mv ./tmp/uart_output.txt.real ./log/$${soft}_log/;	\
	mv ./tmp/mem_trace.txt ./log/$${soft}_log/;         \
	mv ./tmp/logs/*.${WAVEFILE} ./log/$${soft}_log/;	\
	rm -rf ./tmp; \
	done 
endif


clean_soft:
	for soft in ${soft_list}; \
	do \
	rm -rf ./log/$${soft}_log;	\
	rm -rf ./obj/$${soft}_obj;	\
	done

clean:
	rm -f output & rm -rf obj_dir &	\
	rm -rf ./tmp
	for soft in ${soft_list};	\
	do 	\
	rm -rf ./log/$${soft}_log;	\
	rm -rf ./obj/$${soft}_obj;	\
	done


clean_all:
	rm -f output
	rm -rf obj_dir 
	rm -rf log
	rm -rf obj 
	rm -rf ./tmp
	rm -f config-generator.mak 
	rm -f config.log

