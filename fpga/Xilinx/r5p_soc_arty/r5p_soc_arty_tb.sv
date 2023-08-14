////////////////////////////////////////////////////////////////////////////////
// R5P: testbench for SoC
////////////////////////////////////////////////////////////////////////////////
// Copyright 2022 Iztok Jeras
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
///////////////////////////////////////////////////////////////////////////////

module r5p_soc_arty_tb #(
  // implementation device (ASIC/FPGA vendor/device)
  string CHIP = "ARTIX_GEN"
);

// system signals
logic clk;    // clock
logic rst_n;  // reset (active low)

// GPIO
wire  [42-1:0] ck_io;
wire           uart_rxd;
wire           uart_txd;

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

r5p_degu_soc_arty #(
  .CHIP         (CHIP)
) DUT (
  // system signals
  .CLK100MHZ    (clk),
  .ck_rst       (rst_n),
  // GPIO
  .ck_io        (ck_io),
  // UART
  .uart_rxd_out (uart_txd),
  .uart_txd_in  (uart_rxd)
);

// UART loopback
assign uart_rxd = uart_txd;

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