////////////////////////////////////////////////////////////////////////////////
// TCB: Tightly Coupled Bus monitor with RISC-V support
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

module r5p_mouse_tcb_mon
  import riscv_isa_pkg::*;
#(
  string NAME = "",   // monitored bus name
  // printout order
  int DLY_IFU = 0,  // printout delay for instruction fetch
  int DLY_LSU = 0,  // printout delay for load/store
  int DLY_GPR = 0,  // printout delay for GPR access
  // RISC-V ISA parameters
  isa_t  ISA,
  bit    ABI = 1'b1   // enable ABI translation for GPR names
)(
  // instruction execution phase
  input logic [3-1:0] pha,
  // system bus
  tcb_if.sub bus
);

  import riscv_asm_pkg::*;

  // FSM phases (GPR access phases can be decoded from a single bit)
  localparam logic [3-1:0] IF  = 3'b000;  // instruction fetch
  localparam logic [3-1:0] RS1 = 3'b101;  // read register source 1
  localparam logic [3-1:0] RS2 = 3'b110;  // read register source 1
  localparam logic [3-1:0] MLD = 3'b001;  // memory load
  localparam logic [3-1:0] MST = 3'b010;  // memory store
  localparam logic [3-1:0] EXE = 3'b011;  // execute (only used to evaluate branching condition)
  localparam logic [3-1:0] WB  = 3'b100;  // GPR write-back

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

  // system bus delayed by DLY clock periods
  tcb_if #(.PHY (bus.PHY)) dly (.clk (bus.clk), .rst (bus.rst));

  // phase delayed by DLY clock periods
  logic [3-1:0] dly_pha;

  // log signals
  logic [bus.PHY.ABW-1:0] adr;  // address
  logic                   wen;  // write enable
  logic [bus.PHY_BEW-1:0] ben;  // byte enable
  logic [bus.PHY.DBW-1:0] dat;  // data
  logic                   err;  // error

  // delayed signals
  always_ff @(posedge bus.clk, posedge bus.rst)
  if (bus.rst) begin
    // debug enable
    dly_pha <= 'x;
    // TCB
    dly.vld <= '0;
    dly.req <= '{default: 'x};
    dly.rsp <= '{default: 'x};
    dly.rdy <= '1;
  end else begin
    // debug enable
    dly_pha <= pha;
    // TCB
    dly.vld <= bus.vld;
    dly.req <= bus.req;
    dly.rsp <= bus.rsp;
    dly.rdy <= bus.rdy;
  end

////////////////////////////////////////////////////////////////////////////////
// protocol check
////////////////////////////////////////////////////////////////////////////////

// TODO: on reads where byte enables bits are not active

////////////////////////////////////////////////////////////////////////////////
// logging
////////////////////////////////////////////////////////////////////////////////

  // print-out delay queue
  string str_if [$];  // instruction fetch
  string str_wb [$];  // GPR write-back
  string str_ld [$];  // load
  string str_st [$];  // store

  // write/read signals
  always_comb
  begin
    adr <= dly.req.adr;
    wen <= dly.req.wen;
    ben <= dly.req.ben;
    if (dly.req.wen) begin
      dat <= dly.req.wdt;
    end else begin
      dat <= bus.rsp.rdt;
    end
    err <= bus.rsp.sts.err;
  end

  // format GPR string with desired whitespace
  function string format_gpr (logic [5-1:0] idx);
      if (idx < 10)  return($sformatf("x%0d ", idx));
      else           return($sformatf("x%0d", idx));
  endfunction: format_gpr

  // prepare string for each execution phase
  always_ff @(posedge bus.clk)
  begin
    if (dly.trn) begin
      // instruction fetch
      if (dly_pha == IF) begin
        str_if.push_front($sformatf(" 0x%8h (0x%8h)", adr, dat));
      end
      // GPR write-back (rs1/rs2 reads are not logged)
      if (dly_pha == WB) begin
        // byte enable signals are used to disable write to x0 GPR
        if (&ben) begin
            str_wb.push_front($sformatf(" %s 0x%8h", format_gpr(adr[2+:5]), dat));
        end
      end
      // memory load
      if (dly_pha == MLD) begin
        str_ld.push_front($sformatf(" mem 0x%8h", adr));
      end
      // memory store
      if (dly_pha == MST) begin
        str_st.push_front($sformatf(" mem 0x%8h 0x%8h", adr, dat));
      end
    end
  end

  // log file descriptor
  int fd;

  initial
  begin
    fd = $fopen("dut.log", "w");
  end

  logic log_trn = 1'b0;

  // prepare string for each execution phase
  always_ff @(posedge bus.clk)
  begin
    // at instruction fetch combine strings from precious instructions
    if (dly.trn) begin
      log_trn <= 1'b1;
      // instruction fetch
      if (dly_pha == IF) begin
        // skip first fetch
        if (log_trn) begin
            $fwrite(fd, "core   0: 3%s%s%s%s\n", str_if.pop_back(), str_wb.pop_back(), str_ld.pop_back(), str_st.pop_back());
        end
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

endmodule: r5p_mouse_tcb_mon
