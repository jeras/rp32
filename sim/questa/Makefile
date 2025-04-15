################################################################################
# DUT and TOP
################################################################################

# design under test, must be provided as environment variable
DUT ?=

# top level file (an alternative TOP can be provided as environment variable)
TOP ?= r5p_${DUT}_riscv_tb

# include source file list in ${HDL} variable
include ../Makefile-sources-${DUT}

################################################################################
# VHDL standard conditional analysis identifiers
################################################################################

# # "SIMULATION", "SYNTHESIS", "FORMAL"
# TOOL_TYPE    := "SIMULATION"
# TOOL_VENDOR  := "Siemens"
# TOOL_NAME    := "questa"
# # TODO: use sed to extract edition/version from stdout string
# TOOL_EDITION := "$(shell qrun -version)"
# TOOL_VERSION := "$(shell qrun -version)"
#
# # VHDL standard conditional analysis identifiers
# TOOL  = -defineall TOOL_TYPE='${TOOL_TYPE}'
# TOOL += -defineall TOOL_VENDOR='${TOOL_VENDOR}'
# TOOL += -defineall TOOL_NAME='${TOOL_NAME}'
# TOOL += -defineall TOOL_EDITION='${TOOL_EDITION}'
# TOOL += -defineall TOOL_VERSION='${TOOL_VERSION}'

################################################################################
# Verilog defines
################################################################################

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
RISCOF_DEFINES ?= ""
# Verilog TOP level parameters overrides (processed at compile time)
RISCOF_PARAMETERS ?= ""
# Verilog plusarg-s (firmware/signature binary/hex file) (processed at run time)
RISCOF_PLUSARGS ?= ""

################################################################################
#
################################################################################

# TODO: add comment regarding this flag.
# I think it is suppressing errors on clock transition at time 0.
FLAGS  = -suppress 13178
# suppress error caused by mixing combinational/sequential elements in the same unpacked array
FLAGS += -suppress 7033
# disable optimizations
FLAGS += -voptargs=+acc

all:
	qrun -makelib work -sv ${HDL} -end ${DEF} ${PAR} ${FLAGS} ${ARG} -top ${TOP} \
	${RISCOF_DEFINES} ${RISCOF_PARAMETERS} ${RISCOF_PLUSARGS}

gui:
	qrun -makelib work -sv ${HDL} -end ${DEF} ${PAR} ${FLAGS} ${ARG} -top ${TOP} \
	${RISCOF_DEFINES} ${RISCOF_PARAMETERS} ${RISCOF_PLUSARGS} \
	-gui

