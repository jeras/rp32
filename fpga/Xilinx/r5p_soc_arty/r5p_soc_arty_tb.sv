////////////////////////////////////////////////////////////////////////////////
// R5P testbench for core module
////////////////////////////////////////////////////////////////////////////////

module r5p_soc_arty_tb #(
  // implementation device (ASIC/FPGA vendor/device)
  string CHIP = "ARTIX_XPM"
);

// system signals
logic clk;    // clock
logic rst_n;  // reset (active low)

// GPIO
wire  [42-1:0] ck_io;

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

r5p_soc_arty #(
  .CHIP    (CHIP)
) DUT (
  // system signals
  .CLK100MHZ (clk),
  .ck_rst    (rst_n),
  // GPIO
  .ck_io     (ck_io)
);

////////////////////////////////////////////////////////////////////////////////
// test sequence
////////////////////////////////////////////////////////////////////////////////

initial clk = 1'b1;
always #25ns clk = ~clk;

initial
begin
  rst_n = 1'b0;
  repeat (4) @(posedge clk);
  rst_n = 1'b1;
  repeat (64) @(posedge clk);
  $finish();
end

endmodule: r5p_soc_arty_tb