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

typedef logic [3-1:0] fn3_t;

// base opcode map
typedef struct packed {
  op32_op62_et opc;  // base opcode
  logic [1:0]  c11;  // constant 2'b11 got
} op32_opcode_t;

// func3 arithetic/logic unit (R/I-type)
typedef enum logic [$bits(fn3_t)-1:0] {
  ADD   = 3'b000,  // func7[5] ? SUB : ADD
  SL    = 3'b001,  //
  SLT   = 3'b010,  //
  SLTU  = 3'b011,  //
  XOR   = 3'b100,  //
  SR    = 3'b101,  // func7[5] ? SRA : SRL
  OR    = 3'b110,  //
  AND   = 3'b111   //
} fn3_alu_et;

// func3 load unit (I-type)
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

// func3 store (S-type)
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

// func3 branch (B-type)
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
typedef struct packed {logic [4:0] rs3; logic [1:0] func2;          logic [4:0] rs2; logic [4:0] rs1; fn3_t func3; logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_r4_t;  // Register 4 (floating point)
typedef struct packed {                 logic [6:0] func7;          logic [4:0] rs2; logic [4:0] rs1; fn3_t func3; logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_r_t ;  // Register
typedef struct packed {logic [11:00] imm_11_0;                                       logic [4:0] rs1; fn3_t func3; logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_i_t ;  // Immediate
typedef struct packed {logic [11:05] imm_11_5;                      logic [4:0] rs2; logic [4:0] rs1; fn3_t func3; logic [4:0] imm_4_0;                       op32_opcode_t opcode;} op32_s_t ;  // Store
typedef struct packed {logic [12:12] imm_12; logic [10:5] imm_10_5; logic [4:0] rs2; logic [4:0] rs1; fn3_t func3; logic [4:1] imm_4_1; logic [11:11] imm_11; op32_opcode_t opcode;} op32_b_t ;  // Branch
typedef struct packed {logic [31:12] imm_31_12;                                                                    logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_u_t ;  // Upper immediate
typedef struct packed {logic [20:20] imm_20; logic [10:1] imm_10_1; logic [11:11] imm_11; logic [19:12] imm_19_12; logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_j_t ;  // Jump

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
`endif

///////////////////////////////////////////////////////////////////////////////
// 32-bit OP immediate decoder
///////////////////////////////////////////////////////////////////////////////

// per instruction format type definitions
typedef logic signed [12  -1:0] imm_i_t;  // 12's
typedef imm_i_t                 imm_l_t;  // 12's
typedef logic signed [12  -1:0] imm_s_t;  // 12's
typedef logic signed [12+1-1:0] imm_b_t;  // 13's
typedef logic signed [32  -1:0] imm_u_t;  // 32's
typedef logic signed [20    :0] imm_j_t;  // 21's
typedef logic signed [ 6  -1:0] imm_a_t;  //  6'u
// NOTE: there is no load format, 32-bit load instructions use the I-type

// ALU/load immediate (I-type)
function automatic imm_i_t imm_i_f (op32_i_t op);
  imm_i_f = $signed({op.imm_11_0});
endfunction: imm_i_f

// store immediate (S-type)
function automatic imm_s_t imm_s_f (op32_s_t op);
  imm_s_f = $signed({op.imm_11_5, op.imm_4_0});
endfunction: imm_s_f

// branch immediate (B-type)
function automatic imm_b_t imm_b_f (op32_b_t op);
  imm_b_f = $signed({op.imm_12, op.imm_11, op.imm_10_5, op.imm_4_1, 1'b0});
endfunction: imm_b_f

// ALU upper immediate (must be signed for RV64)
function automatic imm_u_t imm_u_f (op32_u_t op);
  imm_u_f = $signed({op.imm_31_12, 12'h000});
endfunction: imm_u_f

// ALU jump immediate
function automatic imm_j_t imm_j_f (op32_j_t op);
  imm_j_f = $signed({op.imm_20, op.imm_19_12, op.imm_11, op.imm_10_1, 1'b0});
endfunction: imm_j_f
// jump addition is done in ALU while the PC adder is used to calculate the link address

// shift ammount immediate (I-type)
function automatic imm_a_t imm_a_f (op32_i_t op);
  imm_a_f = op.imm_11_0[6-1:0];
endfunction: imm_a_f

///////////////////////////////////////////////////////////////////////////////
// 32-bit OP GPR decoder
///////////////////////////////////////////////////////////////////////////////

// TODO: change when Verilator supports unpacked structures
// GPR enable
typedef struct packed {
  logic         rd;   // write enable register destination
  logic         rs1;  // read  enable register source 1
  logic         rs2;  // read  enable register source 2
} gpr_ena_t;

// GPR address
typedef struct packed {
  logic [5-1:0] rd ;  // address register destination (write)
  logic [5-1:0] rs1;  // address register source 1 (read)
  logic [5-1:0] rs2;  // address register source 2 (read)
} gpr_adr_t;

typedef struct packed {
  gpr_ena_t ena;  // enable
  gpr_adr_t adr;  // address
} ctl_gpr_t;

///////////////////////////////////////////////////////////////////////////////
// I base (32E, 32I, 64I, 128I) data types
///////////////////////////////////////////////////////////////////////////////

// opcode type is just shorter type name for the full type name
typedef op32_op62_et opc_t;

// branch unit
typedef struct packed {
  fn3_bru_et fn3;  // func3
  imm_b_t    imm;  // immediate
} ctl_bru_t;

// arithmetic/logic unit
typedef struct packed {
  logic      f75;  // used for subtraction and arithmetic/logic shifts
  fn3_alu_et fn3;  // func3
  imm_i_t    imm;  // immediate
} ctl_alu_t;

// load unit
typedef struct packed {
  fn3_ldu_et fn3;  // func3
  imm_l_t    imm;  // immediate
} ctl_ldu_t;

// store unit
typedef struct packed {
  fn3_stu_et fn3;  // func3
  imm_s_t    imm;  // immediate
} ctl_stu_t;

// upper immediate unit
typedef struct packed {
  imm_u_t    imm;  // immediate
} ctl_uiu_t;

// jump unit
typedef struct packed {
  imm_i_t    imm;  // immediate
  imm_j_t    jmp;  // immediate
} ctl_jmp_t;

///////////////////////////////////////////////////////////////////////////////
// M statndard extension
///////////////////////////////////////////////////////////////////////////////

// func3 multiply/divide/reminder
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

// control structure
// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  logic          ena;  // enable
  isa_priv_typ_t typ;  // type
} ctl_priv_t;

///////////////////////////////////////////////////////////////////////////////
// Zicsr standard extension
///////////////////////////////////////////////////////////////////////////////

// func3 CSR unit
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
// NOTE: the RV128I instruction LQ (load quad) is under the MISC_MEM opcode

// CSR immediate (zero extended from 5 to 32 bits
typedef logic [5-1:0] csr_imm_t;

// control structure
// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  fn3_csr_et fn3;  // func3
  csr_adr_t  adr;  // address
  csr_imm_t  imm;  // immediate
} ctl_csr_t;

///////////////////////////////////////////////////////////////////////////////
// illegal instruction
///////////////////////////////////////////////////////////////////////////////

typedef enum {
  STD,  // standard
  RES,  // REServed for future standard extensions
  NSE,  // reserved for custom extensions (Non Standard Extension)
  HNT,  // HINT
  ILL   // illegal
} ill_t;

///////////////////////////////////////////////////////////////////////////////
// controller
///////////////////////////////////////////////////////////////////////////////

// control structure
// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  ill_t     ill;     // illegal
  integer   siz;     // instruction size
  opc_t     opc;     // operation code
  ctl_gpr_t gpr;     // GPR control/address
  ctl_bru_t bru;     // branch unit
  ctl_alu_t alu;     // arithmetic/logic unit
  ctl_ldu_t ldu;     // load unit
  ctl_stu_t stu;     // store unit
  ctl_uiu_t uiu;     // upper immediate unit
  ctl_jmp_t jmp;     // jump unit

//ctl_m_t    m;       // integer multiplication and division
//ctl_a_t    a;       // atomic
//ctl_f_t    f;       // single-precision floating-point
//ctl_d_t    d;       // double-precision floating-point
//ctl_fnc_t  fnc;     // instruction fence
  ctl_csr_t csr;     // CSR operation
//ctl_q_t    q;       // quad-precision floating-point
//ctl_l_t    l;       // decimal precision floating-point
//ctl_b_t    b;       // bit manipulation
//ctl_j_t    j;       // dynamically translated languages
//ctl_t_t    t;       // transactional memory
//ctl_p_t    p;       // packed-SIMD
//ctl_v_t    v;       // vector operations
//ctl_n_t    n;       // user-level interrupts
//  ctl_prv_t prv;    // priviliged spec instructions
} ctl_t;

///////////////////////////////////////////////////////////////////////////////
// 32-bit instruction decoder
///////////////////////////////////////////////////////////////////////////////

// instruction decoder
`ifndef LANGUAGE_UNSUPPORTED_UNION
function automatic ctl_t dec32 (isa_t isa, op32_t op);
`else
function automatic ctl_t dec32 (isa_t isa, op32_r_t op);
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

  // GPR address
  `ifndef LANGUAGE_UNSUPPORTED_UNION
  dec32.gpr.adr = '{rd: op.r.rd, rs1: op.r.rs1, rs2: op.r.rs2};
  `else
  dec32.gpr.adr = '{rd: op.rd, rs1: op.rs1, rs2: op.rs2};
  `endif

  // GPR decoder is based on opcode
  `ifndef LANGUAGE_UNSUPPORTED_UNION
  unique case (opc_t'(op.r.opcode.opc))
  `else
  unique case (opc_t'(op[6:2]))
  `endif
    //                         rd,rs1,rs2
    LUI    ,
    AUIPC  : dec32.gpr.ena = '{'1, '0, '0};
    JAL    : dec32.gpr.ena = '{'1, '0, '0};
    JALR   : dec32.gpr.ena = '{'1, '1, '0};
    BRANCH : dec32.gpr.ena = '{'0, '1, '1};
    LOAD   : dec32.gpr.ena = '{'1, '1, '0};
    STORE  : dec32.gpr.ena = '{'0, '1, '1};
    OP_IMM : dec32.gpr.ena = '{'1, '1, '0};
    OP     : dec32.gpr.ena = '{'1, '1, '1};
    default: dec32.gpr.ena = '{'0, '0, '0};
  endcase

  // branch unit
  `ifndef LANGUAGE_UNSUPPORTED_UNION
  dec32.bru.fn3 = fn3_bru_et'(op.b.func3);
  `else
  dec32.bru.fn3 = fn3_bru_et'(op  .func3);
  `endif
  dec32.bru.imm = imm_b_f(op);

  // arithmetic/logic unit
  `ifndef LANGUAGE_UNSUPPORTED_UNION
  dec32.alu.f75 =             op.r.func7[5];
  dec32.alu.fn3 = fn3_alu_et'(op.r.func3)  ;
  `else
  dec32.alu.f75 =             op  .func7[5];
  dec32.alu.fn3 = fn3_alu_et'(op  .func3)  ;
  `endif
  dec32.alu.imm = imm_i_f(op);

  // load unit
  `ifndef LANGUAGE_UNSUPPORTED_UNION
  dec32.ldu.fn3 = fn3_ldu_et'(op.i.func3);
  `else
  dec32.ldu.fn3 = fn3_ldu_et'(op  .func3);
  `endif
  dec32.ldu.imm = imm_i_f(op);

  // store unit
  `ifndef LANGUAGE_UNSUPPORTED_UNION
  dec32.stu.fn3 = fn3_stu_et'(op.s.func3);
  `else
  dec32.stu.fn3 = fn3_stu_et'(op.  func3);
  `endif
  dec32.stu.imm = imm_s_f(op);

  // upper immediate unit
  dec32.uiu.imm = imm_u_f(op);

  // jump unit
  dec32.jmp.imm = imm_i_f(op);
  dec32.jmp.jmp = imm_j_f(op);

endfunction: dec32

///////////////////////////////////////////////////////////////////////////////
// 32-bit instruction encoder
///////////////////////////////////////////////////////////////////////////////

`ifndef LANGUAGE_UNSUPPORTED_UNION
function automatic op32_t enc32 (isa_t isa, ctl_t ctl);
`else
function automatic op32_r_t enc32 (isa_t isa, ctl_t ctl);
`endif

  // idle 
  logic IDL = 1'b0;

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
  t_op    .func7     = '{5: ctl.alu.f75, default: IDL};
  t_op    .func3     = ctl.alu.fn3;
  t_op    .rs2       = ctl.gpr.adr.rs2;
  t_op    .rs1       = ctl.gpr.adr.rs1;
  t_op    .rd        = ctl.gpr.adr.rd;

  // OP_IMM
  t_op_imm.opcode    = '{opc: ctl.opc, c11: 2'b11};
  case (ctl.alu.fn3)
    SR, SL :  t_op_imm.imm_11_0 = {IDL, ctl.alu.f75, {4{IDL}}, ctl.alu.imm[6-1:0]};
    default:  t_op_imm.imm_11_0 = ctl.alu.imm;
  endcase
  t_op_imm.func3     = ctl.alu.fn3;
  t_op_imm.rs1       = ctl.gpr.adr.rs1;
  t_op_imm.rd        = ctl.gpr.adr.rd;

  // LOAD
  t_load  .opcode    = '{opc: ctl.opc, c11: 2'b11};
  t_load  .imm_11_0  = ctl.ldu.imm;
  t_load  .func3     = ctl.ldu.fn3;
  t_load  .rs1       = ctl.gpr.adr.rs1;
  t_load  .rd        = ctl.gpr.adr.rd;

  // STORE
  t_store .opcode    = '{opc: ctl.opc, c11: 2'b11};
  t_store .imm_11_5  = ctl.stu.imm[11:5];
  t_store .imm_4_0   = ctl.stu.imm[4:0];
  t_store .func3     = ctl.stu.fn3;
  t_store .rs2       = ctl.gpr.adr.rs2;
  t_store .rs1       = ctl.gpr.adr.rs1;

  // BRANCH
  t_branch.opcode    = '{opc: ctl.opc, c11: 2'b11};
  t_branch.imm_12    = ctl.bru.imm[12];
  t_branch.imm_11    = ctl.bru.imm[11];
  t_branch.imm_10_5  = ctl.bru.imm[10:5];
  t_branch.imm_4_1   = ctl.bru.imm[4:1];
  t_branch.func3     = ctl.bru.fn3;
  t_branch.rs2       = ctl.gpr.adr.rs2;
  t_branch.rs1       = ctl.gpr.adr.rs1;

  // JAL
  t_jal   .opcode    = '{opc: ctl.opc, c11: 2'b11};
  t_jal   .imm_20    = ctl.jmp.jmp[20];
  t_jal   .imm_10_1  = ctl.jmp.jmp[10:1];
  t_jal   .imm_11    = ctl.jmp.jmp[11];
  t_jal   .imm_19_12 = ctl.jmp.jmp[19:12];
  t_jal   .rd        = ctl.gpr.adr.rd;

  // JALR
  t_jalr  .opcode    = '{opc: ctl.opc, c11: 2'b11};
  t_jalr  .imm_11_0  = ctl.jmp.imm;
  t_jalr  .func3     = {3{IDL}};
  t_jalr  .rs1       = ctl.gpr.adr.rs1;
  t_jalr  .rd        = ctl.gpr.adr.rd;

  // LUI/AUIPC
  t_ui    .opcode    = '{opc: ctl.opc, c11: 2'b11};
  t_ui    .imm_31_12 = ctl.uiu.imm[31:12];
  t_ui    .rd        = ctl.gpr.adr.rd;

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
    default: enc32 = '0;
  endcase

endfunction: enc32

endpackage: riscv_isa_i_pkg