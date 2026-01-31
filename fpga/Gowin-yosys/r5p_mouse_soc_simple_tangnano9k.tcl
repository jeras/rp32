# import yosys commands
yosys -import

puts "================================================================================"
puts "= parsing SystemVerilog using Yosys-Slang"
puts "================================================================================"

# TODO: can PRJ be inherited from the shell script?
set PRJ "r5p_mouse_soc_simple_tangnano9k"

set PATH_TCB_RTL "../../submodules/tcb/hdl/rtl"
set PATH_R5P_RTL "../../hdl/rtl"

read_slang --top $PRJ -D YOSYS_SLANG \
$PATH_TCB_RTL/tcb_lite_pkg.sv \
$PATH_TCB_RTL/tcb_lite_if.sv \
$PATH_R5P_RTL/mouse/r5p_mouse.sv \
$PATH_R5P_RTL/soc/r5p_mouse_soc_simple_top.sv \
$PATH_R5P_RTL/fpga/gowin/r5p_mouse_soc_simple_tangnano9k.sv

#hierarchy -top $PRJ

write_verilog $PRJ.slang.v

puts "================================================================================"
puts "= synthesis with Yosys/Apicula"
puts "================================================================================"

synth_gowin -json $PRJ.json
