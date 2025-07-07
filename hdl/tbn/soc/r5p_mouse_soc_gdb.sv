///////////////////////////////////////////////////////////////////////////////
// R5P: Mouse SoC GDB adapter
//
// Copyright 2025 Iztok Jeras <iztok.jeras@gmail.com>
//
// Licensed under CERN-OHL-P v2 or later
///////////////////////////////////////////////////////////////////////////////

module r5p_mouse_soc_gdb #(
  // 8/16/32/64 bit CPU selection
  parameter  int unsigned XLEN = 32,
  parameter  type         SIZE_T = int unsigned,  // could be longint (RV64), but it results in warnings
  // Unix/TCP socket
  parameter  string       SOCKET = "gdb_server_stub_socket",
  // XML target description
  parameter  string       XML_TARGET = "",  // TODO
  // registers
  parameter  int unsigned GNUM = 32,  // GPR number can be 16 for RISC-V E extension (embedded)
  parameter  string       XML_REGISTERS = "",  // TODO
  // memory
  parameter  string       XML_MEMORY = "",
  parameter  SIZE_T       MLEN = 8,       // memory unit width byte/half/word/double (8-bit byte by default)
  parameter  SIZE_T       MSIZ = 2**16,   // memory size
  parameter  SIZE_T       MBGN = 0,       // memory beginning
  parameter  SIZE_T       MEND = MSIZ-1,  // memory end
  // DEBUG parameters
  parameter  bit DEBUG_LOG = 1'b1
)(
  // system signals
  input  logic clk,  // clock
  output logic rst,  // reset
  // registers
  ref    logic [XLEN-1:0] gpr [0:GNUM-1],
  ref    logic [XLEN-1:0] pc,
  // memories
  ref    logic [MLEN-1:0] mem [MBGN:MEND],
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
  import gdb_server_stub_pkg::*;

///////////////////////////////////////////////////////////////////////////////
// adapter class
///////////////////////////////////////////////////////////////////////////////

  class gdb_server_stub_socket_mouse #(
    // 8/16/32/64 bit CPU selection
    parameter  int unsigned XLEN = 32,
    parameter  type         SIZE_T = int unsigned,  // could be longint (RV64), but it results in warnings
    // number of all registers
    parameter  int unsigned RNUM = GNUM+1,
    // DEBUG parameters
    parameter  bit DEBUG_LOG = 1'b1
  ) extends gdb_server_stub_socket #(
    .XLEN      (XLEN),
    .SIZE_T    (SIZE_T),
    .RNUM      (RNUM),
    .DEBUG_LOG (DEBUG_LOG)
  );

    // constructor
    function new(
//      tcb_vif_t tcb,
      string socket = ""
    );
      super.new(
//      .tcb    (tcb),
        .socket (socket)
      );
      // debugger starts in the reset state
      state = RESET;
    endfunction: new

    /////////////////////////////////////////////
    // register/memory access function overrides
    /////////////////////////////////////////////

    // TODO: for a multi memory and cache setup, there should be a decoder here

    virtual function bit [XLEN-1:0] reg_read (
      input  int unsigned idx
    );
      if (idx<GNUM) begin
        reg_read = gpr[idx];
      end else begin
        reg_read = pc;
      end
    endfunction: reg_read

    virtual function void reg_write (
      input  int unsigned   idx,
      input  bit [XLEN-1:0] dat
    );
      if (idx<GNUM) begin
        gpr[idx] = dat;
      end else begin
        pc = dat;
      end
    endfunction: reg_write

    virtual function automatic byte mem_read (
      input  SIZE_T adr
    );
      mem_read = mem[adr/(MLEN/8)][8*(adr%(MLEN/8))+:8];
    endfunction: mem_read

    virtual function automatic void mem_write (
      input  SIZE_T adr,
      input  byte   dat
    );
      mem[adr/(MLEN/8)][8*(adr%(MLEN/8))+:8] = dat;
      $display("DBG: mem[%08x/(MLEN/8] = %08x", adr, mem[adr/(MLEN/8)]);
    endfunction: mem_write

    virtual function automatic void jump (
      input  SIZE_T adr
    );
      $error("step/continue address jump is not supported");
    endfunction: jump

  endclass: gdb_server_stub_socket_mouse

///////////////////////////////////////////////////////////////////////////////
// main loop
///////////////////////////////////////////////////////////////////////////////

  gdb_server_stub_socket_mouse gdb;

  initial
  begin
    static byte ch [] = new[1];
    int status;

    // set RESET
    rst = 1'b1;

    // create GDB socket object
    gdb = new(SOCKET);

    // main loop/FSM
    forever
    begin: loop
      case (gdb.state)

        RESET: begin
          // go through a reset sequence
          rst = 1'b1;
          repeat (4) @(posedge clk);
          rst <= 1'b0;
          // enter trap state
          gdb.state = SIGTRAP;
        end

        CONTINUE: begin
          // non-blocking socket read
          status = server_recv(gdb.fd, ch, MSG_PEEK | MSG_DONTWAIT);
          // if empty, check for breakpoints/watchpoints and continue
          if (status != 1) begin
            // on clock edge sample system buses
            @(posedge clk);

            // check for illegal instructions
            // TODO

            // check for hardware breakpoints
            if (ifu_trn) begin
              if (gdb.points.exists(ifu_adr)) begin
                // software breakpoint (TODO)
                // TODO: check for EBREAK/C.EBREAK instruction codes in memory at address
                // hardware breakpoint
                if (gdb.points[ifu_adr].ptype == hwbreak) begin
                  gdb.state = SIGTRAP;
                  $display("DEBUG: Triggered HW breakpoint at address %h.", ifu_adr);
                  // send response
                  status = gdb.gdb_stop_reply(gdb.state);
                end
              end
            end

            // check for hardware watchpoints
            if (lsu_trn) begin
              if (gdb.points.exists(lsu_adr)) begin
                if (gdb.points[lsu_adr].ptype inside {watch, rwatch, awatch}) begin
                  gdb.state = SIGTRAP;
                  $display("DEBUG: Triggered HW watchpoint at address %h.", lsu_adr);
                  // send response
                  status = gdb.gdb_stop_reply(gdb.state);
                end
              end
            end

          // in case of Ctrl+C (character 0x03)
          end else if (ch[0] == SIGQUIT) begin
            gdb.state = SIGINT;
            $display("DEBUG: Interrupt SIGQUIT (0x03) (Ctrl+c).");
            // send response
            status = gdb.gdb_stop_reply(gdb.state);

          // parse packet and loop back
          end else begin
            status = gdb.gdb_packet(ch);
          end
        end

        STEP: begin
          // step to the next instruction and trap again
          do begin
            @(posedge clk);
          end while (~ifu_trn);
          gdb.state = SIGTRAP;

          // check for illegal instructions
          // TODO

          // send response
          status = gdb.gdb_stop_reply(gdb.state);
        end

        // SIGTRAP, SIGINT, ...
        default: begin
          // blocking socket read
          status = server_recv(gdb.fd, ch, MSG_PEEK);
          // parse packet and loop back
          status = gdb.gdb_packet(ch);
        end
      endcase
    end: loop
  end

  final
  begin
    // stop server (close socket)
    void'(server_stop(gdb.fd));
    $display("DEBUG: stopped server and closed socket.");
  end

endmodule: r5p_mouse_soc_gdb
