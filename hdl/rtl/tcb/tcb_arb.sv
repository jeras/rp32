////////////////////////////////////////////////////////////////////////////////
// TCB: Tightly Coupled Bus arbiter
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

module tcb_arb #(
  // bus parameters
  int unsigned AW = 32,    // address width
  int unsigned DW = 32,    // data    width
  int unsigned BW = DW/8,  // byte e. width
  // interconnect parameters
  int unsigned PN = 2,     // port number
  // arbitration priority mode
  string       MD = "FX",  // "FX" - fixed priority
                           // "RR" - round robin (TODO)
  // port priorities (lower number is higher priority)
  int unsigned PRI [0:PN-1] = '{0, 1}
)(
  tcb_if.sub s[PN-1:0],  // TCB subordinate ports (manager     devices connect here)
  tcb_if.man m           // TCB manager     port  (subordinate device connects here)
);

// multiplexer select width
localparam SW = $clog2(PN);

// priority encoder
function [SW-1:0] clog2 (logic [PN-1:0] val);
  clog2 = 'x;  // optimization of undefined encodings
  for (int unsigned i=0; i<PN; i++) begin
    if (val[i])  clog2 = i[SW-1:0];
  end
endfunction: clog2

// report priority duplication
// TODO

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

// arbiter/multiplexer signals
logic [PN-1:0] s_arb;
logic [SW-1:0] s_sel;
logic [SW-1:0] m_sel;

logic          t_vld [PN-1:0];  // valid
logic          t_wen [PN-1:0];  // write enable
logic [AW-1:0] t_adr [PN-1:0];  // address
logic [BW-1:0] t_ben [PN-1:0];  // byte enable
logic [DW-1:0] t_wdt [PN-1:0];  // write data

genvar i;

////////////////////////////////////////////////////////////////////////////////
// arbiter
////////////////////////////////////////////////////////////////////////////////

// organize priority order
generate
for (i=0; i<PN; i++) begin: gen_arb
  assign s_arb[i] = t_vld[PRI[i]];
end: gen_arb
endgenerate

// simple priority arbiter
assign s_sel = PRI[clog2(s_arb)];

// multiplexer integer select
always_ff @(posedge m.clk, posedge m.rst)
if (s.rst) begin
  m_sel <= '0;
end else if (m.vld & m.rdy) begin
  m_sel <= s_sel;
end

////////////////////////////////////////////////////////////////////////////////
// request
////////////////////////////////////////////////////////////////////////////////

// organize request signals into indexable array
// since a dynamix index can't be used on an array of interfaces
generate
for (i=0; i<PN; i++) begin: gen_req
  assign t_vld[i] = s.vld[i];
  assign t_wen[i] = s.wen[i];
  assign t_ben[i] = s.ben[i];
  assign t_adr[i] = s.adr[i];
  assign t_wdt[i] = s.wdt[i];
end: gen_req
endgenerate

// multiplexer
assign m.vld = t_vld[s_sel];
assign m.wen = t_wen[s_sel];
assign m.ben = t_ben[s_sel];
assign m.adr = t_adr[s_sel];
assign m.wdt = t_wdt[s_sel];

////////////////////////////////////////////////////////////////////////////////
// response
////////////////////////////////////////////////////////////////////////////////

// replicate response signals
generate
for (i=0; i<PN; i++) begin: gen_rsp
  assign s[i].rdt = (m_sel == i[SW-1:0]) ? m.rdt : 'x;  // response phase
  assign s[i].err = (m_sel == i[SW-1:0]) ? m.err : 'x;  // response phase
  assign s[i].rdy = (s_sel == i[SW-1:0]) ? m.rdy : '0;  // request  phase
end: gen_rsp
endgenerate

endmodule: tcb_arb