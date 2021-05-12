import riscv_isa_pkg::*;

module r5p_alu #(
  int unsigned XW = 32
)(
  // system signals
  input  logic          clk,  // clock
  input  logic          rst,  // reset
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

// TODO: construct proper subtraction condition
// adder (summation, subtraction)
//assign {ovf, sum} = $signed(rs1) + (ctl.alu.sig ? -$signed(rs2) : +$signed(rs2));
assign {ovf, sum} = $signed(rs1) + $signed(rs2);

// TODO:
// * check comparison
// * see if overflow can be used

always_comb
case (ctl) inside
  // adder based instructions
  AO_ADD: rd =   $signed(rs1) +   $signed(rs2);
  AO_SUB: rd =   $signed(rs1) -   $signed(rs2);
  AO_LTS: rd =   $signed(rs1) <   $signed(rs2) ? XW'(1) : XW'(0);
  AO_LTU: rd = $unsigned(rs1) < $unsigned(rs2) ? XW'(1) : XW'(0);
  // bitwise logical operations
  AO_AND: rd = rs1 & rs2;
  AO_OR : rd = rs1 | rs2;
  AO_XOR: rd = rs1 ^ rs2;
  // barrel shifter
  AO_SRA: rd =   $signed(rs1) >>> rs2[$clog2(XW)-1:0];
  AO_SRL: rd = $unsigned(rs1)  >> rs2[$clog2(XW)-1:0];
  AO_SLL: rd = $unsigned(rs1)  << rs2[$clog2(XW)-1:0];
  // idle
  AO_XXX : rd = 'x;
  default: rd = 'x;
endcase

endmodule: r5p_alu