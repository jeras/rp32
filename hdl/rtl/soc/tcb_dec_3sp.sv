////////////////////////////////////////////////////////////////////////////////
// TCB: Tightly Coupled Bus decoder (custom RTL with 3 subordinate ports)
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
////////////////////////////////////////////////////////////////////////////////

module tcb_dec_3sp #(
  // bus parameters
  int unsigned AW = 32,    // address width
  int unsigned DW = 32,    // data width
  // interconnect parameters
  int unsigned PN = 3,     // port number (do not change)
  logic [PN-1:0] [AW-1:0] AS = PN'('x)
)(
  tcb_if.sub sub ,  // TCB subordinate port  (manager     device connects here)
  tcb_if.man man0,  // TCB manager     ports (subordinate devices connect here)
  tcb_if.man man1,  // TCB manager     ports (subordinate devices connect here)
  tcb_if.man man2   // TCB manager     ports (subordinate devices connect here)
);

  genvar i;

////////////////////////////////////////////////////////////////////////////////
// map interfaces into an array
////////////////////////////////////////////////////////////////////////////////

tcb_if #(.AW (AW), .DW (DW)) man [PN-1:0] (.clk (sub.clk), .rst (sub.rst));

tcb_pas pas0 (.sub (man0), .man (man[0]));
tcb_pas pas1 (.sub (man1), .man (man[1]));
tcb_pas pas2 (.sub (man2), .man (man[2]));

////////////////////////////////////////////////////////////////////////////////
// parameter validation
////////////////////////////////////////////////////////////////////////////////

// camparing subordinate and manager interface parameters
generate
for (i=0; i<PN; i++) begin
  if (sub.DW  != man[i].DW )  $error("ERROR: %m parameter DW  validation failed");
  if (sub.DW  != man[i].DW )  $error("ERROR: %m parameter DW  validation failed");
  if (sub.BW  != man[i].BW )  $error("ERROR: %m parameter SW  validation failed");
  if (sub.DLY != man[i].DLY)  $error("ERROR: %m parameter DLY validation failed");
end
endgenerate

////////////////////////////////////////////////////////////////////////////////
// local parameters and functions
////////////////////////////////////////////////////////////////////////////////

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
logic [PN-1:0] sub_dec;
logic [SW-1:0] sub_sel;
logic [SW-1:0] man_sel;

logic [DW-1:0] tmp_rdt [PN-1:0];  // read data
logic          tmp_err [PN-1:0];  // error
logic          tmp_rdy [PN-1:0];  // acknowledge

////////////////////////////////////////////////////////////////////////////////
// decoder
////////////////////////////////////////////////////////////////////////////////

// address range decoder into one hot vector
generate
for (i=0; i<PN; i++) begin: gen_dec
  assign sub_dec[i] = sub.adr ==? AS[i];
end: gen_dec
endgenerate

// priority encoder
assign sub_sel = clog2(sub_dec);

// multiplexer select
always_ff @(posedge sub.clk, posedge sub.rst)
if (sub.rst) begin
  man_sel <= '0;
end else if (sub.trn) begin
  man_sel <= sub_sel;
end

////////////////////////////////////////////////////////////////////////////////
// request
////////////////////////////////////////////////////////////////////////////////

// replicate request signals
generate
for (i=0; i<PN; i++) begin: gen_req
  assign man[i].vld = sub_dec[i] ? sub.vld : '0;
  assign man[i].wen = sub_dec[i] ? sub.wen : 'x;
  assign man[i].ben = sub_dec[i] ? sub.ben : 'x;
  assign man[i].adr = sub_dec[i] ? sub.adr : 'x;
  assign man[i].wdt = sub_dec[i] ? sub.wdt : 'x;
end: gen_req
endgenerate

////////////////////////////////////////////////////////////////////////////////
// response
////////////////////////////////////////////////////////////////////////////////

// organize response signals into indexable array
// since a dynamix index can't be used on an array of interfaces
generate
for (i=0; i<PN; i++) begin: gen_rsp
  assign tmp_rdt[i] = man[i].rdt;
  assign tmp_err[i] = man[i].err;
  assign tmp_rdy[i] = man[i].rdy;
end: gen_rsp
endgenerate

// multiplexer
assign sub.rdt = tmp_rdt[man_sel];  // response phase
assign sub.err = tmp_err[man_sel];  // response phase
assign sub.rdy = tmp_rdy[sub_sel];  // request  phase

endmodule: tcb_dec_3sp