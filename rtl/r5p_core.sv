import riscv_isa_pkg::*;

module r5p_core #(
  // RISC-V ISA
  isa_t        ISA = RV32I,  // see `riscv_isa_pkg` for enumeration definition
  int unsigned XW  = 32,    // TODO: calculate it from ISA
  // instruction bus
  int unsigned IAW = 32,    // program address width
  int unsigned IDW = 32,    // program data    width
  int unsigned ISW = IDW/8, // program select  width
  // data bus
  int unsigned DAW = 32,    // data    address width
  int unsigned DDW = 32,    // data    data    width
  int unsigned DSW = DDW/8, // data    select  width
  // constants ???
  logic [IAW-1:0] PC0 = '0
)(
  // system signals
  input  logic                  clk,
  input  logic                  rst,
  // program bus (instruction fetch)
  output logic                  if_req,
  output logic [IAW-1:0]        if_adr,
  input  logic [ISW-1:0][8-1:0] if_rdt,
  input  logic                  if_ack,
  // data bus (load/store)
  output logic                  ls_req,  // write or read request
  output logic                  ls_wen,  // write enable
  output logic [DAW-1:0]        ls_adr,  // address
  output logic [DSW-1:0]        ls_sel,  // byte select
  output logic [DSW-1:0][8-1:0] ls_wdt,  // write data
  input  logic [DSW-1:0][8-1:0] ls_rdt,  // read data
  input  logic                  ls_ack   // write or read acknowledge
);

///////////////////////////////////////////////////////////////////////////////
// calculated parameters
///////////////////////////////////////////////////////////////////////////////

// word address width
localparam int unsigned DWW = $clog2(DSW);

///////////////////////////////////////////////////////////////////////////////
// local signals
///////////////////////////////////////////////////////////////////////////////

// instruction fetch
logic           if_tkn;  // taken
logic [IAW-1:0] if_pc;   // program counter
logic [IAW-1:0] if_pca;  // program counter adder
logic [IAW-1:0] if_pcn;  // program counter next
logic           stall;

// instruction decode
op32_t id_op;   // operation code
ctl_t  id_ctl;  // control structure
logic  id_vld;  // instruction valid

// CSR
logic           csr_expt;
logic [IAW-1:0] csr_evec;
logic [IAW-1:0] csr_epc;

// GPR
logic [XW-1:0] gpr_rs1;  // register source 1
logic [XW-1:0] gpr_rs2;  // register source 2
logic [XW-1:0] gpr_rd ;  // register destination

// ALU
logic [XW-1:0] alu_rs1;  // register source 1
logic [XW-1:0] alu_rs2;  // register source 2
logic [XW-1:0] alu_rd ;  // register destination
logic [XW-1:0] alu_sum;  // sum (can be used regardless of ALU command

// load/sore unit temporary signals
logic [XW-1:0] ls_adr_t;  // address
logic [XW-1:0] ls_wdt_t;  // write data
logic [XW-1:0] ls_rdt_t;  // read data
logic [XW-1:0] ls_mal;    // misaligned

///////////////////////////////////////////////////////////////////////////////
// instruction fetch
///////////////////////////////////////////////////////////////////////////////

// request becomes active after reset
always_ff @ (posedge clk, posedge rst)
if (rst)  if_req <= 1'b0;
else      if_req <= 1'b1;

// PC next is used as IF address
assign if_adr = if_pcn;

// instruction valid
always_ff @ (posedge clk, posedge rst)
if (rst)  id_vld <= 1'b0;
else      id_vld <= if_req & if_ack;

///////////////////////////////////////////////////////////////////////////////
// program counter
///////////////////////////////////////////////////////////////////////////////

// TODO:
assign stall = ~if_ack;

// program counter
always_ff @ (posedge clk, posedge rst)
if (rst)  if_pc <= PC0;
else begin
  if (id_vld & ~stall) if_pc <= if_pcn;
end

// branch unit
r5p_br #(
  .XW  (XW)
) br (
  // control
  .ctl  (id_ctl.i.br),
  // data
  .rs1  (gpr_rs1),
  .rs2  (gpr_rs2),
  // status
  .tkn  (if_tkn)
);

// program counter adder
assign if_pca = if_pc + IAW'(opsiz(id_op[16-1:0]));

// program counter next
always_comb
if (csr_expt)  if_pcn = csr_evec;
else if (if_ack & id_vld) begin
  case (id_ctl.i.pc)
    PC_PCN: if_pcn = if_pca;
    PC_EPC: if_pcn = csr_epc;
    PC_ALU: if_pcn = if_tkn ? alu_sum[IAW-1:0] : if_pca;
    default: if_pcn = 'x;
  endcase
end else begin
  if_pcn = if_pc;
end

///////////////////////////////////////////////////////////////////////////////
// instruction decode
///////////////////////////////////////////////////////////////////////////////

// opcode from instruction fetch
assign id_op = if_rdt;

// 32-bit instruction decoder
assign id_ctl = dec(ISA, id_op);

///////////////////////////////////////////////////////////////////////////////
// execute
///////////////////////////////////////////////////////////////////////////////

// general purpose registers
r5p_gpr #(
  .AW  (ISA.ie ? 4 : 5),
  .XW  (XW)
) gpr (
  // system signals
  .clk    (clk),
  .rst    (rst),
  // read/write enable
  .e_rs1  (id_ctl.i.gpr.e.rs1),
  .e_rs2  (id_ctl.i.gpr.e.rs2),
  .e_rd   (id_ctl.i.gpr.e.rd ),  // there are additional conditions for load write back
  // read/write address
  .a_rs1  (id_ctl.i.gpr.a.rs1),
  .a_rs2  (id_ctl.i.gpr.a.rs2),
  .a_rd   (id_ctl.i.gpr.a.rd ),
  // read/write data
  .d_rs1  (gpr_rs1),
  .d_rs2  (gpr_rs2),
  .d_rd   (gpr_rd )
);

// ALU input multiplexer
always_comb begin
  // RS1
  unique case (id_ctl.i.a1)
    A1_RS1: alu_rs1 = gpr_rs1;
    A1_PC : alu_rs1 = XW'(if_pc);
  endcase
  // RS2
  unique case (id_ctl.i.a2)
    A2_RS2: alu_rs2 = gpr_rs2;
    A2_IMM: alu_rs2 = id_ctl.i.imm;
  endcase
end

r5p_alu #(
  .XW  (XW)
) alu (
  // control
  .ctl  (id_ctl.i.ao),
  // data input/output
  .rs1  (alu_rs1),
  .rs2  (alu_rs2),
  .rd   (alu_rd ),
  // dedicated output for branch address
  .sum  (alu_sum)
);

///////////////////////////////////////////////////////////////////////////////
// load/store
///////////////////////////////////////////////////////////////////////////////

// temprary values
assign ls_adr_t = alu_sum;
assign ls_wdt_t = gpr_rs2;

// request
assign ls_req = id_ctl.i.ls.en;

// write enable
assign ls_wen = id_ctl.i.ls.we;

// address
assign ls_adr = {ls_adr_t[DAW-1:DWW], DWW'('0)};

// byte select
// TODO
always_comb
//for (int unsigned i=0; i<SDW; i++) begin
//  ls_sel[i] = (2**id_ctl.i.st) &
//end
unique case (id_ctl.i.ls.sz)
  SZ_B: ls_sel = DSW'(16'b0000_0000_0000_0001 << ls_adr_t[DWW-1:0]);
  SZ_H: ls_sel = DSW'(16'b0000_0000_0000_0011 << ls_adr_t[DWW-1:0]);
  SZ_W: ls_sel = DSW'(16'b0000_0000_0000_1111 << ls_adr_t[DWW-1:0]);
  SZ_D: ls_sel = DSW'(16'b0000_0000_1111_1111 << ls_adr_t[DWW-1:0]);
  SZ_Q: ls_sel = DSW'(16'b1111_1111_1111_1111 << ls_adr_t[DWW-1:0]);
  default: ls_sel = '0;
endcase

// write data
always_comb
unique case (id_ctl.i.ls.sz)
  SZ_B: ls_wdt = (ls_wdt_t & DDW'(128'h00000000_00000000_00000000_000000ff)) << (8*ls_adr_t[DWW-1:0]);
  SZ_H: ls_wdt = (ls_wdt_t & DDW'(128'h00000000_00000000_00000000_0000ffff)) << (8*ls_adr_t[DWW-1:0]);
  SZ_W: ls_wdt = (ls_wdt_t & DDW'(128'h00000000_00000000_00000000_ffffffff)) << (8*ls_adr_t[DWW-1:0]);
  SZ_D: ls_wdt = (ls_wdt_t & DDW'(128'h00000000_00000000_ffffffff_ffffffff)) << (8*ls_adr_t[DWW-1:0]);
  SZ_Q: ls_wdt = (ls_wdt_t & DDW'(128'hffffffff_ffffffff_ffffffff_ffffffff)) << (8*ls_adr_t[DWW-1:0]);
  default: ls_wdt = 'x;
endcase

// read data
always_comb begin
  logic [XW-1:0] tmp;
  tmp = ls_rdt >> (8*ls_adr_t[DWW-1:0]);
  unique case (id_ctl.i.ls.sz)
    SZ_B: ls_rdt_t = id_ctl.i.ls.sg ? DDW'($signed(  8'(tmp))) : DDW'($unsigned(  8'(tmp)));
    SZ_H: ls_rdt_t = id_ctl.i.ls.sg ? DDW'($signed( 16'(tmp))) : DDW'($unsigned( 16'(tmp)));
    SZ_W: ls_rdt_t = id_ctl.i.ls.sg ? DDW'($signed( 32'(tmp))) : DDW'($unsigned( 32'(tmp)));
    SZ_D: ls_rdt_t = id_ctl.i.ls.sg ? DDW'($signed( 64'(tmp))) : DDW'($unsigned( 64'(tmp)));
    SZ_Q: ls_rdt_t = id_ctl.i.ls.sg ? DDW'($signed(128'(tmp))) : DDW'($unsigned(128'(tmp)));
    default: ls_rdt_t = 'x;
  endcase
end

///////////////////////////////////////////////////////////////////////////////
// write back
///////////////////////////////////////////////////////////////////////////////

// write back multiplexer
always_comb begin
  unique case (id_ctl.i.wb)
    WB_ALU: gpr_rd =     alu_rd ;   // ALU output
    WB_MEM: gpr_rd =     ls_rdt_t;  // memory read data
    WB_PCN: gpr_rd = XW'(if_pcn);   // PC next
    WB_CSR: gpr_rd = 'x;            // CSR
    default: gpr_rd = 'x;           // none
  endcase
end

endmodule: r5p_core