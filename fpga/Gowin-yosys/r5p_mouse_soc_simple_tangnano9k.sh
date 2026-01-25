#! /bin/bash

# using Yosys
#yosys r5p_mouse_soc_simple_tangnano9k.tcl

# using Yosys-Slang
yosys -m slang r5p_mouse_soc_simple_tangnano9k_slang.tcl

#netlistsvg r5p_mouse_soc_simple_tangnano9k.json -o r5p_mouse_soc_simple_tangnano9k.svg

echo "================================================================================"
echo "= P&R"
echo "================================================================================"

nextpnr-himbaechel --json r5p_mouse_soc_simple_tangnano9k.json \
                   --write r5p_mouse_soc_simple_tangnano9k.pnr.json \
                   --device 'GW1NR-LV9QN88PC6/I5' \
                   --vopt family='GW1N-9C' \
                   --vopt cst=tangnano9k.cst

echo "================================================================================"
echo "= pack"
echo "================================================================================"

gowin_pack -d GW1N-9C -o r5p_mouse_soc_simple_tangnano9k.fs r5p_mouse_soc_simple_tangnano9k.pnr.json
# gowin_unpack -d $DEVICE -o r5p_mouse_soc_simple_tangnano9k_unpack.v r5p_mouse_soc_simple_tangnano9k.fs
# yosys -p "read_verilog -lib +/gowin/cells_sim.v; clean -purge; show" r5p_mouse_soc_simple_tangnano9k_unpack.v

echo "================================================================================"
echo "= load"
echo "================================================================================"

#openFPGALoader -b tangnano9k r5p_mouse_soc_simple_tangnano9k.fs

