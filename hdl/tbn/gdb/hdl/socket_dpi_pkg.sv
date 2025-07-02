///////////////////////////////////////////////////////////////////////////////
// socket
//
// Copyright 2025 Iztok Jeras <iztok.jeras@gmail.com>
//
// Licensed under CERN-OHL-P v2 or later
///////////////////////////////////////////////////////////////////////////////

package socket_dpi_pkg;

  // flags
  enum int {
    MSG_OOB          = 32'h00000001, // Process out-of-band data.
    MSG_PEEK         = 32'h00000002, // Peek at incoming messages.
    MSG_DONTROUTE    = 32'h00000004, // Don't use local routing.
    MSG_CTRUNC       = 32'h00000008, // Control data lost before delivery.
    MSG_PROXY        = 32'h00000010, // Supply or ask second address.
    MSG_TRUNC        = 32'h00000020,
    MSG_DONTWAIT     = 32'h00000040, // Nonblocking IO.
    MSG_EOR          = 32'h00000080, // End of record.
    MSG_WAITALL      = 32'h00000100, // Wait for a full request.
    MSG_FIN          = 32'h00000200,
    MSG_SYN          = 32'h00000400,
    MSG_CONFIRM      = 32'h00000800, // Confirm path validity.
    MSG_RST          = 32'h00001000,
    MSG_ERRQUEUE     = 32'h00002000, // Fetch message from error queue.
    MSG_NOSIGNAL     = 32'h00004000, // Do not generate SIGPIPE.
    MSG_MORE         = 32'h00008000, // Sender will send more.
    MSG_WAITFORONE   = 32'h00010000, // Wait for at least one packet to return.
    MSG_BATCH        = 32'h00040000, // sendmmsg: more messages coming.
    MSG_ZEROCOPY     = 32'h04000000, // Use user data in kernel path.
    MSG_FASTOPEN     = 32'h20000000, // Send data in TCP SYN.
    MSG_CMSG_CLOEXEC = 32'h40000000  // Set close_on_exit for file descriptor received through SCM_RIGHTS.
  } flags;


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
