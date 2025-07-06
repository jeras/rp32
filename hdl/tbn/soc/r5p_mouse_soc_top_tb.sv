////////////////////////////////////////////////////////////////////////////////
// R5P mouse: testbench for SoC
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

module r5p_mouse_soc_top_tb #(
  // constants used across the design in signal range sizing instead of literals
  localparam int unsigned XLEN = 32,
  parameter  int unsigned GLEN = 32,
  // SoC peripherals
  parameter  bit          ENA_GPIO = 1'b1,
  parameter  bit          ENA_UART = 1'b0,
  // GPIO
  parameter  int unsigned GW = 32,

    // TCB bus
  parameter  bit [XLEN-1:0] IFU_RST = 32'h8000_0000,
  parameter  bit [XLEN-1:0] IFU_MSK = 32'h8000_3fff,
  parameter  bit [XLEN-1:0] GPR_ADR = 32'h8000_3f80,
  // TCB memory (size in bytes, file name)
  parameter  int unsigned   MEM_ADR = 14,
  parameter  int unsigned   MEM_SIZ = (XLEN/8)*(2**MEM_ADR),
  parameter  string         MEM_FNM = "mem_if.vmem",
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

  r5p_mouse_soc_top #(
    // SoC peripherals
    .ENA_GPIO (ENA_GPIO),
    .ENA_UART (ENA_UART),
    // GPIO
    .GW       (GW),
    // TCB bus
    .IFU_RST  (IFU_RST),
    .IFU_MSK  (IFU_MSK),
    .GPR_ADR  (GPR_ADR),
    // TCB memory (size in bytes, file name)
    .MEM_ADR  (MEM_ADR),
    .MEM_SIZ  (MEM_SIZ),
    .MEM_FNM  (MEM_FNM),
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
  
  typedef logic [XLEN-1:0] gpr_t [GLEN-1:0];

//  // TODO: this is not a bidirectional solution
//  gpr_t gpr;
//  assign gpr = dut.gen_default.mem.mem[(GPR_ADR-IFU_RST)/4:(GPR_ADR-IFU_RST)/4+32-1];

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
    .MEND          (IFU_RST+MEM_SIZ-1)
    // DEBUG parameters
//  .DEBUG_LOG     (DEBUG_LOG)
  ) stub (
    // system signals
    .clk     (clk),
    .rst     (rst),
    // registers
    .gpr     (gpr_t'(dut.gen_default.mem.mem[(GPR_ADR-IFU_RST)/4:(GPR_ADR-IFU_RST)/4+32-1])),
    .pc      (dut.cpu.ctl_pcr),
    // memories
    .mem     (dut.gen_default.mem.mem),
    // IFU interface (instruction fetch unit)
    .ifu_trn (dut.tcb_cpu.trn),
    .ifu_adr (dut.tcb_cpu.req.adr),
    // LSU interface (load/store unit)
    .lsu_trn (dut.tcb_cpu.trn),
    .lsu_wen (dut.tcb_cpu.req.wen),
    .lsu_adr (dut.tcb_cpu.req.adr),
    .lsu_siz (dut.tcb_cpu.req.siz)
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

endmodule: r5p_mouse_soc_top_tb
