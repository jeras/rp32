///////////////////////////////////////////////////////////////////////////////
// RISC-V ISA package
///////////////////////////////////////////////////////////////////////////////

package riscv_isa_pkg;

///////////////////////////////////////////////////////////////////////////////
// ISA base and extensions
// 2-level type `bit` is used for parameters
///////////////////////////////////////////////////////////////////////////////

typedef struct packed {
  // ISA base
  logic ie;  // RV32E  - embedded
  logic iw;  // RV32I  - word
  logic id;  // RV64I  - double
  logic iq;  // RV128I - quad
  // standard extensions
  logic M;         // integer multiplication and division
  logic A;         // atomic instructions
  logic F;         // single-precision floating-point
  logic D;         // double-precision floating-point
  logic Zicsr;     // Control and Status Register (CSR)
  logic Zifencei;  // Instruction-Fetch Fence
  logic Q;         // quad-precision floating-point
  logic L;         // decimal precision floating-point
  logic C;         // compressed
  logic B;         // bit manipulation
  logic J;         // dynamically translated languages
  logic T;         // transactional memory
  logic P;         // packed-SIMD
  logic V;         // vector operations
  logic N;         // user-level interrupts
  logic H;         // hypervisor
  logic S;         // supervisor-level instructions
  logic Zam;       // Misaligned Atomics
  logic Ztso;      // Total Store Ordering
} isa_t;

// enumerations for common configurations
typedef enum isa_t {
  //              base,     standard extensions
  //              ewdq,     MAFD_ZZ_QLCBJTPVNHS_ZZ
  RV32E     = {4'b1000, 19'b????_??_???????????_??},
  RV32I     = {4'b01??, 19'b????_??_???????????_??},
  RV64I     = {4'b0?1?, 19'b????_??_???????????_??},
  RV128I    = {4'b0??1, 19'b????_??_???????????_??},
  //              ewdq,     MAFD_ZZ_QLCBJTPVNHS_ZZ
  RV32EC    = {4'b1000, 19'b????_??_??1????????_??},
  RV32IC    = {4'b01??, 19'b????_??_??1????????_??},
  RV64IC    = {4'b0?1?, 19'b????_??_??1????????_??},
  RV128IC   = {4'b0??1, 19'b????_??_??1????????_??},
  //              ewdq,     MAFD_ZZ_QLCBJTPVNHS_ZZ
  RV32G     = {4'b01??, 19'b1111_11_???????????_??},  // G = IMAFDZicsrZifencei
  RV32GC    = {4'b01??, 19'b1111_11_??1????????_??},  // G = IMAFDZicsrZifencei
  RV64G     = {4'b0?1?, 19'b1111_11_???????????_??},  // G = IMAFDZicsrZifencei
  RV64GC    = {4'b0?1?, 19'b1111_11_??1????????_??},  // G = IMAFDZicsrZifencei
  RV128G    = {4'b0??1, 19'b1111_11_???????????_??},  // G = IMAFDZicsrZifencei
  RV128GC   = {4'b0??1, 19'b1111_11_??1????????_??}   // G = IMAFDZicsrZifencei
} isa_et;

///////////////////////////////////////////////////////////////////////////////
// I base (32E, 32I, 64I, 128I)
// data types
// 4-level type `logic` is used for signals
///////////////////////////////////////////////////////////////////////////////

// generic size type
typedef enum logic [3-1:0] {
  SZ_B = 3'b000,  //   1B - byte
  SZ_H = 3'b001,  //   2B - half
  SZ_W = 3'b010,  //   4B - word
  SZ_D = 3'b011,  //   8B - double
  SZ_Q = 3'b100,  //  16B - quad
  SZ_5 = 3'b101,  //  32B - ?octa?
  SZ_6 = 3'b110,  //  64B - ?hexa?
  SZ_7 = 3'b111   // 128B
} sz_t;

// PC multiplexer
typedef enum logic [2-1:0] {
  PC_PCN = 2'b00,  // next instruction address (PC + opsiz)
  PC_ALU = 2'b01,  // branch address
  PC_EPC = 2'b10,  // EPC value from CSR
  PC_XXX           // none
} pc_t;

// branch type
typedef enum logic [3-1:0] {
  BR_EQ  = 3'b00_0,  //     equal
  BR_NE  = 3'b00_1,  // not equal
  BR_LTS = 3'b10_0,  // less    then            signed
  BR_GES = 3'b10_1,  // greater then or equal   signed
  BR_LTU = 3'b11_0,  // less    then          unsigned
  BR_GEU = 3'b11_1,  // greater then or equal unsigned
  BR_XXX = 3'bxx_x   // idle
} br_t;

// GPR control signals
typedef struct packed {
  struct packed {
    logic         rs1;  // read enable register source 1
    logic         rs2;  // read enable register source 2
    logic         rs3;  // read enable register source 3 (only used in R4/CR4 OP format)
    logic         rd;   // write enable register destination
  } e;
  struct packed {
    logic [5-1:0] rs1;  // address register source 1 (read)
    logic [5-1:0] rs2;  // address register source 2 (read)
    logic [5-1:0] rs3;  // address register source 3 (read)
    logic [5-1:0] rd ;  // address register destination (write)
  } a;
} gpr_t;

// GPR 

// ALU argument 1 multiplexer (RS1,...)
typedef enum logic {
  A1_RS1 = 1'b0,
  A1_PC  = 1'b1
} a1_t;

// ALU argument 2 multiplexer (RS2,...)
typedef enum logic {
  A2_RS2 = 1'b0,
  A2_IMM = 1'b1
} a2_t;

// ALU operation
typedef enum logic [4-1:0] {
  // adder based instructions
  AO_ADD,  // addition
  AO_SUB,  // subtraction
  AO_LTS,  // less then   signed (not greater then or equal)
  AO_LTU,  // less then unsigned (not greater then or equal)
  // bitwise logical operations
  AO_AND,  // logic AND
  AO_OR ,  // logic OR
  AO_XOR,  // logic XOR
  // barrel shifter
  AO_SLL,  // shift left logical
  AO_SRL,  // shift right logical
  AO_SRA,  // shift right arithmetic
  // copies
  AO_CP1,  // copy rs1
  AO_CP2,  // copy rs2
  // explicit idle
  AO_XXX   // do nothing
} ao_t;

// ALU result width
typedef enum logic [2-1:0] {
  AR_X = 2'b00,  // XWIDTH
  AR_W = 2'b01,  // word
  AR_D = 2'b10,  // double
  AR_Q = 2'b11   // quad
} ar_t;

// load/store type
typedef struct packed {
  logic en;  // enable
  logic we;  // write enable
  logic sg;  // sign extend (0 - unsigned, 1 - signed)
  sz_t  sz;  // transfer size
} ls_t;

// load/store enumeration type
typedef enum ls_t {
  //         en,   we,   sg, sz
  LD_BS = {1'b1, 1'b0, 1'b1, SZ_B},  // load signed byte
  LD_HS = {1'b1, 1'b0, 1'b1, SZ_H},  // load signed half
  LD_WS = {1'b1, 1'b0, 1'b1, SZ_W},  // load signed word
  LD_DS = {1'b1, 1'b0, 1'b1, SZ_D},  // load signed double
  LD_QS = {1'b1, 1'b0, 1'b1, SZ_Q},  // load signed quad
  LD_BU = {1'b1, 1'b0, 1'b0, SZ_B},  // load unsigned byte
  LD_HU = {1'b1, 1'b0, 1'b0, SZ_H},  // load unsigned half
  LD_WU = {1'b1, 1'b0, 1'b0, SZ_W},  // load unsigned word
  LD_DU = {1'b1, 1'b0, 1'b0, SZ_D},  // load unsigned double
  LD_QU = {1'b1, 1'b0, 1'b0, SZ_Q},  // load unsigned quad
  ST_B  = {1'b1, 1'b1, 1'bx, SZ_B},  // store byte
  ST_H  = {1'b1, 1'b1, 1'bx, SZ_H},  // store half
  ST_W  = {1'b1, 1'b1, 1'bx, SZ_W},  // store word
  ST_D  = {1'b1, 1'b1, 1'bx, SZ_D},  // store double
  ST_Q  = {1'b1, 1'b1, 1'bx, SZ_Q},  // store quad
  LS_X  = {1'b0, 1'bx, 1'bx, 3'bxxx}   // none
} lse_t;

// write back multiplexer
typedef enum logic [3-1:0] {
  WB_ALU = 3'b1_00,  // arithmetic logic unit
  WB_MEM = 3'b1_01,  // memory
  WB_PCN = 3'b1_10,  // program counter next
  WB_CSR = 3'b1_11,  // 
  WB_XXX = 3'b0_xx   // none
} wb_t;

// CSR operations
typedef enum logic [3-1:0] {
  CSR_R = {1'b1, 2'b00},  // read
  CSR_W = {1'b1, 2'b01},  // write
  CSR_S = {1'b1, 2'b10},  // set
  CSR_C = {1'b1, 2'b11},  // clear
  CSR_N = {1'b0, 2'bxx}   // none
} csr_t;

typedef logic signed [32-1:0] imm_t;

// control structure
typedef struct packed {
  gpr_t  gpr;  // GPR control signals
  imm_t  imm;  // immediate select
  pc_t   pc;   // PC multiplexer
  br_t   br;   // branch type
  a1_t   a1;   // ALU RS1 multiplexer
  a2_t   a2;   // ALU RS1 multiplexer
  ao_t   ao;   // ALU operation
  ar_t   ar;   // ALU result size
  ls_t   ls;   // load/store enable/wrte/sign/size
  wb_t   wb;   // write back multiplexer/enable
  csr_t  csr;  // CSR operation
  logic  ill;  // illegal
} ctl_i_t;

///////////////////////////////////////////////////////////////////////////////
// M extension
///////////////////////////////////////////////////////////////////////////////

// M operation
typedef enum logic [2-1:0] {
  MOP_MUL = 2'b00,  // multiplication lower  half result
  MOP_MUH = 2'b01,  // multiplication higher half result
  MOP_DIV = 2'b10,  // division
  MOP_REM = 2'b11   // reminder
} mop_t;

// control structure
typedef struct packed {
  mop_t op;  // operation
  logic s1;  // sign operand 1
  logic s2;  // sign operand 2
  logic xw;  // XWIDTH (0 - full width, 1 - M64 additional opcodes)
  logic en;  // enable
} ctl_m_t;

///////////////////////////////////////////////////////////////////////////////
// full control structure
///////////////////////////////////////////////////////////////////////////////

// control structure
typedef struct packed {
  ctl_i_t  i;    // integer
//  ctl_m_t  m;    // integer multiplication and division
//  ctl_a_t  a;  // atomic
//  ctl_f_t  f;  // single-precision floating-point
//  ctl_d_t  d;  // double-precision floating-point
//  ctl_q_t  q;  // quad-precision floating-point
//  ctl_l_t  l;  // decimal precision floating-point
//  ctl_b_t  b;  // bit manipulation
//  ctl_j_t  j;  // dynamically translated languages
//  ctl_t_t  t;  // transactional memory
//  ctl_p_t  p;  // packed-SIMD
//  ctl_v_t  v;  // vector operations
//  ctl_n_t  n;  // user-level interrupts
} ctl_t;

///////////////////////////////////////////////////////////////////////////////
// instruction size (in bytes)
///////////////////////////////////////////////////////////////////////////////

function int unsigned opsiz (logic [16-1:0] op);
       if (op ==? 16'bx111_xxxx_x111_111)  opsiz = 24;
  else if (op ==? 16'bxxxx_xxxx_x1111111)  opsiz = 10 + 2 * op[14:12];
  else if (op ==? 16'bxxxx_xxxx_x0111111)  opsiz = 8;
  else if (op ==? 16'bxxxx_xxxx_xx011111)  opsiz = 6;
  else if (op !=? 16'bxxxx_xxxx_xxx111xx
       &&  op ==? 16'bxxxx_xxxx_xxxxxx11)  opsiz = 4;
  else                                     opsiz = 2;
endfunction: opsiz

///////////////////////////////////////////////////////////////////////////////
// 32 bit instruction format
///////////////////////////////////////////////////////////////////////////////

typedef struct packed {logic [4:0] rs3; logic [1:0] func2;          logic [4:0] rs2; logic [4:0] rs1; logic [2:0] func3; logic [4:0] rd     ;                       logic [6:0] opcode;} op32_r4_t;
typedef struct packed {                 logic [6:0] func7;          logic [4:0] rs2; logic [4:0] rs1; logic [2:0] func3; logic [4:0] rd     ;                       logic [6:0] opcode;} op32_r_t;
typedef struct packed {logic [11:00] imm_11_0;                                       logic [4:0] rs1; logic [2:0] func3; logic [4:0] rd     ;                       logic [6:0] opcode;} op32_i_t;
typedef struct packed {logic [11:05] imm_11_5;                      logic [4:0] rs2; logic [4:0] rs1; logic [2:0] func3; logic [4:0] imm_4_0;                       logic [6:0] opcode;} op32_s_t;
typedef struct packed {logic [12:12] imm_12; logic [10:5] imm_10_5; logic [4:0] rs2; logic [4:0] rs1; logic [2:0] func3; logic [4:1] imm_4_1; logic [11:11] imm_11; logic [6:0] opcode;} op32_b_t;
typedef struct packed {logic [31:12] imm_31_12;                                                                          logic [4:0] rd     ;                       logic [6:0] opcode;} op32_u_t;
typedef struct packed {logic [20:20] imm_20; logic [10:1] imm_10_1; logic [11:11] imm_11; logic [19:12] imm_19_12;       logic [4:0] rd     ;                       logic [6:0] opcode;} op32_j_t;

// union of instruction formats
typedef union packed {
  op32_r4_t r4;
  op32_r_t  r;
  op32_i_t  i;
  op32_s_t  s;
  op32_b_t  b;
  op32_u_t  u;
  op32_j_t  j;
} op32_t;

// enumeration of 32-bit instruction formats
typedef enum logic [3:0] {
  T_R4,
  T_R,
  T_I,
  T_S,
  T_B,
  T_U,
  T_J,
  T_X   // undefined type (illegal instruction)
} op32_sel_t;

///////////////////////////////////////////////////////////////////////////////
// immediate decoder
///////////////////////////////////////////////////////////////////////////////

function imm_t imm32 (op32_t op, op32_sel_t sel);
  case (sel)
    T_R4: imm32 = 'x; 
    T_R:  imm32 = 'x;
    T_I:  imm32 = imm_t'($signed({op.i.imm_11_0})); // s11
    T_S:  imm32 = imm_t'($signed({op.s.imm_11_5, op.s.imm_4_0})); // s11
    T_B:  imm32 = imm_t'($signed({op.b.imm_12, op.b.imm_11, op.b.imm_10_5, op.b.imm_4_1, 1'b0})); // s12
    T_U:  imm32 = imm_t'($signed({op.u.imm_31_12, 12'h000})); // s31
    T_J:  imm32 = imm_t'($signed({op.j.imm_20, op.j.imm_19_12, op.j.imm_11, op.j.imm_10_1, 1'b0})); // s20
    T_X:  imm32 = 'x;
    default: imm32 = 'x;
  endcase
endfunction: imm32

///////////////////////////////////////////////////////////////////////////////
// GPR decoder
///////////////////////////////////////////////////////////////////////////////

function gpr_t gpr32 (op32_t op, op32_sel_t sel);
  case (sel)      // rs1,rs2,rs3,rd
    T_R4: gpr32 = '{'{'1, '1, '1, '1}, '{op.r4.rs1, op.r4.rs2, op.r4.rs3, op.r4.rd}};
    T_R:  gpr32 = '{'{'1, '1, '0, '1}, '{op.r4.rs1, op.r4.rs2,        'x, op.r4.rd}};
    T_I:  gpr32 = '{'{'1, '0, '0, '1}, '{op.r4.rs1,        'x,        'x, op.r4.rd}};
    T_S:  gpr32 = '{'{'1, '1, '0, '0}, '{op.r4.rs1, op.r4.rs2,        'x,       'x}};
    T_B:  gpr32 = '{'{'1, '1, '0, '0}, '{op.r4.rs1, op.r4.rs2,        'x,       'x}};
    T_U:  gpr32 = '{'{'0, '0, '0, '1}, '{       'x,        'x,        'x, op.r4.rd}};
    T_J:  gpr32 = '{'{'0, '0, '0, '1}, '{       'x,        'x,        'x, op.r4.rd}};
    T_X:  gpr32 = '{'{'0, '0, '0, '0}, '{       'x,        'x,        'x,       'x}};
    default: gpr32 = 'x;
  endcase
endfunction: gpr32

///////////////////////////////////////////////////////////////////////////////
// instruction decoder
///////////////////////////////////////////////////////////////////////////////

function ctl_t dec (isa_t isa, op32_t op);
unique casez ({isa, op})
//          fedc_ba98_7654_3210_fedc_ba98_7654_3210             gpr          , imm            pc    , br    , a1    , a2    , alu   , ar  , ls   , wb,     csr  ,ill
//{RV32I, 32'b0000_0000_0000_0000_0000_0000_0001_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x,     'x,     'x,     'x,   'x, LS_X , WB_XXX,    'x, '0}; // 32'000000013 - nop (ADDI x0, x0, 0)
{RV32I, 32'b0000_0000_0000_0000_0100_0000_0011_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x,     'x,     'x,     'x,   'x, LS_X , WB_XXX,    'x, '0}; // 32'h00004033 - machine gen. bubble
                                                                                                 
// RV.I32                                                                                        
//          fedc_ba98_7654_3210_fedc_ba98_7654_3210             gpr          , imm            pc    , br    , a1    , a2    , alu   , ar  , ls   , wb,     csr  ,ill
{RV32I, 32'b????_????_????_????_????_????_?011_0111}: dec.i = '{gpr32(op,T_U), imm32(op,T_U), PC_PCN,     'x, A1_PC , A2_IMM, AO_CP2,   'x, LS_X , WB_ALU, CSR_N, '0};  // lui
{RV32I, 32'b????_????_????_????_????_????_?001_0111}: dec.i = '{gpr32(op,T_U), imm32(op,T_U), PC_PCN,     'x, A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , WB_ALU, CSR_N, '0};  // auipc
{RV32I, 32'b????_????_????_????_????_????_?110_1111}: dec.i = '{gpr32(op,T_J), imm32(op,T_J), PC_ALU,     'x, A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , WB_PCN, CSR_N, '0};  // jal
{RV32I, 32'b????_????_????_????_?000_????_?110_0111}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_ALU,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_PCN, CSR_N, '0};  // jalr
{RV32I, 32'b????_????_????_????_?000_????_?110_0011}: dec.i = '{gpr32(op,T_B), imm32(op,T_B), PC_ALU, BR_EQ , A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , WB_XXX, CSR_N, '0};  // beq
{RV32I, 32'b????_????_????_????_?001_????_?110_0011}: dec.i = '{gpr32(op,T_B), imm32(op,T_B), PC_ALU, BR_NE , A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , WB_XXX, CSR_N, '0};  // bne
{RV32I, 32'b????_????_????_????_?100_????_?110_0011}: dec.i = '{gpr32(op,T_B), imm32(op,T_B), PC_ALU, BR_LTS, A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , WB_XXX, CSR_N, '0};  // blt
{RV32I, 32'b????_????_????_????_?101_????_?110_0011}: dec.i = '{gpr32(op,T_B), imm32(op,T_B), PC_ALU, BR_GES, A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , WB_XXX, CSR_N, '0};  // bge
{RV32I, 32'b????_????_????_????_?110_????_?110_0011}: dec.i = '{gpr32(op,T_B), imm32(op,T_B), PC_ALU, BR_LTU, A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , WB_XXX, CSR_N, '0};  // bltu
{RV32I, 32'b????_????_????_????_?111_????_?110_0011}: dec.i = '{gpr32(op,T_B), imm32(op,T_B), PC_ALU, BR_GEU, A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , WB_XXX, CSR_N, '0};  // bgeu
{RV32I, 32'b????_????_????_????_?000_????_?000_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, LD_BS, WB_MEM, CSR_N, '0};  // lb
{RV32I, 32'b????_????_????_????_?001_????_?000_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, LD_HS, WB_MEM, CSR_N, '0};  // lh
{RV32I, 32'b????_????_????_????_?010_????_?000_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, LD_WS, WB_MEM, CSR_N, '0};  // lw
{RV32I, 32'b????_????_????_????_?100_????_?000_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, LD_BU, WB_MEM, CSR_N, '0};  // lbu
{RV32I, 32'b????_????_????_????_?101_????_?000_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, LD_HU, WB_MEM, CSR_N, '0};  // lhu
{RV32I, 32'b????_????_????_????_?000_????_?010_0011}: dec.i = '{gpr32(op,T_S), imm32(op,T_S), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, ST_B , WB_XXX, CSR_N, '0};  // sb
{RV32I, 32'b????_????_????_????_?001_????_?010_0011}: dec.i = '{gpr32(op,T_S), imm32(op,T_S), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, ST_H , WB_XXX, CSR_N, '0};  // sh
{RV32I, 32'b????_????_????_????_?010_????_?010_0011}: dec.i = '{gpr32(op,T_S), imm32(op,T_S), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, ST_W , WB_XXX, CSR_N, '0};  // sw
{RV32I, 32'b????_????_????_????_?000_????_?001_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_ALU, CSR_N, '0};  // addi
{RV32I, 32'b????_????_????_????_?010_????_?001_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_LTS,   'x, LS_X , WB_ALU, CSR_N, '0};  // slti
{RV32I, 32'b????_????_????_????_?011_????_?001_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_LTU,   'x, LS_X , WB_ALU, CSR_N, '0};  // sltiu
{RV32I, 32'b????_????_????_????_?100_????_?001_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_XOR,   'x, LS_X , WB_ALU, CSR_N, '0};  // xori
{RV32I, 32'b????_????_????_????_?110_????_?001_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_OR ,   'x, LS_X , WB_ALU, CSR_N, '0};  // ori
{RV32I, 32'b????_????_????_????_?111_????_?001_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_AND,   'x, LS_X , WB_ALU, CSR_N, '0};  // andi
{RV32I, 32'b0000_000?_????_????_?001_????_?001_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_SLL, AR_X, LS_X , WB_ALU, CSR_N, '0};  // slli TODO: illegal imm mask
{RV32I, 32'b0000_000?_????_????_?101_????_?001_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_SRL, AR_X, LS_X , WB_ALU, CSR_N, '0};  // srli
{RV32I, 32'b0100_000?_????_????_?101_????_?001_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_SRA, AR_X, LS_X , WB_ALU, CSR_N, '0};  // srai
{RV32I, 32'b0000_000?_????_????_?000_????_?011_0011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_ADD, AR_X, LS_X , WB_ALU, CSR_N, '0};  // add
{RV32I, 32'b0100_000?_????_????_?000_????_?011_0011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_SUB, AR_X, LS_X , WB_ALU, CSR_N, '0};  // sub
{RV32I, 32'b0000_000?_????_????_?010_????_?011_0011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_LTS,   'x, LS_X , WB_ALU, CSR_N, '0};  // slt
{RV32I, 32'b0000_000?_????_????_?011_????_?011_0011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_LTU,   'x, LS_X , WB_ALU, CSR_N, '0};  // sltu
{RV32I, 32'b0000_000?_????_????_?100_????_?011_0011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_XOR,   'x, LS_X , WB_ALU, CSR_N, '0};  // xor
{RV32I, 32'b0000_000?_????_????_?001_????_?011_0011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_SLL, AR_X, LS_X , WB_ALU, CSR_N, '0};  // sll
{RV32I, 32'b0000_000?_????_????_?101_????_?011_0011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_SRL, AR_X, LS_X , WB_ALU, CSR_N, '0};  // srl
{RV32I, 32'b0100_000?_????_????_?101_????_?011_0011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_SRA, AR_X, LS_X , WB_ALU, CSR_N, '0};  // sra
{RV32I, 32'b0000_000?_????_????_?110_????_?011_0011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_OR ,   'x, LS_X , WB_ALU, CSR_N, '0};  // or
{RV32I, 32'b0000_000?_????_????_?111_????_?011_0011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_AND,   'x, LS_X , WB_ALU, CSR_N, '0};  // and
{RV32I, 32'b????_????_????_????_?000_????_?000_1111}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x,     'x,     'x,     'x,   'x, LS_X , WB_XXX, CSR_N, '0};  // fence
{RV32I, 32'b????_????_????_????_?001_????_?000_1111}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x,     'x,     'x,     'x,   'x, LS_X , WB_XXX, CSR_N, '0};  // fence.i
{RV32I, 32'b????_????_????_????_?001_????_?111_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1,     'x,     'x,   'x, LS_X , WB_CSR, CSR_W, '0};  // csrrw
{RV32I, 32'b????_????_????_????_?010_????_?111_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1,     'x, AO_CP1,   'x, LS_X , WB_CSR, CSR_S, '0};  // csrrs
{RV32I, 32'b????_????_????_????_?011_????_?111_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1,     'x, AO_CP1,   'x, LS_X , WB_CSR, CSR_C, '0};  // csrrc
{RV32I, 32'b????_????_????_????_?101_????_?111_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x,     'x,     'x,     'x,   'x, LS_X , WB_CSR, CSR_W, '0};  // csrrwi
{RV32I, 32'b????_????_????_????_?110_????_?111_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x,     'x,     'x,     'x,   'x, LS_X , WB_CSR, CSR_S, '0};  // csrrsi
{RV32I, 32'b????_????_????_????_?111_????_?111_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x,     'x,     'x,     'x,   'x, LS_X , WB_CSR, CSR_C, '0};  // csrrci
{RV32I, 32'b0000_0000_0000_0000_0000_0000_0111_0011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x,     'x,     'x,     'x,   'x, LS_X , WB_XXX, CSR_R, '0};  // ecall
{RV32I, 32'b0000_0000_0001_0000_0000_0000_0111_0011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x,     'x,     'x,     'x,   'x, LS_X , WB_XXX, CSR_R, '0};  // ebreak
{RV32I, 32'b0001_0000_0000_0000_0000_0000_0111_0011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_EPC,     'x,     'x,     'x,     'x,   'x, LS_X , WB_XXX, CSR_R, '0};  // eret
{RV32I, 32'b0001_0000_0010_0000_0000_0000_0111_0011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x,     'x,     'x,     'x,   'x, LS_X , WB_XXX, CSR_N, '0};  // wfi
                                                                                                 
// RV.I64                                                                                        
//          fedc_ba98_7654_3210_fedc_ba98_7654_3210             gpr          , imm            pc    , br    , a1    , a2    , alu   , ar  , ls   , wb,     csr  ,ill
{RV64I, 32'b????_????_????_????_?011_????_?000_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, LD_DS, WB_MEM, CSR_N, '0};  // ld
{RV64I, 32'b????_????_????_????_?110_????_?000_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, LD_WU, WB_MEM, CSR_N, '0};  // lwu
{RV64I, 32'b????_????_????_????_?011_????_?010_0011}: dec.i = '{gpr32(op,T_S), imm32(op,T_S), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, ST_D , WB_XXX, CSR_N, '0};  // sd
{RV64I, 32'b????_????_????_????_?000_????_?001_1011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_W, LS_X , WB_ALU, CSR_N, '0};  // addiw
{RV64I, 32'b0000_000?_????_????_?001_????_?001_1011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_SLL, AR_W, LS_X , WB_ALU, CSR_N, '0};  // slliw
{RV64I, 32'b0000_000?_????_????_?101_????_?001_1011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_SRL, AR_W, LS_X , WB_ALU, CSR_N, '0};  // srliw
{RV64I, 32'b0100_000?_????_????_?101_????_?001_1011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_SRA, AR_W, LS_X , WB_ALU, CSR_N, '0};  // sraiw
{RV64I, 32'b0000_000?_????_????_?000_????_?011_1011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_ADD, AR_W, LS_X , WB_ALU, CSR_N, '0};  // addw
{RV64I, 32'b0100_000?_????_????_?000_????_?011_1011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_SUB, AR_W, LS_X , WB_ALU, CSR_N, '0};  // subw
{RV64I, 32'b0000_000?_????_????_?001_????_?011_1011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_SLL, AR_W, LS_X , WB_ALU, CSR_N, '0};  // sllw
{RV64I, 32'b0000_000?_????_????_?101_????_?011_1011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_SRL, AR_W, LS_X , WB_ALU, CSR_N, '0};  // srlw
{RV64I, 32'b0100_000?_????_????_?101_????_?011_1011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_SRA, AR_W, LS_X , WB_ALU, CSR_N, '0};  // sraw
                                                                                                 
// TODO: encoding is not finalized, the only reference I could find was:                         
// https://github.com/0xDeva/ida-cpu-RISC-V/blob/master/risc-v_opcode_map.txt                    
// RV.I128                                                                                       
//           fedc_ba98_7654_3210_fedc_ba98_7654_3210             gpr          , imm            pc    , br    , a1    , a2    , alu   , ar  , ls   , wb,     csr  ,ill
{RV128I, 32'b????_????_????_????_?011_????_?000_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, LD_DS, WB_MEM, CSR_N, '0};  // lq
{RV128I, 32'b????_????_????_????_?110_????_?000_0011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, LD_WU, WB_MEM, CSR_N, '0};  // ldu
{RV128I, 32'b????_????_????_????_?011_????_?010_0011}: dec.i = '{gpr32(op,T_S), imm32(op,T_S), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_X, ST_D , WB_XXX, CSR_N, '0};  // sq
{RV128I, 32'b????_????_????_????_?000_????_?101_1011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_ADD, AR_W, LS_X , WB_ALU, CSR_N, '0};  // addid
{RV128I, 32'b0000_00??_????_????_?001_????_?101_1011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_SLL, AR_W, LS_X , WB_ALU, CSR_N, '0};  // sllid
{RV128I, 32'b0000_00??_????_????_?101_????_?101_1011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_SRL, AR_W, LS_X , WB_ALU, CSR_N, '0};  // srlid
{RV128I, 32'b0100_00??_????_????_?101_????_?101_1011}: dec.i = '{gpr32(op,T_I), imm32(op,T_I), PC_PCN,     'x, A1_RS1, A2_IMM, AO_SRA, AR_W, LS_X , WB_ALU, CSR_N, '0};  // sraid
{RV128I, 32'b0000_000?_????_????_?000_????_?011_1011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_ADD, AR_W, LS_X , WB_ALU, CSR_N, '0};  // addd
{RV128I, 32'b0100_000?_????_????_?000_????_?011_1011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_SUB, AR_W, LS_X , WB_ALU, CSR_N, '0};  // subd
{RV128I, 32'b0000_000?_????_????_?001_????_?011_1011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_SLL, AR_W, LS_X , WB_ALU, CSR_N, '0};  // slld
{RV128I, 32'b0000_000?_????_????_?101_????_?011_1011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_SRL, AR_W, LS_X , WB_ALU, CSR_N, '0};  // srld
{RV128I, 32'b0100_000?_????_????_?101_????_?011_1011}: dec.i = '{gpr32(op,T_R), imm32(op,T_R), PC_PCN,     'x, A1_RS1, A2_RS2, AO_SRA, AR_W, LS_X , WB_ALU, CSR_N, '0};  // srad

//                                                               gpr          , imm            pc    , br    , a1    , a2    , alu   , ar  , ls   , wb,     csr  ,ill
default:                                               dec.i = '{gpr32(op,T_X), imm32(op,T_X), PC_PCN,     'x,     'x,     'x,     'x,   'x, LS_X , WB_XXX, CSR_N, '1};  // illegal
endcase

//         {op, s1, s2, xw, en}
//dec.m = '{'x, 'x, 'x, 'x, '0};

endfunction: dec

///////////////////////////////////////////////////////////////////////////////
// A extension
///////////////////////////////////////////////////////////////////////////////

//// RV.A32
////   ewdq mafdqlbjtpvn      fedc_ba98_7654_3210_fedc_ba98_7654_3210                 pc,     rs1,     rs2,   imm,     alu,     br,   st,ste,    ld,lde,     wb,wbe,   csr,ill
//{16'b????_????????????, 32'b0001_0??0_0000_????_?010_????_?010_1111}: dec = '{"lr.w              ", TYPE_32_R};
//{16'b????_????????????, 32'b0001_1???_????_????_?010_????_?010_1111}: dec = '{"sc.w              ", TYPE_32_R};
//{16'b????_????????????, 32'b0000_0???_????_????_?010_????_?010_1111}: dec = '{"amoadd.w          ", TYPE_32_R};
//{16'b????_????????????, 32'b0010_0???_????_????_?010_????_?010_1111}: dec = '{"amoxor.w          ", TYPE_32_R};
//{16'b????_????????????, 32'b0100_0???_????_????_?010_????_?010_1111}: dec = '{"amoor.w           ", TYPE_32_R};
//{16'b????_????????????, 32'b0110_0???_????_????_?010_????_?010_1111}: dec = '{"amoand.w          ", TYPE_32_R};
//{16'b????_????????????, 32'b1000_0???_????_????_?010_????_?010_1111}: dec = '{"amomin.w          ", TYPE_32_R};
//{16'b????_????????????, 32'b1010_0???_????_????_?010_????_?010_1111}: dec = '{"amomax.w          ", TYPE_32_R};
//{16'b????_????????????, 32'b1100_0???_????_????_?010_????_?010_1111}: dec = '{"amominu.w         ", TYPE_32_R};
//{16'b????_????????????, 32'b1110_0???_????_????_?010_????_?010_1111}: dec = '{"amomaxu.w         ", TYPE_32_R};
//{16'b????_????????????, 32'b0000_1???_????_????_?010_????_?010_1111}: dec = '{"amoswap.w         ", TYPE_32_R};
//
//// RV.A64
////   ewdq mafdqlbjtpvn      fedc_ba98_7654_3210_fedc_ba98_7654_3210                 pc,     rs1,     rs2,   imm,     alu,     br,   st,ste,    ld,lde,     wb,wbe,   csr,ill
//{16'b????_????????????, 32'b0001_0??0_0000_????_?011_????_?010_1111}: dec = '{"lr.d              ", TYPE_32_R};
//{16'b????_????????????, 32'b0001_1???_????_????_?011_????_?010_1111}: dec = '{"sc.d              ", TYPE_32_R};
//{16'b????_????????????, 32'b0000_0???_????_????_?011_????_?010_1111}: dec = '{"amoadd.d          ", TYPE_32_R};
//{16'b????_????????????, 32'b0010_0???_????_????_?011_????_?010_1111}: dec = '{"amoxor.d          ", TYPE_32_R};
//{16'b????_????????????, 32'b0100_0???_????_????_?011_????_?010_1111}: dec = '{"amoor.d           ", TYPE_32_R};
//{16'b????_????????????, 32'b0110_0???_????_????_?011_????_?010_1111}: dec = '{"amoand.d          ", TYPE_32_R};
//{16'b????_????????????, 32'b1000_0???_????_????_?011_????_?010_1111}: dec = '{"amomin.d          ", TYPE_32_R};
//{16'b????_????????????, 32'b1010_0???_????_????_?011_????_?010_1111}: dec = '{"amomax.d          ", TYPE_32_R};
//{16'b????_????????????, 32'b1100_0???_????_????_?011_????_?010_1111}: dec = '{"amominu.d         ", TYPE_32_R};
//{16'b????_????????????, 32'b1110_0???_????_????_?011_????_?010_1111}: dec = '{"amomaxu.d         ", TYPE_32_R};
//{16'b????_????????????, 32'b0000_1???_????_????_?011_????_?010_1111}: dec = '{"amoswap.d         ", TYPE_32_R};

/*
// RV.M32
//   ewdq mafdqlbjtpvn      fedc_ba98_7654_3210_fedc_ba98_7654_3210              {     op, s1, s2, xw, en}
{16'b????_1???????????, 32'b0000_001?_????_????_?000_????_?011_0011}: dec.m = '{MOP_MUL, '1, '1, '0, '1};  // mul
{16'b????_1???????????, 32'b0000_001?_????_????_?001_????_?011_0011}: dec.m = '{MOP_MUH, '1, '1, '0, '1};  // mulh
{16'b????_1???????????, 32'b0000_001?_????_????_?010_????_?011_0011}: dec.m = '{MOP_MUH, '1, '0, '0, '1};  // mulhsu
{16'b????_1???????????, 32'b0000_001?_????_????_?011_????_?011_0011}: dec.m = '{MOP_MUH, '0, '0, '0, '1};  // mulhu
{16'b????_1???????????, 32'b0000_001?_????_????_?100_????_?011_0011}: dec.m = '{MOP_DIV, '1, '1, '0, '1};  // div
{16'b????_1???????????, 32'b0000_001?_????_????_?101_????_?011_0011}: dec.m = '{MOP_DIV, '1, '0, '0, '1};  // divu
{16'b????_1???????????, 32'b0000_001?_????_????_?110_????_?011_0011}: dec.m = '{MOP_REM, '1, '1, '0, '1};  // rem
{16'b????_1???????????, 32'b0000_001?_????_????_?111_????_?011_0011}: dec.m = '{MOP_REM, '1, '0, '0, '1};  // remu

// RV.M64
//   ewdq mafdqlbjtpvn      fedc_ba98_7654_3210_fedc_ba98_7654_3210              {     op, s1, s2, xw, en}
{16'b00??_1???????????, 32'b0000_001?_????_????_?000_????_?011_1011}: dec.m = '{MOP_MUL, '1, '1, '1, '1};  // mulw
{16'b00??_1???????????, 32'b0000_001?_????_????_?100_????_?011_1011}: dec.m = '{MOP_DIV, '1, '1, '1, '1};  // divw
{16'b00??_1???????????, 32'b0000_001?_????_????_?101_????_?011_1011}: dec.m = '{MOP_DIV, '1, '0, '1, '1};  // divuw
{16'b00??_1???????????, 32'b0000_001?_????_????_?110_????_?011_1011}: dec.m = '{MOP_REM, '1, '1, '1, '1};  // remw
{16'b00??_1???????????, 32'b0000_001?_????_????_?111_????_?011_1011}: dec.m = '{MOP_REM, '1, '0, '1, '1};  // remuw

// RV.A32
//   ewdq mafdqlbjtpvn      fedc_ba98_7654_3210_fedc_ba98_7654_3210                 pc,     rs1,     rs2,   imm,     alu,     br,   st,ste,    ld,lde,     wb,wbe,   csr,ill
{16'b????_????????????, 32'b0001_0??0_0000_????_?010_????_?010_1111}: dec = '{"lr.w              ", TYPE_32_R};
{16'b????_????????????, 32'b0001_1???_????_????_?010_????_?010_1111}: dec = '{"sc.w              ", TYPE_32_R};
{16'b????_????????????, 32'b0000_0???_????_????_?010_????_?010_1111}: dec = '{"amoadd.w          ", TYPE_32_R};
{16'b????_????????????, 32'b0010_0???_????_????_?010_????_?010_1111}: dec = '{"amoxor.w          ", TYPE_32_R};
{16'b????_????????????, 32'b0100_0???_????_????_?010_????_?010_1111}: dec = '{"amoor.w           ", TYPE_32_R};
{16'b????_????????????, 32'b0110_0???_????_????_?010_????_?010_1111}: dec = '{"amoand.w          ", TYPE_32_R};
{16'b????_????????????, 32'b1000_0???_????_????_?010_????_?010_1111}: dec = '{"amomin.w          ", TYPE_32_R};
{16'b????_????????????, 32'b1010_0???_????_????_?010_????_?010_1111}: dec = '{"amomax.w          ", TYPE_32_R};
{16'b????_????????????, 32'b1100_0???_????_????_?010_????_?010_1111}: dec = '{"amominu.w         ", TYPE_32_R};
{16'b????_????????????, 32'b1110_0???_????_????_?010_????_?010_1111}: dec = '{"amomaxu.w         ", TYPE_32_R};
{16'b????_????????????, 32'b0000_1???_????_????_?010_????_?010_1111}: dec = '{"amoswap.w         ", TYPE_32_R};

// RV.A64
//   ewdq mafdqlbjtpvn      fedc_ba98_7654_3210_fedc_ba98_7654_3210                 pc,     rs1,     rs2,   imm,     alu,     br,   st,ste,    ld,lde,     wb,wbe,   csr,ill
{16'b????_????????????, 32'b0001_0??0_0000_????_?011_????_?010_1111}: dec = '{"lr.d              ", TYPE_32_R};
{16'b????_????????????, 32'b0001_1???_????_????_?011_????_?010_1111}: dec = '{"sc.d              ", TYPE_32_R};
{16'b????_????????????, 32'b0000_0???_????_????_?011_????_?010_1111}: dec = '{"amoadd.d          ", TYPE_32_R};
{16'b????_????????????, 32'b0010_0???_????_????_?011_????_?010_1111}: dec = '{"amoxor.d          ", TYPE_32_R};
{16'b????_????????????, 32'b0100_0???_????_????_?011_????_?010_1111}: dec = '{"amoor.d           ", TYPE_32_R};
{16'b????_????????????, 32'b0110_0???_????_????_?011_????_?010_1111}: dec = '{"amoand.d          ", TYPE_32_R};
{16'b????_????????????, 32'b1000_0???_????_????_?011_????_?010_1111}: dec = '{"amomin.d          ", TYPE_32_R};
{16'b????_????????????, 32'b1010_0???_????_????_?011_????_?010_1111}: dec = '{"amomax.d          ", TYPE_32_R};
{16'b????_????????????, 32'b1100_0???_????_????_?011_????_?010_1111}: dec = '{"amominu.d         ", TYPE_32_R};
{16'b????_????????????, 32'b1110_0???_????_????_?011_????_?010_1111}: dec = '{"amomaxu.d         ", TYPE_32_R};
{16'b????_????????????, 32'b0000_1???_????_????_?011_????_?010_1111}: dec = '{"amoswap.d         ", TYPE_32_R};

// RV.F32
//   ewdq mafdqlbjtpvn      fedc_ba98_7654_3210_fedc_ba98_7654_3210                 pc,     rs1,     rs2,   imm,     alu,     br,   st,ste,    ld,lde,     wb,wbe,   csr,ill
{16'b????_????????????, 32'b????_????_????_????_?010_????_?000_0111}: dec = '{"flw               ", TYPE_32_I};
{16'b????_????????????, 32'b????_????_????_????_?010_????_?010_0111}: dec = '{"fsw               ", TYPE_32_S};
{16'b????_????????????, 32'b????_?00?_????_????_????_????_?100_0011}: dec = '{"fmadd.s           ", TYPE_32_R4};
{16'b????_????????????, 32'b????_?00?_????_????_????_????_?100_0111}: dec = '{"fmsub.s           ", TYPE_32_R4};
{16'b????_????????????, 32'b????_?00?_????_????_????_????_?100_1011}: dec = '{"fnmsub.s          ", TYPE_32_R4};
{16'b????_????????????, 32'b????_?00?_????_????_????_????_?100_1111}: dec = '{"fnmadd.s          ", TYPE_32_R4};
{16'b????_????????????, 32'b0000_000?_????_????_????_????_?101_0011}: dec = '{"fadd.s            ", TYPE_32_R};
{16'b????_????????????, 32'b0000_100?_????_????_????_????_?101_0011}: dec = '{"fsub.s            ", TYPE_32_R};
{16'b????_????????????, 32'b0001_000?_????_????_????_????_?101_0011}: dec = '{"fmul.s            ", TYPE_32_R};
{16'b????_????????????, 32'b0001_100?_????_????_????_????_?101_0011}: dec = '{"fdiv.s            ", TYPE_32_R};
{16'b????_????????????, 32'b0101_1000_0000_????_????_????_?101_0011}: dec = '{"fsqrt.s           ", TYPE_32_R};
{16'b????_????????????, 32'b0010_000?_????_????_?000_????_?101_0011}: dec = '{"fsgnj.s           ", TYPE_32_R};
{16'b????_????????????, 32'b0010_000?_????_????_?001_????_?101_0011}: dec = '{"fsgnjn.s          ", TYPE_32_R};
{16'b????_????????????, 32'b0010_000?_????_????_?010_????_?101_0011}: dec = '{"fsgnjx.s          ", TYPE_32_R};
{16'b????_????????????, 32'b0010_100?_????_????_?000_????_?101_0011}: dec = '{"fmin.s            ", TYPE_32_R};
{16'b????_????????????, 32'b0010_100?_????_????_?001_????_?101_0011}: dec = '{"fmax.s            ", TYPE_32_R};
{16'b????_????????????, 32'b1100_0000_0000_????_????_????_?101_0011}: dec = '{"fcvt.w.s          ", TYPE_32_R};
{16'b????_????????????, 32'b1100_0000_0001_????_????_????_?101_0011}: dec = '{"fcvt.wu.s         ", TYPE_32_R};
{16'b????_????????????, 32'b1110_0000_0000_????_????_????_?101_0011}: dec = '{"fmv.x.w           ", TYPE_32_R};

{16'b????_????????????, 32'b0001_0??0_0000_????_?011_????_?010_1111}: dec = '{"lr.d              ", TYPE_32_R};

// RV.F64
//   ewdq mafdqlbjtpvn      fedc_ba98_7654_3210_fedc_ba98_7654_3210                 pc,     rs1,     rs2,   imm,     alu,     br,   st,ste,    ld,lde,     wb,wbe,   csr,ill
*/

// 32'b1000_0000_0000_0000_0000_0000_0111_0011: dec = '{"sret              ", TYPE_32_0};

///////////////////////////////////////////////////////////////////////////////
// 16 bit instruction format
///////////////////////////////////////////////////////////////////////////////

typedef struct packed {logic [ 3: 0] funct4;                          logic [ 4: 0] rd_rs1;                          logic [ 4: 0] rs2 ; logic [1:0] opcode;} op16_cr_t;
typedef struct packed {logic [ 2: 0] funct3; logic [12:12] imm_12_12; logic [ 4: 0] rd_rs1; logic [ 6: 2] imm_06_02;                     logic [1:0] opcode;} op16_ci_t;
typedef struct packed {logic [ 2: 0] funct3; logic [12: 7] imm_12_07; logic [ 4: 0] rd_rs1;                          logic [ 4: 0] rs2 ; logic [1:0] opcode;} op16_css_t;
typedef struct packed {logic [ 2: 0] funct3; logic [12: 5] imm_12_05;                                                logic [ 2: 0] rd_ ; logic [1:0] opcode;} op16_ciw_t;
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] imm_12_10; logic [ 2: 0] rs1_  ; logic [ 6: 5] imm_06_05; logic [ 2: 0] rd_ ; logic [1:0] opcode;} op16_cl_t;
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] imm_12_10; logic [ 2: 0] rs1_  ; logic [ 6: 5] imm_06_05; logic [ 2: 0] rs2_; logic [1:0] opcode;} op16_cs_t;
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] off_12_10; logic [ 2: 0] rs1_  ; logic [ 6: 2] off_06_02;                     logic [1:0] opcode;} op16_cb_t;
typedef struct packed {logic [ 2: 0] funct3; logic [12: 2] target;                                                                       logic [1:0] opcode;} op16_cj_t;

typedef union packed {
  op16_cr_t  cr;
  op16_ci_t  ci;
  op16_css_t css;
  op16_ciw_t ciw;
  op16_cl_t  cl;
  op16_cs_t  cs;
  op16_cb_t  cb;
  op16_cj_t  cj;
} op16_t;

typedef enum logic [3:0] {
  T_CR,
  T_CI,
  T_CSS,
  T_CIW,
  T_CL,
  T_CS,
  T_CB,
  T_CJ
} op16_sel_t;

// register width
typedef enum logic [3:0] {
  T16_W,  // word
  T16_D,  // double
  T16_Q   // quad
} op16_wdh_t;

typedef logic signed [16-1:0] imm16_t;

function imm16_t imm16 (op16_t i, op16_sel_t sel, op16_wdh_t wdh);
  imm16 = '0;
  case (sel)
    T_CR:
      imm16 = 'x;
    T_CI:
      case (wdh)
        T16_W: {imm16[5], {imm16[4:2], imm16[7:6]}} = {i.ci.imm_12_12, i.ci.imm_06_02};
        T16_D: {imm16[5], {imm16[4:3], imm16[8:6]}} = {i.ci.imm_12_12, i.ci.imm_06_02};
        T16_Q: {imm16[5], {imm16[4:4], imm16[9:6]}} = {i.ci.imm_12_12, i.ci.imm_06_02};
        default: imm16 = 'x;
      endcase
    T_CSS:
      case (wdh)
        T16_W: {imm16[5:2], imm16[7:6]} = i.css.imm_12_07;
        T16_D: {imm16[5:3], imm16[8:6]} = i.css.imm_12_07;
        T16_Q: {imm16[5:4], imm16[9:6]} = i.css.imm_12_07;
        default: imm16 = 'x;
      endcase
    T_CIW:
      {imm16[5:4], imm16[9:6], imm16[2], imm16[3]} = i.ciw.imm_12_05;
    T_CL,
    T_CS:
      case (wdh)
        T16_W: {imm16[5:3], imm16[2], imm16[  6]} = {i.cl.imm_12_10, i.cl.imm_06_05};
        T16_D: {imm16[5:3],           imm16[7:6]} = {i.cl.imm_12_10, i.cl.imm_06_05};
        T16_Q: {imm16[5:4], imm16[8], imm16[7:6]} = {i.cl.imm_12_10, i.cl.imm_06_05};
        default: imm16 = 'x;
      endcase
    T_CJ:
      {imm16[11], imm16[4], imm16[9:8], imm16[10], imm16[6], imm16[7], imm16[3:1], imm16[5]} = i.cj.target;
    T_CB:
      {imm16[8], imm16[4:3], imm16[7:6], imm16[2:1], imm16[5]} = {i.cb.off_12_10, i.cb.off_06_02};
    default: imm16 = 'x;
  endcase
endfunction: imm16

function logic [4:0] reg_5 (logic [2:0] reg_3);
  reg_5 = {2'b01, reg_3};
endfunction: reg_5

/*
function ctl_i_t dec16 (isa_t isa, op16_t op);
// default values
//              pc,    rs1,    rs2,  imm,     alu,   ar,    br,   st,ste,    ld,lde,     wb,wbe,   csr,ill
dec16.i = '{PC_PCN, A1_RS1, A2_RS2,   'x,      'x,   'x,    'x,   'x, '0,    'x, '0,     'x, '0,    'x, '0};
//         {op, s1, s2, xw, en}
dec16.m = '{'x, 'x, 'x, 'x, '0};

casez ({isa, op})
//  fedc_ba98_7654_3210                pc,     rs1,     rs2,                 imm,     alu,     br,   st,ste,    ld,lde,     wb,wbe,   csr,ill
16'b0000_0000_0000_0000: dec16 = '{PC_PC2,      'x,      'x,                  'x,      'x,     'x,   'x, '0,    'x, '0,     'x, '0,    'x, '1}; // illegal instruction
16'b000?_????_????_??00: dec16 = '{PC_PC2, A1_SP , A2_IMM, 4*imm16(op,T_CIW), AO_ADD,     'x,   'x, '0,    'x, '0,     'x, '0,    'x, ~|imm16(op,T_CIW)}; // C.ADDI4SP
16'b000?_????_????_??00: dec16 = '{PC_PC2,      'x,      'x,    'x,      'x,     'x,   'x, '0,    'x, '0,     'x, '0,    'x, '1}; // illegal instruction
16'b0000_0000_0000_0000: dec16 = '{PC_PC2,      'x,      'x,    'x,      'x,     'x,   'x, '0,    'x, '0,     'x, '0,    'x, '1}; // illegal instruction
16'b0000_0000_0000_0000: dec16 = '{PC_PC2,      'x,      'x,    'x,      'x,     'x,   'x, '0,    'x, '0,     'x, '0,    'x, '1}; // illegal instruction
16'b0000_0000_0000_0000: dec16 = '{PC_PC2,      'x,      'x,    'x,      'x,     'x,   'x, '0,    'x, '0,     'x, '0,    'x, '1}; // illegal instruction
16'b0000_0000_0000_0000: dec16 = '{PC_PC2,      'x,      'x,    'x,      'x,     'x,   'x, '0,    'x, '0,     'x, '0,    'x, '1}; // illegal instruction
16'b0000_0000_0000_0000: dec16 = '{PC_PC2,      'x,      'x,    'x,      'x,     'x,   'x, '0,    'x, '0,     'x, '0,    'x, '1}; // illegal instruction
16'b0000_0000_0000_0000: dec16 = '{PC_PC2,      'x,      'x,    'x,      'x,     'x,   'x, '0,    'x, '0,     'x, '0,    'x, '1}; // illegal instruction

32'b????_????_????_????_????_????_?001_0111: dec16 = '{PC_PCN, A1_PC , A2_IMM, IMM_U, AO_ADD,     'x,   'x, '0,    'x, '0, WB_ALU, '1, CSR_N, '0};  // auipc
32'b????_????_????_????_????_????_?110_1111: dec16 = '{PC_ALU, A1_PC , A2_IMM, IMM_J, AO_ADD,     'x,   'x, '0,    'x, '0, WB_PCN, '1, CSR_N, '0};  // jal
32'b????_????_????_????_?000_????_?110_0111: dec16 = '{PC_ALU, A1_RS1, A2_IMM, IMM_I, AO_ADD,     'x,   'x, '0,    'x, '0, WB_PCN, '1, CSR_N, '0};  // jalr
endcase
endfunction: dec16
*/

endpackage: riscv_isa_pkg