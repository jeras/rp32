import riscv_isa_pkg::*;

module r5p_br #(
  int unsigned XW = 32
)(
  // control
  input  br_t           ctl,
  // data input/output
  input  logic [XW-1:0] rs1,  // source register 1 / immediate
  input  logic [XW-1:0] rs2,  // source register 2 / PC
  // status
  output logic          tkn   // taken
);

logic eq;
logic lts;
logic ltu;

assign eq  = rs1 == rs2;
assign lts =   $signed(rs1) <   $signed(rs2);
assign ltu = $unsigned(rs1) < $unsigned(rs2);

always_comb
case (ctl) inside
  BR_EQ : tkn =  eq;
  BR_NE : tkn = ~eq;
  BR_LTS: tkn =  lts;
  BR_GES: tkn = ~lts;
  BR_LTU: tkn =  ltu;
  BR_GEU: tkn = ~ltu;
  default: tkn = 'x;
endcase

endmodule: r5p_br
