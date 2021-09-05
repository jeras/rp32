#!/bin/bash

# Verilator setup
source ../sim/settings.sh

################################################################################
# RP32
################################################################################

export PATH=/home/ijeras/VLSI/lowrisc-toolchain-gcc-rv32imc-20210412-1/bin/:$PATH

TARGETDIR=`pwd` RISCV_TARGET=r5p WORK=`pwd`/work XLEN=32 make -C ../submodules/riscv-arch-test clean
TARGETDIR=`pwd` RISCV_TARGET=r5p WORK=`pwd`/work XLEN=32 make -C ../submodules/riscv-arch-test compile

TARGETDIR=`pwd` WORK=`pwd`/work RISCV_TARGET=r5p XLEN=32 RISCV_DEVICE=I make -C ../submodules/riscv-arch-test verify
TARGETDIR=`pwd` WORK=`pwd`/work RISCV_TARGET=r5p XLEN=32 RISCV_DEVICE=C make -C ../submodules/riscv-arch-test verify
TARGETDIR=`pwd` WORK=`pwd`/work RISCV_TARGET=r5p XLEN=32 RISCV_DEVICE=M make -C ../submodules/riscv-arch-test verify

################################################################################
# RP64
################################################################################

export PATH=/home/ijeras/VLSI/lowrisc-toolchain-gcc-rv64imac-20210412-1/bin/:$PATH

TARGETDIR=`pwd` RISCV_TARGET=r5p WORK=`pwd`/work XLEN=64 make -C ../submodules/riscv-arch-test clean
TARGETDIR=`pwd` RISCV_TARGET=r5p WORK=`pwd`/work XLEN=64 make -C ../submodules/riscv-arch-test compile

TARGETDIR=`pwd` WORK=`pwd`/work RISCV_TARGET=r5p XLEN=64 RISCV_DEVICE=I make -C ../submodules/riscv-arch-test verify
TARGETDIR=`pwd` WORK=`pwd`/work RISCV_TARGET=r5p XLEN=64 RISCV_DEVICE=C make -C ../submodules/riscv-arch-test verify
TARGETDIR=`pwd` WORK=`pwd`/work RISCV_TARGET=r5p XLEN=64 RISCV_DEVICE=M make -C ../submodules/riscv-arch-test verify

#TARGETDIR=`pwd` WORK=`pwd`/work RISCV_TARGET=r5p XLEN=64 RISCV_DEVICE=I RISCV_TEST=addi-01 make -C ../submodules/riscv-arch-test verify

################################################################################
# RP64 - imperas
################################################################################

# first imperas simulator/test tarball must be extracted into the `submodules` folder
# this was tested with `riscv-ovpsim-plus-bitmanip-tests.v20210721.zip`

# to get an instruction trace for Imperas target
# (this was done in the Imperas extracted folder, so no make path or TARGET are specified)
XLEN=64 RISCV_DEVICE=I RISCV_TEST=ADD-01 RISCV_TARGET_FLAGS="--trace --tracechange" make verify
XLEN=64 RISCV_DEVICE=C RISCV_TEST=I-C-EBREAK-01 RISCV_TARGET_FLAGS="--trace --tracechange" make verify

# to get a reference trace with register changes


# to run a test from Imperas on "r5p"
TARGETDIR=`pwd` WORK=`pwd`/work RISCV_TARGET=r5p XLEN=64 RISCV_DEVICE=I make -C ../submodules/imperas-riscv-tests clean simulate verify
