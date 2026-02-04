#! /bin/bash

PRJ=r5p_mouse_soc_simple_tangnano9k

# using Yosys
PATH_R5P_RTL=../../hdl/rtl
yosys --logfile ${PRJ}.syn.log -D YOSYS_STRINGPARAM --commands "synth_gowin -top ${PRJ} -json ${PRJ}.json" \
$PATH_R5P_RTL/mouse/r5p_mouse.sv \
$PATH_R5P_RTL/soc/r5p_mouse_soc_simple_top.sv \
$PATH_R5P_RTL/fpga/gowin/r5p_mouse_soc_simple_tangnano9k.sv

# # using Yosys-Slang
# yosys --plugin slang --logfile ${PRJ}.syn.log --tcl-scriptfile ${PRJ}.tcl

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
