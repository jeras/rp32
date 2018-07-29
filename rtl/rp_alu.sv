enum logic [4-1:0] {
  RP_AND = 4'b0000,  // logic AND
  RP_OR  = 4'b0001,  // logic OR
  RP_ADD = 4'b0010,  // addition
  RP_SUB = 4'b0110,  // subtraction
  RP_LTS = 4'b1100,  // less then   signed (not greater then or equal)
  RP_LTU = 4'b1100,  // less then unsigned (not greater then or equal)
  RP_NOR = 4'b1100   // logic NOR
} rp_alu_t;

module rp_alu #(
  int unsigned XW = 32
)(
  // control
  input  rp_alu_t       ctl,
  // data input/output
  input  logic [XW-1:0] rs1,  // source register 1
  input  logic [XW-1:0] rs2,  // source register 2
  output logic [XW-1:0] rd,   // destination register
  // status
  output logic          eq,   // equal
  output logic          gr,   // greater
  output logic          of    // overflow
);

// overflow bit
logic ovf;

always_comb
case ctl
  RP_AND: {ovf, rd} = rs1  & rs2;
  RP_OR : {ovf, rd} = rs1  | rs2;
  RP_ADD: {ovf, rd} =   $signed(rs1)  +   $signed(rs2);
  RP_SUB: {ovf, rd} =   $signed(rs1)  -   $signed(rs2);
  RP_LTS: {ovf, rd} =   $signed(rs1)  <   $signed(rs2);
  RP_LTU: {ovf, rd} = $unsigned(rs1)  < $unsigned(rs2);
  RP_NOR: {ovf, rd} = rs1 ~| rs2;
  default: {ovf, rd} = 'x;
endcase

// equal status
assign eq = (rs1 == rs2);

// greater status

endmodule: rp_alu
