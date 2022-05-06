///////////////////////////////////////////////////////////////////////////////
// R5P: write back unit
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

module r5p_wbu
  import riscv_isa_pkg::*;
#(
  int unsigned XLEN = 32  // XLEN width
)(
  // system signals
  input  logic            clk,  // clock
  input  logic            rst,  // reset
  // control structure
  input  ctl_t            ctl,
  // write data inputs
  input  logic [XLEN-1:0] alu,  // ALU destination register
  input  logic [XLEN-1:0] lsu,  // LSU read data
  input  logic [XLEN-1:0] pcs,
  input  logic [XLEN-1:0] lui,  // upper immediate
  input  logic [XLEN-1:0] csr,  // CSR read
  input  logic [XLEN-1:0] mul,  // mul/div/rem
  // GPR write back
  output logic            wen,  // write enable
  output logic [5-1:0]    adr,  // GPR address
  output logic [XLEN-1:0] dat   // data
);

// write data inputs
logic [XLEN-1:0] tmp;

// multiplexer select
op32_op62_et sel;

// destination register write enable and address
always_ff @(posedge clk, posedge rst)
if (rst) begin
  wen <= 1'b0;
  adr <= 5'd0;
  sel <= opc_t'('0);  // TODO: there might be a better choice
end else begin
  wen <= ctl.gpr.ena.rd;
  adr <= ctl.gpr.adr.rd;
  sel <= ctl.opc;
end

// pre multiplexer
always_ff @(posedge clk, posedge rst)
if (rst) begin
  tmp <= '0;
end else begin
  unique case (ctl.opc)
    AUIPC  ,
    OP     ,
    OP_IMM : tmp <= alu;  // ALU output
    LOAD   : tmp <=  'x;  // LSU load data
    JAL    ,
    JALR   : tmp <= pcs;  // PC increment
    LUI    : tmp <= lui;  // upper immediate
//  SYSTEM : tmp <= csr;  // CSR read
//  OP     : tmp <= mul;  // mul/div/rem
    default: tmp <=  'x;  // none
  endcase
end

// write back multiplexer
always_comb begin
  unique case (sel)
    AUIPC  ,
    OP     ,
    OP_IMM : dat = tmp;  // ALU output
    LOAD   : dat = lsu;  // LSU load data
    JAL    ,
    JALR   : dat = tmp;  // PC increment
    LUI    : dat = tmp;  // upper immediate
//  SYSTEM : dat = tmp;  // CSR read
//  OP     : dat = tmp;  // mul/div/rem
    default: dat = 'x;   // none
  endcase
end

endmodule: r5p_wbu