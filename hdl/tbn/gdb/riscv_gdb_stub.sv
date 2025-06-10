///////////////////////////////////////////////////////////////////////////////
// GDB stub
//
// Copyright 2025 Iztok Jeras <iztok.jeras@gmail.com>
//
// Licensed under CERN-OHL-P v2 or later
///////////////////////////////////////////////////////////////////////////////

module riscv_gdb_stub #(
    parameter  int unsigned XLEN = 32,
    parameter  string       PTS = "port_stub",
    // DEBUG parameters
    parameter  bit DEBUG_LOG = 1'b1
)(
  // system signals
  output logic clk,  // clock
  output logic rst   // reset
);

///////////////////////////////////////////////////////////////////////////////
// local signals
///////////////////////////////////////////////////////////////////////////////

  // named pipe file descriptor
  int fd;

  // GPR
  logic [XLEN-1:0] gpr [0:32-1] = '{default: 'x};
  // PC
  logic [XLEN-1:0] pc = '0;

///////////////////////////////////////////////////////////////////////////////
// GDB character get/put
///////////////////////////////////////////////////////////////////////////////

  function automatic byte gdb_getc ();
    int c;
    c = $fgetc(fd);
    gdb_getc = c[7:0];
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

    if (DEBUG_LOG) begin
      $display("DEBUG: <- %p", pkt);
    end

    // Get checksum now
    checksum_ref =                string'(gdb_getc()) ;
    checksum_ref = {checksum_ref, string'(gdb_getc())};

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

    if (DEBUG_LOG) begin
      $display("DEBUG: -> %p", pkt);
    end

    // Send packet start
    gdb_write("$");

    // Send packet data and calculate checksum
    foreach (pkt[i]) begin
      checksum += pkt[i];
      gdb_write(string'(pkt[i]));
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
    status = gdb_send_packet($sformatf("S%02h", exception));
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
// GDB register access
///////////////////////////////////////////////////////////////////////////////

  function automatic int gdb_reg_readall ();
    int status;
    string pkt = "";
    
    // GPR
  	for (int unsigned i=0; i<32; i++) begin
      case (XLEN)
        32: pkt = {pkt, $sformatf("%08h", gpr[i])};
        64: pkt = {pkt, $sformatf("%016h", gpr[i])};
      endcase
    end
    // PC
    case (XLEN)
      32: pkt = {pkt, $sformatf("%08h", pc)};
      64: pkt = {pkt, $sformatf("%016h", pc)};
    endcase

    // send response
    status = gdb_send_packet(pkt);

    return(32+1);
  endfunction: gdb_reg_readall

  function automatic int gdb_reg_writeall (
    input string pkt
  );
    int status;
    int unsigned len = XLEN/8*2;

    // GPR
  	for (int unsigned i=0; i<32; i++) begin
      case (XLEN)
        32: status = $sscanf(pkt.substr(i*len, i*len+len-1), "%08h", gpr[i]);
        64: status = $sscanf(pkt.substr(i*len, i*len+len-1), "%016h", gpr[i]);
      endcase
    end
    // PC
    case (XLEN)
      32: status = $sscanf(pkt.substr(32*len, 32*len+len-1), "%08h", pc);
      64: status = $sscanf(pkt.substr(32*len, 32*len+len-1), "%016h", pc);
    endcase

    // send response
    status = gdb_send_packet("OK");

    return(32+1);
  endfunction: gdb_reg_writeall

  function automatic int gdb_reg_readone (
    input string pkt
  );
    int status;
    int unsigned idx;

    // register index
    status = $sscanf(pkt, "p%08h", idx);

  	if (idx<32) begin
      // GPR
      case (XLEN)
        32: pkt = {pkt, $sformatf("%08h", gpr[idx])};
        64: pkt = {pkt, $sformatf("%016h", gpr[idx])};
      endcase
    end else begin
      // PC
      case (XLEN)
        32: pkt = {pkt, $sformatf("%08h", pc)};
        64: pkt = {pkt, $sformatf("%016h", pc)};
      endcase
    end

    // send response
    status = gdb_send_packet(pkt);

    return(1);
  endfunction: gdb_reg_readone

  function automatic int gdb_reg_writeone (
    input string pkt
  );
    int status;
    int unsigned idx;
    logic [XLEN-1:0] val;

    // register index and value
    case (XLEN)
      32: status = $sscanf(pkt, "P%d=%08h", idx, val);
      64: status = $sscanf(pkt, "P%d=%016h", idx, val);
    endcase

  	if (idx<32) begin
      // GPR
      gpr[idx] = val;
    end else begin
      // PC
      pc = val;
    end

    // send response
    status = gdb_send_packet("OK");

    return(1);
  endfunction: gdb_reg_writeone

///////////////////////////////////////////////////////////////////////////////
// GDB breakpoints/watchpoints
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// main loop
///////////////////////////////////////////////////////////////////////////////

  initial begin
    int status;

    $display("DEBUG: start.");
    // open named pipe for R/W
    fd = $fopen(PTS, "r+");
    $display("DEBUG: fd = '%08h'.", fd);
    if (fd != 0) $info("Connected to '%0s'.", PTS);
    else         $error("Could not open '%s' device node.", PTS);

    // display received characters
    /* verilator lint_off INFINITELOOP */
    forever begin
      string pkt;

      // wait for a packet
      status = gdb_get_packet(pkt);

      // parse command
      case (pkt[0])
        "g": status = gdb_reg_readall();
        "G": status = gdb_reg_writeall(pkt);
        "p": status = gdb_reg_readone(pkt);
        "P": status = gdb_reg_writeone(pkt);
        "?": status = gdb_send_exception(pkt, 5);  // TODO: add exception
        "Q",
        "q": gdb_q_packet(pkt);
        "v": gdb_v_packet(pkt);
        // for unsupported commands respond with empty packet
        default: status = gdb_send_packet("");
      endcase
    end
    /* verilator lint_on INFINITELOOP */
    
    // remove named pipe
    $fclose(fd);
  end

endmodule: riscv_gdb_stub
