

VERILATOR = verilator
VERILATOR_FLAG = -cc -Wall

SRC = $(shell ls rtl/*.sv | grep -v "b_npc")
SRC += rtl/verilog-axi/*.sv \
	rtl/fpga_mem/*.sv

VERILATOR_FLAG += -I rtl

all:
	$(VERILATOR) $(VERILATOR_FLAG) $(SRC)
