################################################################################
# HDL source files
################################################################################

# TCB files
PATH_TCB=../../submodules/tcb/hdl

# SystemVerilog RTL
RTL+=${PATH_TCB}/rtl/tcb_pkg.sv
RTL+=${PATH_TCB}/rtl/tcb_if.sv
RTL+=${PATH_TCB}/rtl/lib/tcb_lib_passthrough.sv
RTL+=${PATH_TCB}/rtl/lib/tcb_lib_logsize2byteena.sv
RTL+=${PATH_TCB}/rtl/lib/tcb_lib_arbiter.sv
RTL+=${PATH_TCB}/rtl/lib/tcb_lib_multiplexer.sv
RTL+=${PATH_TCB}/rtl/lib/tcb_lib_decoder.sv
RTL+=${PATH_TCB}/rtl/lib/tcb_lib_demultiplexer.sv
RTL+=${PATH_TCB}/rtl/lib/tcb_lib_register_request.sv
RTL+=${PATH_TCB}/rtl/lib/tcb_lib_error.sv
RTL+=${PATH_TCB}/rtl/peri/gpio/tcb_peri_gpio.sv
RTL+=${PATH_TCB}/rtl/peri/uart/tcb_peri_uart_ser.sv
RTL+=${PATH_TCB}/rtl/peri/uart/tcb_peri_uart_des.sv
RTL+=${PATH_TCB}/rtl/peri/uart/tcb_peri_uart_fifo.sv
RTL+=${PATH_TCB}/rtl/peri/uart/tcb_peri_uart.sv

# SystemVerilog bench (Test SV)
TSV+=${PATH_TCB}/tbn/vip/tcb_vip_memory.sv
TSV+=${PATH_TCB}/tbn/vip/tcb_vip_protocol_checker.sv

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
RTL+=${PATH_R5P}/rtl/mouse/r5p_mouse.sv

# SoC files
#RTL+=${PATH_R5P}/rtl/soc/tcb_dec_3sp.sv
RTL+=${PATH_R5P}/rtl/soc/r5p_soc_memory.sv
RTL+=${PATH_R5P}/rtl/soc/r5p_mouse_soc_top.sv

# SystemVerilog bench (Test SV)
TSV+=${PATH_R5P}/tbn/riscv/riscv_asm_pkg.sv
TSV+=${PATH_R5P}/tbn/soc/r5p_mouse_trace.sv
TSV+=${PATH_R5P}/tbn/soc/r5p_mouse_soc_top_tb.sv
TSV+=${PATH_R5P}/tbn/htif/r5p_htif.sv
TSV+=${PATH_R5P}/tbn/riscof/trace_spike_pkg.sv
TSV+=${PATH_R5P}/tbn/riscof/r5p_mouse_riscof_tb.sv

# combined HDL sources
HDL =${RTL}
HDL+=${TSV}
