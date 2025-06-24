///////////////////////////////////////////////////////////////////////////////
// socket
//
// Copyright 2025 Iztok Jeras <iztok.jeras@gmail.com>
//
// Licensed under CERN-OHL-P v2 or later
///////////////////////////////////////////////////////////////////////////////

package socket_dpi_pkg;

  import "DPI-C" function int test (input int val);

  // start Unix socket server
  import "DPI-C" function int server_start (
    input string file
  );

  // stop Unix socket server
  import "DPI-C" function int server_stop (
    input int fd
  );

  // send data (returns the number of bytes sent)
  import "DPI-C" function int server_send (
    input  int  fd,
    input  byte data [],
    input  int  flags
  );

  // receive data (returns the number of bytes received)
  import "DPI-C" function int server_recv (
    input  int  fd,
    output byte data [],
    input  int  flags
  );

endpackage: socket_dpi_pkg
