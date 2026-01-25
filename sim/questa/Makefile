################################################################################
# DUT, TOP and source files
################################################################################

# design under test, must be provided as environment variable
DUT ?=

# top level file (an alternative TOP can be provided as environment variable)
TOP ?= r5p_${DUT}_riscof_tb

# include source file list in ${HDL} and ${SRC} variables
include ../sources-${DUT}.mk

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

# example
# DEF += -defineall macro
# DEF += -defineall macro=value

# define TOOL_* macro (used to handle tool quirks)
DEF = -defineall TOOL_QUESTA

################################################################################
# Verilog toplevel parameter override
################################################################################

# example
# PAR += -Gparameter=value

################################################################################
# Verilog plusargs
################################################################################

# example
# ARG += +key
# ARG += +key=value

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
# firmware include path
################################################################################

INC ?= +incdir+../../src

################################################################################
# targets
################################################################################

# uncomment the GUI target for debugging purposes
#all: gui
all: run

run: ${HDL} ${SRC}
	qrun -makelib work -sv ${HDL} ${SRC} -end ${DEF} ${PAR} ${FLAGS} ${INC} ${ARG} -top ${TOP} \
	${RISCOF_DEFINES} ${RISCOF_PARAMETERS} ${RISCOF_PLUSARGS}

gui: ${HDL} ${SRC}
	qrun -makelib work -sv ${HDL} ${SRC} -end ${DEF} ${PAR} ${FLAGS} ${INC} ${ARG} -top ${TOP} \
	${RISCOF_DEFINES} ${RISCOF_PARAMETERS} ${RISCOF_PLUSARGS} \
	-gui

