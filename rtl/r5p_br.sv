///////////////////////////////////////////////////////////////////////////////
// branch unit
///////////////////////////////////////////////////////////////////////////////

import riscv_isa_pkg::br_t;

module r5p_br #(
  int unsigned XLEN = 32
)(
  // control
  input  br_t             ctl,
  // data input/output
  input  logic [XLEN-1:0] rs1,  // source register 1 / immediate
  input  logic [XLEN-1:0] rs2,  // source register 2 / PC
  // status
  output logic            tkn   // taken
);

logic eq ;  // equal
logic lts;  // less then   signed
logic ltu;  // less then unsigned

assign eq  =           rs1 ==           rs2 ;  // equal
assign lts =   $signed(rs1) <   $signed(rs2);  // less then   signed
assign ltu = $unsigned(rs1) < $unsigned(rs2);  // less then unsigned

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

endmodule: r5p_br