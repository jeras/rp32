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

//  process io;

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
    repeat (10) @(posedge clk);
    $display("ERROR: reached simulation timeout!");
    repeat (4) @(posedge clk);
    $finish();
    /* verilator lint_on INITIALDLY */
  end: process_reset

  initial
  begin: process_io
    byte buffer [];
    int status;
    int code;
    int ch;
    int fd;

    // test
    $display("TEST: test(10) = %0d", test(10));

    // start server
    fd = server_start("riscv_gdb_stub");

    // send data
    buffer = new[5]('{"A", "B", "C", "D", 0});
    $display("DEBUG: buffer = %s", buffer);
    status = server_send(fd, buffer, 0);
    $display("DEBUG: send status = %0d", status);

    // receive data
    status = server_recv(fd, buffer, 0);
    $display("DEBUG: recv status = %0d", status);
    $display("DEBUG: buffer = %p", buffer);
    $display("DEBUG: buffer = %s", buffer);


    // stop server
    $display("DEBUG: stop server.");
    status = server_stop(fd);

  end: process_io

endmodule: riscv_gdb_stub_tb
