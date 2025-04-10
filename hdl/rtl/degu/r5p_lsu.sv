///////////////////////////////////////////////////////////////////////////////
// R5P: load/store unit
///////////////////////////////////////////////////////////////////////////////
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

module r5p_lsu
  import riscv_isa_i_pkg::*;
  import tcb_pkg::*;
#(
  int unsigned XLEN = 32,  // XLEN
  // data bus
  int unsigned AW = 32,    // address width
  int unsigned DW = XLEN,  // data    width
  int unsigned BW = DW/8,  // byte en width
  // optimizations
  logic        CFG_VLD_ILL = 1'bx,  // valid        for illegal instruction
  logic        CFG_WEN_ILL = 1'bx,  // write enable for illegal instruction
  logic        CFG_WEN_IDL = 1'bx,  // write enable for idle !(LOAD | STORE)
  logic        CFG_BEN_IDL = 1'bx,  // byte  enable for idle !(LOAD | STORE)
  logic        CFG_BEN_ILL = 1'bx   // byte  enable for illegal instruction
)(
  // system signals
  input  logic              clk,  // clock
  input  logic              rst,  // reset
  // control
  input  dec_t              dec,
  // data input/output
  input  logic              run,  // illegal
  input  logic              ill,  // illegal
  input  logic   [XLEN-1:0] adr,  // address
  input  logic   [XLEN-1:0] wdt,  // write data
  output logic   [XLEN-1:0] rdt,  // read data
  output logic              mal,  // misaligned
  output logic              rdy,  // ready
  // TCB system bus (load/store)
  tcb_if.man                tcb,
  input  logic              tcb_mal
);

// read/write misalignment
logic rma;  // read  misaligned
logic wma;  // write misaligned

// valid and write anable
always_comb
if (run) begin
  if (ill) begin
    tcb.vld     = CFG_VLD_ILL;
    tcb.req.wen = CFG_WEN_ILL;
  end else begin
    unique case (dec.opc)
      LOAD   : begin tcb.vld = 1'b1; tcb.req.wen = 1'b0       ; end
      STORE  : begin tcb.vld = 1'b1; tcb.req.wen = 1'b1       ; end
      default: begin tcb.vld = 1'b0; tcb.req.wen = CFG_WEN_IDL; end
    endcase
  end
end else begin
  tcb.vld     = 1'b0;
  tcb.req.wen = CFG_WEN_ILL;
end

// address
assign tcb.req.adr = adr;

// transfer size
assign tcb.req.siz = dec.fn3[1:0];

// write data
assign tcb.req.wdt = wdt;

// read alignment delayed signals
fn3_ldu_et dly_fn3;

// read alignment
always_ff @ (posedge clk, posedge rst)
if (rst) begin
  dly_fn3 <= XLEN == 32 ? LW : LD;
end else if (tcb.trn & ~tcb.req.wen) begin
  dly_fn3 <= fn3_ldu_et'(dec.fn3);
end

// read data
always_comb begin: blk_rdt
  // sign extension
  // NOTE: this is a good fit for LUT4
  unique case (dly_fn3)
    LB     : rdt = DW'(  $signed( 8'(tcb.rsp.rdt)));
    LH     : rdt = DW'(  $signed(16'(tcb.rsp.rdt)));
    LW     : rdt = DW'(  $signed(32'(tcb.rsp.rdt)));
    LBU    : rdt = DW'($unsigned( 8'(tcb.rsp.rdt)));
    LHU    : rdt = DW'($unsigned(16'(tcb.rsp.rdt)));
    LWU    : rdt = DW'($unsigned(32'(tcb.rsp.rdt)));  // Quartus does a better job if this line is present
    default: rdt = 'x;
  endcase
end: blk_rdt

// misalignment
assign mal = tcb_mal;

// system stall
assign rdy = tcb.rdy;

// TODO
assign tcb.req.cmd = '0;
assign tcb.req.ndn = TCB_LITTLE;

endmodule: r5p_lsu
