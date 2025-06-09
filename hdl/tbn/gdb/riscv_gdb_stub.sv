///////////////////////////////////////////////////////////////////////////////
// GDB stub
//
// Copyright 2025 Iztok Jeras <iztok.jeras@gmail.com>
//
// Licensed under CERN-OHL-P v2 or later
///////////////////////////////////////////////////////////////////////////////

module riscv_gdb_stub #(
    parameter  int unsigned XLEN = 32,
    parameter  string       PIPE = "gdb_stub"
)(
  // system signals
  output logic clk,  // clock
  output logic rst   // reset
);

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////

  // named pipe file descriptor
  int fd;
  byte c;
  int unsigned i = 0;

///////////////////////////////////////////////////////////////////////////////
// 
///////////////////////////////////////////////////////////////////////////////

  function automatic byte gdb_getc ();
    int c;
    c = $fgetc(fd);
    gdb_getc = c[7:0];
    $display("%0s (0x%02h)\n", gdb_getc, gdb_getc);
  endfunction: gdb_getc

  function automatic void gdb_putc (byte c);
    int status;
    status = $ungetc(int'(c), fd);
  endfunction: gdb_putc

  function automatic int gdb_get_packet(
    output byte pkt [$]
  );
    byte   ch;
    byte   checksum = 0;
    string checksum_ref = "00";
    string checksum_str = "00";

    // wait for the start character, ignore the rest
    do begin
      ch = gdb_getc();
    end while (ch != "$");

    // Read until receive '#'
    do begin
      ch = gdb_getc();
      if (ch != "#") begin
        pkt.push_back(ch);
        checksum += ch;
      end
    end while (ch != "#");

    // Get checksum now
    checksum_ref[0] = gdb_getc();
    checksum_ref[1] = gdb_getc();

    // Verify checksum
    checksum_str = $sformatf("%02h", checksum);
    if (checksum_ref != checksum_str) begin
      $error("Bad checksum. Got 0x%s but was expecting: 0x%s", checksum_ref, checksum_str);
      // NACK packet
      gdb_putc("-");
      return (-1);
    end else begin
      // ACK packet
      gdb_putc("+");
      return(0);
    end
  endfunction: gdb_get_packet

///////////////////////////////////////////////////////////////////////////////
// main loop
///////////////////////////////////////////////////////////////////////////////

  initial begin
    int status;

    // create named pipe
    status = $system($sformatf("rm %s", PIPE));
    status = $system($sformatf("mkfifo %s", PIPE));
    $display("DEBUG: created named pipe '%0s'.", PIPE);

    // open named pipe for R/W
    fd = $fopen(PIPE, "rb+");

    // display received characters
    /* verilator lint_off INFINITELOOP */
    forever begin
      byte pkt [$];
      status = gdb_get_packet(pkt);
      $display("%p\n", pkt);
    end
    /* verilator lint_on INFINITELOOP */
    
    // remove named pipe
    $system($sformatf("rm %s", PIPE));
  end

endmodule: riscv_gdb_stub
