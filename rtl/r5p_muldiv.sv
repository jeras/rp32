import riscv_isa_pkg::*;

module r5p_muldiv #(
  int unsigned XW = 32
)(
  // control
  input  ctl_m_t        ctl,
  // data input/output
  input  logic [XW-1:0] rs1,  // source register 1
  input  logic [XW-1:0] rs2,  // source register 2
  output logic [XW-1:0] rd    // destination register
);

logic [2-1:0][XW-1:0] mul;
logic        [XW-1:0] div;
logic        [XW-1:0] rem;

// multiplication
always_comb
case ({ctl.s1, ctl.s2}) inside
  {1'b0, 1'b0}: mul = $unsigned(rs1) * $unsigned(rs2);
  {1'b1, 1'b0}: mul =   $signed(rs1) * $unsigned(rs2);
  {1'b1, 1'b1}: mul =   $signed(rs1) *   $signed(rs2);
  default     : mul = 'x;
endcase

// division
always_comb
case ({ctl.s1, ctl.s2}) inside
  {1'b0, 1'b0}: div = $unsigned(rs1) / $unsigned(rs2);
  {1'b1, 1'b1}: div =   $signed(rs1) /   $signed(rs2);
  default     : div = 'x;
endcase

// reminder
always_comb
case ({ctl.s1, ctl.s2}) inside
  {1'b0, 1'b0}: rem = $unsigned(rs1) / $unsigned(rs2);
  {1'b1, 1'b1}: rem =   $signed(rs1) /   $signed(rs2);
  default     : rem = 'x;
endcase

always_comb
case (ctl.op) inside
  M_MUL: rd = mul[0];
  M_MUH: rd = mul[1];
  M_DIV: rd = div;
  M_REM: rd = rem;
endcase

endmodule: r5p_muldiv