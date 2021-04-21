import riscv_isa_pkg::*;

module r5p_core #(
  // RISC-V ISA
  isa_t ISA = 16'b0100_000000000000,
//  isa_t ISA = '{
//	        // ISA base
//                .e = 1'b0,  // RV32E  - embedded
//                .w = 1'b1,  // RV32I  - word
//                .d = 1'b0,  // RV64I  - double
//                .q = 1'b0,  // RV128I - quad
//                // extensions
//                .m = 1'b0,  // integer multiplication and division
//                .a = 1'b0,  // atomic
//                .f = 1'b0,  // single-precision floating-point
//                .d = 1'b0,  // double-precision floating-point
//                .q = 1'b0,  // quad-precision floating-point
//                .l = 1'b0,  // decimal precision floating-point
//              //.c = 1'b0,  // compressed
//                .b = 1'b0,  // bit manipulation
//                .j = 1'b0,  // dynamically translated languages
//                .t = 1'b0,  // transactional memory
//                .p = 1'b0,  // packed-SIMD
//                .v = 1'b0,  // vector operations
//                .n = 1'b0   // user-level interrupts
//	      },
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

// TODO
localparam int unsigned XW = 32;

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
logic [XW-1:0] gpr_rs1;
logic [XW-1:0] gpr_rs2;
logic [XW-1:0] gpr_rd ;

// ALU
logic [XW-1:0] alu_rs1;
logic [XW-1:0] alu_rs2;
logic [XW-1:0] alu_rd ;
logic [XW-1:0] alu_sum;

///////////////////////////////////////////////////////////////////////////////
// instruction fetch
///////////////////////////////////////////////////////////////////////////////

// request becomes active after reset
always_ff @ (posedge clk, posedge rst)
if (rst)  if_req <= 1'b0;
else      if_req <= 1'b1;

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
assign id_ctl = dec32(ISA, id_op);

// write back multiplexer
always_comb begin
  unique case (id_ctl.i.wb)
    WB_ALU: gpr_rd =     alu_rd ;  // ALU output
    WB_MEM: gpr_rd =     ls_rdt ;  // memory read data
    WB_PCN: gpr_rd = XW'(if_pcn);  // PC next
    WB_CSR: gpr_rd = 'x;           // CSR
    default: gpr_rd = 'x;           // none
  endcase
end

// general purpose registers
r5p_gpr #(
  .AW  (ISA.ie ? 4 : 5),
  .XW  (XW)
) gpr (
  // system signals
  .clk    (clk),
  .rst    (rst),
  // read/write enable
//.e_rs1  (),
//.e_rs2  (),
  .e_rd   (id_ctl.i.wb != WB_XXX),
  // read/write address
  .a_rs1  (id_op.r.rs1),
  .a_rs2  (id_op.r.rs2),
  .a_rd   (id_op.r.rd ),
  // read/write data
  .d_rs1  (gpr_rs1),
  .d_rs2  (gpr_rs2),
  .d_rd   (gpr_rd )
);

///////////////////////////////////////////////////////////////////////////////
// execute
///////////////////////////////////////////////////////////////////////////////

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

// request
assign ls_req = (id_ctl.i.st != ST_X) | (id_ctl.i.ld != LD_XX);

// write enable
assign ls_wen = (id_ctl.i.st != ST_X);

// address
assign ls_adr = alu_sum[DAW-1:0];

// byte select
// TODO
assign ls_sel = '1;

// write data
assign ls_wdt = gpr_rs2;

endmodule: r5p_core