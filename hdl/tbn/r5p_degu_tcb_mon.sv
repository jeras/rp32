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
#(
  // constants used across the design in signal range sizing instead of literals
  localparam int unsigned XLEN = 32,
  localparam int unsigned XLOG = $clog2(XLEN),
  // log file name
  string LOG = "",
  // TODO: check for GPR size differently
  parameter int unsigned GPRS = 32,
  // RISC-V ISA parameters
  isa_t  ISA,
  bit    ABI = 1'b1   // enable ABI translation for GPR names
)(
  // GPR array
  // TODO: support RV32E
  input logic [XLEN-1:0] gpr [0:GPRS-1],
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

  // GPR delayed
  logic [XLEN-1:0] dly_gpr [0:GPRS-1];

//  // log signals
//  logic [tcb.PHY.ABW-1:0] adr;  // address
//  logic                   wen;  // write enable
//  logic           [3-1:0] fn3;  // RISC-V func3
//  logic [tcb.PHY.DBW-1:0] dat;  // data
//  logic                   err;  // error

////////////////////////////////////////////////////////////////////////////////
// delay TCB signals
////////////////////////////////////////////////////////////////////////////////

  // GPR delayed signals
  always_ff @(posedge tcb_ifu.clk, posedge tcb_ifu.rst)
  if (tcb_ifu.rst) begin
    dly_gpr <= '{default: 'x};
  end else begin
    dly_gpr <= gpr;
  end

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
  string str_if [$];  // instruction fetch
  string str_wb [$];  // GPR write-back
  string str_ld [$];  // load
  string str_st [$];  // store

  // format GPR string with desired whitespace
  function string format_gpr (logic [5-1:0] idx);
      if (idx < 10)  return($sformatf("x%0d ", idx));
      else           return($sformatf("x%0d", idx));
  endfunction: format_gpr

  // instruction fetch
  always_ff @(posedge dly_ifu.clk)
  begin
    if (dly_ifu.trn) begin
      str_if.push_front($sformatf(" 0x%8h (0x%8h)", dly_ifu.req.adr, tcb_ifu.rsp.rdt));
    end
  end

  // GPR write-back (rs1/rs2 reads are not logged)
  always_ff @(posedge dly_ifu.clk)
  begin
    // ignore GPR x0
    for (int unsigned i=1; i<GPRS; i++) begin
      if (dly_gpr[i] != gpr[i]) begin
          str_wb.push_front($sformatf(" %s 0x%8h", format_gpr(i), dly_gpr[i]));
      end
    end
  end

  // memory load/store
  always_ff @(posedge dly_lsu.clk)
  begin
    if (dly_lsu.trn) begin
      if (dly_lsu.req.wen) begin
        // memory store
        str_st.push_front($sformatf(" mem 0x%8h 0x%8h", dly_lsu.req.adr, tcb_lsu.req.wdt));
      end else begin
        // memory load
        str_if.push_front($sformatf(" 0x%8h (0x%8h)", dly_lsu.req.adr, tcb_lsu.rsp.rdt));
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
        $fwrite(fd, "core   0: 3%s%s%s%s\n", str_if.pop_back(), str_wb.pop_back(), str_ld.pop_back(), str_st.pop_back());
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
