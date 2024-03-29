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
  logic [PN-1:0] [AW-1:0] ADR = PN'('0),  // address
  logic [PN-1:0] [AW-1:0] MSK = PN'('1)   // mask
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

//tcb_pas pas0 (.sub (man0), .man (man[0]));
//tcb_pas pas1 (.sub (man1), .man (man[1]));
//tcb_pas pas2 (.sub (man2), .man (man[2]));

assign man[0].vld = man0.vld;
assign man[0].wen = man0.wen;
assign man[0].ben = man0.ben;
assign man[0].adr = man0.adr;
assign man[0].wdt = man0.wdt;

assign man0.rdt = man[0].rdt;
assign man0.err = man[0].err;
assign man0.rdy = man[0].rdy;


assign man[1].vld = man1.vld;
assign man[1].wen = man1.wen;
assign man[1].ben = man1.ben;
assign man[1].adr = man1.adr;
assign man[1].wdt = man1.wdt;

assign man1.rdt = man[1].rdt;
assign man1.err = man[1].err;
assign man1.rdy = man[1].rdy;


assign man[2].vld = man2.vld;
assign man[2].wen = man2.wen;
assign man[2].ben = man2.ben;
assign man[2].adr = man2.adr;
assign man[2].wdt = man2.wdt;

assign man2.rdt = man[2].rdt;
assign man2.err = man[2].err;
assign man2.rdy = man[2].rdy;

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
assign sub_dec[0] = (sub.adr & MSK[0]) == (ADR[0] & MSK[0]);
assign sub_dec[1] = (sub.adr & MSK[1]) == (ADR[1] & MSK[1]);
assign sub_dec[2] = (sub.adr & MSK[2]) == (ADR[2] & MSK[2]);

// priority encoder

function [SW-1:0] clog2 (logic [PN-1:0] val);
  clog2 = 'x;  // optimization of undefined encodings
  for (int unsigned i=0; i<PN; i++) begin
    if (val[i])  clog2 = i[SW-1:0];
  end
endfunction: clog2

assign sub_sel = clog2(sub_dec);

//always_comb
//case (sub_dec)
//  3'b001 : sub_sel = 2'd0;
//  3'b010 : sub_sel = 2'd1;
//  3'b100 : sub_sel = 2'd2;
//  default: sub_sel = 2'dx;
//endcase

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