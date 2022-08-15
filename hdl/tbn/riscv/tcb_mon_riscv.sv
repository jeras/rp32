////////////////////////////////////////////////////////////////////////////////
// TCB: Tightly Coupled Bus monitorwith RISC-V support
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

module tcb_mon_riscv
  import riscv_isa_pkg::*;
#(
  string NAME = "",   // monitored bus name
  // TCB parameters
  // DODO: DLY
  // RISC-V ISA parameters
  isa_t  ISA,
  bit    ABI = 1'b1   // enable ABI translation for GPIO names
)(
  // debug mode enable (must be active with VALID)
  input logic dbg_ifu,  // indicator of instruction fetch
  input logic dbg_lsu,  // indicator of load/store
  input logic dbg_gpr,  // indicator of GPR access
  // system bus
  tcb_if.sub bus
);

import riscv_asm_pkg::*;

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

// system bus delayed by DLY clock periods
tcb_if #(.AW (bus.AW), .DW (bus.DW)) dly (.clk (bus.clk), .rst (bus.rst));

// debug mode enable delayed by DLY clock periods
logic dly_ifu;  // indicator of instruction fetch
logic dly_lsu;  // indicator of load/store
logic dly_gpr;  // indicator of GPR access

// log signals
logic [bus.AW-1:0] adr;  // address
logic [bus.BW-1:0] ben;  // byte enable
logic [bus.DW-1:0] dat;  // data
logic              err;  // error

// delayed signals
always_ff @(posedge bus.clk, posedge bus.rst)
if (bus.rst) begin
  // debug enable
  dly_ifu <= 'x;
  dly_lsu <= 'x;
  dly_gpr <= 'x;
  // TCB
  dly.vld <= '0;
  dly.wen <= 'x;
  dly.adr <= 'x;
  dly.ben <= 'x;
  dly.wdt <= 'x;
  dly.rdt <= 'x;
  dly.err <= 'x;
  dly.rdy <= 'x;
end else begin
  // debug enable
  dly_ifu <= dbg_ifu;
  dly_lsu <= dbg_lsu;
  dly_gpr <= dbg_gpr;
  // TCB
  dly.vld <= bus.vld;
  dly.wen <= bus.wen;
  dly.adr <= bus.adr;
  dly.ben <= bus.ben;
  dly.wdt <= bus.wdt;
  dly.rdt <= bus.rdt;
  dly.err <= bus.err;
  dly.rdy <= bus.rdy;
end

////////////////////////////////////////////////////////////////////////////////
// protocol check
////////////////////////////////////////////////////////////////////////////////

// TODO: on reads where byte enables bits are not active

////////////////////////////////////////////////////////////////////////////////
// logging
////////////////////////////////////////////////////////////////////////////////

string dir;  // direction
string txt;  // decoded data

always @(posedge bus.clk)
if (dly.vld & dly.rdy) begin
  // write/read
  adr = dly.adr;
  ben = dly.ben;
  if (dly.wen) begin
    dir = "WR";
    dat = dly.wdt;
  end else begin
    dir = "RD";
    dat = bus.rdt;
  end
  err = bus.err;
  // common text
  txt = $sformatf("%s: %s adr=0x%h ben=0b%b dat=0x%h err=%b", NAME, dir, adr, ben, dat, err);
  // instruction, load/store, GPR
  if (dly_ifu)  $display("%s | IFU: %s", txt, disasm(ISA, dat, ABI));
  if (dly_lsu)  $display("%s | LSU: %s", txt, $sformatf("%s", dat));
  if (dly_gpr)  $display("%s | GPR: %s", txt, $sformatf("%s %s %08h", gpr_n(adr[2+5-1:2], ABI), dly.wen ? "<=" : "=>", dat));
end

////////////////////////////////////////////////////////////////////////////////
// statistics
////////////////////////////////////////////////////////////////////////////////

// TODO add delay counter, statistics

endmodule: tcb_mon_riscv
