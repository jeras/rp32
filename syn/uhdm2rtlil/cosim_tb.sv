// ============================================================================
// Gate-level co-simulation testbench for the r5p_mouse simple SoC.
//
// Instantiates the original RTL (`r5p_mouse_soc_simple_top`) and the
// uhdm2rtlil-synthesized gate netlist (`r5p_mouse_soc_simple_top_gate`) side by
// side, drives them with the same clock/reset/inputs, and raises `mismatch`
// whenever any observable output differs.  Both run the same boot program from
// memory, so the comparison is fully deterministic.
// ============================================================================
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

  r5p_mouse_soc_simple_top dut_rtl (
    .clk (clk), .rst (rst),
    .gpio_o (r_gpio_o), .gpio_e (r_gpio_e), .gpio_i (gpio_i),
    .uart_txd (r_uart_txd), .uart_rxd (uart_rxd)
  );

  r5p_mouse_soc_simple_top_gate dut_gate (
    .clk (clk), .rst (rst),
    .gpio_o (g_gpio_o), .gpio_e (g_gpio_e), .gpio_i (gpio_i),
    .uart_txd (g_uart_txd), .uart_rxd (uart_rxd)
  );

  always_comb
    mismatch = (r_gpio_o !== g_gpio_o)
            || (r_gpio_e !== g_gpio_e)
            || (r_uart_txd !== g_uart_txd);
endmodule
