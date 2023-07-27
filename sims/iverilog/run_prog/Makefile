OBJ_DIR = ./obj_dir
#add your verilator include path to this var, then delete this line.

SIMU_TOP = ../testbench
SIMU_TOP_NAME = tb
VERILATOR_INCLUDE += -I ${SIMU_TOP} 
VERILATOR_SRC += ${SIMU_TOP}/*.v

SIMU_INCLUDE =$(TOP_SOC_SRC)
VERILATOR_INCLUDE += -I ${SIMU_INCLUDE} 
VERILATOR_SRC += ${SIMU_INCLUDE}/*.v

include config-generator.mak 

ifeq ('${MYCPU}', 'y') 
VERILATOR_INCLUDE += -I ${MYCPU_SRC} 
VERILATOR_SRC += ${MYCPU_SRC}/*.v
endif

ifeq ('${BRIDGE}', 'y') 
VERILATOR_INCLUDE += -I ${BRIDGE_SRC} 
VERILATOR_SRC += ${BRIDGE_SRC}/*.v
endif

ifeq ('${CONFREG}', 'y') 
VERILATOR_INCLUDE += -I ${CONFREG_SRC} 
VERILATOR_SRC += ${CONFREG_SRC}/confreg_sim.v
endif 

ifeq ('${AXI_RAND}', 'y') 
VERILATOR_INCLUDE += -I ${AXI_RAND_SRC} 
VERILATOR_SRC += ${AXI_RAND_SRC}/*.v
endif 

ifeq ('${AXI_SRAM}', 'y') 
VERILATOR_INCLUDE += -I ${AXI_SRAM_SRC} 
VERILATOR_SRC += ${AXI_SRAM_SRC}/*.v
endif 

VERILATOR_INCLUDE += -I ${AMBA_SRC}
VERILATOR_SRC += ${AMBA_SRC}/axi2apb.v ${AMBA_SRC}/axi_mux_sim.v
VERILATOR_INCLUDE += -I ${APB_DEV_SRC}
VERILATOR_SRC += ${APB_DEV_SRC}/apb_dev_top.v ${APB_DEV_SRC}/apb_mux2.v ${APB_DEV_SRC}/nand_module.v
VERILATOR_INCLUDE += -I ${UART_SRC}
VERILATOR_SRC += ${UART_SRC}/*.v
VERILATOR_INCLUDE += -I ${NAND_SRC}
VERILATOR_SRC += ${NAND_SRC}/*.v

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

include config-software.mak 

ifeq ('${DUMP}', 'n')
CFLAGS += -DNO_DUMP
endif

all:compile software run

compile:
	iverilog -DSIMU ${VFLAGS} ${CFLAGS} -Diverilog=1 -g2012 ${VERILATOR_INCLUDE} ${VERILATOR_SRC} -s ${SIMU_TOP_NAME} -o simv

software:
	make -C ../../../software/func/${RUN_SOFTWARE}
	mv ../../../software/func/${RUN_SOFTWARE}/obj ./

run:
	./simv

wave:
	gtkwave test.vcd

clean:
	rm simv test.vcd inst_ram.mif obj/ -rf
