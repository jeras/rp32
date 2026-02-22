///////////////////////////////////////////////////////////////////////////////
// RISC-V ISA base I extension package (based on ISA spec)
///////////////////////////////////////////////////////////////////////////////
// Copyright 2022 Iztok Jeras
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
///////////////////////////////////////////////////////////////////////////////

`ifdef ALTERA_RESERVED_QIS
`define LANGUAGE_UNSUPPORTED_UNION
`endif

package riscv_isa_i_pkg;

import riscv_isa_pkg::*;
import riscv_priv_pkg::*;

///////////////////////////////////////////////////////////////////////////////
// instruction size (in bytes)
///////////////////////////////////////////////////////////////////////////////

// TODO: rewrite this function so it is correct and fit for synthesis
function automatic int unsigned opsiz (logic [16-1:0] op);
priority casez (op)
//16'b????_????_?1111111:  opsiz = 10 + 2 * op[14:12];
//16'b????_????_?0111111:  opsiz = 8;
//16'b????_????_??011111:  opsiz = 6;
//16'b????_????_???111??,
  16'b????_????_??????11:  opsiz = 4;
  default               :  opsiz = 2;
endcase
endfunction: opsiz

///////////////////////////////////////////////////////////////////////////////
// 32-bit instruction format
///////////////////////////////////////////////////////////////////////////////

// base opcode map
typedef enum logic [6:2] {
  LOAD   = 5'b00_000,  LOAD_FP  = 5'b00_001,  CUSTOM_0   = 5'b00_010,  MISC_MEM = 5'b00_011,  OP_IMM = 5'b00_100,  AUIPC      = 5'b00_101,  OP_IMM_32 = 5'b00_110,  OP_48_1 = 5'b00_111,
  STORE  = 5'b01_000,  STORE_FP = 5'b01_001,  CUSTOM_1   = 5'b01_010,  AMO      = 5'b01_011,  OP     = 5'b01_100,  LUI        = 5'b01_101,  OP_32     = 5'b01_110,  OP_64   = 5'b01_111,
  MADD   = 5'b10_000,  MSUB     = 5'b10_001,  NMSUB      = 5'b10_010,  NMADD    = 5'b10_011,  OP_FP  = 5'b10_100,  RESERVED_6 = 5'b10_101,  CUSTOM_2  = 5'b10_110,  OP_48_2 = 5'b10_111,
  BRANCH = 5'b11_000,  JALR     = 5'b11_001,  RESERVED_A = 5'b11_010,  JAL      = 5'b11_011,  SYSTEM = 5'b11_100,  RESERVED_D = 5'b11_101,  CUSTOM_3  = 5'b11_110,  OP_80   = 5'b11_111
} op32_op62_et;

// function fields
typedef logic [3-1:0] fn3_t;  // funct3
typedef logic [7-1:0] fn7_t;  // funct7

// base opcode map
typedef struct packed {
  op32_op62_et opc;  // base opcode
  logic [1:0]  c11;  // constant 2'b11 got
} op32_opcode_t;

// funct3 arithmetic/logic unit (R/I-type)
typedef enum logic [$bits(fn3_t)-1:0] {
  ADD   = 3'b000,  // funct7[5] ? SUB : ADD
  SL    = 3'b001,  //
  SLT   = 3'b010,  //
  SLTU  = 3'b011,  //
  XOR   = 3'b100,  //
  SR    = 3'b101,  // funct7[5] ? SRA : SRL
  OR    = 3'b110,  //
  AND   = 3'b111   //
} fn3_alu_et;

// funct3 load unit (I-type)
typedef enum logic [$bits(fn3_t)-1:0] {
  LB  = 3'b000,  // RV32I RV64I RV128I
  LH  = 3'b001,  // RV32I RV64I RV128I
  LW  = 3'b010,  // RV32I RV64I RV128I
  LD  = 3'b011,  //       RV64I RV128I
  LBU = 3'b100,  // RV32I RV64I RV128I
  LHU = 3'b101,  // RV32I RV64I RV128I
  LWU = 3'b110,  //       RV64I RV128I
  LDU = 3'b111   //             RV128I
} fn3_ldu_et;
// NOTE: the RV128I instruction LQ (load quad) is under the MISC_MEM opcode

// funct3 store (S-type)
typedef enum logic [$bits(fn3_t)-1:0] {
  SB  = 3'b000,  // RV32I RV64I RV128I
  SH  = 3'b001,  // RV32I RV64I RV128I
  SW  = 3'b010,  // RV32I RV64I RV128I
  SD  = 3'b011,  //       RV64I RV128I
  SQ  = 3'b100   //             RV128I
//    = 3'b101,  //
//    = 3'b110,  //
//    = 3'b111   //
} fn3_stu_et;

// funct3 branch (B-type)
typedef enum logic [$bits(fn3_t)-1:0] {
  BEQ  = 3'b000,  //     equal
  BNE  = 3'b001,  // not equal
//     = 3'b010,
//     = 3'b011,
  BLT  = 3'b100,  // less    then            signed
  BGE  = 3'b101,  // greater then or equal   signed
  BLTU = 3'b110,  // less    then          unsigned
  BGEU = 3'b111   // greater then or equal unsigned
} fn3_bru_et;

// 32-bit instruction format structures
typedef struct packed {logic [4:0] rs3; logic [1:0] fmt;            logic [4:0] rs2; logic [4:0] rs1; fn3_t funct3; logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_r4_t;  // Register 4 (floating point)
typedef struct packed {                               fn7_t funct7; logic [4:0] rs2; logic [4:0] rs1; fn3_t funct3; logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_r_t ;  // Register
typedef struct packed {logic [11:00] imm_11_0;                                       logic [4:0] rs1; fn3_t funct3; logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_i_t ;  // Immediate
typedef struct packed {logic [11:05] imm_11_5;                      logic [4:0] rs2; logic [4:0] rs1; fn3_t funct3; logic [4:0] imm_4_0;                       op32_opcode_t opcode;} op32_s_t ;  // Store
typedef struct packed {logic [12:12] imm_12; logic [10:5] imm_10_5; logic [4:0] rs2; logic [4:0] rs1; fn3_t funct3; logic [4:1] imm_4_1; logic [11:11] imm_11; op32_opcode_t opcode;} op32_b_t ;  // Branch
typedef struct packed {logic [31:12] imm_31_12;                                                                     logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_u_t ;  // Upper immediate
typedef struct packed {logic [20:20] imm_20; logic [10:1] imm_10_1; logic [11:11] imm_11; logic [19:12] imm_19_12;  logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_j_t ;  // Jump

`ifndef LANGUAGE_UNSUPPORTED_UNION
// union of 32-bit instruction formats
typedef union packed {
  op32_r4_t r4;  // Register 4
  op32_r_t  r ;  // Register
  op32_i_t  i ;  // Immediate
  op32_s_t  s ;  // Store
  op32_b_t  b ;  // Branch
  op32_u_t  u ;  // Upper immediate
  op32_j_t  j ;  // Jump
} op32_t;
`else
  typedef logic [32-1:0] op32_t;
`endif

///////////////////////////////////////////////////////////////////////////////
// 32-bit OP immediate decoder
///////////////////////////////////////////////////////////////////////////////

  // immediate signed/unsigned types
  typedef logic   signed [32-1:0] imm_t;
  typedef logic unsigned [32-1:0] immu_t;

  // I-immediate (ALU, load offset)
  function automatic imm_t imm_i_f (op32_i_t op);
    imm_i_f = imm_t'($signed({op.imm_11_0}));
  endfunction: imm_i_f

  // S-immediate (store offset)
  function automatic imm_t imm_s_f (op32_s_t op);
    imm_s_f = imm_t'($signed({op.imm_11_5, op.imm_4_0}));
  endfunction: imm_s_f

  // B-immediate (branch offset)
  function automatic imm_t imm_b_f (op32_b_t op);
    imm_b_f = imm_t'($signed({op.imm_12, op.imm_11, op.imm_10_5, op.imm_4_1, 1'b0}));
  endfunction: imm_b_f

  // U-immediate (ALU upper)
  function automatic imm_t imm_u_f (op32_u_t op);
    imm_u_f = imm_t'($signed({op.imm_31_12, 12'h000}));
  endfunction: imm_u_f

  // J-immediate (ALU jump)
  function automatic imm_t imm_j_f (op32_j_t op);
    imm_j_f = imm_t'($signed({op.imm_20, op.imm_19_12, op.imm_11, op.imm_10_1, 1'b0}));
  endfunction: imm_j_f

///////////////////////////////////////////////////////////////////////////////
// 32-bit OP GPR decoder
///////////////////////////////////////////////////////////////////////////////

  typedef logic [5-1:0] gpr_idx_t;

  // GPR enable
  typedef struct packed {
    logic         rd;   // write enable register destination
    logic         rs1;  // read  enable register source 1
    logic         rs2;  // read  enable register source 2
  } gpr_ena_t;

///////////////////////////////////////////////////////////////////////////////
// I base (32E, 32I, 64I, 128I) data types
///////////////////////////////////////////////////////////////////////////////

// opcode type is just shorter type name for the full type name
typedef op32_op62_et opc_t;

///////////////////////////////////////////////////////////////////////////////
// M standard extension
///////////////////////////////////////////////////////////////////////////////

// funct3 multiply/divide/reminder
typedef enum logic [$bits(fn3_t)-1:0] {
  MUL    = 3'b000,  // multiply
  MULH   = 3'b001,  // multiply high
  MULHSU = 3'b010,  // multiply high signed/unsigned
  MULHU  = 3'b011,  // multiply high unsigned
  DIV    = 3'b100,  // divide
  DIVU   = 3'b101,  // divide unsigned
  REM    = 3'b110,  // reminder
  REMU   = 3'b111   // reminder unsigned
} fn3_mdr_et;

///////////////////////////////////////////////////////////////////////////////
// privileged instructions
///////////////////////////////////////////////////////////////////////////////

// NOTE: only the *RET privilege level is optimally encoded
//       the rest tries to allign with *CAUSE register encoding
// TODO: rethink this encoding
typedef enum logic [4-1:0] {
  PRIV_EBREAK = {2'b00, 2'b11},  // csr_cause_t'(CAUSE_EXC_OP_EBREAK)
  PRIV_ECALL  = {2'b10, 2'b??},  // csr_cause_t'(CAUSE_EXC_OP_*CALL)  for U/S//M modes
  PRIV_WFI    = {2'b11, 2'b11},  //  PRIV_WFI    = {2'b11, 2'bxx},
  PRIV_URET   = {2'b01, LVL_U},
  PRIV_SRET   = {2'b01, LVL_S},
  PRIV_MRET   = {2'b01, LVL_M}
} isa_priv_typ_t;

///////////////////////////////////////////////////////////////////////////////
// Zicsr standard extension
///////////////////////////////////////////////////////////////////////////////

// funct3 CSR unit
typedef enum logic [$bits(fn3_t)-1:0] {
//       = 3'b000,  //
  CSRRW  = 3'b001,  //
  CSRRS  = 3'b010,  //
  CSRRC  = 3'b011,  //
//       = 3'b100,  //
  CSRRWI = 3'b101,  //
  CSRRSI = 3'b110,  //
  CSRRCI = 3'b111   //
} fn3_csr_et;

// CSR address
typedef logic [12-1:0] csr_adr_t;

// CSR immediate (zero extended from 5 to 32 bits
typedef logic [5-1:0] csr_imm_t;

///////////////////////////////////////////////////////////////////////////////
// illegal/... instruction types
///////////////////////////////////////////////////////////////////////////////

typedef enum {
  STD,  // standard
  RES,  // REServed for future standard extensions
  NSE,  // reserved for custom extensions (Non Standard Extension)
  HNT,  // HINT
  ILL   // illegal
} ill_t;

///////////////////////////////////////////////////////////////////////////////
// decoder structure
///////////////////////////////////////////////////////////////////////////////

  typedef struct {
    // instruction encodings
    ill_t     ill;  // illegal
    integer   siz;  // instruction size
    opc_t     opc;  // operation code
    fn3_t     fn3;  // func3
    fn7_t     fn7;  // func7
    // GPR indexes
    gpr_idx_t rd ;  // destination register index
    gpr_idx_t rs1;  // register source 1 index
    gpr_idx_t rs2;  // register source 2 index
    gpr_ena_t gpr;  // GPR read write enable for {rd, rs1, rs2}
    // immediates
    imm_t     i_i;  // I-immediate (ALU)
    imm_t     i_l;  // I-immediate (load offset) used in C extension
    imm_t     i_s;  // S-immediate (store offset)
    imm_t     i_b;  // B-immediate (branch offset)
    imm_t     i_u;  // U-immediate (ALU upper)
    imm_t     i_j;  // J-immediate (ALU jump)
    // CSR
    csr_adr_t csr;
    csr_imm_t i_c;
  } dec_t;

///////////////////////////////////////////////////////////////////////////////
// 32-bit instruction decoder
///////////////////////////////////////////////////////////////////////////////

// instruction decoder
`ifndef LANGUAGE_UNSUPPORTED_UNION
function automatic dec_t dec32 (isa_t isa, op32_t op);
`else
function automatic dec_t dec32 (isa_t isa, op32_r_t op);
`endif

  // set instruction size
  dec32.siz = 4;

  // RV32 I base extension
  unique casez (op)
    //  fedc_ba98_7654_3210_fedc_ba98_7654_3210
    32'b0000_0000_0000_0000_0000_0000_0000_0000: dec32.ill = ILL;  // illegal instruction
    32'b????_????_????_????_????_????_?011_0111: dec32.ill = STD;  // LUI
    32'b????_????_????_????_????_????_?001_0111: dec32.ill = STD;  // AUIPC
    32'b????_????_????_????_????_????_?110_1111: dec32.ill = STD;  // JAL  TODO: Instruction-address-misaligned exception
    32'b????_????_????_????_?000_????_?110_0111: dec32.ill = STD;  // JALR TODO: Instruction-address-misaligned exception
    32'b????_????_????_????_?000_????_?110_0011: dec32.ill = STD;  // BEQ
    32'b????_????_????_????_?001_????_?110_0011: dec32.ill = STD;  // BNE
    32'b????_????_????_????_?100_????_?110_0011: dec32.ill = STD;  // BLT
    32'b????_????_????_????_?101_????_?110_0011: dec32.ill = STD;  // BGE
    32'b????_????_????_????_?110_????_?110_0011: dec32.ill = STD;  // BLTU
    32'b????_????_????_????_?111_????_?110_0011: dec32.ill = STD;  // BGEU
    32'b????_????_????_????_?000_????_?000_0011: dec32.ill = STD;  // LB
    32'b????_????_????_????_?001_????_?000_0011: dec32.ill = STD;  // LH
    32'b????_????_????_????_?010_????_?000_0011: dec32.ill = STD;  // LW
    32'b????_????_????_????_?100_????_?000_0011: dec32.ill = STD;  // LBU
    32'b????_????_????_????_?101_????_?000_0011: dec32.ill = STD;  // LHU
    32'b????_????_????_????_?000_????_?010_0011: dec32.ill = STD;  // SB
    32'b????_????_????_????_?001_????_?010_0011: dec32.ill = STD;  // SH
    32'b????_????_????_????_?010_????_?010_0011: dec32.ill = STD;  // SW
    32'b????_????_????_????_?000_????_?001_0011: dec32.ill = STD;  // ADDI
    32'b????_????_????_????_?010_????_?001_0011: dec32.ill = STD;  // SLTI
    32'b????_????_????_????_?011_????_?001_0011: dec32.ill = STD;  // SLTIU
    32'b????_????_????_????_?100_????_?001_0011: dec32.ill = STD;  // XORI
    32'b????_????_????_????_?110_????_?001_0011: dec32.ill = STD;  // ORI
    32'b????_????_????_????_?111_????_?001_0011: dec32.ill = STD;  // ANDI
    32'b0000_000?_????_????_?001_????_?001_0011: dec32.ill = STD;  // SLLI
    32'b0000_000?_????_????_?101_????_?001_0011: dec32.ill = STD;  // SRLI
    32'b0100_000?_????_????_?101_????_?001_0011: dec32.ill = STD;  // SRAI
    32'b0000_000?_????_????_?000_????_?011_0011: dec32.ill = STD;  // ADD
    32'b0100_000?_????_????_?000_????_?011_0011: dec32.ill = STD;  // SUB
    32'b0000_000?_????_????_?010_????_?011_0011: dec32.ill = STD;  // SLT
    32'b0000_000?_????_????_?011_????_?011_0011: dec32.ill = STD;  // SLTU
    32'b0000_000?_????_????_?100_????_?011_0011: dec32.ill = STD;  // XOR
    32'b0000_000?_????_????_?001_????_?011_0011: dec32.ill = STD;  // SLL
    32'b0000_000?_????_????_?101_????_?011_0011: dec32.ill = STD;  // SRL
    32'b0100_000?_????_????_?101_????_?011_0011: dec32.ill = STD;  // SRA
    32'b0000_000?_????_????_?110_????_?011_0011: dec32.ill = STD;  // OR
    32'b0000_000?_????_????_?111_????_?011_0011: dec32.ill = STD;  // AND
    32'b????_????_????_????_?000_????_?000_1111: dec32.ill = STD;  // FENCE
    default                                    : dec32.ill = ILL;  // illegal
  endcase

  // operation code
  `ifndef LANGUAGE_UNSUPPORTED_UNION
  dec32.opc = op.r.opcode.opc;
  `else
  dec32.opc = opc_t'(op[6:2]);
  `endif

  // GPR index
  `ifndef LANGUAGE_UNSUPPORTED_UNION
  dec32.rd  = op.r.rd ;
  dec32.rs1 = op.r.rs1;
  dec32.rs2 = op.r.rs2;
  `else
  dec32.rd  = op.rd ;
  dec32.rs1 = op.rs1;
  dec32.rs2 = op.rs2;
  `endif

  // GPR enable decoder is based on opcode
  `ifndef LANGUAGE_UNSUPPORTED_UNION
  unique case (opc_t'(op.r.opcode.opc))
  `else
  unique case (opc_t'(op[6:2]))
  `endif
    //                     rd,rs1,rs2
    LUI    ,
    AUIPC  : dec32.gpr = '{'1, '0, '0};
    JAL    : dec32.gpr = '{'1, '0, '0};
    JALR   : dec32.gpr = '{'1, '1, '0};
    BRANCH : dec32.gpr = '{'0, '1, '1};
    LOAD   : dec32.gpr = '{'1, '1, '0};
    STORE  : dec32.gpr = '{'0, '1, '1};
    OP_IMM : dec32.gpr = '{'1, '1, '0};
    OP     : dec32.gpr = '{'1, '1, '1};
    default: dec32.gpr = '{'0, '0, '0};
  endcase

  // func3/func7
  `ifndef LANGUAGE_UNSUPPORTED_UNION
  dec32.fn3 = op.r.funct3;
  dec32.fn7 = op.r.funct7;
  `else
  dec32.fn3 = op  .funct3;
  dec32.fn7 = op  .funct7;
  `endif

  // immediates
  dec32.i_b = imm_b_f(op32_b_t'(op));
  dec32.i_i = imm_i_f(op32_i_t'(op));
  dec32.i_l = imm_i_f(op32_i_t'(op));
  dec32.i_s = imm_s_f(op32_s_t'(op));
  dec32.i_u = imm_u_f(op32_u_t'(op));
  dec32.i_j = imm_j_f(op32_j_t'(op));

  // CSR
  // TODO: organize better
  dec32.csr = op[31:20];
  dec32.i_c = op[19:15];

endfunction: dec32

///////////////////////////////////////////////////////////////////////////////
// 32-bit instruction encoder
///////////////////////////////////////////////////////////////////////////////

`ifndef LANGUAGE_UNSUPPORTED_UNION
function automatic op32_t enc32 (isa_t isa, dec_t ctl);
`else
function automatic op32_t enc32 (isa_t isa, dec_t ctl);
`endif

  // idle
  logic IDL = 1'b0;

  // templates
  op32_r_t t_op    ;
  op32_i_t t_op_imm;
  op32_i_t t_load  ;
  op32_s_t t_store ;
  op32_b_t t_branch;
  op32_j_t t_jal   ;
  op32_i_t t_jalr  ;
  op32_u_t t_ui    ;

  // OP
  t_op    .opcode    = '{opc: ctl.opc, c11: 2'b11};
  t_op    .funct7    = ctl.fn7;
  t_op    .funct3    = ctl.fn3;
  t_op    .rs2       = ctl.rs2;
  t_op    .rs1       = ctl.rs1;
  t_op    .rd        = ctl.rd ;

  // OP_IMM
  t_op_imm.opcode    = '{opc: ctl.opc, c11: 2'b11};
  case (ctl.fn3)
    SR, SL :  t_op_imm.imm_11_0 = {ctl.fn7, ctl.i_i[5-1:0]};  // TODO: this at least partially depends on XLEN (shift ammount can be 5 or 6 bits)
    default:  t_op_imm.imm_11_0 =           ctl.i_i[11:0];
  endcase
  t_op_imm.funct3    = ctl.fn3;
  t_op_imm.rs1       = ctl.rs1;
  t_op_imm.rd        = ctl.rd ;

  // LOAD
  t_load  .opcode    = '{opc: ctl.opc, c11: 2'b11};
  t_load  .imm_11_0  = ctl.i_i[11:0];
  t_load  .funct3    = ctl.fn3;
  t_load  .rs1       = ctl.rs1;
  t_load  .rd        = ctl.rd ;

  // STORE
  t_store .opcode    = '{opc: ctl.opc, c11: 2'b11};
  t_store .imm_11_5  = ctl.i_s[11:5];
  t_store .imm_4_0   = ctl.i_s[4:0];
  t_store .funct3    = ctl.fn3;
  t_store .rs2       = ctl.rs2;
  t_store .rs1       = ctl.rs1;

  // BRANCH
  t_branch.opcode    = '{opc: ctl.opc, c11: 2'b11};
  t_branch.imm_12    = ctl.i_b[12];
  t_branch.imm_11    = ctl.i_b[11];
  t_branch.imm_10_5  = ctl.i_b[10:5];
  t_branch.imm_4_1   = ctl.i_b[4:1];
  t_branch.funct3    = ctl.fn3;
  t_branch.rs2       = ctl.rs2;
  t_branch.rs1       = ctl.rs1;

  // JAL
  t_jal   .opcode    = '{opc: ctl.opc, c11: 2'b11};
  t_jal   .imm_20    = ctl.i_j[20];
  t_jal   .imm_10_1  = ctl.i_j[10:1];
  t_jal   .imm_11    = ctl.i_j[11];
  t_jal   .imm_19_12 = ctl.i_j[19:12];
  t_jal   .rd        = ctl.rd ;

  // JALR
  t_jalr  .opcode    = '{opc: ctl.opc, c11: 2'b11};
  t_jalr  .imm_11_0  = ctl.i_i[11:0];
  t_jalr  .funct3    = {3{IDL}};  // TODO: 'x is an option?
  t_jalr  .rs1       = ctl.rs1;
  t_jalr  .rd        = ctl.rd ;

  // LUI/AUIPC
  t_ui    .opcode    = '{opc: ctl.opc, c11: 2'b11};
  t_ui    .imm_31_12 = ctl.i_u[31:12];
  t_ui    .rd        = ctl.rd ;

  // multiplexer
  unique case (ctl.opc)
    OP     : enc32 = t_op    ;
    OP_IMM : enc32 = t_op_imm;
    LOAD   : enc32 = t_load  ;
    STORE  : enc32 = t_store ;
    BRANCH : enc32 = t_branch;
    JAL    : enc32 = t_jal   ;
    JALR   : enc32 = t_jalr  ;
    LUI    ,
    AUIPC  : enc32 = t_ui    ;
    default: enc32 = '0;  // TODO: 'x is an option
  endcase

endfunction: enc32

endpackage: riscv_isa_i_pkg
