///////////////////////////////////////////////////////////////////////////////
// R5P: write back unit
///////////////////////////////////////////////////////////////////////////////

module r5p_wbu #(
  int unsigned XLEN = 32  // XLEN width
)(
  // system signals
  input  logic            clk,  // clock
  input  logic            rst,  // reset
  // control structure
  input  ctl_t            ctl,
  // write data inputs
  input  logic [XLEN-1:0] alu,
  input  logic [XLEN-1:0] lsu,
  input  logic [XLEN-1:0] pcs,
  input  logic [XLEN-1:0] imm,
  input  logic [XLEN-1:0] csr,
  input  logic [XLEN-1:0] mul,
  // GPR write back
  output logic            wen,  // write enable
  output logic [5-1:0]    adr,  // address
  output logic [XLEN-1:0] dat   // data
);

// destination register write enable and address
assign wen = ctl.gpr.e.rd;
assign adr = ctl.gpr.a.rd;

// write back multiplexer
always_comb begin
  unique case (ctl.i.wb)
    WB_ALU : dat = alu;  // ALU output
    WB_LSU : dat = lsu;  // LSU load data
    WB_PCI : dat = pcs;  // PC increment
    WB_IMM : dat = imm;  // immediate
    WB_CSR : dat = csr;  // CSR
    WB_MUL : dat = mul;  // mul/div/rem
    default: dat = 'x;   // none
  endcase
end

endmodule: r5p_wbu