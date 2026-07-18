# ============================================================================
# rp32 design catalog for the uhdm2rtlil Yosys flow.
#
# Sourced by build.sh / run.sh.  `design_select <name>` sets:
#   TOP   top module name
#   SRCS  space-separated, dependency-ordered source list (absolute paths)
#   COSIM "yes" if a deterministic gate-level co-simulation is wired up
#
# Requires R5P_RTL (abs path to hdl/rtl) and R5P_TCB (abs path to the TCB RTL,
# submodules/tcb/hdl/rtl) to be exported by the caller.
# ============================================================================

# RISC-V ISA packages shared by the hierarchical cores.
_riscv_pkgs() {
    echo "$R5P_RTL/riscv/riscv_isa_pkg.sv \
          $R5P_RTL/riscv/riscv_priv_pkg.sv \
          $R5P_RTL/riscv/riscv_isa_i_pkg.sv \
          $R5P_RTL/riscv/riscv_isa_c_pkg.sv \
          $R5P_RTL/riscv/rv32_csr_pkg.sv \
          $R5P_RTL/riscv/rv64_csr_pkg.sv"
}

# degu core sources (packages + submodules + core), dependency-ordered.
_degu_core() {
    echo "$R5P_TCB/tcb_lite_pkg.sv $R5P_TCB/tcb_lite_if.sv \
          $(_riscv_pkgs) \
          $R5P_RTL/degu/r5p_pkg.sv $R5P_RTL/degu/r5p_degu_pkg.sv \
          $R5P_RTL/core/r5p_gpr_2r1w.sv \
          $R5P_RTL/degu/r5p_bru.sv $R5P_RTL/degu/r5p_alu.sv \
          $R5P_RTL/degu/r5p_mdu.sv $R5P_RTL/degu/r5p_lsu.sv \
          $R5P_RTL/degu/r5p_wbu.sv $R5P_RTL/degu/r5p_degu.sv"
}

# TCB "lite" peripheral library + devices used by the full SoCs.
_tcb_soc_lib() {
    echo "$R5P_TCB/lite_lib/tcb_lite_lib_error.sv \
          $R5P_TCB/lite_lib/tcb_lite_lib_passthrough.sv \
          $R5P_TCB/lite_lib/tcb_lite_lib_register_request.sv \
          $R5P_TCB/lite_lib/tcb_lite_lib_register_response.sv \
          $R5P_TCB/lite_lib/tcb_lite_lib_register_backpressure.sv \
          $R5P_TCB/lite_lib/tcb_lite_lib_arbiter.sv \
          $R5P_TCB/lite_lib/tcb_lite_lib_multiplexer.sv \
          $R5P_TCB/lite_lib/tcb_lite_lib_decoder.sv \
          $R5P_TCB/lite_lib/tcb_lite_lib_demultiplexer.sv \
          $R5P_TCB/lite_lib/tcb_lite_lib_logsize2byteena.sv \
          $R5P_TCB/dev/gpio/tcb_dev_gpio_cdc__generic.sv \
          $R5P_TCB/dev/gpio/tcb_dev_gpio.sv \
          $R5P_TCB/lite_dev/gpio/tcb_lite_dev_gpio.sv \
          $R5P_TCB/dev/uart/tcb_dev_uart_ser.sv \
          $R5P_TCB/dev/uart/tcb_dev_uart_des.sv \
          $R5P_TCB/dev/uart/tcb_dev_uart_fifo.sv \
          $R5P_TCB/dev/uart/tcb_dev_uart.sv \
          $R5P_TCB/lite_dev/uart/tcb_lite_dev_uart.sv"
}

# List all known design names.
design_list() {
    echo "mouse hamster degu mouse_soc_simple mouse_soc degu_soc"
}

design_select() {
    COSIM="no"
    case "$1" in
      # --- cores ---------------------------------------------------------
      mouse)
        TOP=r5p_mouse
        SRCS="$R5P_RTL/mouse/r5p_mouse.sv" ;;
      hamster)
        TOP=r5p_hamster
        SRCS="$(_riscv_pkgs) $R5P_RTL/core/r5p_gpr_1r1w.sv $R5P_RTL/hamster/r5p_hamster.sv" ;;
      degu)
        TOP=r5p_degu
        SRCS="$(_degu_core)" ;;
      # --- SoCs ----------------------------------------------------------
      mouse_soc_simple)
        TOP=r5p_mouse_soc_simple_top
        SRCS="$R5P_RTL/mouse/r5p_mouse.sv $R5P_RTL/soc/r5p_mouse_soc_simple_top.sv"
        COSIM="yes" ;;
      mouse_soc)
        TOP=r5p_mouse_soc_top
        SRCS="$R5P_TCB/tcb_lite_pkg.sv $R5P_TCB/tcb_lite_if.sv $(_tcb_soc_lib) \
              $R5P_RTL/mouse/r5p_mouse.sv $R5P_RTL/soc/r5p_soc_memory__gowin_inference.sv \
              $R5P_RTL/soc/r5p_mouse_soc_top.sv" ;;
      degu_soc)
        TOP=r5p_degu_soc_top
        SRCS="$R5P_TCB/tcb_lite_pkg.sv $R5P_TCB/tcb_lite_if.sv $(_tcb_soc_lib) \
              $(_riscv_pkgs) \
              $R5P_RTL/core/r5p_gpr_2r1w.sv \
              $R5P_RTL/degu/r5p_pkg.sv $R5P_RTL/degu/r5p_bru.sv \
              $R5P_RTL/degu/r5p_alu.sv $R5P_RTL/degu/r5p_mdu.sv \
              $R5P_RTL/degu/r5p_lsu.sv $R5P_RTL/degu/r5p_wbu.sv \
              $R5P_RTL/degu/r5p_degu_pkg.sv $R5P_RTL/degu/r5p_degu.sv \
              $R5P_RTL/soc/r5p_soc_memory__gowin_inference.sv $R5P_RTL/soc/r5p_degu_soc_top.sv" ;;
      *)
        echo "unknown design '$1'; known: $(design_list)" >&2
        return 1 ;;
    esac
}
