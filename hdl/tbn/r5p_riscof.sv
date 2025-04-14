////////////////////////////////////////////////////////////////////////////////
// R5P RISCOF controller
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

module r5p_riscof
import riscv_isa_pkg::*;
import tcb_pkg::*;
#(
  // constants used across the design in signal range sizing instead of literals
  localparam int unsigned XLEN = 32,
  localparam int unsigned XLOG = $clog2(XLEN),
  // miscelaneous
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

  // symbol addresses
  logic [XLEN-1:0] begin_signature;
  logic [XLEN-1:0] end_signature  ;
  logic [XLEN-1:0] tohost         ;
  logic [XLEN-1:0] fromhost       ;

  // signature memory
  int unsigned signature_size;
  logic [8-1:0] signature [];

  initial
  begin
    // get ELF symbols from plusargs
    void'($value$plusargs("begin_signature=%0h", begin_signature));
    void'($value$plusargs("end_signature=%0h"  , end_signature  ));
    void'($value$plusargs("tohost=%0h"         , tohost         ));
    void'($value$plusargs("fromhost=%0h"       , fromhost       ));
    // display ELF symbols
    $display("begin_signature = 0x%08h", begin_signature);
    $display("end_signature   = 0x%08h", end_signature  );
    $display("tohost          = 0x%08h", tohost         );
    $display("fromhost        = 0x%08h", fromhost       );
    // allocate signature memory
    signature_size = int'(end_signature) - int'(begin_signature);
    signature = new[signature_size];
  end

////////////////////////////////////////////////////////////////////////////////
// signature memory
////////////////////////////////////////////////////////////////////////////////

  // request address and size (TCB_LOG_SIZE mode)
  int unsigned adr;
  int unsigned siz;

  // read/write data packed arrays
  logic [tcb.PHY_BEN-1:0][tcb.PHY.UNT-1:0] wdt;

  // request address and size (TCB_LOG_SIZE mode)
  assign adr =    int'(tcb.req.adr) - int'(begin_signature);
  assign siz = 2**int'(tcb.req.siz);

  // map write data to a packed array
  assign wdt = tcb.req.wdt;

  // write access
  always @(posedge tcb.clk)
  if (tcb.trn) begin
    if (tcb.req.wen) begin: write
      for (int unsigned b=0; b<tcb.PHY_BEN; b++) begin: bytes
        if (adr+b < signature_size) begin: decode
          case (tcb.PHY.MOD)
            TCB_LOG_SIZE: begin: log_size
              // write only transfer size bytes
              // TODO: Questa: Non-blocking assignment to elements of dynamic arrays is not currently supported.
              //if (b < siz)  signature[adr+b] <= wdt[b];
              if (b < siz)  signature[adr+b] = wdt[b];
            end: log_size
            TCB_BYTE_ENA: begin: byte_ena
              // write only enabled bytes
              // TODO: Questa: Non-blocking assignment to elements of dynamic arrays is not currently supported.
              //if (tcb.req.ben[(adr+b)%tcb.PHY_BEN])  signature[adr+b] <= wdt[(adr+b)%tcb.PHY_BEN];
              if (tcb.req.ben[(adr+b)%tcb.PHY_BEN])  signature[adr+b] = wdt[(adr+b)%tcb.PHY_BEN];
            end: byte_ena
          endcase
        end: decode
      end: bytes
    end: write
  end

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

  // dump
  function void write_hex (string fn);
    int fd;    // file descriptor
    fd = $fopen(fn, "w");
    for (int unsigned addr=0; addr<signature_size; addr+=4) begin
      $fwrite(fd, "%h%h%h%h\n", signature[addr+3], signature[addr+2], signature[addr+1], signature[addr+0]);
    end
    $fclose(fd);
  endfunction: write_hex

  // finish simulation
  always @(posedge tcb.clk)
  if (htif_halt | timeout) begin
    string fn;  // file name
    if (htif_halt)  $display("RISCOF: HALT");
    if (timeout  )  $display("RISCOF: TIMEOUT");
    if ($value$plusargs("signature=%s", fn)) begin
      $display("RISCOF: Saving signature file with data from 0x%8h to 0x%8h: %s", begin_signature, end_signature, fn);
      write_hex(fn);
      $display("RISCOF: Saving signature to file: '%s'.", fn);
    end else begin
      $display("RISCOF: ERROR: signature save file plusarg not found.");
      $finish;
    end
    // a few more clock cycles
    repeat (16) @(posedge tcb.clk);
    $finish;
  end

  // at the end dump the test signature
  // TODO: not working in Verilator, at least if the C code ends the simulation.
  final begin
    $display("RISCOF: FINAL");
    $display("RISCOF: TIME: cnt = %d", cnt);
  end

endmodule: r5p_riscof
