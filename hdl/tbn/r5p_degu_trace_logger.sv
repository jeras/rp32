////////////////////////////////////////////////////////////////////////////////
// R5P-degu TCB monitor and execution trace logger
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

module r5p_degu_trace_logger
  import riscv_isa_pkg::*;
  import riscv_isa_i_pkg::*;
#(
  // constants used across the design in signal range sizing instead of literals
  localparam int unsigned XLEN = 32,
  localparam int unsigned XLOG = $clog2(XLEN),
  // log file name
  string LOG = "",
  // TODO: check for GPR size differently
  parameter  int unsigned GNUM = 32,
  localparam int unsigned GLOG = $clog2(GNUM),
  // RISC-V ISA parameters
  isa_t  ISA,
  bit    ABI = 1'b1   // enable ABI translation for GPR names
)(
  // GPR array
  input logic            gpr_wen,
  input logic [GLOG-1:0] gpr_wid,
  input logic [XLEN-1:0] gpr_wdt,
  // TCB IFU/LSU system busses
  tcb_if.mon tcb_ifu,
  tcb_if.mon tcb_lsu
);

////////////////////////////////////////////////////////////////////////////////
// local parameters and signals
////////////////////////////////////////////////////////////////////////////////

  import riscv_asm_pkg::*;
  import tcb_pkg::*;

  // log file name and descriptor
  string fn;  // file name
  int fd;

  // print-out delay queue
  string str_ifu [$];  // instruction fetch
  string str_gpr [$];  // GPR write-back
  string str_lsu [$];  // load

////////////////////////////////////////////////////////////////////////////////
// logging (matching spike simulator logs)
////////////////////////////////////////////////////////////////////////////////

  // initialize dummy data into the queue to enforce order
  initial
  begin
    str_gpr = '{};
    str_lsu = '{};
    str_ifu = '{""};
  end

  // format GPR string with desired whitespace
  function string format_gpr (logic [5-1:0] idx);
      if (idx < 10)  return($sformatf("x%0d ", idx));
      else           return($sformatf("x%0d", idx));
  endfunction: format_gpr

  // instruction fetch
  always_ff @(posedge tcb_ifu.clk)
  begin
    if ($past(tcb_ifu.trn)) begin
      if (opsiz(tcb_ifu.rsp.rdt) == 4) begin
        str_ifu.push_front($sformatf(" 0x%8h (0x%8h)", $past(tcb_ifu.req.adr), tcb_ifu.rsp.rdt));
      end else begin
        str_ifu.push_front($sformatf(" 0x%8h (0x%4h)", $past(tcb_ifu.req.adr), tcb_ifu.rsp.rdt[16-1:0]));
      end
    end
  end

  // GPR write-back (rs1/rs2 reads are not logged)
  always_ff @(posedge tcb_ifu.clk)
  begin
    if ($past(tcb_ifu.trn)) begin
      if (gpr_wen) begin
        // ignore GPR x0
        if (gpr_wid != 0) begin
            str_gpr.push_front($sformatf(" %s 0x%8h", format_gpr(gpr_wid), gpr_wdt));
        end
      end else begin
        str_gpr.push_front("");
      end
    end
  end

  // memory load/store
  always_ff @(posedge tcb_lsu.clk)
  begin
    if ($past(tcb_lsu.trn)) begin
      if ($past(tcb_lsu.req.wen)) begin
        // memory store
        str_lsu.push_front($sformatf(" mem 0x%8h 0x%8h", $past(tcb_lsu.req.adr), $past(tcb_lsu.req.wdt)));
      end else begin
        // memory load
        str_lsu.push_front($sformatf(" 0x%8h (0x%8h)", $past(tcb_lsu.req.adr), tcb_lsu.rsp.rdt));
      end
    end
  end

  // prepare string for committed instruction
  always_ff @(posedge tcb_ifu.clk)
  begin
    // only log if a log file was opened
    if (fd) begin
      // at instruction fetch combine strings from previous instructions
      if ($past(tcb_ifu.trn)) begin
        $fwrite(fd, "core   0: 3%s%s%s\n", str_ifu.pop_back(), str_gpr.pop_back(), str_lsu.pop_back());
      end
    end
  end

  // open log file if name is given by parameter
  initial
  begin
    // log file if name is given by parameter
    if ($value$plusargs("log=%s", fn)) begin
    end
    // log file with filename obtained through plusargs
    else if (LOG) begin
      fn = LOG;
    end
    if (fn) begin
      fd = $fopen(fn, "w");
      $display("LOGGING: opened log file: '%s'.", fn);
    end else begin
      $display("LOGGING: no log file name was provided.");
    end
  end

  final
  begin
    $fclose(fd);
    $display("LOGGING: closed log file: '%s'.", fn);
  end

////////////////////////////////////////////////////////////////////////////////
// statistics
////////////////////////////////////////////////////////////////////////////////

endmodule: r5p_degu_trace_logger
