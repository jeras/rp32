///////////////////////////////////////////////////////////////////////////////
// R5P: branch unit
///////////////////////////////////////////////////////////////////////////////

import riscv_isa_pkg::*;

module r5p_bru #(
  int unsigned XLEN = 32
)(
  // control
  input  bru_t            ctl,
  // data input/output
  input  logic [XLEN-1:0] rs1,  // source register 1
  input  logic [XLEN-1:0] rs2,  // source register 2
  // status
  output logic            tkn   // taken
);

logic eq;   // equal
logic lt;   // less then
logic lts;  // less then   signed
logic ltu;  // less then unsigned

assign eq  = rs1          == rs2          ;  // equal
assign lt  = rs1[XLEN-2:0] < rs2[XLEN-2:0];  // less then

assign lts = (rs1[XLEN-1] == rs2[XLEN-1]) ? lt : (rs1[XLEN-1] > rs2[XLEN-1]);  // less then   signed
assign ltu = (rs1[XLEN-1] == rs2[XLEN-1]) ? lt : (rs1[XLEN-1] < rs2[XLEN-1]);  // less then unsigned

always_comb
case (ctl) inside
  BEQ    : tkn =  eq ;
  BNE    : tkn = ~eq ;
  BLT    : tkn =  lts;
  BGE    : tkn = ~lts;
  BLTU   : tkn =  ltu;
  BGEU   : tkn = ~ltu;
  default: tkn = 'x;
endcase

endmodule: r5p_bru