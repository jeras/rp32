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
  // memory
  parameter  int unsigned MEM_SIZ = 2**16,
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

  // IFU interface (instruction fetch unit)
  logic ifu_trn;  // transfer
  logic ifu_adr;  // address
  // LSU interface (load/store unit)
  logic lsu_trn;  // transfer
  logic lsu_adr;  // address
  logic lsu_wen;  // write enable

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
//    $finish();
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
  logic [8-1:0] mem [0:MEM_SIZ-1];

  always @(posedge clk, posedge rst)
  if (rst) begin
    pc <= 32'h8000_0000;
  end else begin
    pc <= pc+4;
//    $display("DBG: mem[%08h] = %p", pc, mem[pc[$clog2(MEM_SIZ):0]+:4]);
  end

  assign ifu_trn = ~rst;
  assign ifu_adr = pc;

///////////////////////////////////////////////////////////////////////////////
// debugger stub
///////////////////////////////////////////////////////////////////////////////

  riscv_gdb_stub #(
    .XLEN   (XLEN  ),
    .SIZE_T (SIZE_T),
    .SOCKET (SOCKET),
    // memories
    .MEM_SIZ (MEM_SIZ),
    // DEBUG parameters
    .DEBUG_LOG (DEBUG_LOG)
  ) stub (
    // system signals
    .clk     (clk),
//  .rst     (rst),
    // registers
    .gpr     (gpr),
    .pc      (pc ),
    // memories
    .mem     (mem),
    // IFU interface (instruction fetch unit)
    .ifu_trn (ifu_trn),
    .ifu_adr (ifu_adr),
    // LSU interface (load/store unit)
    .lsu_trn (lsu_trn),
    .lsu_adr (lsu_adr),
    .lsu_wen (lsu_wen)
  );

endmodule: riscv_gdb_stub_tb
