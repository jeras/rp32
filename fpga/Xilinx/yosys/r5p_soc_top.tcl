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
+define+LANGUAGE_UNSUPPORTED_ARRAY_ASSIGNMENT_PATTERN \
-top r5p_soc_top \
-parse \
../../../hdl/rtl/riscv/riscv_isa_pkg.sv \
../../../hdl/rtl/riscv/riscv_priv_pkg.sv \
../../../hdl/rtl/riscv/riscv_isa_i_pkg.sv \
../../../hdl/rtl/riscv/riscv_isa_c_pkg.sv \
../../../hdl/rtl/degu/r5p_bru.sv \
../../../hdl/rtl/degu/r5p_gpr.sv \
../../../hdl/rtl/degu/r5p_alu.sv \
../../../hdl/rtl/degu/r5p_lsu.sv \
../../../hdl/rtl/degu/r5p_wbu.sv \
../../../hdl/rtl/degu/r5p_degu.sv \
../../../submodules/tcb/hdl/rtl/tcb_if.sv \
../../../submodules/tcb/hdl/rtl/tcb_err.sv \
../../../submodules/tcb/hdl/rtl/tcb_pas.sv \
../../../submodules/tcb/hdl/rtl/gpio/tcb_gpio.sv \
../../../submodules/tcb/hdl/rtl/uart/tcb_uart_ser.sv \
../../../submodules/tcb/hdl/rtl/uart/tcb_uart_des.sv \
../../../submodules/tcb/hdl/rtl/uart/tcb_uart_fifo.sv \
../../../submodules/tcb/hdl/rtl/uart/tcb_uart.sv \
../../../hdl/rtl/soc/tcb_dec_3sp.sv \
../../../hdl/rtl/soc/r5p_soc_mem.sv \
../../../hdl/rtl/soc/r5p_soc_top.sv \

synth_xilinx -top r5p_soc_top -edif top.edif

#hierarchy -top r5p_soc_top

#write_ilang

#proc
#opt

#show -format ps #dot -viewer xdot

#techmap; opt

# SoC files

