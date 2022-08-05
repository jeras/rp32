# 
# Run this script as:
# yosys -s build.tcl
#

plugin -i systemverilog

# SystemVerilog RTL
read_systemverilog \
-top r5p_wbu \
-parse \
../../../hdl/rtl/riscv/riscv_isa_pkg.sv \
../../../hdl/rtl/riscv/riscv_isa_c_pkg.sv \
../../../hdl/rtl/core/r5p_bru.sv \
../../../hdl/rtl/core/r5p_gpr.sv \
../../../hdl/rtl/core/r5p_alu.sv \
../../../hdl/rtl/core/r5p_lsu.sv \
../../../hdl/rtl/core/r5p_wbu.sv \
../../../hdl/rtl/core/r5p_core.sv \

synth_xilinx -top r5p_wbu -edif top.edif

#hierarchy -top r5p_core

#write_ilang

#proc
#opt

#show -format ps #dot -viewer xdot

#techmap; opt

# SoC files

