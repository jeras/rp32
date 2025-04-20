////////////////////////////////////////////////////////////////////////////////
// R5P-mouse TCB monitor and execution trace logger logger
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

module r5p_mouse_trace_logger
  import riscv_isa_pkg::*;
  import riscv_isa_i_pkg::*;
  import tcb_pkg::*;
#(
  // log file name
  string LOG = ""
)(
  // instruction execution phase
  input logic [3-1:0] pha,
  // TCB system bus
  tcb_if.mon tcb
);

////////////////////////////////////////////////////////////////////////////////
// local parameters and signals
////////////////////////////////////////////////////////////////////////////////

  import riscv_asm_pkg::*;
  import tcb_pkg::*;

  // TODO: try to share this table with RTL, while keeping Verilog2005 compatibility ?
  // FSM phases (GPR access phases can be decoded from a single bit)
  localparam logic [3-1:0] IF  = 3'b000;  // instruction fetch
  localparam logic [3-1:0] RS1 = 3'b101;  // read register source 1
  localparam logic [3-1:0] RS2 = 3'b110;  // read register source 1
  localparam logic [3-1:0] MLD = 3'b001;  // memory load
  localparam logic [3-1:0] MST = 3'b010;  // memory store
  localparam logic [3-1:0] EXE = 3'b011;  // execute (only used to evaluate branching condition)
  localparam logic [3-1:0] WB  = 3'b100;  // GPR write-back

  // log file name and descriptor
  string fn;  // file name
  int fd;

  // print-out delay queue
  string str_if [$];  // instruction fetch
  string str_wb [$];  // GPR write-back
  string str_ld [$];  // load
  string str_st [$];  // store

////////////////////////////////////////////////////////////////////////////////
// logging (matching spike simulator logs)
////////////////////////////////////////////////////////////////////////////////

  // format GPR string with desired whitespace
  function string format_gpr (logic [5-1:0] idx);
      if (idx < 10)  return($sformatf("x%0d ", idx));
      else           return($sformatf("x%0d", idx));
  endfunction: format_gpr

  // prepare string for each execution phase
  always_ff @(posedge tcb.clk)
  begin
    if ($past(tcb.trn)) begin
      // instruction fetch
      if ($past(pha) == IF) begin
        str_if.push_front($sformatf(" 0x%8h (0x%8h)", $past(tcb.req.adr), tcb.rsp.rdt));
      end
      // GPR write-back (rs1/rs2 reads are not logged)
      if ($past(pha) == WB) begin
        str_wb.push_front($sformatf(" %s 0x%8h", format_gpr($past(tcb.req.adr[2+:5])), $past(tcb.req.wdt)));
      end
      // memory load
      if ($past(pha) == MLD) begin
        str_ld.push_front($sformatf(" mem 0x%8h", $past(tcb.req.adr)));
      end
      // memory store
      if ($past(pha) == MST) begin
        case ($past(tcb.req.siz))
          2'd0: str_st.push_front($sformatf(" mem 0x%8h 0x%2h", $past(tcb.req.adr), $past(tcb.req.wdt[ 8-1:0])));
          2'd1: str_st.push_front($sformatf(" mem 0x%8h 0x%4h", $past(tcb.req.adr), $past(tcb.req.wdt[16-1:0])));
          2'd2: str_st.push_front($sformatf(" mem 0x%8h 0x%8h", $past(tcb.req.adr), $past(tcb.req.wdt[32-1:0])));
        endcase
      end
    end
  end

  // prepare string for committed instruction
  always_ff @(posedge tcb.clk)
  begin
    // only log if a log file was opened
    if (fd) begin
      // at instruction fetch combine strings from previous instructions
      if ($past(tcb.trn)) begin
        // instruction fetch
        if ($past(pha) == IF) begin
          // skip first fetch
          if (~$past(tcb.rst,3)) begin
              $fwrite(fd, "core   0: 3%s%s%s%s\n", str_if.pop_back(), str_wb.pop_back(), str_ld.pop_back(), str_st.pop_back());
          end
        end
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

endmodule: r5p_mouse_trace_logger
