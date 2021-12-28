################################################################################
# HDL source files
################################################################################

PATH_RTL=../../hdl/rtl
PATH_TBN=../../hdl/tbn
PATH_SRC=../../hdl/src

# SystemVerilog RTL
RTL+=${PATH_RTL}/riscv/riscv_isa_pkg.sv
RTL+=${PATH_RTL}/riscv/riscv_csr_pkg.sv
#RTL+=${PATH_RTL}/riscv_csr_adr_map_pkg.sv
RTL+=${PATH_RTL}/core/r5p_pkg.sv
RTL+=${PATH_RTL}/core/r5p_br.sv
RTL+=${PATH_RTL}/core/r5p_gpr.sv
RTL+=${PATH_RTL}/core/r5p_alu.sv
RTL+=${PATH_RTL}/core/r5p_mdu.sv
#RTL+=${PATH_RTL}/core/r5p_fpu.sv
RTL+=${PATH_RTL}/core/r5p_lsu.sv
RTL+=${PATH_RTL}/core/r5p_csr_pkg.sv
RTL+=${PATH_RTL}/core/r5p_csr.sv
RTL+=${PATH_RTL}/core/r5p_core.sv

# SoC files
RTL+=${PATH_RTL}/soc/r5p_bus_if.sv
RTL+=${PATH_RTL}/soc/r5p_bus_arb.sv
RTL+=${PATH_RTL}/soc/r5p_bus_dec.sv
RTL+=${PATH_RTL}/soc/r5p_soc_mem.sv
RTL+=${PATH_RTL}/soc/r5p_soc_gpio.sv
RTL+=${PATH_RTL}/soc/r5p_soc_top.sv

# SystemVerilog bench (Test SV)
TSV =${PATH_TBN}/riscv_asm_pkg.sv
TSV+=${PATH_TBN}/mem.sv
TSV+=${PATH_TBN}/r5p_bus_mon.sv
TSV+=${PATH_TBN}/r5p_tb.sv

# combined HDL sources
HDL =${RTL}
HDL+=${TSV}

# top level file
# TODO: pass it as macro to CS compiler
TOP = r5p_tb

################################################################################
# SystemC
################################################################################

# SystemC bench (Test SystemC)
TSC =${PATH_SRC}/sc_main.cpp

################################################################################
# Verilator compiler/linker flags
################################################################################

# specify SystemVerilog LRM version
#VFLAGS += +1800-2012ext+sv
# Generate SystemC in executable form
VFLAGS += -sc --exe
# Generate makefile dependencies (not shown as complicates the Makefile)
#VFLAGS += -MMD
# Optimize
VFLAGS += -O2
# optimize for speed or maximize finding X assign issues
VFLAGS += --x-assign fast
#VFLAGS += --x-assign 0
#VFLAGS += --x-assign 1
#VFLAGS += --x-assign unique
# Warn abount lint issues; may not want this on less solid designs
#VFLAGS += -Wall
# Make waveforms
VFLAGS += --trace-fst
VFLAGS += --trace-structs
# Check SystemVerilog assertions
VFLAGS += --assert
# Generate coverage analysis
#VFLAGS += --coverage
# Run Verilator in debug mode
#VFLAGS += --debug
# Add this trace to get a backtrace in gdb
#VFLAGS += --gdbbt

################################################################################
# Verilog macros
################################################################################

# set VERILATOR macro (used to handle tool quirks)
#MCR += -DVERILATOR

################################################################################
# Verilog toplevel parameter override
################################################################################

# set XLEN parameter
XLEN ?= 32
PAR += -GXLEN=${XLEN}

################################################################################
# Verilog $plusargs runtime arguments
################################################################################

ARG+= +FILE_MEM="${FILE_MEM}" +FILE_SIG="${FILE_SIG}"
ARG+= +trace

################################################################################
#
################################################################################

all: sim

lint: ${HDL}
	verilator --lint-only ${HDL} --top ${TOP}

verilate: ${HDL} ${TSC}
	verilator $(VFLAGS) ${MCR} ${PAR} --top ${TOP} ${HDL} ${TSC}

compile: verilate
	make -j 4 -C obj_dir -f V${TOP}.mk

sim: compile
	obj_dir/V${TOP} ${ARG}
#	verilator_coverage --annotate logs/annotated logs/coverage.dat