import riscv_isa_pkg::*;

module r5p_csr #(
  int unsigned XW = 32
)(
  // system signals
  input  logic          clk,  // clock
  input  logic          rst,  // reset
  // control structure
  input  ctl_csr_t      ctl,
  // data input/output
  input  logic [XW-1:0] wdt,  // write data
  output logic [XW-1:0] rdt   // read data
);

// logic          csr_expt;
// logic [XW-1:0] csr_evec;
// logic [XW-1:0] csr_epc;

logic [2**12-1:0][XW-1:0] csr;
logic            [XW-1:0] msk;  // mask  data

// read access
assign rdt = csr[ctl.adr];

// CSR mask decoder
always_comb begin
  unique case (ctl.msk)
    CSR_REG: msk = wdt;           // GPR register source 1
    CSR_IMM: msk = XW'(ctl.imm);  // 5-bit zero extended immediate
    default: msk = 'x;
  endcase
end

// write access (CSR operation decoder)
always_ff @(posedge clk, posedge rst)
if (rst)  csr <= '{default: '0};
else begin
  unique casez (ctl.op)
    CSR_RW : csr[ctl.adr] <=        wdt;  // read/write
    CSR_SET: csr[ctl.adr] <= rdt |  msk;  // set
    CSR_CLR: csr[ctl.adr] <= rdt & ~msk;  // clear
    default: csr[ctl.adr] <= 'x;
  endcase
end

endmodule: r5p_csr