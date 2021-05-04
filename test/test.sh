#!/bin/sh

export PATH=/home/ijeras/VLSI/lowrisc-toolchain-gcc-rv32imc-20210412-1/bin/:$PATH

TARGETDIR=`pwd` RISCV_TARGET=r5p WORK=`pwd`/work make -C ../submodules/riscv-arch-test clean
TARGETDIR=`pwd` RISCV_TARGET=r5p WORK=`pwd`/work make -C ../submodules/riscv-arch-test compile
