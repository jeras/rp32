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
  // log file name
  string LOG = "",
  // RISC-V ISA parameters
  isa_t  ISA,
  bit    ABI = 1'b1   // enable ABI translation for GPR names
)(
  // instruction execution phase
  input logic [3-1:0] pha,
  // TCB system bus
  tcb_if.sub tcb
);

  import riscv_asm_pkg::*;
  import tcb_pkg::*;

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

  // TCB system bus delayed by DLY clock periods
  tcb_if #(.PHY (tcb.PHY)) dly (.clk (tcb.clk), .rst (tcb.rst));

  // phase delayed by DLY clock periods
  logic [3-1:0] dly_pha;

  // log signals
  logic [tcb.PHY.ABW-1:0] adr;  // address
  logic                   wen;  // write enable
  logic           [3-1:0] fn3;  // RISC-V func3
  logic [tcb.PHY.DBW-1:0] dat;  // data
  logic                   err;  // error

////////////////////////////////////////////////////////////////////////////////
// delay TCB signals
////////////////////////////////////////////////////////////////////////////////

  // delayed signals
  always_ff @(posedge tcb.clk, posedge tcb.rst)
  if (tcb.rst) begin
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
    dly.vld <= tcb.vld;
    dly.req <= tcb.req;
    dly.rsp <= tcb.rsp;
    dly.rdy <= tcb.rdy;
  end

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
    adr <=  dly.req.adr;
    wen <=  dly.req.wen;
    fn3 <= {dly.req.uns,
            dly.req.siz};
    if (dly.req.wen) begin
      dat <= dly.req.wdt;
    end else begin
      dat <= tcb.rsp.rdt;
    end
    err <= tcb.rsp.sts.err;
  end

  // format GPR string with desired whitespace
  function string format_gpr (logic [5-1:0] idx);
      if (idx < 10)  return($sformatf("x%0d ", idx));
      else           return($sformatf("x%0d", idx));
  endfunction: format_gpr

  // prepare string for each execution phase
  always_ff @(posedge tcb.clk)
  begin
    if (dly.trn) begin
      // instruction fetch
      if (dly_pha == IF) begin
        str_if.push_front($sformatf(" 0x%8h (0x%8h)", adr, dat));
      end
      // GPR write-back (rs1/rs2 reads are not logged)
      if (dly_pha == WB) begin
        // byte enable signals are used to disable write to x0 GPR
        if (fn3 == {1'b0, 2'b10}) begin
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

  // open log file if name is given by parameter
  initial
  begin
    if (LOG) begin
      fd = $fopen(LOG, "w");
    end
  end

  // skip retirement of reset JAL instruction
  logic log_trn = 1'b0;

  // prepare string for each execution phase
  always_ff @(posedge tcb.clk)
  begin
    // only log if a log file was opened
    if (fd) begin
      // at instruction fetch combine strings from precious instructions
      if (dly.trn) begin
        // skip retirement of reset JAL instruction
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
  end

  final
  begin
    $fclose(fd);
  end

////////////////////////////////////////////////////////////////////////////////
// statistics
////////////////////////////////////////////////////////////////////////////////

endmodule: r5p_degu_tcb_mon
