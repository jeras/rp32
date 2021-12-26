#!/bin/sh

export GIT_TOPLEVEL=`git rev-parse --show-toplevel`
# build trivial application
make -C $GIT_TOPLEVEL/src/
cp -v $GIT_TOPLEVEL/src/mem_if.vmem $GIT_TOPLEVEL/sim/verilator
# run HDL simulation in Verilator
make -C $GIT_TOPLEVEL/sim/verilator -f Makefile XLEN=32 TOP=r5p_soc_top \
TSC=$GIT_TOPLEVEL/hdl/src/r5p_soc_tb.cpp
