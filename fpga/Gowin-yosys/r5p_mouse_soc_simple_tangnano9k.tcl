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
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_error.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_passthrough.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_register_request.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_register_response.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_register_backpressure.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_arbiter.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_multiplexer.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_decoder.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_demultiplexer.sv \
$PATH_TCB_RTL/lite_lib/tcb_lite_lib_logsize2byteena.sv \
$PATH_TCB_RTL/peri/gpio/tcb_peri_gpio_cdc_generic.sv \
$PATH_TCB_RTL/peri/gpio/tcb_peri_gpio.sv \
$PATH_TCB_RTL/lite_peri/gpio/tcb_lite_peri_gpio.sv \
$PATH_TCB_RTL/peri/uart/tcb_peri_uart_ser.sv \
$PATH_TCB_RTL/peri/uart/tcb_peri_uart_des.sv \
$PATH_TCB_RTL/peri/uart/tcb_peri_uart_fifo.sv \
$PATH_TCB_RTL/peri/uart/tcb_peri_uart.sv \
$PATH_TCB_RTL/lite_peri/uart/tcb_lite_peri_uart.sv \
$PATH_R5P_RTL/mouse/r5p_mouse.sv \
$PATH_R5P_RTL/soc/r5p_soc_memory_gowin_inference.sv \
$PATH_R5P_RTL/soc/r5p_mouse_soc_simple_top.sv \
$PATH_R5P_RTL/fpga/gowin/r5p_mouse_soc_simple_tangnano9k.sv

#hierarchy -top $PRJ

write_verilog $PRJ.slang.v

puts "================================================================================"
puts "= synthesis with Yosys/Apicula"
puts "================================================================================"

synth_gowin -json $PRJ.json
