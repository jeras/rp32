module rp_alu #(
  int unsigned XW = 32
)(
  // control
  input  rp_alu_t       ctl,
  // data input/output
  input  logic [XW-1:0] rs1,  // source register 1 / immediate
  input  logic [XW-1:0] rs2,  // source register 2 / PC
  output logic [XW-1:0] rd,   // destination register
  // dedicated output for branch address
  output logic [XW-1:0 sum,  // equal
);

logic ovf;  // overflow bit

// adder (summation, subtraction)
assign {ovf, sum} = $signed(rs1) + (ctl.alu.sig ? -$signed(rs2) : +$signed(rs2));

// TODO:
// * check comparison
// * see if overflow can be used

always_comb
case ctl inside
  ALU_ADD,            //   $signed(rs1) +   $signed(rs2)
  ALU_SUB: rd = sum;  //   $signed(rs1) -   $signed(rs2)
  ALU_LTS: rd = (rs1[XW-1] ^ rs2[XW-1]) ? sum[XW-1] : rs2[XW-1];   //   $signed(rs1) <   $signed(rs2)
  ALU_LTU: rd = (rs1[XW-1] ^ rs2[XW-1]) ? sum[XW-1] : rs1[XW-1];   // $unsigned(rs1) < $unsigned(rs2)
  ALU_SRA: rd =   $signed(rs1) >>> rs2[$clog2(XD)-1:0];
  ALU_SRL: rd = $unsigned(rs1)  >> rs2[$clog2(XD)-1:0];
  ALU_SLL: rd = $unsigned(rs1)  << rs2[$clog2(XD)-1:0];
  ALU_AND: rd = rs1 & rs2;
  ALU_OR : rd = rs1 | rs2;
  ALU_XOR: rd = rs1 ^ rs2;
  ALU_CP1: rd = rs1;
  ALU_CP2: rd = rs2;
  ALU_XXX: rd = 'x;
  default: rd = 'x;
endcase

endmodule: rp_alu
