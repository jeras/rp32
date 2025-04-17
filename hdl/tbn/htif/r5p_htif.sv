////////////////////////////////////////////////////////////////////////////////
// R5P HTIF controller
////////////////////////////////////////////////////////////////////////////////
// Copyright 2022 Iztok Jeras
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
///////////////////////////////////////////////////////////////////////////////

module r5p_htif
  import riscv_isa_pkg::*;
  import tcb_pkg::*;
#(
  // constants used across the design in signal range sizing instead of literals
  localparam int unsigned XLEN = 32,
  localparam int unsigned XLOG = $clog2(XLEN),
  // memory
  parameter  int unsigned MEM_ADR,
  parameter  int unsigned MEM_SIZ,
  // miscellaneous
  parameter  int unsigned TIMEOUT
)(
  // TCB system bus
  tcb_if.mon tcb
);

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

  // HTIF halt
  logic htif_halt = 1'b0;

////////////////////////////////////////////////////////////////////////////////
// clock period counter
////////////////////////////////////////////////////////////////////////////////

  int unsigned cnt;
  bit timeout = 1'b0;
  
  // time counter
  always_ff @(posedge tcb.clk, posedge tcb.rst)
  if (tcb.rst) begin
    cnt <= 0;
    timeout <= 1'b0;
  end else begin
    cnt <= cnt+1;
    if (cnt == TIMEOUT) begin
      timeout <= 1'b1;
    end
  end

////////////////////////////////////////////////////////////////////////////////
// protocol checker
////////////////////////////////////////////////////////////////////////////////

  tcb_vip_protocol_checker tcb_chk (.tcb (tcb));

////////////////////////////////////////////////////////////////////////////////
// ELF file symbols
////////////////////////////////////////////////////////////////////////////////

  // signature memory
  logic [8-1:0] mem [MEM_ADR:MEM_ADR+MEM_SIZ-1];

  // symbol addresses
  logic [XLEN-1:0] begin_signature;
  logic [XLEN-1:0] end_signature  ;
  logic [XLEN-1:0] tohost         ;
  logic [XLEN-1:0] fromhost       ;

  initial
  begin
    // get/display ELF symbols from plusargs
    if ($value$plusargs("begin_signature=%h", begin_signature))  $display("HTIF: begin_signature = 0x%08h", begin_signature);  else  $fatal(0, "HTIF: ERROR: begin_signature $plusarg not found!");
    if ($value$plusargs("end_signature=%h"  , end_signature  ))  $display("HTIF: end_signature   = 0x%08h", end_signature  );  else  $fatal(0, "HTIF: ERROR: end_signature   $plusarg not found!");
    if ($value$plusargs("tohost=%h"         , tohost         ))  $display("HTIF: tohost          = 0x%08h", tohost         );  else  $fatal(0, "HTIF: ERROR: tohost          $plusarg not found!");
    if ($value$plusargs("fromhost=%h"       , fromhost       ))  $display("HTIF: fromhost        = 0x%08h", fromhost       );  else  $fatal(0, "HTIF: ERROR: fromhost        $plusarg not found!");
  end

////////////////////////////////////////////////////////////////////////////////
// signature memory
////////////////////////////////////////////////////////////////////////////////

  // local copies of TCB PHY parameters
  localparam UNT = tcb.PHY.UNT;
  localparam BEN = tcb.PHY_BEN;

  // request address and size (TCB_LOG_SIZE mode)
  int unsigned adr;
  int unsigned siz;

  // read/write data packed arrays
  logic [BEN-1:0][UNT-1:0] wdt;

  // request address and size (TCB_LOG_SIZE mode)
  assign adr =    int'(tcb.req.adr);
  assign siz = 2**int'(tcb.req.siz);

  // map write data to a packed array
  assign wdt = tcb.req.wdt;

  // write access
  always @(posedge tcb.clk)
  if (tcb.trn) begin
    if (tcb.req.wen) begin: write
      for (int unsigned b=0; b<BEN; b++) begin: bytes
        case (tcb.PHY.MOD)
          TCB_LOG_SIZE: begin: log_size
            // write only transfer size bytes
            if (b < siz)  mem[adr+b] <= wdt[b];
          end: log_size
          TCB_BYTE_ENA: begin: byte_ena
            // write only enabled bytes
            if (tcb.req.ben[(adr+b)%BEN])  mem[adr+b] <= wdt[(adr+b)%BEN];
          end: byte_ena
        endcase
      end: bytes
    end: write
  end

  // read binary into memory
  function int read_bin (string fn);
    int code;  // status code
    int fd;    // file descriptor
    bit [640-1:0] err;
    fd = $fopen(fn, "rb");
    code = $fread(mem, fd);
  `ifndef VERILATOR
    if (code == 0) begin
      code = $ferror(fd, err);
      $display("HTIF: read_bin: code = %d, err = %s", code, err);
    end else begin
      $display("HTIF: read %dB from binary file", code);
    end
  `endif
    $fclose(fd);
    return code;
  endfunction: read_bin

  // dump
  function void write_hex (string fn);
    int fd;    // file descriptor
    fd = $fopen(fn, "w");
    for (int unsigned addr=begin_signature; addr<end_signature; addr+=4) begin
      $fwrite(fd, "%h%h%h%h\n", mem[addr+3], mem[addr+2], mem[addr+1], mem[addr+0]);
    end
    $fclose(fd);
  endfunction: write_hex

////////////////////////////////////////////////////////////////////////////////
// HTIF
////////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge tcb.clk, posedge tcb.rst)
  if (tcb.rst) begin
    htif_halt <= 1'b0;
  end else if (tcb.trn) begin
    if (tcb.req.wen) begin
      // HTIF tohost
      if (tcb.req.adr == tohost) begin
        htif_halt <= tcb.req.wdt[0];
      end
    end
  end

  // finish simulation
  always @(posedge tcb.clk)
  if (htif_halt | timeout) begin
    string fn;  // file name
    if (htif_halt)  $display("HTIF: HALT");
    if (timeout  )  $display("HTIF: TIMEOUT");
    if ($value$plusargs("signature=%s", fn)) begin
      $display("HTIF: Saving signature file with data from 0x%8h to 0x%8h: %s", begin_signature, end_signature, fn);
      write_hex(fn);
    end else begin
      $display("HTIF: ERROR: signature save file plusarg not found.");
      $finish;
    end
    // a few more clock cycles
    repeat (16) @(posedge tcb.clk);
    $finish;
  end

  // at the end dump the test signature
  // TODO: not working in Verilator, at least if the C code ends the simulation.
  final begin
    $display("HTIF: FINAL");
    $display("HTIF: TIME: cnt = %d", cnt);
  end

endmodule: r5p_htif
