////////////////////////////////////////////////////////////////////////////////
// R5P-degu TCB monitor and execution logger
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

module r5p_degu_tcb_mon
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

  import riscv_asm_pkg::*;
  import tcb_pkg::*;

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

  // TCB IFU/LSU system busses delayed by DLY clock periods
  tcb_if #(.PHY (tcb_ifu.PHY)) dly_ifu (.clk (tcb_ifu.clk), .rst (tcb_ifu.rst));
  tcb_if #(.PHY (tcb_lsu.PHY)) dly_lsu (.clk (tcb_lsu.clk), .rst (tcb_lsu.rst));

////////////////////////////////////////////////////////////////////////////////
// delay TCB signals
////////////////////////////////////////////////////////////////////////////////

  // TCB IFU delayed signals
  always_ff @(posedge tcb_ifu.clk, posedge tcb_ifu.rst)
  if (tcb_ifu.rst) begin
    dly_ifu.vld <= '0;
    dly_ifu.req <= '{default: 'x};
    dly_ifu.rsp <= '{default: 'x};
    dly_ifu.rdy <= '1;
  end else begin
    dly_ifu.vld <= tcb_ifu.vld;
    dly_ifu.req <= tcb_ifu.req;
    dly_ifu.rsp <= tcb_ifu.rsp;
    dly_ifu.rdy <= tcb_ifu.rdy;
  end

  // TCB LSU delayed signals
  always_ff @(posedge tcb_lsu.clk, posedge tcb_lsu.rst)
  if (tcb_lsu.rst) begin
    dly_lsu.vld <= '0;
    dly_lsu.req <= '{default: 'x};
    dly_lsu.rsp <= '{default: 'x};
    dly_lsu.rdy <= '1;
  end else begin
    dly_lsu.vld <= tcb_lsu.vld;
    dly_lsu.req <= tcb_lsu.req;
    dly_lsu.rsp <= tcb_lsu.rsp;
    dly_lsu.rdy <= tcb_lsu.rdy;
  end

////////////////////////////////////////////////////////////////////////////////
// logging (matching spike simulator logs)
////////////////////////////////////////////////////////////////////////////////

  // print-out delay queue
  string str_ifu [$];  // instruction fetch
  string str_gpr [$];  // GPR write-back
  string str_lsu [$];  // load

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
  always_ff @(posedge dly_ifu.clk)
  begin
    if (dly_ifu.trn) begin
      if (opsiz(tcb_ifu.rsp.rdt) == 4) begin
        str_ifu.push_front($sformatf(" 0x%8h (0x%8h)", dly_ifu.req.adr, tcb_ifu.rsp.rdt));
      end else begin
        str_ifu.push_front($sformatf(" 0x%8h (0x%4h)", dly_ifu.req.adr, tcb_ifu.rsp.rdt[16-1:0]));
      end
    end
  end

  // GPR write-back (rs1/rs2 reads are not logged)
  always_ff @(posedge dly_ifu.clk)
  begin
    if (dly_ifu.trn) begin
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
  always_ff @(posedge dly_lsu.clk)
  begin
    if (dly_lsu.trn) begin
      if (dly_lsu.req.wen) begin
        // memory store
        str_lsu.push_front($sformatf(" mem 0x%8h 0x%8h", dly_lsu.req.adr, dly_lsu.req.wdt));
      end else begin
        // memory load
        str_lsu.push_front($sformatf(" 0x%8h (0x%8h)", dly_lsu.req.adr, tcb_lsu.rsp.rdt));
      end
    end
  end

  // log file descriptor
  int fd;

  // open log file if name is given by parameter
  initial
  begin
    if (LOG) begin
      fd = $fopen(LOG, "w");
    end
  end

  // prepare string for each execution phase
  always_ff @(posedge dly_ifu.clk)
  begin
    // only log if a log file was opened
    if (fd) begin
      // at instruction fetch combine strings from precious instructions
      if (dly_ifu.trn) begin
        $fwrite(fd, "core   0: 3%s%s%s\n", str_ifu.pop_back(), str_gpr.pop_back(), str_lsu.pop_back());
      end
    end
  end

  final
  begin
    $fclose(fd);
  end

////////////////////////////////////////////////////////////////////////////////
// statistics
////////////////////////////////////////////////////////////////////////////////

endmodule: r5p_degu_tcb_mon
