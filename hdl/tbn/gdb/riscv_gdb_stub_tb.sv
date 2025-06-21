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
  parameter  string       PTS = "port_stub",
  // DEBUG parameters
  parameter  bit DEBUG_LOG = 1'b1
);

///////////////////////////////////////////////////////////////////////////////
// local signals
///////////////////////////////////////////////////////////////////////////////

  // system signals
  logic clk = 1'b1;  // clock
  logic rst = 1'b1;  // reset

  // byte dynamic array type for casting to/from string
  typedef byte array_t [];

  // named pipe file descriptor
  int fd;

  // GPR
  logic [XLEN-1:0] gpr [0:32-1] = '{default: '0};
  // PC
  logic [XLEN-1:0] pc = '0;

  // memory
  logic [8-1:0] mem [0:2**16-1];

///////////////////////////////////////////////////////////////////////////////
// main loop
///////////////////////////////////////////////////////////////////////////////

  // clock
  always #(20ns/2) clk = ~clk;

  // reset
  initial
  begin: process_reset
    /* verilator lint_off INITIALDLY */
    repeat (4) @(posedge clk);
    // synchronous reset release
    rst <= 1'b0;
    repeat (10) @(posedge clk);
    $display("ERROR: reached simulation timeout!");
    repeat (4) @(posedge clk);
    $finish();
    /* verilator lint_on INITIALDLY */
  end: process_reset

  initial
  begin: process_io
    int status;
    int code;
    int ch;
    int fd;

    fd = 32'h8000_0001;
    // open character device for R/W
    fd = $fopen(PTS, "r+");
    $display("DEBUG: fd = '%08h'.", fd);

    // check if device was found
    if (fd == 0) begin
      $fatal(0, "Could not open '%s' device node.", PTS);
    end else begin
      $info("Connected to '%0s'.", PTS);
    end

    ch = $fgetc(fd);
    $display("DEBUG: '%s' (0x%02h)", ch, ch);
  end: process_io

endmodule: riscv_gdb_stub_tb
