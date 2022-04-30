////////////////////////////////////////////////////////////////////////////////
// r5p system bus monitor
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

module tcb_mon #(
  string NAME = "",   // monitored bus name
  string MODE = "D",  // modes are D-data and I-instruction
  isa_t  ISA,
  bit    ABI = 1'b1   // enable ABI translation for GPIO names
)(
  // system bus
  tcb_if.sub bus
);

import riscv_asm_pkg::*;

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

// system bus delayed by one clock period
tcb_if #(.AW (bus.AW), .DW (bus.DW)) dly (.clk (bus.clk), .rst (bus.rst));

// log signals
logic [bus.AW-1:0] adr;  // address
logic [bus.BW-1:0] ben;  // byte enable
logic [bus.DW-1:0] dat;  // data

// delayed signals
always_ff @(posedge bus.clk, posedge bus.rst)
if (bus.rst) begin
  dly.vld <= '0;
  dly.wen <= 'x;
  dly.ben <= 'x;
  dly.adr <= 'x;
  dly.wdt <= 'x;
  dly.rdt <= 'x;
  dly.rdy <= 'x;
end else begin
  dly.vld <= bus.vld;
  dly.wen <= bus.wen;
  dly.ben <= bus.ben;
  dly.adr <= bus.adr;
  dly.wdt <= bus.wdt;
  dly.rdt <= bus.rdt;
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
  // write/read direction
  if (dly.wen) begin
    dir = "W";
    ben = dly.ben;
    adr = dly.adr;
    dat = dly.wdt;
  end else begin
    dir = "R";
    ben = dly.ben;
    adr = dly.adr;
    dat = bus.rdt;
  end
  // data/instruction
  if (MODE == "D")  txt = $sformatf("%s", dat);
  if (MODE == "I")  txt = disasm(ISA, dat, ABI);
  // log printout
  $display("%s: %s adr=0x%h dat=0x%h ben=0b%b, txt=\"%s\"", NAME, dir, adr, dat, ben, txt);
end

////////////////////////////////////////////////////////////////////////////////
// statistics
////////////////////////////////////////////////////////////////////////////////

// TODO add delay counter, statistics

endmodule: tcb_mon