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

# TODO: add comment regarding this flag.
# I think it is suppressing errors on clock transition at time 0.
FLAGS  = -suppress 13178
# suppress error caused by mixing combinational/sequential elements in the same unpacked array
FLAGS += -suppress 7033
# disable optimizations
FLAGS += -voptargs=+acc

################################################################################
# Verilog define macros
################################################################################

# define TOOL_QUESTA macro (used to handle tool quirks)
DEF = -defineall TOOL_QUESTA

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
RISCOF_DEFINES ?=
# Verilog TOP level parameters overrides (processed at compile time)
RISCOF_PARAMETERS ?=
# Verilog plusarg-s (firmware/signature binary/hex file) (processed at run time)
RISCOF_PLUSARGS ?=

################################################################################
# targets
################################################################################

all: ${HDL}
	qrun -makelib work -sv ${HDL} -end ${DEF} ${PAR} ${FLAGS} ${ARG} -top ${TOP} \
	${RISCOF_DEFINES} ${RISCOF_PARAMETERS} ${RISCOF_PLUSARGS}

gui: ${HDL}
	qrun -makelib work -sv ${HDL} -end ${DEF} ${PAR} ${FLAGS} ${ARG} -top ${TOP} \
	${RISCOF_DEFINES} ${RISCOF_PARAMETERS} ${RISCOF_PLUSARGS} \
	-gui

