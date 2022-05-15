////////////////////////////////////////////////////////////////////////////////
// TCB: Tightly Coupled Bus decoder
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

module tcb_dec #(
  // bus parameters
  int unsigned AW = 32,    // address width
  int unsigned DW = 32,    // data width
  // interconnect parameters
  int unsigned PN = 2,     // port number
  logic [PN-1:0] [AW-1:0] AS = '{PN{'x}}
)(
  tcb_if.sub s        ,  // TCB subordinate port  (manager     device connects here)
  tcb_if.man m[PN-1:0]   // TCB manager     ports (subordinate devices connect here)
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

// report address range overlapping
// TODO

////////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

// decoder/multiplexer signals
logic [PN-1:0] s_dec;
logic [SW-1:0] s_sel;
logic [SW-1:0] m_sel;

logic [DW-1:0] t_rdt [PN-1:0];  // read data
logic          t_err [PN-1:0];  // error
logic          t_rdy [PN-1:0];  // acknowledge

genvar i;

////////////////////////////////////////////////////////////////////////////////
// decoder
////////////////////////////////////////////////////////////////////////////////

// address range decoder into one hot vector
generate
for (i=0; i<PN; i++) begin: gen_dec
  assign s_dec[i] = s.adr ==? AS[i];
end: gen_dec
endgenerate

// priority encoder
assign s_sel = clog2(s_dec);

// multiplexer select
always_ff @(posedge s.clk, posedge s.rst)
if (s.rst) begin
  m_sel <= '0;
end else if (s.vld & s.rdy) begin
  m_sel <= s_sel;
end

////////////////////////////////////////////////////////////////////////////////
// request
////////////////////////////////////////////////////////////////////////////////

// replicate request signals
generate
for (i=0; i<PN; i++) begin: gen_req
  assign m[i].vld = s_dec[i] ? s.vld : '0;
  assign m[i].wen = s_dec[i] ? s.wen : 'x;
  assign m[i].ben = s_dec[i] ? s.ben : 'x;
  assign m[i].adr = s_dec[i] ? s.adr : 'x;
  assign m[i].wdt = s_dec[i] ? s.wdt : 'x;
end: gen_req
endgenerate

////////////////////////////////////////////////////////////////////////////////
// response
////////////////////////////////////////////////////////////////////////////////

// organize response signals into indexable array
// since a dynamix index can't be used on an array of interfaces
generate
for (i=0; i<PN; i++) begin: gen_rsp
  assign t_rdt[i] = m[i].rdt;
  assign t_err[i] = m[i].err;
  assign t_rdy[i] = m[i].rdy;
end: gen_rsp
endgenerate

// multiplexer
assign s.rdt = t_rdt[m_sel];  // response phase
assign s.err = t_err[m_sel];  // response phase
assign s.rdy = t_rdy[s_sel];  // request  phase

endmodule: tcb_dec