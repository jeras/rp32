////////////////////////////////////////////////////////////////////////////////
// R5P: SoC for Arty development board
//
// NOTE: details on XPM libraries: ug953-vivado-7series-libraries.pdf
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

module r5p_degu_soc_arty #(
  // implementation device (ASIC/FPGA vendor/device)
  parameter  string CHIP = "ARTIX_GEN"
)(
  // system signals
  input  logic          CLK100MHZ,  // clock
  input  logic          ck_rst,     // reset (active low)
  // GPIO
  inout  wire  [42-1:0] ck_io,
  // UART
  output wire           uart_rxd_out,
  input  wire           uart_txd_in
);

///////////////////////////////////////////////////////////////////////////////
// local parameters
////////////////////////////////////////////////////////////////////////////////

localparam int unsigned GW = 32;

///////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

// clock
logic clk;

// reset synchronizer
logic rst;

// GPIO
logic [GW-1:0] gpio_o;
logic [GW-1:0] gpio_e;
logic [GW-1:0] gpio_i;

///////////////////////////////////////////////////////////////////////////////
// PLL
////////////////////////////////////////////////////////////////////////////////

// TODO: use proper PLL
assign clk = CLK100MHZ;

///////////////////////////////////////////////////////////////////////////////
// reset synchronizer
////////////////////////////////////////////////////////////////////////////////

//logic rst_r;

//always @(posedge clk, negedge ck_rst)
//if (~ck_rst)  {rst, rst_r} <= 2'b1;
//else          {rst, rst_r} <= {rst_r, 1'b0};

// xpm_cdc_async_rst: Asynchronous Reset Synchronizer
// Xilinx Parameterized Macro, version 2023.1
xpm_cdc_async_rst #(
 .DEST_SYNC_FF    (4), // DECIMAL; range: 2-10
 .INIT_SYNC_FF    (0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
 .RST_ACTIVE_HIGH (1)  // DECIMAL; 0=active low reset, 1=active high reset
) xpm_cdc_async_rst_inst (
  .src_arst  (~ck_rst),
  .dest_arst (rst),
  .dest_clk  (clk)
);

////////////////////////////////////////////////////////////////////////////////
// R5P SoC instance
////////////////////////////////////////////////////////////////////////////////

r5p_degu_soc_top #(
  .GW        (GW),
  .CHIP      (CHIP)
) soc (
  // system signals
  .clk       (clk),
  .rst       (rst),
  // GPIO
  .gpio_o    (gpio_o),
  .gpio_e    (gpio_e),
  .gpio_i    (gpio_i),
  // UART
  .uart_txd  (uart_rxd_out),
  .uart_rxd  (uart_txd_in )
);

////////////////////////////////////////////////////////////////////////////////
// GPIO
////////////////////////////////////////////////////////////////////////////////

// GPIO inputs
assign gpio_i = ck_io[GW-1:0];

// GPIO outputs
generate
for (genvar i=0; i<GW; i++) begin
  assign ck_io[i] = gpio_e[i] ? gpio_o[i] : 1'bz;
end
endgenerate

// unused IO
assign ck_io[42-1:GW] = 1'bz;

endmodule: r5p_degu_soc_arty
