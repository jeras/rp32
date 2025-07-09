///////////////////////////////////////////////////////////////////////////////
// R5P: Mouse SoC GDB adapter
//
// Copyright 2025 Iztok Jeras <iztok.jeras@gmail.com>
//
// Licensed under CERN-OHL-P v2 or later
///////////////////////////////////////////////////////////////////////////////

// SoC hierarchical paths
`define cpu    $root.r5p_mouse_soc_top_tb.dut.cpu
//`define pc     $root.r5p_mouse_soc_top_tb.dut.cpu.ctl_pcr
// next PC
`define pc     $root.r5p_mouse_soc_top_tb.dut.cpu.ctl_pcn
`define gpr(i) $root.r5p_mouse_soc_top_tb.dut.gen_default.mem.mem[(`cpu.GPR_ADR-`cpu.IFU_RST)/4+(i)]
`define mem(i) $root.r5p_mouse_soc_top_tb.dut.gen_default.mem.mem[((i)-`cpu.IFU_RST)/4][8*((i)%4)+:8]

module r5p_mouse_soc_gdb #(
  // 8/16/32/64 bit CPU selection
  parameter  int unsigned XLEN = 32,
  parameter  type         SIZE_T = int unsigned,  // could be longint (RV64), but it results in warnings
  // number of GPR registers
  localparam int unsigned GNUM = 32,  // GPR number can be 16 for RISC-V E extension (embedded)
  // Unix/TCP socket
  parameter  string       SOCKET = "gdb_server_stub_socket",
  // XML target/registers/memory description
  parameter  string       XML_TARGET    = "",
  parameter  string       XML_REGISTERS = "",
  parameter  string       XML_MEMORY    = "",
  // DEBUG parameters
  parameter  bit          DEBUG_LOG = 1'b1
)(
  // system signals
  input  logic clk,  // clock
  output logic rst,  // reset
  // LSU interface (load/store unit)
  input  logic            bus_trn,  // transfer
  input  logic            bus_xen,  // execute enable
  input  logic            bus_wen,  // write enable
  input  logic [XLEN-1:0] bus_adr,  // address
  input  logic    [2-1:0] bus_siz   // size
);

  import socket_dpi_pkg::*;
  import gdb_server_stub_pkg::*;

///////////////////////////////////////////////////////////////////////////////
// adapter class (extends the gdb_server_stub_socket class)
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
      string socket = ""
    );
      super.new(
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
        reg_read = `gpr(idx);
      end else begin
        reg_read = `pc;
      end
    endfunction: reg_read

    virtual function void reg_write (
      input  int unsigned   idx,
      input  bit [XLEN-1:0] dat
    );
      if (idx<GNUM) begin
        `gpr(idx) = dat;
      end else begin
        `pc = dat;
      end
    endfunction: reg_write

    virtual function automatic byte mem_read (
      input  SIZE_T adr
    );
      mem_read = `mem(adr);
    endfunction: mem_read

    virtual function automatic void mem_write (
      input  SIZE_T adr,
      input  byte   dat
    );
      `mem(adr) = dat;
      $display("DBG: mem[%08x] = %02x", adr, `mem(adr));
    endfunction: mem_write

    virtual function automatic bit exe_illegal (
      input  SIZE_T adr
    );
      // TODO: implement proper illegal instruction check
      exe_illegal = $isunknown({`mem(adr+1), `mem(adr+0)}) ? 1'b1 : 1'b0;
//      $display("DBG: exe_illegal[%08x] = %04x", adr, {`mem(adr+1), `mem(adr+0)});
    endfunction: exe_illegal

    virtual function automatic bit exe_ebreak (
      input  SIZE_T adr
    );
      // TODO: implement proper illegal instruction check
//    mem_ebreak = ({                          `mem(adr+1), `mem(adr+0)} == 16'hxxxx) ||
//                 ({`mem(adr+3), `mem(adr+2), `mem(adr+1), `mem(adr+0)} == 32'hxxxxxxxx) ? 1'b1 : 1'b0;
      exe_ebreak = 1'b0;
    endfunction: exe_ebreak

    virtual function automatic void jump (
      input  SIZE_T adr
    );
      $error("step/continue address jump is not supported");
    endfunction: jump

  endclass: gdb_server_stub_socket_mouse

///////////////////////////////////////////////////////////////////////////////
// main loop
///////////////////////////////////////////////////////////////////////////////

  event socket_blocking;
  event socket_nonblocking;

//  task step;
//    do begin
//      @(posedge clk);
//    end while (~(bus_trn & bus_xen));
//  endtask: step

  gdb_server_stub_socket_mouse gdb;

  initial
  begin: main_initial
    static byte ch [] = new[1];
    int status;

    // set RESET
    rst = 1'b1;

    // create GDB socket object
    gdb = new(SOCKET);

    // main loop/FSM
    forever
    begin: main_loop
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
          -> socket_nonblocking;
          status = server_recv(gdb.fd, ch, MSG_PEEK | MSG_DONTWAIT);
          // if empty, check for breakpoints/watchpoints and continue
          if (status != 1) begin
            // on clock edge sample system buses
            @(posedge clk);

            // check for illegal instructions and hardware/software breakpoints
            if (bus_trn & bus_xen) begin
              gdb.state = gdb.gdb_breakpoint_match(bus_adr);
            end

            // check for hardware watchpoints
            if (bus_trn & ~bus_xen) begin
              gdb.state = gdb.gdb_watchpoint_match(bus_adr, bus_wen, bus_siz);
            end

          // in case of Ctrl+C (character 0x03)
          end else if (ch[0] == SIGQUIT) begin
            // TODO: perhaps step to next instruction
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
          end while (~(bus_trn & bus_xen));
          gdb.state = SIGTRAP;

          // send response
          status = gdb.gdb_stop_reply(gdb.state);
        end

        // SIGILL, SIGTRAP, SIGINT, ...
        default: begin
          // blocking socket read
          -> socket_blocking;
          status = server_recv(gdb.fd, ch, MSG_PEEK);
          // parse packet and loop back
          status = gdb.gdb_packet(ch);
        end
      endcase
    end: main_loop
  end: main_initial

  final
  begin
    // stop server (close socket)
    gdb.close_socket();
    $display("DEBUG: stopped server and closed socket.");
  end

endmodule: r5p_mouse_soc_gdb
