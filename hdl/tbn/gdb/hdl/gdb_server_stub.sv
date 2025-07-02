///////////////////////////////////////////////////////////////////////////////
// GDB server stub
//
// Copyright 2025 Iztok Jeras <iztok.jeras@gmail.com>
//
// Licensed under CERN-OHL-P v2 or later
///////////////////////////////////////////////////////////////////////////////

module gdb_server_stub #(
  parameter  int unsigned XLEN = 32,
  parameter  type         SIZE_T = int unsigned,  // could be longint, but it results in warnings
  parameter  string       SOCKET = "gdb_server_stub_socket",
  // memory
  parameter  int unsigned MEM_SIZ = 2**16,
  // DEBUG parameters
  parameter  bit DEBUG_LOG = 1'b1
)(
  // system signals
  input  logic clk,  // clock
  output logic rst,  // reset
  // registers
  ref    logic [XLEN-1:0] gpr [0:32-1],
  ref    logic [XLEN-1:0] pc,
  // memories
  ref    logic    [8-1:0] mem [0:2**16-1],
  // IFU interface (instruction fetch unit)
  input  logic            ifu_trn,  // transfer
  input  logic [XLEN-1:0] ifu_adr,  // address
  // LSU interface (load/store unit)
  input  logic            lsu_trn,  // transfer
  input  logic            lsu_wen,  // write enable
  input  logic [XLEN-1:0] lsu_adr,  // address
  input  logic    [2-1:0] lsu_siz   // size
);

  import socket_dpi_pkg::*;

///////////////////////////////////////////////////////////////////////////////
// local signals
///////////////////////////////////////////////////////////////////////////////

  // byte dynamic array type for casting to/from string
  typedef byte array_t [];

  // named pipe file descriptor
  int fd;

  // state
  typedef enum byte {
    // signals
    SIGHUP  = 8'd01,  // Hangup
    SIGINT  = 8'd02,  // Terminal interrupt signal
    SIGQUIT = 8'd03,  // Terminal quit signal
    SIGILL  = 8'd04,  // Illegal instruction
    SIGTRAP = 8'd05,  // Trace/breakpoint trap
    SIGABRT = 8'd06,  // Process abort signal
    SIGEMT  = 8'd07,
    SIGFPE  = 8'd08,  // Erroneous arithmetic operation
    SIGKILL = 8'd09,  // Kill (cannot be caught or ignored)
	  SIGBUS  = 8'd10,
	  SIGSEGV = 8'd11,  // Invalid memory reference (address decoder error)
	  SIGSYS  = 8'd12,
	  SIGPIPE = 8'd13,  // Write on a pipe with no one to read it
	  SIGALRM = 8'd14,  // Alarm clock
	  SIGTERM = 8'd15,  // Termination signal
    // reset
    RESET    = 8'h80,
    // running continuously
    CONTINUE = 8'h81,
    // running step
    STEP     = 8'h82
  } state_t;

  state_t state;

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
    string str = "";
    byte   checksum = 0;
    string checksum_ref;
    string checksum_str;

    // wait for the start character, ignore the rest
    // TODO: error handling?
    do begin
      status = server_recv(fd, buffer, 0);
//      $display("DEBUG: gdb_get_packet: buffer = %p", buffer);
      str = {str, string'(buffer)};
      len = str.len();
//      $display("DEBUG: gdb_get_packet: str = %s", str);
    end while (str[len-3] != "#");

    // extract packet data from received string
    pkt = str.substr(1,len-4);
    if (DEBUG_LOG) begin
  //    $display("DEBUG: <= %s", str);
      $display("DEBUG: <- %s", pkt);
    end

    // calculate packet data checksum
    cmd = new[len-4](array_t'(pkt));
    checksum = cmd.sum();

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
    else               return(-1);
  endfunction: gdb_send_packet

///////////////////////////////////////////////////////////////////////////////
// GDB state
///////////////////////////////////////////////////////////////////////////////

  // Send a exception packet "T <value>"
  function automatic int gdb_state();
    string pkt;
    int status;

    // read packet
    status = gdb_get_packet(pkt);

    // reply with current state
    status = gdb_stop_reply();
    return(status);
  endfunction: gdb_state

  // Send a exception packet "T <value>"
  function automatic int gdb_stop_reply(
    input byte signal = state
  );
    // reply with signal (current state by default)
    return(gdb_send_packet($sformatf("S%02h", signal)));
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

  function automatic void gdb_query_packet ();
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
  endfunction: gdb_query_packet

///////////////////////////////////////////////////////////////////////////////
// GDB verbose
///////////////////////////////////////////////////////////////////////////////

  function automatic void gdb_verbose_packet ();
    string pkt;
    int status;

    // read packet
    status = gdb_get_packet(pkt);

    // not supported, send empty response packet
    status = gdb_send_packet("");
  endfunction: gdb_verbose_packet

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

//    $display("DBG: gdb_mem_read: pkt = %s", pkt);

    // memory address and length
`ifdef VERILATOR
    code = $sscanf(pkt, "m%h,%h", adr, len);
`else
    case (XLEN)
      32: code = $sscanf(pkt, "m%8h,%8h", adr, len);
      64: code = $sscanf(pkt, "m%16h,%16h", adr, len);
    endcase
`endif

//    $display("DBG: gdb_mem_read: adr = %08x, len=%08x", adr, len);

    // TODO: handle individual memory instances
    adr = adr[$clog2(MEM_SIZ):0];

    // read memory
    pkt = {len{"XX"}};
    for (SIZE_T i=0; i<len; i++) begin
      string tmp = "XX";
      tmp = $sformatf("%02h", mem[adr+i]);
      pkt[i*2+0] = tmp[0];
      pkt[i*2+1] = tmp[1];
    end

//    $display("DBG: gdb_mem_read: pkt = %s", pkt);

    // send response
    status = gdb_send_packet(pkt);

    return(len);
  endfunction: gdb_mem_read

  function automatic int gdb_mem_write ();
    int code;
    string pkt;
    string dat;
    int status;
    SIZE_T adr;
    SIZE_T len;

    // read packet
    status = gdb_get_packet(pkt);
//    $display("DBG: gdb_mem_write: pkt = %s", pkt);

    // memory address and length
`ifdef VERILATOR
    code = $sscanf(pkt, "M%h,%h:", adr, len);
`else
    case (XLEN)
      32:     code = $sscanf(pkt, "M%8h,%8h:", adr, len);
      64:     code = $sscanf(pkt, "M%16h,%16h:", adr, len);
    endcase
`endif
//    $display("DBG: gdb_mem_write: adr = 'h%08h, len = 'd%0d", adr, len);

    // remove the header from the packet, only data remains
    dat = pkt.substr(pkt.len() - 2*len, pkt.len() - 1);
//    $display("DBG: gdb_mem_write: dat = %s", dat);

    // TODO: handle individual memory instances
    adr = adr[$clog2(MEM_SIZ):0];

    // write memory
    for (SIZE_T i=0; i<len; i++) begin
//      $display("DBG: gdb_mem_write: adr+i = 'h%08h, mem[adr+i] = 'h%02h", adr+i, mem[adr+i]);
`ifdef VERILATOR
      status = $sscanf(dat.substr(i*2, i*2+1), "%2h", mem[adr+i]);
`else
      status = $sscanf(dat.substr(i*2, i*2+1), "%h", mem[adr+i]);
`endif
//      $display("DBG: gdb_mem_write: adr+i = 'h%08h, mem[adr+i] = 'h%02h", adr+i, mem[adr+i]);
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
// GDB multiple register access
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
`ifdef VERILATOR
      status = $sscanf(pkt.substr(i*len, i*len+len-1), "%h", val);
`else
      case (XLEN)
        32: status = $sscanf(pkt.substr(i*len, i*len+len-1), "%8h", val);
        64: status = $sscanf(pkt.substr(i*len, i*len+len-1), "%16h", val);
      endcase
`endif
      // swap byte order since they are sent LSB first
      gpr[i] = {<<8{val}};
    end
    // PC
`ifdef VERILATOR
    status = $sscanf(pkt.substr(32*len, 32*len+len-1), "%h", val);
`else
    case (XLEN)
      32: status = $sscanf(pkt.substr(32*len, 32*len+len-1), "%8h", val);
      64: status = $sscanf(pkt.substr(32*len, 32*len+len-1), "%16h", val);
    endcase
`endif
    // swap byte order since they are sent LSB first
    pc = {<<8{val}};

    // send response
    status = gdb_send_packet("OK");

    return(32+1);
  endfunction: gdb_reg_writeall

///////////////////////////////////////////////////////////////////////////////
// GDB single register access
///////////////////////////////////////////////////////////////////////////////

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
`ifdef VERILATOR
    status = $sscanf(pkt, "P%h=%h", idx, val);
`else
    case (XLEN)
      32: status = $sscanf(pkt, "P%h=%8h", idx, val);
      64: status = $sscanf(pkt, "P%h=%16h", idx, val);
    endcase
`endif

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

  // point type
  typedef enum int unsigned {
    swbreak = 0,  // software breakpoint
    hwbreak = 1,  // hardware breakpoint
    watch   = 2,  // write  watchpoint
    rwatch  = 3,  // read   watchpoint
    awatch  = 4   // access watchpoint
  } ptype_t;

  typedef int unsigned pkind_t;

  typedef struct packed {
    ptype_t ptype;
    pkind_t pkind;
  } point_t;

  // associative array for hardware breakpoints/watchpoint
  point_t points [logic [XLEN-1:0]];

  function automatic int gdb_point_remove ();
    int status;
    string pkt;
    ptype_t ptype;
    logic [XLEN-1:0] addr;
    pkind_t pkind;

    // read packet
    status = gdb_get_packet(pkt);

    // breakpoint/watchpoint
`ifdef VERILATOR
    status = $sscanf(pkt, "z%h,%h,%h", ptype, addr, pkind);
`else
    case (XLEN)
      32: status = $sscanf(pkt, "z%h,%8h,%h", ptype, addr, pkind);
      64: status = $sscanf(pkt, "z%h,%16h,%h", ptype, addr, pkind);
    endcase
`endif

    case (ptype)
      swbreak: begin
        // software breakpoints are not supported
        status = gdb_send_packet("");
      end
      default: begin
        // software breakpoints are not supported
        points.delete(addr);
        status = gdb_send_packet("OK");
      end
    endcase

    return(1);
  endfunction: gdb_point_remove

  function automatic int gdb_point_insert ();
    int status;
    string pkt;
    ptype_t ptype;
    logic [XLEN-1:0] addr;
    pkind_t pkind;

    // read packet
    status = gdb_get_packet(pkt);

    // breakpoint/watchpoint
`ifdef VERILATOR
    status = $sscanf(pkt, "Z%h,%h,%h", ptype, addr, pkind);
`else
    case (XLEN)
      32: status = $sscanf(pkt, "Z%h,%8h,%h", ptype, addr, pkind);
      64: status = $sscanf(pkt, "Z%h,%16h,%h", ptype, addr, pkind);
    endcase
`endif

    case (ptype)
      swbreak: begin
        // software breakpoints are not supported
        status = gdb_send_packet("");
      end
      default: begin
        // software breakpoints are not supported
        points[addr] = '{ptype, pkind};
        status = gdb_send_packet("OK");
      end
    endcase

    return(1);
  endfunction: gdb_point_insert

///////////////////////////////////////////////////////////////////////////////
// GDB step/continue/kill
///////////////////////////////////////////////////////////////////////////////

  // TODO: jump to address might not be supported

  function automatic int gdb_step;
    int status;
    string pkt;
    SIZE_T addr;
    int    sig;
    logic [XLEN-1:0] val;

    // read packet
    status = gdb_get_packet(pkt);

    // signal/address
    case (pkt[0])
      "s": begin
        status = $sscanf(pkt, "s%h", addr);
        state = STEP;
        if (status == 1) begin
          pc = addr;
        end
      end
      "S": begin
        status = $sscanf(pkt, "S%h;%h", sig, addr);
        state = state_t'(sig);
        if (status == 2) begin
          pc = addr;
        end
      end
    endcase

    // do not send packet response here
    return(0);
  endfunction: gdb_step

  function automatic int gdb_continue ();
    int status;
    string pkt;
    SIZE_T addr;
    int    sig;
    logic [XLEN-1:0] val;

    // read packet
    status = gdb_get_packet(pkt);

    // signal/address
    case (pkt[0])
      "c": begin
        status = $sscanf(pkt, "c%h", addr);
        state = CONTINUE;
        if (status == 1) begin
          pc = addr;
        end
      end
      "C": begin
        status = $sscanf(pkt, "C%h;%h", sig, addr);
        state = state_t'(sig);
        if (status == 2) begin
          pc = addr;
        end
      end
    endcase

    $display("DBG: points: %p", points);

    // do not send packet response here
    return(0);
  endfunction: gdb_continue

  function automatic int gdb_kill ();
    int status;
    string pkt;
    SIZE_T addr;
    int    sig;
    logic [XLEN-1:0] val;

    // read packet
    status = gdb_get_packet(pkt);

    // enter RESET state
    state = RESET;

    // do not send packet response here
    return(0);
  endfunction: gdb_kill

///////////////////////////////////////////////////////////////////////////////
// GDB packet
///////////////////////////////////////////////////////////////////////////////

  function automatic int gdb_packet (
    input byte ch [1]
  );
    static byte bf [] = new[2];
    int status;
    int code;

    if (ch[0] == "+") begin
      $display("DEBUG: unexpected \"+\".");
      // remove the acknowledge from the socket
      status = server_recv(fd, ch, 0);
    end else
    if (ch[0] == "$") begin
      status = server_recv(fd, bf, MSG_PEEK);
      // parse command
      case (bf[1])
//        "x": status = gdb_mem_bin_read();
//        "X": status = gdb_mem_bin_write();
        "m": status = gdb_mem_read();
        "M": status = gdb_mem_write();
        "g": status = gdb_reg_readall();
        "G": status = gdb_reg_writeall();
        "p": status = gdb_reg_readone();
        "P": status = gdb_reg_writeone();
        "s",
        "S": status = gdb_step();
        "c",
        "C": status = gdb_continue();
        "?": status = gdb_state();
        "Q",
        "q":          gdb_query_packet();
        "v":          gdb_verbose_packet();
        "z": status = gdb_point_remove();
        "Z": status = gdb_point_insert();
        "k": status = gdb_kill();
        default: begin
          string pkt;
          // read packet
          status = gdb_get_packet(pkt);
          // for unsupported commands respond with empty packet
          status = gdb_send_packet("");
        end
      endcase
    end else begin
      $error("Unexpected sequence from degugger %p = \"%s\".", ch, ch);
    end
    return status;
  endfunction: gdb_packet

///////////////////////////////////////////////////////////////////////////////
// main loop
///////////////////////////////////////////////////////////////////////////////

  initial
  begin
    static byte ch [] = new[1];
    int status;
    int code;

    // set RESET
    rst = 1'b1;
    state = RESET;

    // open character device for R/W
    fd = server_start("gdb_server_stub");
    $display("DEBUG: fd = '%08h'.", fd);

    // check if device was found
    // TODO: check for actual return values
    if (fd == 0) begin
      $fatal(0, "Could not open '%s' device node.", SOCKET);
    end else begin
      $info("Connected to '%0s'.", SOCKET);
    end

    // main loop/FSM
    forever
    begin: loop
      case (state)

        RESET: begin
          // go through a reset sequence
          rst = 1'b1;
          repeat (4) @(posedge clk);
          rst <= 1'b0;
          // enter trap state
          state = SIGTRAP;
        end

        CONTINUE: begin
          // non-blocking socket read
          status = server_recv(fd, ch, MSG_PEEK | MSG_DONTWAIT);
          // if empty, check for breakpoints/watchpoints and continue
          if (status != 1) begin
            // on clock edge sample system buses
            @(posedge clk);

            // check for illegal instructions
            // TODO

            // check for hardware breakpoints
            if (ifu_trn) begin
              if (points.exists(ifu_adr)) begin
                // software breakpoint (TODO)
                // TODO: check for EBREAK/C.EBREAK instruction codes in memory at address
                // hardware breakpoint
                if (points[ifu_adr].ptype == hwbreak) begin
                  state = SIGTRAP;
                  $display("DEBUG: Triggered HW breakpoint at address %h.", ifu_adr);
                  // send response
                  status = gdb_stop_reply(state);
                end
              end
            end

            // check for hardware watchpoints
            if (lsu_trn) begin
              if (points.exists(lsu_adr)) begin
                if (points[lsu_adr].ptype inside {watch, rwatch, awatch}) begin
                  state = SIGTRAP;
                  $display("DEBUG: Triggered HW watchpoint at address %h.", lsu_adr);
                  // send response
                  status = gdb_stop_reply(state);
                end
              end
            end

          // in case of Ctrl+C (character 0x03)
          end else if (ch[0] == SIGQUIT) begin
            state = SIGINT;
            $display("DEBUG: Interrupt SIGQUIT (0x03) (Ctrl+c).");
            // send response
            status = gdb_stop_reply(state);

          // parse packet and loop back
          end else begin
            status = gdb_packet(ch);
          end
        end

        STEP: begin
          // step to the next instruction and trap again
          do begin
            @(posedge clk);
          end while (~ifu_trn);
          state = SIGTRAP;

          // check for illegal instructions
          // TODO

          // send response
          status = gdb_stop_reply(state);
        end

        // SIGTRAP, SIGINT, ...
        default: begin
          // blocking socket read
          status = server_recv(fd, ch, MSG_PEEK);
          // parse packet and loop back
          status = gdb_packet(ch);
        end
      endcase
    end: loop
  end

  final
  begin
    // stop server (close socket)
    server_stop(fd);
    $display("DEBUG: stopped server and closed socket.");
  end

endmodule: gdb_server_stub
