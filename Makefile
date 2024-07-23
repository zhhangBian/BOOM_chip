VERILATOR_HOME=verilator
VERILATOR_FLAG=-cc -Wall \
	--top-module core_top \
	-O3 \
	-Wno-fatal \
	-Wall \
	-Wno-DECLFILENAME \
	-Wno-EOFNEWLINE \
	--cc
	# -Wno-PINCONNECTEMPTY \
	-Wno-PINMISSING \
	-Wno-WIDTH \

VERILATOR_INCLUDE += -y rtl
VERILATOR_INCLUDE += -y rtl/fpga_mem
VERILATOR_INCLUDE += -y rtl/verilog-axi

# Source code
VERILATOR_SRC += rtl/*.sv
VERILATOR_SRC += rtl/fpga_mem/*.sv
VERILATOR_SRC += rtl/verilog-axi/*.sv

all:
	$(VERILATOR_HOME) $(VERILATOR_INCLUDE) $(VERILATOR_FLAG) $(VERILATOR_SRC) 

.PHONY: clean
clean:
	rm -rf ./obj_dir
