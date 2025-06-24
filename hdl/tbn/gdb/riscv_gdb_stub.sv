///////////////////////////////////////////////////////////////////////////////
// GDB stub
//
// Copyright 2025 Iztok Jeras <iztok.jeras@gmail.com>
//
// Licensed under CERN-OHL-P v2 or later
///////////////////////////////////////////////////////////////////////////////

module riscv_gdb_stub #(
  parameter  int unsigned XLEN = 32,
  parameter  type         SIZE_T = int unsigned,  // could be longint, but it results in warnings
  parameter  string       SOCKET = "gdb_stub_socket",
  // DEBUG parameters
  parameter  bit DEBUG_LOG = 1'b1
)(
  // system signals
  output logic clk,  // clock
  output logic rst,  // reset
  // CPU debug interface
  output logic dbg_req,  // request (behaves like VALID)
  output logic dbg_grt   // grant   (behaves like VALID)
);

  import socket_dpi_pkg::*;

///////////////////////////////////////////////////////////////////////////////
// local signals
///////////////////////////////////////////////////////////////////////////////

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


  // state
  typedef enum byte {
    RUNNING = 8'h00,
    // signals
    SIGHUP  = 8'd01,
    SIGINT  = 8'd02,  // Terminal interrupt signal
    SIGQUIT = 8'd03,  // Terminal quit signal
    SIGILL  = 8'd04,  // Illegal instruction
    SIGTRAP = 8'd05,  // Trace/breakpoint trap
    SIGABRT = 8'd06,
    SIGEMT  = 8'd07,
    SIGFPE  = 8'd08,
    SIGKILL = 8'd09,
	  SIGBUS  = 8'd10,
	  SIGSEGV = 8'd11,  // Invalid memory reference (address decoder error)
	  SIGSYS  = 8'd12,
	  SIGPIPE = 8'd13,
	  SIGALRM = 8'd14,
	  SIGTERM = 8'd15,
    // reset
    RESET   = 8'h80
  } state_t;

  state_t state = RUNNING;

///////////////////////////////////////////////////////////////////////////////
// GDB character get/put
///////////////////////////////////////////////////////////////////////////////

  function automatic void gdb_write (string str);
    int status;
    byte buffer [] = new[str.len()](array_t'(str));
    status = server_send(fd, buffer, 0);
  endfunction: gdb_write

///////////////////////////////////////////////////////////////////////////////
// GDB packet get/send
///////////////////////////////////////////////////////////////////////////////

  function automatic int gdb_get_packet(
    output string pkt
  );
    int status;
    int unsigned len;
    byte   buffer [] = new[512];
    byte   cmd [];
    string str;
    byte   checksum = 0;
    string checksum_ref;
    string checksum_str;

    // wait for the start character, ignore the rest
    // TODO: error handling?
    status = server_recv(fd, buffer, 0);
    len = status;

    str = string'(buffer);
    cmd = new[len-4](array_t'(str.substr(1,len-4)));
    checksum = cmd.sum();
    if (DEBUG_LOG) begin
      $display("DEBUG: <- %s", str.substr(1,len-4));
    end

    // Get checksum now
    checksum_ref = str.substr(len-2,len-1);

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
    int status;
    byte   ch [] = new[1];
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
    status = server_recv(fd, ch, 0);
    if (ch[0] == "+")  return(0);
    else            return(-1);
  endfunction: gdb_send_packet

///////////////////////////////////////////////////////////////////////////////
// GDB packet handlers
///////////////////////////////////////////////////////////////////////////////

  // Send a exception packet "T <value>"
  function automatic int gdb_stop_reply();
    string pkt;
    int status;

    // read packet
    status = gdb_get_packet(pkt);

    // reply with current state
    status = gdb_send_packet($sformatf("S%02h", state));
    return(status);
  endfunction: gdb_stop_reply

///////////////////////////////////////////////////////////////////////////////
// GDB query
///////////////////////////////////////////////////////////////////////////////

  function automatic bit gdb_qsupported (
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

  function automatic void gdb_q_packet ();
    string pkt;
    int status;

    // read packet
    status = gdb_get_packet(pkt);

    if (gdb_qsupported(pkt)) begin
      return;
    end else begin
      // not supported, send empty response packet
      status = gdb_send_packet("");
    end
  endfunction: gdb_q_packet

///////////////////////////////////////////////////////////////////////////////
// GDB verbose
///////////////////////////////////////////////////////////////////////////////

  function automatic void gdb_v_packet ();
    string pkt;
    int status;

    // read packet
    status = gdb_get_packet(pkt);

    // not supported, send empty response packet
    status = gdb_send_packet("");
  endfunction: gdb_v_packet

///////////////////////////////////////////////////////////////////////////////
// GDB memory access (hexadecimal)
///////////////////////////////////////////////////////////////////////////////

  function automatic int gdb_mem_read ();
    int code;
    string pkt;
    int status;
    SIZE_T adr;
    SIZE_T len;

    // read packet
    status = gdb_get_packet(pkt);

    // memory address and length
`ifdef VERILATOR
    code = $sscanf(pkt, "m%h,%h", adr, len);
`else
    case (XLEN)
      32: code = $sscanf(pkt, "m%8h,%8h", adr, len);
      64: code = $sscanf(pkt, "m%16h,%16h", adr, len);
    endcase
`endif

    // read memory
    pkt = {len{"XX"}};
    for (SIZE_T i=0; i<len; i++) begin
      string tmp = "XX";
      tmp = $sformatf("%02h", mem[adr+i]);
      pkt[i*2+0] = tmp[0];
      pkt[i*2+1] = tmp[1];
    end

    // send response
    status = gdb_send_packet(pkt);

    return(len);
  endfunction: gdb_mem_read

  function automatic int gdb_mem_write ();
    int code;
    string pkt;
    int status;
    SIZE_T adr;
    SIZE_T len;

    // read packet
    status = gdb_get_packet(pkt);

    // memory address and length
`ifdef VERILATOR
    code = $sscanf(pkt, "M%h,%h:", adr, len);
`else
    case (XLEN)
      32:     code = $sscanf(pkt, "M%8h,%8h:", adr, len);
      64:     code = $sscanf(pkt, "M%16h,%16h:", adr, len);
    endcase
`endif

    // write memory
    for (SIZE_T i=0; i<len; i++) begin
`ifdef VERILATOR
      status = $sscanf(pkt.substr(code+(adr+i)*2, code+(adr+i)*2+1), "%2h", mem[adr+i]);
`else
      status = $sscanf(pkt.substr(code+(adr+i)*2, code+(adr+i)*2+1), "%h", mem[adr+i]);
`endif
    end

    // send response
    status = gdb_send_packet("OK");

    return(len);
  endfunction: gdb_mem_write

///////////////////////////////////////////////////////////////////////////////
// GDB memory access (binary)
///////////////////////////////////////////////////////////////////////////////

  function automatic int gdb_mem_bin_read ();
    int code;
    string pkt;
    int status;
    SIZE_T adr;
    SIZE_T len;

    // read packet
    status = gdb_get_packet(pkt);

    // memory address and length
`ifdef VERILATOR
    code = $sscanf(pkt, "x%h,%h", adr, len);
`else
    case (XLEN)
      32: code = $sscanf(pkt, "x%8h,%8h", adr, len);
      64: code = $sscanf(pkt, "x%16h,%16h", adr, len);
    endcase
`endif

    // read memory
    pkt = {len{8'h00}};
    for (SIZE_T i=0; i<len; i++) begin
      pkt[i] = mem[adr+i];
    end

    // send response
    status = gdb_send_packet(pkt);

    return(len);
  endfunction: gdb_mem_bin_read

  function automatic int gdb_mem_bin_write ();
    int code;
    string pkt;
    int status;
    SIZE_T adr;
    SIZE_T len;

    // read packet
    status = gdb_get_packet(pkt);

    // memory address and length
`ifdef VERILATOR
    code = $sscanf(pkt, "X%h,%h:", adr, len);
`else
    case (XLEN)
      32:     code = $sscanf(pkt, "X%8h,%8h:", adr, len);
      64:     code = $sscanf(pkt, "X%16h,%16h:", adr, len);
    endcase
`endif

    // write memory
    for (SIZE_T i=0; i<len; i++) begin
      mem[adr+i] = pkt[code+i];
    end

    // send response
    status = gdb_send_packet("OK");

    return(len);
  endfunction: gdb_mem_bin_write

///////////////////////////////////////////////////////////////////////////////
// GDB register access
///////////////////////////////////////////////////////////////////////////////

  // "g" packet
  function automatic int gdb_reg_readall ();
    int status;
    string pkt;
    logic [XLEN-1:0] val;

    // read packet
    status = gdb_get_packet(pkt);

    // GPR
    pkt = "";
    for (int unsigned i=0; i<32; i++) begin
      // swap byte order since they are sent LSB first
      val = {<<8{gpr[i]}};
      case (XLEN)
        32: pkt = {pkt, $sformatf("%08h", val)};
        64: pkt = {pkt, $sformatf("%016h", val)};
      endcase
    end
    // PC
    // swap byte order since they are sent LSB first
    val = {<<8{pc}};
    case (XLEN)
      32: pkt = {pkt, $sformatf("%08h", val)};
      64: pkt = {pkt, $sformatf("%016h", val)};
    endcase

    // send response
    status = gdb_send_packet(pkt);

    return(32+1);
  endfunction: gdb_reg_readall

  function automatic int gdb_reg_writeall ();
    string pkt;
    int status;
    int unsigned len = XLEN/8*2;
    logic [XLEN-1:0] val;

    // read packet
    status = gdb_get_packet(pkt);
    // remove command
    pkt = pkt.substr(1, pkt.len()-1);

    // GPR
    for (int unsigned i=0; i<32; i++) begin
      case (XLEN)
`ifdef VERILATOR
        32: status = $sscanf(pkt.substr(i*len, i*len+len-1), "%h", val);
        64: status = $sscanf(pkt.substr(i*len, i*len+len-1), "%h", val);
`else
        32: status = $sscanf(pkt.substr(i*len, i*len+len-1), "%8h", val);
        64: status = $sscanf(pkt.substr(i*len, i*len+len-1), "%16h", val);
`endif
      endcase
      // swap byte order since they are sent LSB first
      gpr[i] = {<<8{val}};
    end
    // PC
    case (XLEN)
`ifdef VERILATOR
      32: status = $sscanf(pkt.substr(32*len, 32*len+len-1), "%h", val);
      64: status = $sscanf(pkt.substr(32*len, 32*len+len-1), "%h", val);
`else
      32: status = $sscanf(pkt.substr(32*len, 32*len+len-1), "%8h", val);
      64: status = $sscanf(pkt.substr(32*len, 32*len+len-1), "%16h", val);
`endif
    endcase
    // swap byte order since they are sent LSB first
    pc = {<<8{val}};

    // send response
    status = gdb_send_packet("OK");

    return(32+1);
  endfunction: gdb_reg_writeall

  function automatic int gdb_reg_readone ();
    int status;
    string pkt;
    int unsigned idx;
    logic [XLEN-1:0] val;

    // read packet
    status = gdb_get_packet(pkt);

    // register index
    status = $sscanf(pkt, "p%h", idx);

    if (idx<32) begin
      // GPR
      // swap byte order since they are sent LSB first
      val = {<<8{gpr[idx]}};
      case (XLEN)
        32: pkt = {pkt, $sformatf("%08h", val)};
        64: pkt = {pkt, $sformatf("%016h", val)};
      endcase
    end else begin
      // PC
      // swap byte order since they are sent LSB first
      val = {<<8{pc}};
      case (XLEN)
        32: pkt = {pkt, $sformatf("%08h", val)};
        64: pkt = {pkt, $sformatf("%016h", val)};
      endcase
    end

    // send response
    status = gdb_send_packet(pkt);

    return(1);
  endfunction: gdb_reg_readone

  function automatic int gdb_reg_writeone ();
    int status;
    string pkt;
    int unsigned idx;
    logic [XLEN-1:0] val;

    // read packet
    status = gdb_get_packet(pkt);

    // register index and value
    case (XLEN)
`ifdef VERILATOR
      32: status = $sscanf(pkt, "P%h=%h", idx, val);
      64: status = $sscanf(pkt, "P%h=%h", idx, val);
`else
      32: status = $sscanf(pkt, "P%h=%8h", idx, val);
      64: status = $sscanf(pkt, "P%h=%16h", idx, val);
`endif
    endcase

    // write registers
    if (idx<32) begin
      // GPR
      // swap byte order since they are sent LSB first
      gpr[idx] = {<<8{val}};
      case (XLEN)
        32: $display("DEBUG: GPR[%0d] <= 32'h%08h", idx, val);
        64: $display("DEBUG: GPR[%0d] <= 64'h%016h", idx, val);
      endcase
    end else begin
      // PC
      // swap byte order since they are sent LSB first
      pc = {<<8{val}};
      case (XLEN)
        32: $display("DEBUG: PC <= 32'h%08h", val);
        64: $display("DEBUG: PC <= 64'h%016h", val);
      endcase
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
    static byte ch [] = new[1];
    static byte bf [] = new[2];
    int status;
    int code;

    // open character device for R/W
    fd = server_start("riscv_gdb_stub");
    $display("DEBUG: fd = '%08h'.", fd);

    // check if device was found
    // TODO: check for actual return values
    if (fd == 0) begin
      $fatal(0, "Could not open '%s' device node.", SOCKET);
    end else begin
      $info("Connected to '%0s'.", SOCKET);
    end

    // display received characters
    /* verilator lint_off INFINITELOOP */
    forever begin

      // Questa quirk, flush STDOUT
      $fflush(32'h00000002);
      status = server_recv(fd, ch, MSG_PEEK);
      if (ch[0] == "+") begin
        status = server_recv(fd, ch, 0);
        $display("DEBUG: unexpected \"+\".");
      end else
      if (ch[0] == SIGQUIT) begin  // 0x03
        state = SIGINT;
        $error("Interrupt SIGQUIT (0x03) (Ctrl+c).");
        // fake empty packet
        status = gdb_stop_reply();
      end else
      if (ch[0] == "$") begin
        status = server_recv(fd, bf, MSG_PEEK);
        // parse command
        case (bf[1])
          "x": status = gdb_mem_bin_read();
          "X": status = gdb_mem_bin_write();
          "m": status = gdb_mem_read();
          "M": status = gdb_mem_write();
          "g": status = gdb_reg_readall();
          "G": status = gdb_reg_writeall();
          "p": status = gdb_reg_readone();
          "P": status = gdb_reg_writeone();
          "?": status = gdb_stop_reply();
          "Q",
          "q": gdb_q_packet();
          "v": gdb_v_packet();
          default: begin
            string pkt;
            // read packet
            status = gdb_get_packet(pkt);
            // for unsupported commands respond with empty packet
            status = gdb_send_packet("");
          end
        endcase
      end else begin
        $error("Unexpected sequence from degugger \"%s\".", ch);
      end
    end
    /* verilator lint_on INFINITELOOP */

  end

  final
  begin
    // stop server (close socket)
    server_stop(fd);
    $display("DEBUG: stopped server and closed socket.");
  end

endmodule: riscv_gdb_stub
