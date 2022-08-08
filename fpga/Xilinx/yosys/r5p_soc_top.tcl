# 
# Run this script as:
# yosys -s build.tcl
#

plugin -i systemverilog

# SystemVerilog RTL
read_systemverilog \
-top r5p_soc_top \
-parse \
../../../hdl/rtl/riscv/riscv_isa_pkg.sv \
../../../hdl/rtl/riscv/riscv_isa_c_pkg.sv \
../../../hdl/rtl/core/r5p_bru.sv \
../../../hdl/rtl/core/r5p_gpr.sv \
../../../hdl/rtl/core/r5p_alu.sv \
../../../hdl/rtl/core/r5p_lsu.sv \
../../../hdl/rtl/core/r5p_wbu.sv \
../../../hdl/rtl/core/r5p_core.sv \
../../../submodules/tcb/hdl/rtl/tcb_if.sv \
../../../submodules/tcb/hdl/rtl/tcb_pas.sv \
../../../submodules/tcb/hdl/rtl/tcb_dec.sv \
../../../submodules/tcb/hdl/rtl/tcb_arb.sv \
../../../submodules/tcb/hdl/rtl/tcb_reg.sv \
../../../submodules/tcb/hdl/rtl/tcb_err.sv \
../../../submodules/tcb/hdl/rtl/gpio/tcb_gpio.sv \
../../../submodules/tcb/hdl/rtl/uart/tcb_uart_ser.sv \
../../../submodules/tcb/hdl/rtl/uart/tcb_uart_des.sv \
../../../submodules/tcb/hdl/rtl/uart/tcb_uart_fifo.sv \
../../../submodules/tcb/hdl/rtl/uart/tcb_uart.sv \
../../../hdl/rtl/soc/tcb_dec_3sp.sv \
../../../hdl/rtl/soc/r5p_soc_mem.sv \
../../../hdl/rtl/soc/r5p_soc_top.sv \

#synth_xilinx -top r5p_soc_top -edif top.edif

#hierarchy -top r5p_soc_top

#write_ilang

#proc
#opt

#show -format ps #dot -viewer xdot

#techmap; opt

# SoC files
