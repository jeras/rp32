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
  // data bus (load/store)
  output logic          lsb_vld,  // valid
  output logic          lsb_wen,  // write enable
  output logic [AW-1:0] lsb_adr,  // address
  output logic [BW-1:0] lsb_ben,  // byte enable
  output logic [DW-1:0] lsb_wdt,  // write data
  input  logic [DW-1:0] lsb_rdt,  // read data
  input  logic          lsb_err,  // error
  input  logic          lsb_rdy   // ready
);

// word address width
localparam int unsigned WW = $clog2(BW);

// read/write missalignment
logic rma;  // read  misaligned
logic wma;  // write misaligned

// read/write transfer
logic lsb_rtr;
logic lsb_wtr;

// read/write transfer
assign lsb_rtr = lsb_vld & lsb_rdy & ~lsb_wen;
assign lsb_wtr = lsb_vld & lsb_rdy &  lsb_wen;

// valid and write anable
always_comb
if (run) begin
  if (ill) begin
    lsb_vld = CFG_VLD_ILL;
    lsb_wen = CFG_WEN_ILL;
  end else begin
    unique case (dec.opc)
      LOAD   : begin lsb_vld = 1'b1; lsb_wen = 1'b0       ; end
      STORE  : begin lsb_vld = 1'b1; lsb_wen = 1'b1       ; end
      default: begin lsb_vld = 1'b0; lsb_wen = CFG_WEN_IDL; end
    endcase
  end
end else begin
  lsb_vld = 1'b0;
  lsb_wen = CFG_WEN_ILL;
end

// address
assign lsb_adr = {adr[AW-1:WW], WW'('0)};

// misalignment
// decodings for read and write access are identical
always_comb
unique case (dec.opc)
  LOAD   : begin
      // read access
      unique case (fn3_ldu_et'(dec.fn3))
        LB, LBU: rma = 1'b0;
        LH, LHU: rma = |adr[0:0];
        LW, LWU: rma = |adr[1:0];
      //LD, LDU: rma = |adr[2:0];
        default: rma = 1'bx;
      endcase
      // write access
      wma = 1'bx;
    end
  STORE  : begin
      // read access
      rma = 1'bx;
      // write access
      unique case (fn3_stu_et'(dec.fn3))
        SB     : wma = 1'b0;
        SH     : wma = |adr[0:0];
        SW     : wma = |adr[1:0];
      //SD     : wma = |adr[2:0];
        default: wma = 1'bx;
      endcase
    end
  default: begin
      // read access
      rma = 1'bx;
      // write access
      wma = 1'bx;
    end
endcase

assign mal = wma | rma;

// write data and byte select
always_comb
if (ill) begin
  lsb_wdt = 'x;
  lsb_ben = {BW{CFG_BEN_ILL}};
end else begin
  // dafault values
  lsb_wdt = 'x;
  // conbinational logic
  unique case (dec.opc)
    LOAD   : begin
      case (fn3_ldu_et'(dec.fn3))
        LB, LBU: case (adr[1:0])
          2'b00: lsb_ben = 4'b0001;
          2'b01: lsb_ben = 4'b0010;
          2'b10: lsb_ben = 4'b0100;
          2'b11: lsb_ben = 4'b1000;
        endcase
        LH, LHU: case (adr[1])
          1'b0 : lsb_ben = 4'b0011;
          1'b1 : lsb_ben = 4'b1100;
        endcase
        LW, LWU: lsb_ben = 4'b1111;
        default: lsb_ben = 4'bxxxx;
      endcase
    end
    STORE  :
      // write access
      case (fn3_stu_et'(dec.fn3))
        SB     : case (adr[1:0])
          2'b00: begin lsb_wdt[ 7: 0] = wdt[ 7: 0]; lsb_ben = 4'b0001; end
          2'b01: begin lsb_wdt[15: 8] = wdt[ 7: 0]; lsb_ben = 4'b0010; end
          2'b10: begin lsb_wdt[23:16] = wdt[ 7: 0]; lsb_ben = 4'b0100; end
          2'b11: begin lsb_wdt[31:24] = wdt[ 7: 0]; lsb_ben = 4'b1000; end
        endcase
        SH     : case (adr[1])
          1'b0 : begin lsb_wdt[15: 0] = wdt[15: 0]; lsb_ben = 4'b0011; end
          1'b1 : begin lsb_wdt[31:16] = wdt[15: 0]; lsb_ben = 4'b1100; end
        endcase
        SW     : begin lsb_wdt[31: 0] = wdt[31: 0]; lsb_ben = 4'b1111; end
        default: begin lsb_wdt[31: 0] = 'x        ; lsb_ben = 4'bxxxx; end
      endcase
    default: begin
      lsb_wdt = 'x;
      lsb_ben = {BW{CFG_BEN_IDL}};
    end
  endcase
end

// read alignment delayed signals
logic            dly_rma;
logic   [WW-1:0] dly_adr;
fn3_ldu_et       dly_fn3;

logic [XLEN-1:0] dly_dat;  // data
logic   [32-1:0] dly_dtw;  // data word
logic   [16-1:0] dly_dth;  // data half
logic   [ 8-1:0] dly_dtb;  // data byte

// read alignment
always_ff @ (posedge clk, posedge rst)
if (rst) begin
  dly_rma <= 1'b0;
  dly_adr <= '0;
  dly_fn3 <= XLEN == 32 ? LW : LD;
end else if (lsb_rtr) begin
  dly_rma <= rma;
  dly_adr <= adr[WW-1:0];
  dly_fn3 <= fn3_ldu_et'(dec.fn3);
end

// read data
always_comb begin: blk_rdt
  // read data multiplexer
  dly_dtw = lsb_rdt[31: 0];
  dly_dth = dly_adr[1] ? dly_dtw[31:16] : dly_dtw[15: 0];
  dly_dtb = dly_adr[0] ? dly_dth[15: 8] : dly_dth[ 7: 0];
  // read data multiplexer
  dly_dat = {dly_dtw[31:16], dly_dth[15: 8], dly_dtb[ 7: 0]};
  // sign extension
  // NOTE: this is a good fit for LUT4
  unique case (dly_fn3)
    LB     : rdt = DW'(  $signed( 8'(dly_dat)));
    LH     : rdt = DW'(  $signed(16'(dly_dat)));
    LW     : rdt = DW'(  $signed(32'(dly_dat)));
    LBU    : rdt = DW'($unsigned( 8'(dly_dat)));
    LHU    : rdt = DW'($unsigned(16'(dly_dat)));
    LWU    : rdt = DW'($unsigned(32'(dly_dat)));  // Quartus does a better job if this line is present
    default: rdt = 'x;
  endcase
end: blk_rdt

// system stall
assign rdy = lsb_rdy;

endmodule: r5p_lsu
