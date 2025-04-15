################################################################################
# DUT, TOP and source files
################################################################################

# design under test, must be provided as environment variable
DUT ?=

# top level file (an alternative TOP can be provided as environment variable)
TOP ?= r5p_${DUT}_riscv_tb

# include source file list in ${HDL} variable
include ../Makefile-sources-${DUT}

################################################################################
# Verilator compiler/linker flags
################################################################################

# specify SystemVerilog LRM version
#VFLAGS += +1800-2012ext+sv
# Generate binary executable
VFLAGS += --binary
# Optimize
VFLAGS += -O3
# Number of CPU threads
VFLAGS += -j 0
# optimize for speed or maximize finding X assign issues
VFLAGS += --x-assign fast
#VFLAGS += --x-assign 0
#VFLAGS += --x-assign 1
#VFLAGS += --x-assign unique
# Warn about lint issues; may not want this on less solid designs
#VFLAGS += -Wall
# Check SystemVerilog assertions
VFLAGS += --assert
# Generate coverage analysis
#VFLAGS += --coverage

# Run Verilator in debug mode
#VFLAGS += --debug
# Add this trace to get a backtrace in gdb
#VFLAGS += --gdbbt

# Make waveforms
#ifdef TRACE_DEBUG
VFLAGS += --trace-fst
VFLAGS += --trace-structs
#endif

################################################################################
# Verilog define macros
################################################################################

# define macro VERILATOR is already predefined in Verilator

# define TOOL_VERILATOR macro (used to handle tool quirks)
DEF = -DTOOL_VERILATOR

################################################################################
# Verilog toplevel parameter override
################################################################################

# set XLEN parameter
#XLEN ?= 32
#PAR += -GXLEN=${XLEN}

################################################################################
# Verilog plusargs
################################################################################

ARG =

################################################################################
# CLI arguments from RISCOF
################################################################################

# Verilog define macros (processed at compile time)
RISCOF_DEFINES ?= ""
# Verilog TOP level parameters overrides (processed at compile time)
RISCOF_PARAMETERS ?= ""
# Verilog plusarg-s (firmware/signature binary/hex file) (processed at run time)
RISCOF_PLUSARGS ?= ""

################################################################################
# targets
################################################################################

all: sim

lint: ${HDL}
	verilator --lint-only ${DEF} ${PAR} ${RISCOF_DEFINES} ${RISCOF_PARAMETERS} --top ${TOP} ${HDL}

compile: ${HDL}
	verilator ${VFLAGS} ${DEF} ${PAR} ${RISCOF_DEFINES} ${RISCOF_PARAMETERS} --top ${TOP} ${HDL}

sim: compile
	obj_dir/V${TOP} ${ARG} ${RISCOF_ARGUMENTS}
#	verilator_coverage --annotate logs/annotated logs/coverage.dat
