################################################################################
# documentation
################################################################################

# https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation/Vivado-Simulator-Quick-Reference-Guide
# https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation/Elaborating-and-Generating-a-Design-Snapshot-xelab
# https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation/Simulating-the-Design-Snapshot-xsim

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
# tool specific flags
################################################################################

################################################################################
# Verilog define macros
################################################################################

# example
# DEF += -d macro
# DEF += -d macro=value

# define TOOL_VIVADO_SIMULATOR macro (used to handle tool quirks)
DEF = -d TOOL_VIVADO_SIMULATOR

################################################################################
# Verilog toplevel parameter override
################################################################################

# example
# PAR += -generic_top "generic/parameter=value"

################################################################################
# Verilog plusargs
################################################################################

# example
# ARG += -testplusarg key
# ARG += -testplusarg key=value

################################################################################
# CLI arguments from RISCOF
################################################################################

# Verilog define macros (processed at compile time)
RISCOF_DEFINES ?=
# Verilog TOP level parameters overrides (processed at compile time)
RISCOF_PARAMETERS ?=
# Verilog plusarg-s (firmware/signature binary/hex file) (processed at run time)
RISCOF_PLUSARGS ?=

################################################################################
# targets
################################################################################

all: gui
all: simulate

compile: ${HDL}
	xvlog ${FLAGS} ${DEF} ${RISCOF_DEFINES} -sv ${HDL}

elaborate: compile
	xelab ${PAR} ${RISCOF_PARAMETERS} work.${TOP} -s ${TOP}

simulate: elaborate
	xsim ${ARG} ${RISCOF_PLUSARGS} ${TOP} -R

gui: elaborate
	xsim ${ARG} ${RISCOF_PLUSARGS} ${TOP} -R -gui
