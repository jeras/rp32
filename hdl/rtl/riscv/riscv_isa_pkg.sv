///////////////////////////////////////////////////////////////////////////////
// RISC-V ISA package (based on isa spec)
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

package riscv_isa_pkg;

///////////////////////////////////////////////////////////////////////////////
// ISA base and extensions
// 4-level type `logic` is used for parameters, so `?` fields can be ignored
///////////////////////////////////////////////////////////////////////////////

// base
typedef struct packed {
  bit E;  // RV32E  - embedded
  bit W;  // RV32I  - word
  bit D;  // RV64I  - double
  bit Q;  // RV128I - quad
} isa_base_t;

// base enumerations
typedef enum logic [$bits(isa_base_t)-1:0] {
  //           EWDQ
  RV_32E  = 4'b1100,
  RV_32I  = 4'b0100,
  RV_64I  = 4'b0010,
  RV_128I = 4'b0001
} isa_base_et;

// privilege mode support (onehot)
typedef struct packed {
  bit M;  // Machine
  bit R;  // Reserved
  bit S;  // Supervisor
  bit U;  // User/Application
} isa_priv_t;

// privilege mode support
typedef enum logic [$bits(isa_priv_t)-1:0] {
  MODES_NONE = 4'b0000, // no privileged modes are supported
  MODES_M    = 4'b1000,  // Simple embedded systems
  MODES_MU   = 4'b1001,  // Secure embedded systems
  MODES_MSU  = 4'b1011   // Systems running Unix-like operating systems
} isa_priv_et;

// standard extensions (onehot)
typedef struct packed {
  bit M       ;  // integer multiplication and division
  bit A       ;  // atomic instructions
  bit F       ;  // single-precision floating-point
  bit D       ;  // double-precision floating-point
  bit Zicsr   ;  // Control and Status Register (CSR)
  bit Zifencei;  // Instruction-Fetch Fence
  bit Q       ;  // quad-precision floating-point
  bit L       ;  // decimal precision floating-point
  bit C       ;  // compressed
  bit B       ;  // bit manipulation
  bit J       ;  // dynamically translated languages
  bit T       ;  // transactional memory
  bit P       ;  // packed-SIMD
  bit V       ;  // vector operations
  bit N       ;  // user-level interrupts
  bit H       ;  // hypervisor
  bit S       ;  // supervisor-level instructions
  bit Zam     ;  // Misaligned Atomics
  bit Ztso    ;  // Total Store Ordering
} isa_ext_t;

// standard extensions
typedef enum logic [$bits(isa_ext_t)-1:0] {
  //                MAFD_ZZ_QLCBJTPVNHS_ZZ
  RV_M        = 19'b1000_00_00000000000_00,  // integer multiplication and division
  RV_A        = 19'b0100_00_00000000000_00,  // atomic instructions
  RV_F        = 19'b0010_00_00000000000_00,  // single-precision floating-point
  RV_D        = 19'b0011_00_00000000000_00,  // double-precision floating-point (NOTE: also enables F)
  RV_Zicsr    = 19'b0000_10_00000000000_00,  // Control and Status Register (CSR)
  RV_Zifencei = 19'b0000_01_00000000000_00,  // Instruction-Fetch Fence
  RV_Q        = 19'b0000_00_10000000000_00,  // quad-precision floating-point
  RV_L        = 19'b0000_00_01000000000_00,  // decimal precision floating-point
  RV_C        = 19'b0000_00_00100000000_00,  // compressed
  RV_B        = 19'b0000_00_00010000000_00,  // bit manipulation
  RV_J        = 19'b0000_00_00001000000_00,  // dynamically translated languages
  RV_T        = 19'b0000_00_00000100000_00,  // transactional memory
  RV_P        = 19'b0000_00_00000010000_00,  // packed-SIMD
  RV_V        = 19'b0000_00_00000001000_00,  // vector operations
  RV_N        = 19'b0000_00_00000000100_00,  // user-level interrupts
  RV_H        = 19'b0000_00_00000000010_00,  // hypervisor
  RV_S        = 19'b0000_00_00000000001_00,  // supervisor-level instructions
  RV_Zam      = 19'b0000_00_00000000000_10,  // Misaligned Atomics
  RV_Ztso     = 19'b0000_00_00000000000_01,  // Total Store Ordering
  //                MAFD_ZZ_QLCBJTPVNHS_ZZ
  RV_G        = 19'b1111_11_00000000000_00,  // general-purpose standard extenssion combination (G = IMAFDZicsrZifencei)
  RV_NONE     = 19'b0000_00_00000000000_00   // no standard extensions
} isa_ext_et;

// ISA specification configuration
// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  isa_base_t base;
  isa_ext_t  ext;
} isa_spec_t;

// enumerations for common and individual configurations
// TODO: verilator does not support struct literals inside enumeration definition
typedef enum logic [$bits(isa_spec_t)-1:0] {
  RV32E   = {RV_32E , RV_NONE    },
  RV32I   = {RV_32I , RV_NONE    },
  RV64I   = {RV_64I , RV_NONE    },
  RV128I  = {RV_128I, RV_NONE    },
  RV32EC  = {RV_32E ,        RV_C},
  RV32IC  = {RV_32I ,        RV_C},
  RV64IC  = {RV_64I ,        RV_C},
  RV128IC = {RV_128I,        RV_C},
  RV32EMC = {RV_32E , RV_M | RV_C},
  RV32IMC = {RV_32I , RV_M | RV_C},
  RV64IMC = {RV_64I , RV_M | RV_C},
  RV32G   = {RV_32I , RV_G       },
  RV64G   = {RV_64I , RV_G       },
  RV128G  = {RV_128I, RV_G       },
  RV32GC  = {RV_32I , RV_G | RV_C},
  RV64GC  = {RV_64I , RV_G | RV_C},
  RV128GC = {RV_128I, RV_G | RV_C}
} isa_spec_et;

// ISA configuration
// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  isa_spec_t spec;
  isa_priv_t priv;
} isa_t;

///////////////////////////////////////////////////////////////////////////////
// instruction size (in bytes)
///////////////////////////////////////////////////////////////////////////////

function automatic int unsigned opsiz (logic [16-1:0] op);
       if (op ==? 16'bxxxx_xxxx_x1111111)  opsiz = 10 + 2 * op[14:12];
  else if (op ==? 16'bxxxx_xxxx_x0111111)  opsiz = 8;
  else if (op ==? 16'bxxxx_xxxx_xx011111)  opsiz = 6;
  else if (op !=? 16'bxxxx_xxxx_xxx111xx
       &&  op ==? 16'bxxxx_xxxx_xxxxxx11)  opsiz = 4;
  else                                     opsiz = 2;
endfunction: opsiz

///////////////////////////////////////////////////////////////////////////////
// 32-bit instruction format
///////////////////////////////////////////////////////////////////////////////

// base opcode map
typedef enum logic [6:2] {
  LOAD   = 5'b00_000,  LOAD_FP  = 5'b00_001,  CUSTON_0   = 5'b00_010,  MISC_MEM = 5'b00_011,  OP_IMM = 5'b00_100,  AUIPC      = 5'b00_101,  OP_IMM_32 = 5'b00_110,  OP_48_1 = 5'b00_111,
  STORE  = 5'b01_000,  STORE_FP = 5'b01_001,  CUSTOM_1   = 5'b01_010,  AMO      = 5'b01_011,  OP     = 5'b01_100,  LUI        = 5'b01_101,  OP_32     = 5'b01_110,  OP_64   = 5'b01_111,
  MADD   = 5'b10_000,  MSUB     = 5'b10_001,  NMSUB      = 5'b10_010,  NMADD    = 5'b10_011,  OP_FP  = 5'b10_100,  RESERVED_6 = 5'b10_101,  CUSTOM_2  = 5'b10_110,  OP_48_2 = 5'b10_111,
  BRANCH = 5'b11_000,  JALR     = 5'b11_001,  RESERVED_A = 5'b11_010,  JAL      = 5'b11_011,  SYSTEM = 5'b11_100,  RESERVED_D = 5'b11_101,  CUSTOM_3  = 5'b11_110,  OP_80   = 5'b11_111
} op32_op62_et;

// base opcode map
typedef struct packed {
  op32_op62_et op;   //
  logic [1:0]  c11;  // constant 2'b11 got
} op32_opcode_t;

// func3 R-type (immediate)
typedef enum logic [3-1:0] {
  ADD   = 3'b000,  // func7[5] ? SUB : ADD
  SL    = 3'b001,  //
  SLT   = 3'b010,  //
  SLTU  = 3'b011,  //
  XOR   = 3'b100,  //
  SR    = 3'b101,  // func7[5] ? SRA : SRL
  OR    = 3'b110,  //
  AND   = 3'b111   //
} op32_r_func3_et;

// func3 I-type (load)
typedef enum logic [3-1:0] {
  LB  = 3'b000,  // RV32I RV64I RV128I
  LH  = 3'b001,  // RV32I RV64I RV128I
  LW  = 3'b010,  // RV32I RV64I RV128I
  LD  = 3'b011,  //       RV64I RV128I
  LBU = 3'b100,  // RV32I RV64I RV128I
  LHU = 3'b101,  // RV32I RV64I RV128I
  LWU = 3'b110,  //       RV64I RV128I
  LDU = 3'b111   //             RV128I
} op32_l_func3_et;
// NOTE: the RV128I instruction LQ (load quad) is under the MISC_MEM opcode

`ifndef ALTERA_RESERVED_QIS
typedef union packed {
  op32_l_func3_et l;
  op32_r_func3_et r;
} op32_i_func3_ut;
`else
// func3 I-type (immediate)
typedef op32_l_func3_et op32_i_func3_ut;
`endif

// func3 S-type (store)
typedef enum logic [3-1:0] {
  SB  = 3'b000,  // RV32I RV64I RV128I
  SH  = 3'b001,  // RV32I RV64I RV128I
  SW  = 3'b010,  // RV32I RV64I RV128I
  SD  = 3'b011,  //       RV64I RV128I
  SQ  = 3'b100   //             RV128I
//    = 3'b101,  //
//    = 3'b110,  //
//    = 3'b111   //
} op32_s_func3_et;

// func3 B-type (branch)
typedef enum logic [3-1:0] {
  BEQ  = 3'b000,  //     equal
  BNE  = 3'b001,  // not equal
//     = 3'b010,
//     = 3'b011,
  BLT  = 3'b100,  // less    then            signed
  BGE  = 3'b101,  // greater then or equal   signed
  BLTU = 3'b110,  // less    then          unsigned
  BGEU = 3'b111   // greater then or equal unsigned
} op32_b_func3_et;

// 32-bit instruction format structures
typedef struct packed {logic [4:0] rs3; logic [1:0] func2;          logic [4:0] rs2; logic [4:0] rs1; logic [2:0]     func3; logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_r4_t;  // Register 4 (floating point)
typedef struct packed {                 logic [6:0] func7;          logic [4:0] rs2; logic [4:0] rs1; op32_r_func3_et func3; logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_r_t ;  // Register
typedef struct packed {logic [11:00] imm_11_0;                                       logic [4:0] rs1; op32_i_func3_ut func3; logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_i_t ;  // Immediate
typedef struct packed {logic [11:05] imm_11_5;                      logic [4:0] rs2; logic [4:0] rs1; op32_s_func3_et func3; logic [4:0] imm_4_0;                       op32_opcode_t opcode;} op32_s_t ;  // Store
typedef struct packed {logic [12:12] imm_12; logic [10:5] imm_10_5; logic [4:0] rs2; logic [4:0] rs1; op32_b_func3_et func3; logic [4:1] imm_4_1; logic [11:11] imm_11; op32_opcode_t opcode;} op32_b_t ;  // Branch
typedef struct packed {logic [31:12] imm_31_12;                                                                              logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_u_t ;  // Upper immediate
typedef struct packed {logic [20:20] imm_20; logic [10:1] imm_10_1; logic [11:11] imm_11; logic [19:12] imm_19_12;           logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_j_t ;  // Jump

`ifndef ALTERA_RESERVED_QIS
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

// NOTE: there is no load format, 32-bit load instructions use the I-type
typedef struct packed {
  imm_i_t i;  // arithmetic/logic
  imm_l_t l;  // load
  imm_s_t s;  // store
  imm_b_t b;  // branch
  imm_u_t u;  // upper
  imm_j_t j;  // jump
} imm_t;

// per instruction format illegal (idle) value
const imm_i_t IMM_I_ILL = 'x;
const imm_l_t IMM_L_ILL = 'x;
const imm_s_t IMM_S_ILL = 'x;
const imm_b_t IMM_B_ILL = 'x;
const imm_u_t IMM_U_ILL = 'x;
const imm_j_t IMM_J_ILL = 'x;

const imm_t IMM_ILL = '{
  i: IMM_I_ILL,
  l: IMM_L_ILL,
  s: IMM_S_ILL,
  b: IMM_B_ILL,
  u: IMM_U_ILL,
  j: IMM_J_ILL
};

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

///////////////////////////////////////////////////////////////////////////////
// 32-bit OP GPR decoder
///////////////////////////////////////////////////////////////////////////////

// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  struct packed {
    logic         rs1;  // read enable register source 1
    logic         rs2;  // read enable register source 2
    logic         rd;   // write enable register destination
  } ena;
  struct packed {
    logic [5-1:0] rs1;  // address register source 1 (read)
    logic [5-1:0] rs2;  // address register source 2 (read)
    logic [5-1:0] rd ;  // address register destination (write)
  } adr;
} gpr_t;

// illegal (idle) value
const gpr_t GPR_ILL = '{ena: '0, adr: 'x};

///////////////////////////////////////////////////////////////////////////////
// I base (32E, 32I, 64I, 128I)
// data types
// 4-level type `logic` is used for signals
///////////////////////////////////////////////////////////////////////////////

// opcode type is just shorter type name for the full type name
typedef op32_op62_et opc_t;

// ALU operation {func7[5], func3}
typedef struct packed {
  logic           f7_5;  // used for subtraction
  op32_r_func3_et f3;
} alu_t;

const alu_t ALU_ILL = '{1'bx, op32_r_func3_et'(3'bxxx)};

// load/store func3 union
typedef struct packed {
  op32_l_func3_et l;
  op32_s_func3_et s;
} lsu_t;

const lsu_t LSU_ILL = '{op32_l_func3_et'('x), op32_s_func3_et'('x)};

// branch type is just shorter type name for the full branch func7 type
typedef op32_b_func3_et bru_t;

const bru_t BRU_ILL = bru_t'('x);

// control structure
// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  opc_t opc;  // operation code
  bru_t bru;  // branch unit
  alu_t alu;  // ALU (multiplexer/operation/width)
  lsu_t lsu;  // load/store (enable/wrte/sign/size)
} ctl_i_t;

// NOTE: trap on illegal instruction
// illegal (idle) value
const ctl_i_t CTL_I_ILL = '{opc: opc_t'(5'bxx_xxx), bru: BRU_ILL, alu: ALU_ILL, lsu: LSU_ILL};

///////////////////////////////////////////////////////////////////////////////
// M statndard extension
///////////////////////////////////////////////////////////////////////////////

// M operation
typedef enum logic [2-1:0] {
  M_MUL = 2'b00,  // multiplication lower  half result
  M_MUH = 2'b01,  // multiplication higher half result
  M_DIV = 2'b10,  // division
  M_REM = 2'b11   // reminder
} muldiv_t;

// don't care value
const muldiv_t M_XXX = muldiv_t'('x);

// control structure
// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  muldiv_t      op;   // operation
  logic [2-1:0] s12;  // sign operand 1/2 (0 - unsigned, 1 - signed)
  logic         en;   // enable
} ctl_m_t;

// illegal (idle) value
const ctl_m_t CTL_M_ILL = '{op: M_XXX, s12: 2'bxx, en: 1'b0};

///////////////////////////////////////////////////////////////////////////////
// privileged instructions
///////////////////////////////////////////////////////////////////////////////

// privilege level
typedef enum logic [1:0] {
  LVL_U = 2'b00,  // User/Application
  LVL_S = 2'b01,  // Supervisor
  LVL_R = 2'b10,  // Reserved
  LVL_M = 2'b11   // Machine
} isa_level_t;

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

// don't care value
const isa_priv_typ_t PRIV_XXX = isa_priv_typ_t'('x);

// control structure
// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  logic          ena;  // enable
  isa_priv_typ_t typ;  // type
} ctl_priv_t;

// illegal (idle) value
const ctl_priv_t CTL_PRIV_ILL = '{ena: 1'b0, typ: PRIV_XXX};

///////////////////////////////////////////////////////////////////////////////
// Zicsr standard extension
///////////////////////////////////////////////////////////////////////////////

// CSR operation type
typedef enum logic [2-1:0] {
  CSR_IDL = 2'b00,  // TODO: idle
  CSR_RW  = 2'b01,  // read/write
  CSR_SET = 2'b10,  // set
  CSR_CLR = 2'b11   // clear
} csr_op_t;

// don't care value
const csr_op_t CSR_XXX = csr_op_t'('x);

// CSR mask source
typedef enum logic [1-1:0] {
  CSR_REG = 1'b0,  // register
  CSR_IMM = 1'b1   // immediate
} csr_msk_t;

// don't care value
const csr_msk_t CSR_MX = csr_msk_t'('x);

// access permissions
// NOTE: from privileged spec
typedef enum logic [2-1:0] {
  ACCESS_RW0 = 2'b00,  // read/write
  ACCESS_RW1 = 2'b01,  // read/write
  ACCESS_RW2 = 2'b10,  // read/write
  ACCESS_RO3 = 2'b11   // read-only
} csr_perm_t;

// CSR address structure
// NOTE: from privileged spec
typedef struct packed {
   csr_perm_t  perm;
   isa_level_t level;
   logic [7:0] addr;
} csr_adr_t;

// don't care value
const csr_adr_t CSR_AX = csr_adr_t'('x);

// CSR immediate (zero extended from 5 to 32 bits
typedef logic [5-1:0] csr_imm_t;

// don't care value
const csr_imm_t IMM_X = csr_imm_t'('x);

// control structure
// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  logic     wen;  // write enable
  logic     ren;  // read enable
  csr_adr_t adr;  // address
  csr_imm_t imm;  // immediate
  csr_msk_t msk;  // mask
  csr_op_t  op ;  // operation
} ctl_csr_t;

// illegal (idle) value
// verilator lint_off WIDTHCONCAT
// TODO: Verilator should not complain here
const ctl_csr_t CTL_CSR_ILL = '{wen: 1'b0, ren: 1'b0, adr: CSR_AX, imm: IMM_X, msk: CSR_MX, op: CSR_XXX};
// verilator lint_on WIDTHCONCAT

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
  ill_t      ill;     // illegal
  integer    siz;     // instruction size
  imm_t      imm;     // immediate value
  gpr_t      gpr;     // GPR control signals
  ctl_i_t    i;       // integer
  ctl_m_t    m;       // integer multiplication and division
//ctl_a_t    a;       // atomic
//ctl_f_t    f;       // single-precision floating-point
//ctl_d_t    d;       // double-precision floating-point
//ctl_fnc_t  fnc;     // instruction fence
  ctl_csr_t  csr;     // CSR operation
//ctl_q_t    q;       // quad-precision floating-point
//ctl_l_t    l;       // decimal precision floating-point
//ctl_b_t    b;       // bit manipulation
//ctl_j_t    j;       // dynamically translated languages
//ctl_t_t    t;       // transactional memory
//ctl_p_t    p;       // packed-SIMD
//ctl_v_t    v;       // vector operations
//ctl_n_t    n;       // user-level interrupts
  ctl_priv_t priv;    // priviliged spec instructions
} ctl_t;

// illegal (idle) value
const ctl_t CTL_ILL = '{
  ill  : ILL,
  siz  : 0,
  imm  : IMM_ILL,
  gpr  : GPR_ILL,
  i    : CTL_I_ILL,
  m    : CTL_M_ILL,
  csr  : CTL_CSR_ILL,
  priv : CTL_PRIV_ILL
};

///////////////////////////////////////////////////////////////////////////////
// 32-bit instruction decoder
///////////////////////////////////////////////////////////////////////////////

// instruction decoder
`ifndef ALTERA_RESERVED_QIS
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

// immediate decoder
dec32.imm.i = imm_i_f(op);
dec32.imm.l = imm_i_f(op);
dec32.imm.s = imm_s_f(op);
dec32.imm.b = imm_b_f(op);
dec32.imm.u = imm_u_f(op);
dec32.imm.j = imm_j_f(op);

// GPR address
`ifndef ALTERA_RESERVED_QIS
dec32.gpr.adr = '{rs1: op.r.rs1, rs2: op.r.rs2, rd: op.r.rd};
`else
dec32.gpr.adr = '{rs1: op.rs1, rs2: op.rs2, rd: op.rd};
`endif

// operation code
dec32.i.opc = opc_t'(op[6:2]);

// GPR and immediate decoders are based on instruction formats
unique case (dec32.i.opc)
  //                        rs1,rs2, rd
  LUI    ,
  AUIPC  : dec32.gpr.ena = '{'0, '0, '1};
  JAL    : dec32.gpr.ena = '{'0, '0, '1};
  JALR   : dec32.gpr.ena = '{'1, '0, '1};
  BRANCH : dec32.gpr.ena = '{'1, '1, '0};
  LOAD   : dec32.gpr.ena = '{'1, '0, '1};
  STORE  : dec32.gpr.ena = '{'1, '1, '0};
  OP_IMM : dec32.gpr.ena = '{'1, '0, '1};
  OP     : dec32.gpr.ena = '{'1, '1, '1};
  default: dec32.gpr.ena = '{'0, '0, '0};
endcase

// branch unit
`ifndef ALTERA_RESERVED_QIS
dec32.i.bru = op.b.func3;
`else
dec32.i.bru = op32_b_func3_et'(op.func3);
`endif

// ALU operation {func7[5], func3}
`ifndef ALTERA_RESERVED_QIS
dec32.i.alu.f7_5 = op.r.func7[5];
dec32.i.alu.f3   = op.r.func3   ;
`else
dec32.i.alu.f7_5 =                  op.func7[5];
dec32.i.alu.f3   = op32_r_func3_et'(op.func3);
`endif

// LSU operation
`ifndef ALTERA_RESERVED_QIS
dec32.i.lsu.l = op32_l_func3_et'(op.i.func3);
dec32.i.lsu.s = op32_s_func3_et'(op.s.func3);
`else
dec32.i.lsu.l = op32_l_func3_et'(op.func3);
dec32.i.lsu.s = op32_s_func3_et'(op.func3);
`endif

endfunction: dec32

///////////////////////////////////////////////////////////////////////////////
// 32-bit instruction encoder
///////////////////////////////////////////////////////////////////////////////

// instruction decoder
`ifndef ALTERA_RESERVED_QIS
function automatic op32_t enc32 (isa_t isa, ctl_t ctl);
`else
function automatic op32_r_t enc32 (isa_t isa, ctl_t ctl);
`endif
endfunction: enc32

endpackage: riscv_isa_pkg