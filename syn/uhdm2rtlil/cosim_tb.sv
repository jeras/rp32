// ============================================================================
// Gate-level co-simulation testbench for the r5p_mouse SoCs.
//
// Instantiates the original RTL (`TOP_RTL`) and the uhdm2rtlil-synthesized gate
// netlist (`TOP_GATE`) side by side, drives them with the same
// clock/reset/inputs, and raises `mismatch` whenever any observable output
// differs.  Both run the same boot program from memory, so the comparison is
// fully deterministic.
//
// The two module names are supplied by cosim.sh via +define+ so the SAME
// testbench serves both the discrete `mouse_soc_simple` and the TCB-interface
// `mouse_soc` (their top-level ports are identical).  Defaults keep the file
// usable standalone for the simple SoC.
// ============================================================================
`ifndef TOP_RTL
  `define TOP_RTL  r5p_mouse_soc_simple_top
`endif
`ifndef TOP_GATE
  `define TOP_GATE r5p_mouse_soc_simple_top_gate
`endif

module tb (
  input  logic        clk,
  input  logic        rst,
  input  logic [31:0] gpio_i,
  input  logic        uart_rxd,
  output logic        mismatch
);
  // RTL reference outputs
  logic [31:0] r_gpio_o, r_gpio_e;
  logic        r_uart_txd;
  // gate-level netlist outputs
  logic [31:0] g_gpio_o, g_gpio_e;
  logic        g_uart_txd;

  `TOP_RTL dut_rtl (
    .clk (clk), .rst (rst),
    .gpio_o (r_gpio_o), .gpio_e (r_gpio_e), .gpio_i (gpio_i),
    .uart_txd (r_uart_txd), .uart_rxd (uart_rxd)
  );

  `TOP_GATE dut_gate (
    .clk (clk), .rst (rst),
    .gpio_o (g_gpio_o), .gpio_e (g_gpio_e), .gpio_i (gpio_i),
    .uart_txd (g_uart_txd), .uart_rxd (uart_rxd)
  );

  always_comb
    mismatch = (r_gpio_o !== g_gpio_o)
            || (r_gpio_e !== g_gpio_e)
            || (r_uart_txd !== g_uart_txd);
endmodule
