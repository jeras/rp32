#!/bin/bash

#export PATH=/home/ijeras/VLSI/lowrisc-toolchain-gcc-rv32imc-20210412-1/bin/:$PATH
export PATH=/home/ijeras/VLSI/lowrisc-toolchain-gcc-rv64imac-20210412-1/bin/:$PATH

source ../sim/settings.sh

#TARGETDIR=`pwd` RISCV_TARGET=r5p WORK=`pwd`/work make -C ../submodules/riscv-arch-test clean
TARGETDIR=`pwd` RISCV_TARGET=r5p WORK=`pwd`/work make -C ../submodules/riscv-arch-test compile

TARGETDIR=`pwd` WORK=`pwd`/work RISCV_TARGET=r5p RISCV_DEVICE=M RISCV_TEST=mulhsu-01 XLEN=64 make -C ../submodules/riscv-arch-test verify
