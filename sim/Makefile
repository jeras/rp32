# SystemVerilog bench

# top level file
# TODO: pass it as macro to CS compiler
TOP = rp_tb

V_FLAGS =
# Generate SystemC in executable form
V_FLAGS += -sc --exe
# Generate makefile dependencies (not shown as complicates the Makefile)
#V_FLAGS += -MMD
# Optimize
V_FLAGS += -O2 -x-assign 0
# Warn abount lint issues; may not want this on less solid designs
#V_FLAGS += -Wall
# Make waveforms
V_FLAGS += --trace
V_FLAGS += --trace-structs
# Check SystemVerilog assertions
V_FLAGS += --assert
# Generate coverage analysis
V_FLAGS += --coverage
# Run Verilator in debug mode
#V_FLAGS += --debug
# Add this trace to get a backtrace in gdb
#V_FLAGS += --gdbbt

all: sim

sim: ${HDL}
	$(VERILATOR_ROOT)/bin/verilator $(V_FLAGS) --top-module ${TOP} -cc rp_tb.sv -exe main.cpp
	make -j -C obj_dir -f V${TOP}.mk V${TOP}
	obj_dir/V${TOP} +trace

