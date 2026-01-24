# import yosys commands
yosys -import

puts "================================================================================"
puts "= parsing SystemVerilog using Yosys-Slang"
puts "================================================================================"

set PATH_TCB_RTL "../../submodules/tcb/hdl/rtl"
set PATH_CPU_RTL "../../hdl/rtl"

read_slang --top r5p_degu_soc_tangnano9k \
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
$PATH_CPU_RTL/riscv/riscv_isa_pkg.sv \
$PATH_CPU_RTL/riscv/riscv_priv_pkg.sv \
$PATH_CPU_RTL/riscv/riscv_isa_i_pkg.sv \
$PATH_CPU_RTL/riscv/riscv_isa_c_pkg.sv \
$PATH_CPU_RTL/riscv/rv32_csr_pkg.sv \
$PATH_CPU_RTL/riscv/rv64_csr_pkg.sv \
$PATH_CPU_RTL/core/r5p_gpr_2r1w.sv \
$PATH_CPU_RTL/degu/r5p_pkg.sv \
$PATH_CPU_RTL/degu/r5p_bru.sv \
$PATH_CPU_RTL/degu/r5p_alu.sv \
$PATH_CPU_RTL/degu/r5p_mdu.sv \
$PATH_CPU_RTL/degu/r5p_lsu.sv \
$PATH_CPU_RTL/degu/r5p_wbu.sv \
$PATH_CPU_RTL/degu/r5p_degu_pkg.sv \
$PATH_CPU_RTL/degu/r5p_degu.sv \
$PATH_CPU_RTL/soc/r5p_soc_memory_gowin_inference.sv \
$PATH_CPU_RTL/soc/r5p_degu_soc_top.sv \
$PATH_CPU_RTL/fpga/gowin/r5p_degu_soc_tangnano9k.sv

#hierarchy -top r5p_degu_soc_tangnano9k

puts "================================================================================"
puts "= synthesis with Yosys/Apicula"
puts "================================================================================"

synth_gowin -json r5p_degu_soc_tangnano9k.json
