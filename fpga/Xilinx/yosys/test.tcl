
plugin -i systemverilog

# SystemVerilog RTL
read_systemverilog -parse ../../../hdl/rtl/riscv/riscv_isa_pkg.sv
#read_systemverilog -parse ../../../hdl/rtl/core/r5p_pkg.sv
#read_systemverilog -parse ../../../hdl/rtl/core/r5p_bru.sv
#read_systemverilog -parse ../../../hdl/rtl/core/r5p_gpr.sv
#read_systemverilog -parse ../../../hdl/rtl/core/r5p_alu.sv
#read_systemverilog -parse ../../../hdl/rtl/core/r5p_mdu.sv
read_systemverilog -parse ../../../hdl/rtl/core/r5p_lsu.sv
#read_systemverilog -parse ../../../hdl/rtl/core/r5p_wbu.sv
#read_systemverilog -parse ../../../hdl/rtl/core/r5p_core.sv

# SoC files
#read_systemverilog -parse ../../../hdl/rtl/soc/r5p_bus_if.sv
#read_systemverilog -parse ../../../hdl/rtl/soc/r5p_bus_arb.sv
#read_systemverilog -parse ../../../hdl/rtl/soc/r5p_bus_dec.sv
#read_systemverilog -parse ../../../hdl/rtl/soc/r5p_soc_mem.sv
#read_systemverilog -parse ../../../hdl/rtl/soc/r5p_soc_gpio.sv
#read_systemverilog -parse ../../../hdl/rtl/soc/r5p_soc_top.sv

