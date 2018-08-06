MODELSIM_BIN=$(HOME)/altera/14.1/modelsim_ase/bin

RTL=../rtl/rp8.sv ../rtl/rp8_gpio.sv ../rtl/mem.sv
TBN=../tbn/avr_disasm.sv ../tbn/rp8_tb.sv

all: modelsim

copy_test_isa:
	cp -f ../src/test_isa/test_isa.elf .
	cp -f ../src/test_isa/test_isa.vmem .

iverilog:
	iverilog -g2012 -o $(RTL) $(TBN)
	vvp rp8.out

verilator: copy_test_isa
	# compile SystemVerilog sources
	verilator -Wall --cc --trace --exe ../tbn/rp8_verilator.cpp --top-module rp8_verilator \
	-Wno-fatal \
	-y ../tbn/ \
	-CFLAGS -I/usr/local/include/simavr/ \
	-LDFLAGS -lsimavr \
	../tbn/rp8_verilator.sv \
	$(RTL)
	# build C++ project
	make -j -C obj_dir/ -f Vrp8_verilator.mk Vrp8_verilator
	# run executable simulation
	LD_LIBRARY_PATH=/usr/local/lib/ obj_dir/Vrp8_verilator

modelsim: copy_test_isa
	$(MODELSIM_BIN)/vlib work
	$(MODELSIM_BIN)/vlog $(RTL) $(TBN)
	$(MODELSIM_BIN)/vsim -c -do 'run -all;quit' rp8_tb

gtkwave:
	gtkwave rp8_tb.vcd        -a rp8_tb.gtkw
	gtkwave rp8_verilator.vcd -a rp8_verilator.gtkw
