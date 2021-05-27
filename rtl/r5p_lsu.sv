import riscv_isa_pkg::*;

module r5p_lsu #(
  int unsigned XW = 32,   // XLEN
    // data bus
  int unsigned AW = 32,   // address width
  int unsigned DW = 32,   // data    width
  int unsigned SW = DW/8  // select  width
)(
  // system signals
  input  logic                 clk,  // clock
  input  logic                 rst,  // reset
  // control
  input  lsu_t                 ctl,
  // data input/output
  input  logic        [XW-1:0] adr,  // address
  input  logic        [XW-1:0] wdt,  // write data
  output logic        [XW-1:0] rdt,  // read data
  output logic        [XW-1:0] mal,  // misaligned
  output logic                 dly,  // delayed writeback enable
  // data bus (load/store)
  output logic                 ls_req,  // write or read request
  output logic                 ls_wen,  // write enable
  output logic [AW-1:0]        ls_adr,  // address
  output logic [SW-1:0]        ls_sel,  // byte select
  output logic [SW-1:0][8-1:0] ls_wdt,  // write data
  input  logic [SW-1:0][8-1:0] ls_rdt,  // read data
  input  logic                 ls_ack   // write or read acknowledge
);

// word address width
localparam int unsigned WW = $clog2(SW);

// request
assign ls_req = ctl.en & ~dly;

// write enable
assign ls_wen = ctl.we;

// address
assign ls_adr = {adr[AW-1:WW], WW'('0)};

// byte select
// TODO
always_comb
//for (int unsigned i=0; i<SW; i++) begin
//  ls_sel[i] = (2**id_ctl.i.st) &
//end
unique case (ctl.sz)
  SZ_B: ls_sel = SW'(16'b0000_0000_0000_0001 << adr[WW-1:0]);
  SZ_H: ls_sel = SW'(16'b0000_0000_0000_0011 << adr[WW-1:0]);
  SZ_W: ls_sel = SW'(16'b0000_0000_0000_1111 << adr[WW-1:0]);
  SZ_D: ls_sel = SW'(16'b0000_0000_1111_1111 << adr[WW-1:0]);
  SZ_Q: ls_sel = SW'(16'b1111_1111_1111_1111 << adr[WW-1:0]);
  default: ls_sel = '0;
endcase

// write data
always_comb
unique case (ctl.sz)
  SZ_B: ls_wdt = (wdt & DW'(128'h00000000_00000000_00000000_000000ff)) << (8*adr[WW-1:0]);
  SZ_H: ls_wdt = (wdt & DW'(128'h00000000_00000000_00000000_0000ffff)) << (8*adr[WW-1:0]);
  SZ_W: ls_wdt = (wdt & DW'(128'h00000000_00000000_00000000_ffffffff)) << (8*adr[WW-1:0]);
  SZ_D: ls_wdt = (wdt & DW'(128'h00000000_00000000_ffffffff_ffffffff)) << (8*adr[WW-1:0]);
  SZ_Q: ls_wdt = (wdt & DW'(128'hffffffff_ffffffff_ffffffff_ffffffff)) << (8*adr[WW-1:0]);
  default: ls_wdt = 'x;
endcase

// read data
always_comb begin: blk_rdt
  logic [XW-1:0] tmp;
  tmp = ls_rdt >> (8*adr[WW-1:0]);
  unique case (ctl.sz)
    SZ_B: rdt = ctl.sg ? DW'($signed(  8'(tmp))) : DW'($unsigned(  8'(tmp)));
    SZ_H: rdt = ctl.sg ? DW'($signed( 16'(tmp))) : DW'($unsigned( 16'(tmp)));
    SZ_W: rdt = ctl.sg ? DW'($signed( 32'(tmp))) : DW'($unsigned( 32'(tmp)));
    SZ_D: rdt = ctl.sg ? DW'($signed( 64'(tmp))) : DW'($unsigned( 64'(tmp)));
    SZ_Q: rdt = ctl.sg ? DW'($signed(128'(tmp))) : DW'($unsigned(128'(tmp)));
    default: rdt = 'x;
  endcase
end: blk_rdt

// access delay
always_ff @ (posedge clk, posedge rst)
if (rst)  dly <= 1'b0;
else      dly <= ls_req & ls_ack & ~ls_wen;

endmodule: r5p_lsu