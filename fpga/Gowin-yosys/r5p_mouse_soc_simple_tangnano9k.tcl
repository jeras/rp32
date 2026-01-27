# import yosys commands
yosys -import

puts "================================================================================"
puts "= parsing SystemVerilog using Yosys-Slang"
puts "================================================================================"

set PATH_TCB_RTL "../../submodules/tcb/hdl/rtl"
set PATH_R5P_RTL "../../hdl/rtl"

read_slang --top r5p_mouse_soc_simple_tangnano9k \
$PATH_R5P_RTL/mouse/r5p_mouse.sv \
$PATH_R5P_RTL/soc/r5p_mouse_soc_simple_top.sv \
$PATH_R5P_RTL/fpga/gowin/r5p_mouse_soc_simple_tangnano9k.sv

#hierarchy -top r5p_mouse_soc_simple_tangnano9k

write_verilog r5p_mouse_soc_simple_tangnano9k.slang.v

puts "================================================================================"
puts "= synthesis with Yosys/Apicula"
puts "================================================================================"

synth_gowin -json r5p_mouse_soc_simple_tangnano9k.json
