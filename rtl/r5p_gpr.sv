///////////////////////////////////////////////////////////////////////////////
// general purpose registers
///////////////////////////////////////////////////////////////////////////////

module r5p_gpr #(
  int unsigned AW = 5,  // can be 4 for RV32E base ISA
  int unsigned XLEN = 32  // XLEN width
)(
  // system signals
  input  logic            clk,  // clock
  input  logic            rst,  // reset
  // read/write enable
  input  logic            e_rs1,
  input  logic            e_rs2,
  input  logic            e_rd,
  // read/write address
  input  logic   [AW-1:0] a_rs1,
  input  logic   [AW-1:0] a_rs2,
  input  logic   [AW-1:0] a_rd,
  // read/write data
  output logic [XLEN-1:0] d_rs1,
  output logic [XLEN-1:0] d_rs2,
  input  logic [XLEN-1:0] d_rd
);

// register file
logic [XLEN-1:0] gpr [1:2**AW-1];

// write access
always_ff @(posedge clk, posedge rst)
if (rst) begin
  for (int unsigned i=1; i<2**AW; i++) begin: reset
    gpr[i] <= '0;
  end: reset
end else if (e_rd & |a_rd) begin
  gpr[a_rd] <= d_rd;
end

// read access
assign d_rs1 = (e_rs1 & |a_rs1) ? gpr[a_rs1] : '0;
assign d_rs2 = (e_rs2 & |a_rs2) ? gpr[a_rs2] : '0;

endmodule: r5p_gpr