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

import riscv_isa_pkg::*;

module r5p_lsu #(
  int unsigned XLEN = 32,  // XLEN
  // data bus
  int unsigned AW = 32,    // address width
  int unsigned DW = XLEN,  // data    width
  int unsigned BW = DW/8,  // byte en width
  // optimizations
  logic        CFG_VLD_ILL = 1'bx,  // valid        for illegal instruction
  logic        CFG_WEN_ILL = 1'bx,  // write enable for illegal instruction
  logic        CFG_WEN_IDL = 1'bx,  // write enable for idle !(LOAD | STORE)
  logic        CFG_BEN_RD  = 1'bx,  // byte  enable for read (TODO)
  logic        CFG_BEN_IDL = 1'bx,  // byte  enable for idle !(LOAD | STORE)
  logic        CFG_BEN_ILL = 1'bx   // byte  enable for illegal instruction
)(
  // system signals
  input  logic             clk,  // clock
  input  logic             rst,  // reset
  // control
  input  ctl_t             ctl,
  // data input/output
  input  logic             run,  // illegal
  input  logic             ill,  // illegal
  input  logic  [XLEN-1:0] adr,  // address
  input  logic  [XLEN-1:0] wdt,  // write data
  output logic  [XLEN-1:0] rdt,  // read data
  output logic             mal,  // misaligned
  output logic             rdy,  // ready
  // data bus (load/store)
  output logic          ls_vld,  // write or read request
  output logic          ls_wen,  // write enable
  output logic [AW-1:0] ls_adr,  // address
  output logic [BW-1:0] ls_ben,  // byte enable
  output logic [DW-1:0] ls_wdt,  // write data
  input  logic [DW-1:0] ls_rdt,  // read data
  input  logic          ls_rdy   // write or read acknowledge
);

// word address width
localparam int unsigned WW = $clog2(BW);

// read/write transfer
logic ls_rtr;
logic ls_wtr;

// read/write transfer
assign ls_rtr = ls_vld & ls_rdy & ~ls_wen;
assign ls_wtr = ls_vld & ls_rdy &  ls_wen;

// valid and write anable
always_comb
if (run) begin
  if (ill) begin
    ls_vld = CFG_VLD_ILL;
    ls_wen = CFG_WEN_ILL;
  end else begin
    unique case (ctl.i.opc)
      LOAD   : begin ls_vld = 1'b1; ls_wen = 1'b0       ; end
      STORE  : begin ls_vld = 1'b1; ls_wen = 1'b1       ; end
      default: begin ls_vld = 1'b0; ls_wen = CFG_WEN_IDL; end
    endcase
  end
end else begin
  ls_vld = 1'b0;
  ls_wen = CFG_WEN_ILL;
end

// address
assign ls_adr = {adr[AW-1:WW], WW'('0)};

// misalignment
// decodings for read and write access are identical
always_comb
unique case (ctl.i.opc)
  LOAD   :
    // read access
    unique case (ctl.i.lsu.l)
      LB, LBU: mal = 1'b0;
      LH, LHU: mal = |adr[0:0];
      LW, LWU: mal = |adr[1:0];
    //LD, LDU: mal = |adr[2:0];
      default: mal = 1'bx;
    endcase
  STORE  :
    // write access
    unique case (ctl.i.lsu.s)
      SB     : mal = 1'b0;
      SH     : mal = |adr[0:0];
      SW     : mal = |adr[1:0];
    //SD     : mal = |adr[2:0];
      default: mal = 1'bx;
    endcase
  default: mal = 1'bx;
endcase

// write data and byte select
always_comb
if (ill) begin
  ls_wdt = 'x;
  ls_ben = {BW{CFG_BEN_ILL}};
end else begin
  unique case (ctl.i.opc)
    LOAD   : begin
        ls_wdt = 'x;
        ls_ben = {BW{CFG_BEN_RD}};
      end
    STORE  :
      // write access
      case (ctl.i.lsu.s)
        3'b000 : case (adr[1:0])
          2'b00: begin ls_wdt = {8'hxx     , 8'hxx     , 8'hxx     , wdt[ 7: 0]}; ls_ben = 4'b0001; end
          2'b01: begin ls_wdt = {8'hxx     , 8'hxx     , wdt[ 7: 0], 8'hxx     }; ls_ben = 4'b0010; end
          2'b10: begin ls_wdt = {8'hxx     , wdt[ 7: 0], 8'hxx     , 8'hxx     }; ls_ben = 4'b0100; end
          2'b11: begin ls_wdt = {wdt[ 7: 0], 8'hxx     , 8'hxx     , 8'hxx     }; ls_ben = 4'b1000; end
        endcase
        3'b001 : casez (adr[1])
          1'b0 : begin ls_wdt = {8'hxx     , 8'hxx     , wdt[15: 8], wdt[ 7: 0]}; ls_ben = 4'b0011; end
          1'b1 : begin ls_wdt = {wdt[15: 8], wdt[ 7: 0], 8'hxx     , 8'hxx     }; ls_ben = 4'b1100; end
        endcase
        3'b010 : begin ls_wdt = {wdt[31:24], wdt[23:16], wdt[15: 8], wdt[ 7: 0]}; ls_ben = 4'b1111; end
        default: begin ls_wdt = {8'hxx     , 8'hxx     , 8'hxx     , 8'hxx     }; ls_ben = 4'bxxxx; end
      endcase
    default: begin
        ls_wdt = 'x;
        ls_ben = {BW{CFG_BEN_IDL}};
      end
  endcase
end

// read alignment
logic [WW-1:0]  ral;
op32_l_func3_et rf3;

// read alignment
always_ff @ (posedge clk, posedge rst)
if (rst) begin
  ral <= '0;
  rf3 <= XLEN == 32 ? LW : LD;
end else if (ls_rtr) begin
  ral <= adr[WW-1:0];
  rf3 <= ctl.i.lsu.l;
end

// read data (sign extend)
always_comb begin: blk_rdt
  logic [XLEN-1:0] tmp;
  tmp = ls_rdt >> (8*ral);
  unique case (rf3)
    LB     : rdt = DW'(  $signed( 8'(tmp)));
    LH     : rdt = DW'(  $signed(16'(tmp)));
    LW     : rdt = DW'(  $signed(32'(tmp)));
  //LD     : rdt = DW'(  $signed(64'(tmp)));
    LBU    : rdt = DW'($unsigned( 8'(tmp)));
    LHU    : rdt = DW'($unsigned(16'(tmp)));
    LWU    : rdt = DW'($unsigned(32'(tmp)));  // Quartus does a better job if this line is present
  //LDU    : rdt = DW'($unsigned(64'(tmp)));
    default: rdt = 'x;
  endcase
end: blk_rdt

// system stall
assign rdy = ls_rdy;

endmodule: r5p_lsu