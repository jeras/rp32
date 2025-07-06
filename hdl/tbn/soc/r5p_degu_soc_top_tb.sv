////////////////////////////////////////////////////////////////////////////////
// R5P degu: testbench for SoC
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

module r5p_degu_soc_top_tb #(
  // constants used across the design in signal range sizing instead of literals
  localparam int unsigned XLEN = 32,
  // SoC peripherals
  parameter  bit          ENA_GPIO = 1'b1,
  parameter  bit          ENA_UART = 1'b0,
  // GPIO
  parameter  int unsigned GW = 32,

  // IFU bus
  parameter  bit [XLEN-1:0] IFU_RST = 32'h8000_0000,
  parameter  bit [XLEN-1:0] IFU_MSK = 32'h8000_3fff,
  // IFU memory (size in bytes, file name)
  parameter  int unsigned   IFM_ADR = 14,
  parameter  int unsigned   IFM_SIZ = (XLEN/8)*(2**IFM_ADR),
  parameter  string         IFM_FNM = "mem_if.vmem",
  // LSU bus
  parameter  bit [XLEN-1:0] LSU_MSK = 32'h8000_7fff,
  // LSU memory (size)
  parameter  int unsigned   LSM_ADR = 14,
  parameter  int unsigned   LSM_SIZ = (XLEN/8)*(2**LSM_ADR),
  // implementation device (ASIC/FPGA vendor/device)
  string CHIP = ""
);

  // system signals
  logic clk;  // clock
  logic rst;  // reset

  // GPIO
  wire logic [GW-1:0] gpio_o;  // output
  wire logic [GW-1:0] gpio_e;  // enable
  wire logic [GW-1:0] gpio_i;  // input

  // UART
  wire logic          uart_txd;
  wire logic          uart_rxd;

////////////////////////////////////////////////////////////////////////////////
// RTL DUT instance
////////////////////////////////////////////////////////////////////////////////

  r5p_degu_soc_top #(
    // SoC peripherals
    .ENA_GPIO (ENA_GPIO),
    .ENA_UART (ENA_UART),
    // GPIO
    .GW       (GW),
    // implementation device (ASIC/FPGA vendor/device)
    .CHIP     (CHIP)
  ) dut (
    // system signals
    .clk      (clk),
    .rst      (rst),
    // GPIO
    .gpio_o   (gpio_o),
    .gpio_e   (gpio_e),
    .gpio_i   (gpio_i),
    // UART
    .uart_rxd (uart_txd),
    .uart_txd (uart_rxd)
  );

  // UART loopback
  assign uart_rxd = uart_txd;

  // GPIO loopback
  generate
  for (genvar i=0; i<GW; i++) begin: gpio_loopback
    assign gpio_i[i] = gpio_e[i] ? gpio_o[i] : 1'bz;
  end: gpio_loopback
  endgenerate  

////////////////////////////////////////////////////////////////////////////////
// GDB stub instance
////////////////////////////////////////////////////////////////////////////////

  gdb_server_stub #(
    // 8/16/32/64 bit CPU selection
    .XLEN          (32),
    .SIZE_T        (int unsigned),
    // Unix/TCP socket
    .SOCKET        ("gdb_server_stub_socket"),
    // XML target description
//  .XML_TARGET    (XML_TARGET),
    // registers
//  .GLEN          (GLEN),
//  .XML_REGISTERS (XML_REGISTERS),
    // memory
//  .XML_MEMORY    (XML_MEMORY),
    .MLEN          (32),
    .MBGN          (IFU_RST),
    .MEND          (IFU_RST+IFM_SIZ-1)
    // DEBUG parameters
//  .DEBUG_LOG     (DEBUG_LOG)
  ) stub (
    // system signals
    .clk     (clk),
    .rst     (rst),
    // registers
    .gpr     (dut.cpu.gpr.gen_default.gpr),
    .pc      (dut.cpu.ifu_pc),
    // memories
    .mem     (dut.gen_default.imem.mem),
    // IFU interface (instruction fetch unit)
    .ifu_trn (dut.tcb_ifu.trn),
    .ifu_adr (dut.tcb_ifu.req.adr),
    // LSU interface (load/store unit)
    .lsu_trn (dut.tcb_lsu.trn),
    .lsu_wen (dut.tcb_lsu.req.wen),
    .lsu_adr (dut.tcb_lsu.req.adr),
    .lsu_siz (dut.tcb_lsu.req.siz)
  );

////////////////////////////////////////////////////////////////////////////////
// test sequence
////////////////////////////////////////////////////////////////////////////////

  // 2*25ns=50ns period is 20MHz frequency
  initial      clk = 1'b1;
  always #25ns clk = ~clk;

  initial
  begin
    repeat (64) @(posedge clk);
    $finish();
  end

endmodule: r5p_degu_soc_top_tb
