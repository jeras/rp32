# 
# Run this script as:
# yosys -s build.tcl
#

plugin -i systemverilog

# SystemVerilog RTL
read_systemverilog \
+define+LANGUAGE_UNSUPPORTED_UNION \
+define+LANGUAGE_UNSUPPORTED_STREAM_OPERATOR \
+define+LANGUAGE_UNSUPPORTED_INTERFACE_ARRAY_PORT \
-top r5p_core \
-parse \
../../../hdl/rtl/riscv/riscv_isa_pkg.sv \
../../../hdl/rtl/riscv/riscv_isa_c_pkg.sv \
../../../hdl/rtl/degu/r5p_bru.sv \
../../../hdl/rtl/degu/r5p_gpr.sv \
../../../hdl/rtl/degu/r5p_alu.sv \
../../../hdl/rtl/degu/r5p_lsu.sv \
../../../hdl/rtl/degu/r5p_wbu.sv \
../../../hdl/rtl/degu/r5p_degu_core.sv \

synth_xilinx -top r5p_core -edif top.edif

#hierarchy -top r5p_core

#write_ilang

#proc
#opt

#show -format ps #dot -viewer xdot

#techmap; opt

# SoC files

