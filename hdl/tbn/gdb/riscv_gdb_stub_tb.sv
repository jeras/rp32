///////////////////////////////////////////////////////////////////////////////
// GDB stub testbench
//
// Copyright 2025 Iztok Jeras <iztok.jeras@gmail.com>
//
// Licensed under CERN-OHL-P v2 or later
///////////////////////////////////////////////////////////////////////////////

module riscv_gdb_stub_tb #(
  parameter  int unsigned XLEN = 32,
  parameter  type         SIZE_T = int unsigned,  // could be longint, but it results in warnings
  parameter  string       SOCKET = "gdb_stub_socket",
  // DEBUG parameters
  parameter  bit DEBUG_LOG = 1'b1
);

  import socket_dpi_pkg::*;

///////////////////////////////////////////////////////////////////////////////
// local signals
///////////////////////////////////////////////////////////////////////////////

  // system signals
  logic clk = 1'b1;  // clock
  logic rst = 1'b1;  // reset

///////////////////////////////////////////////////////////////////////////////
// main loop
///////////////////////////////////////////////////////////////////////////////

  // clock
  always #(20ns/2) clk = ~clk;

  // reset
  initial
  begin: process_reset
//    $display("io.status.name=%s", io.status().name());
    /* verilator lint_off INITIALDLY */
    repeat (4) @(posedge clk);
    // synchronous reset release
    rst <= 1'b0;
    repeat (1000) @(posedge clk);
    $display("ERROR: reached simulation timeout!");
    repeat (4) @(posedge clk);
    $finish();
    /* verilator lint_on INITIALDLY */
  end: process_reset
  
///////////////////////////////////////////////////////////////////////////////
// CPU DUT
///////////////////////////////////////////////////////////////////////////////

  // GPR
  logic [XLEN-1:0] gpr [0:32-1] = '{default: '0};
  // PC
  logic [XLEN-1:0] pc = '0;

  // memory
  logic [8-1:0] mem [0:2**16-1];

  // CPU debug interface
  logic dbg_req;  // request (behaves like VALID)
  logic dbg_grt;  // grant   (behaves like VALID)

  always @(posedge clk, posedge rst)
  if (rst) pc <= 0;
  else     pc <= pc+1;

///////////////////////////////////////////////////////////////////////////////
// debugger stub
///////////////////////////////////////////////////////////////////////////////

  riscv_gdb_stub #(
    .XLEN   (XLEN  ),
    .SIZE_T (SIZE_T),
    .SOCKET (SOCKET),
    // DEBUG parameters
    .DEBUG_LOG (DEBUG_LOG)
  ) stub (
    // system signals
    .clk  (clk),
//    .rst  (rst),
    // registers
    .gpr  (gpr),
    .pc   (pc ),
    // memories
    .mem  (mem),
    // CPU debug interface
    .dbg_req (dbg_req),
    .dbg_grt (dbg_grt)
  );

endmodule: riscv_gdb_stub_tb
