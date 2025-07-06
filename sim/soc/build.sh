#!/bin/sh

export GIT_TOPLEVEL=`git rev-parse --show-toplevel`
# build trivial application
#make -C $GIT_TOPLEVEL/src/
#cp -v $GIT_TOPLEVEL/src/mem_if.vmem $GIT_TOPLEVEL/sim/questa

# run HDL simulation in Verilator
make -C $GIT_TOPLEVEL/sim/questa -f Makefile DUT=degu TOP=r5p_degu_soc_top_tb
make -C $GIT_TOPLEVEL/sim/questa -f Makefile DUT=mouse TOP=r5p_mouse_soc_top_tb