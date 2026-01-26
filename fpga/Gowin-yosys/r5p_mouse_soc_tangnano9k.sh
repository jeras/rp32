#! /bin/bash

PRJ=r5p_mouse_soc_tangnano9k

# using Yosys
#yosys ${PRJ}.tcl

# using Yosys-Slang
yosys --plugin slang --logfile ${PRJ}.syn.log ${PRJ}.tcl

#netlistsvg ${PRJ}.json -o ${PRJ}.svg

echo "================================================================================"
echo "= P&R"
echo "================================================================================"

nextpnr-himbaechel --json   ${PRJ}.json \
                   --device 'GW1NR-LV9QN88PC6/I5' \
                   --vopt   family='GW1N-9C' \
                   --vopt   cst=tangnano9k.cst \
                   --sdc    ${PRJ}.sdc \
                   --write  ${PRJ}.pnr.json \
                   --log    ${PRJ}.pnr.log

echo "================================================================================"
echo "= pack"
echo "================================================================================"

gowin_pack -d GW1N-9C -o ${PRJ}.fs ${PRJ}.pnr.json
# gowin_unpack -d $DEVICE -o ${PRJ}_unpack.v ${PRJ}.fs
# yosys -p "read_verilog -lib +/gowin/cells_sim.v; clean -purge; show" ${PRJ}_unpack.v

echo "================================================================================"
echo "= load"
echo "================================================================================"

#openFPGALoader -b tangnano9k ${PRJ}.fs
