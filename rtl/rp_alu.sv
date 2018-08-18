import riscv_isa_pkg::*;

module rp_alu #(
  int unsigned XW = 32
)(
  // control
  input  ao_t           ctl,
  // data input/output
  input  logic [XW-1:0] rs1,  // source register 1 / immediate
  input  logic [XW-1:0] rs2,  // source register 2 / PC
  output logic [XW-1:0] rd,   // destination register
  // dedicated output for branch address
  output logic [XW-1:0] sum   // equal
);

logic ovf;  // overflow bit

// adder (summation, subtraction)
//assign {ovf, sum} = $signed(rs1) + (ctl.alu.sig ? -$signed(rs2) : +$signed(rs2));
assign {ovf, sum} = $signed(rs1) + $signed(rs2);

// TODO:
// * check comparison
// * see if overflow can be used

always_comb
case (ctl) inside
  AO_ADD,            //   $signed(rs1) +   $signed(rs2)
  AO_SUB: rd = sum;  //   $signed(rs1) -   $signed(rs2)
  AO_LTS: rd = (rs1[XW-1] ^ rs2[XW-1]) ? sum[XW-1] : rs2[XW-1];   //   $signed(rs1) <   $signed(rs2)
  AO_LTU: rd = (rs1[XW-1] ^ rs2[XW-1]) ? sum[XW-1] : rs1[XW-1];   // $unsigned(rs1) < $unsigned(rs2)
  AO_SRA: rd =   $signed(rs1) >>> rs2[$clog2(XW)-1:0];
  AO_SRL: rd = $unsigned(rs1)  >> rs2[$clog2(XW)-1:0];
  AO_SLL: rd = $unsigned(rs1)  << rs2[$clog2(XW)-1:0];
  AO_AND: rd = rs1 & rs2;
  AO_OR : rd = rs1 | rs2;
  AO_XOR: rd = rs1 ^ rs2;
  AO_CP1: rd = rs1;
  AO_CP2: rd = rs2;
  AO_XXX: rd = 'x;
  default: rd = 'x;
endcase

endmodule: rp_alu
