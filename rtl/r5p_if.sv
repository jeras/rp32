import riscv_isa_pkg::*;

module r5p_if #(
  int unsigned XW = 32,
  int unsigned AW = XW   // address width
)(
  // branch condition
  input  logic [XW-1:0] rs1,
  input  logic [XW-1:0] rs2,
  input  logic  [3-1:0] ctl,
  // branch status
  output logic          sts
);

// local signals
logic [XW-1:0] sum;  // equal
logic          ovf;  // overflow bit
logic          eq ;  // equal
logic          lts;  // less then   signed
logic          ltu;  // less then unsigned

assign eq  =           rs1 ==           rs2 ;  // equal
assign lts =   $signed(rs1) <   $signed(rs2);  // less then   signed
assign ltu = $unsigned(rs1) < $unsigned(rs2);  // less then unsigned

always_comb
case (ctl) inside
  BR_EQ:   sts =  eq;
  BR_NE:   sts = ~eq;
  BR_LTS:  sts =  lts;
  BR_GES:  sts = ~lts;
  BR_LTU:  sts =  ltu;
  BR_GEU:  sts = ~ltu;
  default: sts = 1'b0;
endcase

endmodule: r5p_if