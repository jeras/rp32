
plugin -i systemverilog

#verilog_defines -DALTERA_RESERVED_QIS
#-top r5p_soc_top \

# SystemVerilog RTL
read_systemverilog \
+define+ALTERA_RESERVED_QIS \
-top r5p_core \
-parse \
../../../hdl/rtl/riscv/riscv_isa_pkg.sv \
../../../hdl/rtl/core/r5p_bru.sv \
../../../hdl/rtl/core/r5p_gpr.sv \
../../../hdl/rtl/core/r5p_alu.sv \
../../../hdl/rtl/core/r5p_lsu.sv \
../../../hdl/rtl/core/r5p_wbu.sv \
../../../hdl/rtl/core/r5p_core.sv \
../../../hdl/rtl/tcb/tcb_if.sv \
../../../hdl/rtl/soc/r5p_soc_gpio.sv \
../../../hdl/rtl/tcb/tcb_dec.sv \
../../../hdl/rtl/tcb/tcb_arb.sv \
../../../hdl/rtl/soc/r5p_soc_mem.sv \
../../../hdl/rtl/soc/r5p_soc_top.sv \

synth_xilinx -top r5p_core -edif top.edif

#hierarchy -top r5p_core

#write_ilang

#proc
#opt

#show -format ps #dot -viewer xdot

#techmap; opt

# SoC files

