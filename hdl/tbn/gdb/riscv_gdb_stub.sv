///////////////////////////////////////////////////////////////////////////////
// GDB stub
//
// Copyright 2025 Iztok Jeras <iztok.jeras@gmail.com>
//
// Licensed under CERN-OHL-P v2 or later
///////////////////////////////////////////////////////////////////////////////

module riscv_gdb_stub #(
    parameter  int unsigned XLEN = 32,
    parameter  string       PTS = "port_stub"
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
// GDB character get/put
///////////////////////////////////////////////////////////////////////////////

  function automatic byte gdb_getc ();
    int c;
    c = $fgetc(fd);
    gdb_getc = c[7:0];
    $display("%0s (0x%02h)", gdb_getc, gdb_getc);
  endfunction: gdb_getc

  function automatic void gdb_write (string str);
    int status;
    $fwrite(fd, str);
  endfunction: gdb_write

///////////////////////////////////////////////////////////////////////////////
// GDB packet get/send
///////////////////////////////////////////////////////////////////////////////

  function automatic int gdb_get_packet(
    output string pkt
  );
    byte   ch;
    byte   checksum = 0;
    string checksum_ref;
    string checksum_str;

    // wait for the start character, ignore the rest
    do begin
      ch = gdb_getc();
    end while (ch != "$");

    // Read until receive '#'
    pkt = "";
    do begin
      ch = gdb_getc();
      if (ch != "#") begin
        pkt = {pkt, ch};
        checksum += ch;
      end
    end while (ch != "#");

    // Get checksum now
    checksum_ref =                gdb_getc() ;
    checksum_ref = {checksum_ref, gdb_getc()};

    // Verify checksum
    checksum_str = $sformatf("%02h", checksum);
    if (checksum_ref != checksum_str) begin
      $error("Bad checksum. Got 0x%s but was expecting: 0x%s for packet '%s'", checksum_ref, checksum_str, pkt);
      // NACK packet
      gdb_write("-");
      return (-1);
    end else begin
      // ACK packet
      gdb_write("+");
      return(0);
    end
  endfunction: gdb_get_packet

  function automatic int gdb_send_packet(
    input string pkt
  );
    byte   ch;
    byte   checksum = 0;
    string checksum_str;

    // Send packet start
    gdb_write("$");

    // Send packet data and calculate checksum
    foreach (pkt[i]) begin
      checksum += pkt[i];
      gdb_write(pkt[i]);
    end

    // Send packet end
    gdb_write("#");

    // Send the checksum
    gdb_write($sformatf("%02h", checksum));

    // Check response
    ch = gdb_getc();
    if (ch == "+")  return(0);
    else            return(-1);
  endfunction: gdb_send_packet

///////////////////////////////////////////////////////////////////////////////
// GDB packet handlers
///////////////////////////////////////////////////////////////////////////////

  // Send a exception packet "T <value>"
  function automatic int gdb_send_exception(
    input string pkt,
    input byte   exception
  );
    int status;
    status = gdb_send_packet($sformatf("S %02h", exception));
	  return(status);
  endfunction: gdb_send_exception

  function automatic bit gdb_qsupported(
    input string pkt
  );
    int status;
    if (pkt.substr(0,10) == "qSupported") begin
      status = gdb_send_packet("");
      return(1'b1);
    end else begin
	    return(1'b0);
    end
  endfunction: gdb_qsupported

  function automatic void gdb_q_packet (
    input string pkt
  );
    int status;
	  if (gdb_qsupported(pkt)) begin
		  return;
    end else begin
      status = gdb_send_packet("");
    end
  endfunction: gdb_q_packet

  function automatic void gdb_v_packet (
    input string pkt
  );
    int status;
    status = gdb_send_packet("");
  endfunction: gdb_v_packet

///////////////////////////////////////////////////////////////////////////////
// main loop
///////////////////////////////////////////////////////////////////////////////

  initial begin
    int status;

    // open named pipe for R/W
    fd = $fopen(PTS, "rb+");
    $display("DEBUG: connected to '%0s'.", PTS);
//    gdb_putc("+");
    // display received characters
    /* verilator lint_off INFINITELOOP */
    forever begin
      string pkt;

      // wait for a packet
      status = gdb_get_packet(pkt);
      $display("DEBUG: %p\n", pkt);

      // parse command
      case (pkt[0])
        "?": status = gdb_send_exception(pkt, 0);  // TODO: add exception
        "Q",
        "q": gdb_q_packet(pkt);
        "v": gdb_v_packet(pkt);
        // for unsupported commands respond with empty packet
        default: status = gdb_send_packet("");
      endcase
    end
    /* verilator lint_on INFINITELOOP */
    
    // remove named pipe
    $system($sformatf("rm %s", PTS));
  end

endmodule: riscv_gdb_stub
