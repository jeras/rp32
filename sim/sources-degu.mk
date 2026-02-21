################################################################################
# HDL source files
################################################################################

# TCB files
PATH_TCB=../../submodules/tcb/hdl

# SystemVerilog RTL
RTL+=${PATH_TCB}/rtl/tcb_lite_pkg.sv
RTL+=${PATH_TCB}/rtl/tcb_lite_if.sv
RTL+=${PATH_TCB}/rtl/lite_lib/tcb_lite_lib_passthrough.sv
RTL+=${PATH_TCB}/rtl/lite_lib/tcb_lite_lib_logsize2byteena.sv
RTL+=${PATH_TCB}/rtl/lite_lib/tcb_lite_lib_arbiter.sv
RTL+=${PATH_TCB}/rtl/lite_lib/tcb_lite_lib_multiplexer.sv
RTL+=${PATH_TCB}/rtl/lite_lib/tcb_lite_lib_decoder.sv
RTL+=${PATH_TCB}/rtl/lite_lib/tcb_lite_lib_demultiplexer.sv
RTL+=${PATH_TCB}/rtl/lite_lib/tcb_lite_lib_register_request.sv
RTL+=${PATH_TCB}/rtl/lite_lib/tcb_lite_lib_error.sv
RTL+=${PATH_TCB}/rtl/peri/gpio/tcb_peri_gpio_cdc_generic.sv
RTL+=${PATH_TCB}/rtl/peri/gpio/tcb_peri_gpio.sv
RTL+=${PATH_TCB}/rtl/lite_peri/gpio/tcb_lite_peri_gpio.sv
RTL+=${PATH_TCB}/rtl/peri/uart/tcb_peri_uart_ser.sv
RTL+=${PATH_TCB}/rtl/peri/uart/tcb_peri_uart_des.sv
RTL+=${PATH_TCB}/rtl/peri/uart/tcb_peri_uart_fifo.sv
RTL+=${PATH_TCB}/rtl/peri/uart/tcb_peri_uart.sv
RTL+=${PATH_TCB}/rtl/lite_peri/uart/tcb_lite_peri_uart.sv

# SystemVerilog bench (Test SV)
TSV+=${PATH_TCB}/tbn/lite_vip/tcb_lite_vip_memory.sv
TSV+=${PATH_TCB}/tbn/lite_vip/tcb_lite_vip_protocol_checker.sv

# HDLDB files
PATH_GDB=../../submodules/hdldb/hdl

# SystemVerilog bench (Test SV)
#TSV+=${PATH_GDB}/hdldb_trace_pkg.sv

# R5P files
PATH_R5P=../../hdl

# SystemVerilog RTL
RTL+=${PATH_R5P}/rtl/riscv/riscv_isa_pkg.sv
RTL+=${PATH_R5P}/rtl/riscv/riscv_priv_pkg.sv
RTL+=${PATH_R5P}/rtl/riscv/riscv_isa_i_pkg.sv
RTL+=${PATH_R5P}/rtl/riscv/riscv_isa_c_pkg.sv
RTL+=${PATH_R5P}/rtl/riscv/rv32_csr_pkg.sv
RTL+=${PATH_R5P}/rtl/riscv/rv64_csr_pkg.sv
RTL+=${PATH_R5P}/rtl/core/r5p_gpr_2r1w.sv
RTL+=${PATH_R5P}/rtl/degu/r5p_pkg.sv
RTL+=${PATH_R5P}/rtl/degu/r5p_bru.sv
RTL+=${PATH_R5P}/rtl/degu/r5p_alu.sv
RTL+=${PATH_R5P}/rtl/degu/r5p_mdu.sv
#RTL+=${PATH_R5P}/rtl/degu/r5p_fpu.sv
RTL+=${PATH_R5P}/rtl/degu/r5p_lsu.sv
RTL+=${PATH_R5P}/rtl/degu/r5p_wbu.sv
#RTL+=${PATH_R5P}/rtl/riscv_csr_adr_map_pkg.sv
#RTL+=${PATH_R5P}/rtl/degu/r5p32_csr_pkg.sv
#RTL+=${PATH_R5P}/rtl/degu/r5p64_csr_pkg.sv
#RTL+=${PATH_R5P}/rtl/degu/r5p_csr.sv
RTL+=${PATH_R5P}/rtl/degu/r5p_degu_pkg.sv
RTL+=${PATH_R5P}/rtl/degu/r5p_degu.sv

# SoC files
#RTL+=${PATH_R5P}/rtl/soc/r5p_soc_memory.sv
RTL+=${PATH_R5P}/rtl/soc/r5p_soc_memory__gowin_inference.sv
RTL+=${PATH_R5P}/rtl/soc/r5p_degu_soc_top.sv
RTL+=${PATH_R5P}/rtl/fpga/gowin/r5p_degu_soc_tangnano9k.sv

# SystemVerilog RISCOF bench (Test SV)
TSV+=${PATH_R5P}/tbn/riscv/riscv_asm_pkg.sv
TSV+=${PATH_R5P}/tbn/riscv/trace_generic_pkg.sv
TSV+=${PATH_R5P}/tbn/riscof/trace_spike_pkg.sv
TSV+=${PATH_R5P}/tbn/riscof/trace_sail_pkg.sv
TSV+=${PATH_R5P}/tbn/soc/r5p_degu_trace.sv
TSV+=${PATH_R5P}/tbn/htif/r5p_htif.sv
TSV+=${PATH_R5P}/tbn/riscof/r5p_degu_riscof_tb.sv

# SystemVerilog SoC bench (Test SV)
TSV+=${PATH_R5P}/tbn/soc/r5p_degu_soc_top_tb.sv
TSV+=${PATH_R5P}/tbn/fpga/gowin/r5p_degu_soc_tangnano9k_tb.sv


# combined HDL sources
HDL =${RTL}
HDL+=${TSV}
