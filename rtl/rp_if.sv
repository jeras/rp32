module pr_if #(
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
logic eq;  // equal
logic lts;  // less then   signed
logic ltu;  // less then unsigned

always_comb
case ctl inside
  BR_EQ:   sts =  eq;
  BR_NE:   sts = ~eq;
  BR_LTS:  sts =  lts;
  BR_GES:  sts = ~lts;
  BR_LTU:  sts =  ltu;
  BR_GEU:  sts = ~ltu;
  default: sts = 1'b0;
endcase

endmodule: rp_if
