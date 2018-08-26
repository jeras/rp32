import riscv_isa_pkg::*;

module rp_core #(
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
  // program bus
  int unsigned PAW = 32,    // program address width
  int unsigned PDW = 32,    // program data    width
  int unsigned PSW = PDW/8, // program select  width
  // data bus
  int unsigned DAW = 32,    // data    address width
  int unsigned DDW = 32,    // data    data    width
  int unsigned DSW = DDW/8, // data    select  width
  // constants ???
  logic [PAW-1:0] PC0 = '0
)(
  // system signals
  input  logic                  clk,
  input  logic                  rst,
  // program bus (instruction fetch)
  output logic                  bup_req,
  output logic [PAW-1:0]        bup_adr,
  input  logic [PSW-1:0][8-1:0] bup_rdt,
  input  logic                  bup_ack,
  // data bus (load/store)
  output logic                  bud_req,  // write or read request
  output logic                  bud_wen,  // write enable
  output logic [DAW-1:0]        bud_adr,  // address
  output logic [DSW-1:0]        bud_sel,  // byte select
  output logic [DSW-1:0][8-1:0] bud_wdt,  // write data
  input  logic [DSW-1:0][8-1:0] bud_rdt,  // read data
  input  logic                  bud_ack   // write or read acknowledge
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
logic           tkn;  // taken
logic [PAW-1:0] pc;   // program counter
logic [PAW-1:0] pcn;  // program counter next
logic           stall;

// instruction decode
frm32_t op;   // structured opcode
ctl_t   ctl;  // control structure

// CSR
logic           csr_expt;
logic [PAW-1:0] csr_evec;
logic [PAW-1:0] csr_epc;

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
if (rst)  bup_req <= 1'b0;
else      bup_req <= 1'b1;

assign bup_adr = pcn;

///////////////////////////////////////////////////////////////////////////////
// program counter
///////////////////////////////////////////////////////////////////////////////

// TODO:
assign stall = 1'b0;

// program counter
always_ff @ (posedge clk, posedge rst)
if (rst)  pc <= PC0;
else begin
  if (~stall) pc <= pcn;
end

// branch unit
rp_br #(
  .XW  (XW)
) br (
  // control
  .ctl  (ctl.i.br),
  // data
  .rs1  (gpr_rs1),
  .rs2  (gpr_rs2),
  // status
  .tkn  (tkn)
);

// program counter next
always_comb
if (csr_expt)  pcn = csr_evec;
else if (bup_ack) begin
  case (ctl.i.pc)
    PC_PC2: pcn = pc + 'd2;
    PC_PC4: pcn = pc + 'd4;
    PC_EPC: pcn = csr_epc;
    PC_ALU: pcn = tkn ? alu_sum[PAW-1:0] : pc + 'd4;
    default: pcn = 'x;
  endcase
end

///////////////////////////////////////////////////////////////////////////////
// instruction decode
///////////////////////////////////////////////////////////////////////////////

assign op = bup_rdt;

assign ctl = dec32(ISA, op);

// general purpose registers
rp_gpr #(
  .AW  (ISA.ie ? 4 : 5),
  .XW  (XW)
) gpr (
  // system signals
  .clk    (clk),
  .rst    (rst),
  // read/write enable
//.e_rs1  (),
//.e_rs2  (),
  .e_rd   (ctl.i.wb != WB_XXX),
  // read/write address
  .a_rs1  (op.r.rs1),
  .a_rs2  (op.r.rs2),
  .a_rd   (op.r.rd ),
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
  unique case (ctl.i.a1)
    A1_RS1: alu_rs1 = gpr_rs1;
    A1_PC : alu_rs1 = XW'(pc);
  endcase
  // RS2
  unique case (ctl.i.a2)
    A2_RS2: alu_rs2 = gpr_rs2;
    A2_IMM: alu_rs2 = ctl.i.imm;
  endcase
end

rp_alu #(
  .XW  (XW)
) alu (
  // control
  .ctl  (ctl.i.ao),
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
assign bud_req = (ctl.i.st != ST_X) | (ctl.i.ld != LD_XX);

// write enable
assign bud_wen = (ctl.i.st != ST_X);

// address
assign bud_adr = alu_sum[DAW-1:0];

// byte select
// TODO
assign bud_sel = '1;

// write data
assign bud_wdt = gpr_rd;

endmodule: rp_core
