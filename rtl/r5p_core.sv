import riscv_isa_pkg::*;
import riscv_csr_pkg::*;

module r5p_core #(
  // RISC-V ISA
  int unsigned XLEN = 32,   // is used to quickly switch between 32 and 64 for testing
  // extensions  (see `riscv_isa_pkg` for enumeration definition)
  isa_ext_t    XTEN = RV_M | RV_C,
  // privilige modes
  isa_priv_t   MODES = MODES_M,
  // ISA
  isa_t        ISA = XLEN==32 ? '{'{RV_32I , XTEN}, MODES}
                   : XLEN==64 ? '{'{RV_64I , XTEN}, MODES}
                              : '{'{RV_128I, XTEN}, MODES},
  // privilege implementation details
  csr_vector_t VEC = MODE_DIRECT,  // mtvec MODE
  // instruction bus
  int unsigned IAW = 32,    // program address width
  int unsigned IDW = 32,    // program data    width
  int unsigned IBW = IDW/8, // program byte en width
  // data bus
  int unsigned DAW = 32,    // data    address width
  int unsigned DDW = XLEN,  // data    data    width
  int unsigned DBW = DDW/8, // data    byte en width
  // constants ???
  logic [XLEN-1:0] MTVEC = 'h0000_0000,  // machine trap vector
  logic [XLEN-1:0] PC0   = 'h0000_0080   // reset vector
)(
  // system signals
  input  logic                  clk,
  input  logic                  rst,
  // program bus (instruction fetch)
  output logic                  if_req,
  output logic [IAW-1:0]        if_adr,
  input  logic [IBW-1:0][8-1:0] if_rdt,
  input  logic                  if_ack,
  // data bus (load/store)
  output logic                  ls_req,  // write or read request
  output logic                  ls_wen,  // write enable
  output logic [DAW-1:0]        ls_adr,  // address
  output logic [DBW-1:0]        ls_ben,  // byte enable
  output logic [DBW-1:0][8-1:0] ls_wdt,  // write data
  input  logic [DBW-1:0][8-1:0] ls_rdt,  // read data
  input  logic                  ls_ack   // write or read acknowledge
);

///////////////////////////////////////////////////////////////////////////////
// local signals
///////////////////////////////////////////////////////////////////////////////

// instruction fetch
logic            if_run;  // running status
logic            if_tkn;  // taken
logic  [IAW-1:0] if_pc;   // program counter
logic  [IAW-1:0] if_pcn;  // program counter next
logic  [IAW-1:0] if_pca;  // program counter addend
logic  [IAW-1:0] if_pcs;  // program counter sum
//logic  [IAW-1:0] if_pci;  // program counter incrementing adder
//logic  [IAW-1:0] if_pcb;  // program counter branch adder
logic            stall;

// instruction decode
op32_t           id_op32; // 32-bit operation code
op16_t           id_op16; // 16-bit operation code
ctl_t            id_ctl;  // control structure
logic            id_vld;  // instruction valid

// GPR
logic [XLEN-1:0] gpr_rs1;  // register source 1
logic [XLEN-1:0] gpr_rs2;  // register source 2
logic [XLEN-1:0] gpr_rd ;  // register destination

// ALU
logic [XLEN-1:0] alu_rd ;  // register destination

// MUL/DIV/REM
logic [XLEN-1:0] mul_rd;   // multiplier unit outpLENt

// CSR
logic [XLEN-1:0] csr_rdt;  // read  data

// CSR address map union
csr_map_ut       csr_csr;

logic [XLEN-1:0] csr_tvec;
logic [XLEN-1:0] csr_epc ;

// load/sore unit temporary signals
logic [XLEN-1:0] lsu_adr;  // address
logic [XLEN-1:0] lsu_wdt;  // write data
logic [XLEN-1:0] lsu_rdt;  // read data
logic            lsu_mal;  // MisALigned
logic            lsu_dly;  // DeLaYed writeback enable

///////////////////////////////////////////////////////////////////////////////
// instruction fetch
///////////////////////////////////////////////////////////////////////////////

// start running after reset
always_ff @ (posedge clk, posedge rst)
if (rst)  if_run <= 1'b0;
else      if_run <= 1'b1;

// request becomes active after reset
assign if_req = if_run & ~(ls_req & ~ls_wen);

// PC next is used as IF address
assign if_adr = if_pcn;

// instruction valid
always_ff @ (posedge clk, posedge rst)
if (rst)  id_vld <= 1'b0;
else      id_vld <= (if_req & if_ack) | (id_vld & stall);

///////////////////////////////////////////////////////////////////////////////
// program counter
///////////////////////////////////////////////////////////////////////////////

// TODO:
assign stall = (if_req & ~if_ack) | (ls_req & ~ls_ack) | (ls_req & ~ls_wen);

// program counter
always_ff @ (posedge clk, posedge rst)
if (rst)  if_pc <= IAW'(PC0);
else begin
  if (id_vld & ~stall) if_pc <= if_pcn;
end

generate
//if (CFG_BRU) begin
if (0) begin

  // branch ALU for checking branch conditions
  r5p_br #(
    .XLEN    (XLEN)
  ) br (
    // control
    .ctl     (id_ctl.i.br),
    // data
    .rs1     (gpr_rs1),
    .rs2     (gpr_rs2),
    // status
    .tkn     (if_tkn)
  );

end else begin

  always_comb
  case (id_ctl.i.br) inside
    BEQ    : if_tkn = ~(|alu_rd);
    BNE    : if_tkn =  (|alu_rd);
    BLT    : if_tkn =    alu_rd[0];
    BGE    : if_tkn = ~  alu_rd[0];
    BLTU   : if_tkn =    alu_rd[0];
    BGEU   : if_tkn = ~  alu_rd[0];
    default: if_tkn = 'x;
  endcase

end
endgenerate

// TODO: optimization parameters
// 1. branch immediate direct branch type decoder (kind of obvious, but see if it beats the tool optimizations)
// 2. separate adder for PC next and branch address, since mux control signal from ALU is late and is best used just before output
// 3. a separate branch ALU with explicit [un]signed comparator instead of adder in the main ALU
// 4. split PC adder into 12-bit immediate adder and the rest is an incrementer/decrementer, calculate both increment and decrement in advance.

// program counter incrementing adder
//assign if_pci = if_pc + IAW'(opsiz(id_op16[16-1:0]));

// branch address adder
//assign if_pcb = if_pc + IAW'(imm32(id_op32,T_B));
//assign if_pcb = if_pc + IAW'(id_ctl.imm);

// PC addend
assign if_pca = (id_ctl.i.pc == PC_BRN) & if_tkn ? IAW'(id_ctl.imm)
                                                 : IAW'(opsiz(id_op16[16-1:0]));

// PC sum
assign if_pcs = if_pc + if_pca;

// program counter next
always_comb
if (if_ack & id_vld) begin
  case (id_ctl.i.pc)
    PC_PCI,
    PC_BRN : if_pcn = if_pcs;
    PC_JMP : if_pcn = {alu_rd[IAW-1:1], 1'b0};
    PC_TRP : if_pcn = IAW'(csr_tvec);
    PC_EPC : if_pcn = IAW'(csr_epc);
    default: if_pcn = 'x;
  endcase
end else begin
  if_pcn = if_pc;
end

///////////////////////////////////////////////////////////////////////////////
// instruction decode
///////////////////////////////////////////////////////////////////////////////

// opcode from instruction fetch
assign id_op32 = if_rdt[4-1:0];
assign id_op16 = if_rdt[2-1:0];

// 32-bit instruction decoder
assign id_ctl = dec(ISA, id_op32);

///////////////////////////////////////////////////////////////////////////////
// execute
///////////////////////////////////////////////////////////////////////////////

// general purpose registers
r5p_gpr #(
  .AW      (ISA.spec.base.E ? 4 : 5),
  .XLEN    (XLEN)
) gpr (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // read/write enable
  .e_rs1   (id_ctl.gpr.e.rs1),
  .e_rs2   (id_ctl.gpr.e.rs2),
  .e_rd    (id_ctl.gpr.e.rd & (id_ctl.i.wb == WB_MEM ? lsu_dly : 1'b1)),
  // read/write address
  .a_rs1   (id_ctl.gpr.a.rs1),
  .a_rs2   (id_ctl.gpr.a.rs2),
  .a_rd    (id_ctl.gpr.a.rd ),
  // read/write data
  .d_rs1   (gpr_rs1),
  .d_rs2   (gpr_rs2),
  .d_rd    (gpr_rd )
);

// base ALU
r5p_alu #(
  .XLEN    (XLEN)
) alu (
   // system signals
  .clk     (clk),
  .rst     (rst),
  // control
  .ctl     (id_ctl.i.alu),
  // data input/output
  .imm     (XLEN'(id_ctl.imm)),
  .pc      (XLEN'(if_pc)),
  .rs1     (gpr_rs1),
  .rs2     (gpr_rs2),
  .rd      (alu_rd )
);

// mul/div/rem unit
r5p_mdu #(
  .XLEN    (XLEN)
) mdu (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // control
  .ctl     (id_ctl.m),
  // data input/output
  .rs1     (gpr_rs1),
  .rs2     (gpr_rs2),
  .rd      (mul_rd )
);

///////////////////////////////////////////////////////////////////////////////
// CSR
///////////////////////////////////////////////////////////////////////////////

r5p_csr #(
  .ISA     (ISA),
  .XLEN    (XLEN),
  .MTVEC   (MTVEC)
) csr (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // control
  .ctl     (id_ctl.csr),
  // data input/output
  .wdt     (gpr_rs1),
  .rdt     (csr_rdt),
  // CSR address map union
  .csr     (csr_csr),
  // TODO
  .priv_i  (id_ctl.priv),
  .trap_i  (id_ctl.i.pc == PC_TRP),
  .cause_i (CAUSE_EXC_OP_EBREAK),
  .epc_i   (XLEN'(if_pcs  )),
  .tvec    (csr_tvec),
  .epc_o   (csr_epc )
);

///////////////////////////////////////////////////////////////////////////////
// load/store
///////////////////////////////////////////////////////////////////////////////

// intermediate signals
assign lsu_adr = alu_rd;  // TODO: use ALU destination RPG data output
assign lsu_wdt = gpr_rs2;

// load/store unit
r5p_lsu #(
  .XLEN    (XLEN),
  // data bus
  .AW      (DAW),
  .DW      (DDW),
  .BW      (DBW)
) lsu (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // control
  .ctl     (id_ctl.i.lsu),
  // data input/output
  .adr     (lsu_adr),
  .wdt     (lsu_wdt),
  .rdt     (lsu_rdt),
  .mal     (lsu_mal),
  .dly     (lsu_dly),
  // data bus (load/store)
  .ls_req  (ls_req),
  .ls_wen  (ls_wen),
  .ls_adr  (ls_adr),
  .ls_ben  (ls_ben),
  .ls_wdt  (ls_wdt),
  .ls_rdt  (ls_rdt),
  .ls_ack  (ls_ack)
);

///////////////////////////////////////////////////////////////////////////////
// write back
///////////////////////////////////////////////////////////////////////////////

// write back multiplexer
always_comb begin
  unique case (id_ctl.i.wb)
    WB_ALU : gpr_rd = alu_rd;             // ALU output
    WB_MEM : gpr_rd = lsu_rdt;            // memory read data
    WB_PCI : gpr_rd = XLEN'(if_pcs);      // PC increment
    WB_IMM : gpr_rd = XLEN'(id_ctl.imm);  // immediate  // TODO: optimize this code // imm32(id_op32, T_U)
    WB_CSR : gpr_rd = csr_rdt;            // CSR
    WB_MUL : gpr_rd = mul_rd;             // mul/div/rem
    default: gpr_rd = 'x;                 // none
  endcase
end

endmodule: r5p_core