///////////////////////////////////////////////////////////////////////////////
// RISC-V ISA package (based on isa spec)
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
// generic size type (based on AMBA statndard encoding)
///////////////////////////////////////////////////////////////////////////////

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
// GPR control structure
///////////////////////////////////////////////////////////////////////////////

// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  struct packed {
    logic         rs1;  // read enable register source 1
    logic         rs2;  // read enable register source 2
    logic         rd;   // write enable register destination
  } e;
  struct packed {
    logic [5-1:0] rs1;  // address register source 1 (read)
    logic [5-1:0] rs2;  // address register source 2 (read)
    logic [5-1:0] rd ;  // address register destination (write)
  } a;
} gpr_t;

// illegal (idle) value
localparam gpr_t GPR_ILL = '{e: '0, a: 'x};

///////////////////////////////////////////////////////////////////////////////
// 32-bit immediate type
///////////////////////////////////////////////////////////////////////////////

typedef logic signed [32-1:0] imm_t;

// illegal (idle) value
localparam imm_t IMM_ILL = 'x;

///////////////////////////////////////////////////////////////////////////////
// 32-bit instruction format
///////////////////////////////////////////////////////////////////////////////

// base opcode map
typedef enum logic [6:2] {
  LOAD   = 'b00_000,  LOAD_FP  = 'b00_001,  CUSTON_0   = 'b00_010,  MISC_MEM = 'b00_011,  OP_IMM = 'b00_100,  AUIPC      = 'b00_101,  OP_IMM_32 = 'b00_110,  OP_48_1 = 'b00_111,
  STORE  = 'b01_000,  STORE_FP = 'b01_001,  CUSTOM_1   = 'b01_010,  AMO      = 'b01_011,  OP     = 'b01_100,  LUI        = 'b01_101,  OP_32     = 'b01_110,  OP_64   = 'b01_111,
  MADD   = 'b10_000,  MSUB     = 'b10_001,  NMSUB      = 'b10_010,  NMADD    = 'b10_011,  OP_FP  = 'b10_100,  RESERVED_6 = 'b10_101,  CUSTOM_2  = 'b10_110,  OP_48_2 = 'b10_111,
  BRANCH = 'b11_000,  JALR     = 'b11_001,  RESERVED_A = 'b11_010,  JAL      = 'b11_011,  SYSTEM = 'b11_100,  RESERVED_D = 'b11_101,  CUSTOM_3  = 'b11_110,  OP_80   = 'b11_111
} op32_op62_t;

// base opcode map
typedef struct packed {
  op32_op62_t op;   //
  logic [1:0] c11;  // constant 2'b11 got
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
} op32_r_func3_t;

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
} op32_i_func3_load_t;
// NOTE: the RV128I instruction LQ (load quad) is under the MISC_MEM opcode

// func3 I-type (immediate)
typedef union packed {
  op32_i_func3_load_t load;
  op32_r_func3_t      alu ;
} op32_i_func3_t;

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
} op32_s_func3_t;

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
} op32_b_func3_t;

// 32-bit instruction format structures
typedef struct packed {logic [4:0] rs3; logic [1:0] func2;          logic [4:0] rs2; logic [4:0] rs1; logic [2:0]    func3; logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_r4_t;  // Register 4 (floating point)
typedef struct packed {                 logic [6:0] func7;          logic [4:0] rs2; logic [4:0] rs1; op32_r_func3_t func3; logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_r_t ;  // Register
typedef struct packed {logic [11:00] imm_11_0;                                       logic [4:0] rs1; op32_i_func3_t func3; logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_i_t ;  // Immediate
typedef struct packed {logic [11:05] imm_11_5;                      logic [4:0] rs2; logic [4:0] rs1; op32_s_func3_t func3; logic [4:0] imm_4_0;                       op32_opcode_t opcode;} op32_s_t ;  // Store
typedef struct packed {logic [12:12] imm_12; logic [10:5] imm_10_5; logic [4:0] rs2; logic [4:0] rs1; op32_b_func3_t func3; logic [4:1] imm_4_1; logic [11:11] imm_11; op32_opcode_t opcode;} op32_b_t ;  // Branch
typedef struct packed {logic [31:12] imm_31_12;                                                                             logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_u_t ;  // Upper immediate
typedef struct packed {logic [20:20] imm_20; logic [10:1] imm_10_1; logic [11:11] imm_11; logic [19:12] imm_19_12;          logic [4:0] rd     ;                       op32_opcode_t opcode;} op32_j_t ;  // Jump

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

// enumeration of 32-bit instruction formats
typedef enum {
  T_R4,  // Register 4
  T_R ,  // Register
  T_I ,  // Immediate
  T_S ,  // Store
  T_B ,  // Branch
  T_U ,  // Upper immediate
  T_J    // Jump
} op32_frm_t;

///////////////////////////////////////////////////////////////////////////////
// 32-bit OP immediate decoder
///////////////////////////////////////////////////////////////////////////////

// ALU/load immediate (I-type)
function logic signed [12-1:0] imm_i (op32_t op);
  imm_i = $signed({op.i.imm_11_0});
endfunction: imm_i

// store immediate (S-type)
function logic signed [12-1:0] imm_s (op32_t op);
  imm_s = $signed({op.s.imm_11_5, op.s.imm_4_0});
endfunction: imm_s

// branch immediate (B-type)
function logic signed [12+1-1:0] imm_b (op32_t op);
  imm_b = $signed({op.b.imm_12, op.b.imm_11, op.b.imm_10_5, op.b.imm_4_1, 1'b0});
endfunction: imm_b

// ALU upper immediate (must be signed for RV64)
function logic signed [32-1:0] imm_u (op32_t op);
  imm_u = $signed({op.u.imm_31_12, 12'h000});
endfunction: imm_u

// ALU jump immediate
function logic signed [20:0] imm_j (op32_t op);
  imm_j = $signed({op.j.imm_20, op.j.imm_19_12, op.j.imm_11, op.j.imm_10_1, 1'b0});
endfunction: imm_j
// jump addition is done in ALU while the PC adder is used to calculate the link address

// full immediate decoder
function imm_t imm32 (op32_t op, op32_frm_t frm);
  unique case (frm)
    T_R4   : imm32 = IMM_ILL;
    T_R    : imm32 = IMM_ILL;
    T_I    : imm32 = imm_t'(imm_i(op));  // s11
    T_S    : imm32 = imm_t'(imm_s(op));  // s11
    T_B    : imm32 = imm_t'(imm_b(op));  // s12
    T_U    : imm32 = imm_t'(imm_u(op));  // s31
    T_J    : imm32 = imm_t'(imm_j(op));  // s20
    default: imm32 = IMM_ILL;
  endcase
endfunction: imm32

///////////////////////////////////////////////////////////////////////////////
// 32-bit OP GPR decoder
///////////////////////////////////////////////////////////////////////////////

function gpr_t gpr32 (op32_t op, op32_frm_t frm);
  unique case (frm)
    T_R4   : gpr32 = GPR_ILL;
    //                  rs1,rs2, rd           rs1,       rs2,       rd
    T_R    : gpr32 = '{'{'1, '1, '1}, '{op.r .rs1, op.r .rs2, op.r .rd}};
    T_I    : gpr32 = '{'{'1, '0, '1}, '{op.i .rs1,        'x, op.i .rd}};
    T_S    : gpr32 = '{'{'1, '1, '0}, '{op.s .rs1, op.s .rs2,       'x}};
    T_B    : gpr32 = '{'{'1, '1, '0}, '{op.b .rs1, op.b .rs2,       'x}};
    T_U    : gpr32 = '{'{'0, '0, '1}, '{       'x,        'x, op.u .rd}};
    T_J    : gpr32 = '{'{'0, '0, '1}, '{       'x,        'x, op.j .rd}};
    default: gpr32 = GPR_ILL;
  endcase
endfunction: gpr32

///////////////////////////////////////////////////////////////////////////////
// 16-bit compressed instruction format
///////////////////////////////////////////////////////////////////////////////

// 16-bit instruction format structures
typedef struct packed {logic [ 3: 0] funct4;                          logic [ 4: 0] rd_rs1 ;                          logic [ 4: 0] rs2 ; logic [1:0] opcode;} op16_cr_t ;  // Register
typedef struct packed {logic [ 2: 0] funct3; logic [12:12] imm_12_12; logic [ 4: 0] rd_rs1 ; logic [ 6: 2] imm_06_02;                     logic [1:0] opcode;} op16_ci_t ;  // Immediate
typedef struct packed {logic [ 2: 0] funct3; logic [12: 7] imm_12_07;                                                 logic [ 4: 0] rs2 ; logic [1:0] opcode;} op16_css_t;  // Stack-relative Store
typedef struct packed {logic [ 2: 0] funct3; logic [12: 5] imm_12_05;                                                 logic [ 2: 0] rd_ ; logic [1:0] opcode;} op16_ciw_t;  // Wide Immediate
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] imm_12_10; logic [ 2: 0] rs1_   ; logic [ 6: 5] imm_06_05; logic [ 2: 0] rd_ ; logic [1:0] opcode;} op16_cl_t ;  // Load
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] imm_12_10; logic [ 2: 0] rs1_   ; logic [ 6: 5] imm_06_05; logic [ 2: 0] rs2_; logic [1:0] opcode;} op16_cs_t ;  // Store
typedef struct packed {logic [ 5: 0] funct6;                          logic [ 2: 0] rd_rs1_; logic [ 1: 0] func2;     logic [ 2: 0] rs2_; logic [1:0] opcode;} op16_ca_t ;  // Arithmetic
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] off_12_10; logic [ 2: 0] rs1_   ; logic [ 6: 2] off_06_02;                     logic [1:0] opcode;} op16_cb_t ;  // Branch
typedef struct packed {logic [ 2: 0] funct3; logic [12: 2] target;                                                                        logic [1:0] opcode;} op16_cj_t ;  // Jump

// union of 16-bit instruction formats
typedef union packed {
  op16_cr_t  cr ;  // Register
  op16_ci_t  ci ;  // Immediate
  op16_css_t css;  // Stack-relative Store
  op16_ciw_t ciw;  // Wide Immediate
  op16_cl_t  cl ;  // Load
  op16_cs_t  cs ;  // Store
  op16_ca_t  ca ;  // Arithmetic
  op16_cb_t  cb ;  // Branch
  op16_cj_t  cj ;  // Jump
} op16_t;

// enumeration of 16-bit instruction formats
// appendix defines GPR access special cases
typedef enum {
  T_CR  ,  // Register
  T_CR_0,  // Register + rs1=x0 (zero)
  T_CR_L,  // Register + rd=x1 (link)
  T_CI  ,  // Immediate
  T_CI_J,  // Immediate + jump
  T_CI_S,  // Immediate + rs1=x2 (sp)
  T_CI_L,  // Immediate + rs1=x2 (sp) Load
  T_CSS ,  // Stack-relative Store
  T_CIW ,  // Wide Immediate
  T_CL  ,  // Load
  T_CS  ,  // Store
  T_CA  ,  // Arithmetic
  T_CB  ,  // Branch (branches)
  T_CB_A,  // Branch/Arithmetic (shifts and c.addi)
  T_CJ  ,  // Jump + rd=x0 (zero)
  T_CJ_L   // Jump + rd=x1 (link)
} op16_frm_t;

// immediate decoder qualifiers
typedef enum {
  T_C_W,  // word   sized load/store
  T_C_D,  // double sized load/store
  T_C_Q,  // quad   sized load/store
  T_C_P,  // signed upper immediate, for C.LUI instruction (12-bit Page sized shift)
  T_C_S,  // signed       immediate, for ADDI  instruction
  T_C_U,  // unsigned     immediate, for shift instruction
  T_C_F   // signed       immediate, scaled *16 for C.ADDI16SP instruction
} op16_imm_t;

///////////////////////////////////////////////////////////////////////////////
// 16-bit OP immediate decoder
///////////////////////////////////////////////////////////////////////////////

// branch immediate (CB-type)
function logic signed [8:0] imm_cb (op16_t op);
  {imm_cb[8], imm_cb[4:3], imm_cb[7:6], imm_cb[2:1], imm_cb[5], imm_cb[0]} = {op.cb.off_12_10, op.cb.off_06_02, 1'b0};
endfunction: imm_cb


// load immediate (I-type)
//function logic signed [12-1:0] imm_i (op16_t op);
//  imm_i = $signed({op.i.imm_11_0});
//endfunction: imm_i

// {zero extended (unsigned), 6-bit, scaled by 4/8/16} load immediate (CI_L-type)
function logic unsigned [12-1:0] imm_ci_l (op16_t op, op16_imm_t imm);
  imm_ci_l = '0;
  case (imm)
    T_C_W: {imm_ci_l[5], {imm_ci_l[4:2], imm_ci_l[7:6]}} = {op.ci.imm_12_12, op.ci.imm_06_02};  // C.LWSP, C.FLWSP
    T_C_D: {imm_ci_l[5], {imm_ci_l[4:3], imm_ci_l[8:6]}} = {op.ci.imm_12_12, op.ci.imm_06_02};  // C.LDSP, C.FLDSP
    T_C_Q: {imm_ci_l[5], {imm_ci_l[4:4], imm_ci_l[9:6]}} = {op.ci.imm_12_12, op.ci.imm_06_02};  // C.LQSP
    default: imm_ci_l = 'x;
  endcase
endfunction: imm_ci_l

// {zero extended (unsigned), 6-bit, scaled by 4/8/16} store immediate (CSS-type)
function logic unsigned [12-1:0] imm_css (op16_t op, op16_imm_t imm);
  imm_css = '0;
  case (imm)
    T_C_W: {imm_css[5:2], imm_css[7:6]} = op.css.imm_12_07;  // C.SWSP, C.FSWSP
    T_C_D: {imm_css[5:3], imm_css[8:6]} = op.css.imm_12_07;  // C.SDSP, C.FSDSP
    T_C_Q: {imm_css[5:4], imm_css[9:6]} = op.css.imm_12_07;  // C.SQSP
    default: imm_css = 'x;
  endcase
endfunction: imm_css

// {zero extended (unsigned), 5-bit, scaled by 4/8/16} store immediate (C[LS]-type)
function logic unsigned [12-1:0] imm_cls (op16_t op, op16_imm_t imm);
  imm_cls = '0;
  case (imm)
        T_C_W: {imm_cls[5:3], imm_cls[2], imm_cls[  6]} = {op.cl.imm_12_10, op.cl.imm_06_05};  // C.LW, C.FLW
        T_C_D: {imm_cls[5:3],             imm_cls[7:6]} = {op.cl.imm_12_10, op.cl.imm_06_05};  // C.LD, C.FLD
        T_C_Q: {imm_cls[5:4], imm_cls[8], imm_cls[7:6]} = {op.cl.imm_12_10, op.cl.imm_06_05};  // C.LQ
    default: imm_cls = 'x;
  endcase
endfunction: imm_cls

// full immediate decoder
function imm_t imm16 (op16_t i, op16_frm_t sel, op16_imm_t imm);
  imm16 = '0;
  unique case (sel)
    T_CR  ,
    T_CR_0:  imm16 = IMM_ILL;
    T_CR_L:  imm16 = '0;
    T_CI  :
      case (imm)
        T_C_P:  imm16 = 32'(  $signed({i.ci.imm_12_12, i.ci.imm_06_02, 12'h000}));  // upper immediate for C.LUI instruction
        T_C_S:  imm16 = 32'(  $signed({i.ci.imm_12_12, i.ci.imm_06_02}));  // signed immediate
        T_C_U:  imm16 = 32'($unsigned({i.ci.imm_12_12, i.ci.imm_06_02}));  // unsigned immediate
        default: imm16 = IMM_ILL;
      endcase
    T_CI_J:  imm16 = '0;
    T_CI_S:
      case (imm)
        T_C_F: {imm16[31:10], {imm16[9], imm16[4], imm16[6], imm16[8:7], imm16[5]}, imm16[3:0]} = 32'($signed({i.ci.imm_12_12, i.ci.imm_06_02, 4'h0}));  // signed immediate *16
        default: imm16 = IMM_ILL;
      endcase
    T_CI_L:  imm16 = imm_t'(imm_ci_l(i, imm));
    T_CSS :  imm16 = imm_t'(imm_css (i, imm));
    T_CIW : {imm16[5:4], imm16[9:6], imm16[2], imm16[3]} = i.ciw.imm_12_05;
    T_CL  ,
    T_CS  :  imm16 = imm_t'(imm_cls (i, imm));
    T_CA  :  imm16 = IMM_ILL;
    T_CB  :  imm16 = imm_t'(imm_cb  (i));
    T_CB_A:  imm16 = 32'($signed({i.ci.imm_12_12, i.ci.imm_06_02}));  // signed immediate
    T_CJ  ,
    T_CJ_L: {imm16[31:12], {imm16[11], imm16[4], imm16[9:8], imm16[10], imm16[6], imm16[7], imm16[3:1], imm16[5]}, imm16[0]} = 32'($signed({i.cj.target, 1'b0}));
    default: imm16 = IMM_ILL;
  endcase
endfunction: imm16

///////////////////////////////////////////////////////////////////////////////
// 16-bit OP GPR decoder
///////////////////////////////////////////////////////////////////////////////

function gpr_t gpr16 (op16_t op, op16_frm_t frm);
  unique case (frm)   // rs1,rs2,rd                        rs1  ,                rs2  ,                rd
    T_CR   :  gpr16 = '{'{'1, '1, '1}, '{        op.cr .rd_rs1  ,         op.cr .rs2  ,         op.cr .rd_rs1   }};
    T_CR_0 :  gpr16 = '{'{'0, '1, '1}, '{ 5'h00                 ,         op.cr .rs2  ,         op.cr .rd_rs1   }};
    T_CR_L :  gpr16 = '{'{'1, '0, '1}, '{        op.cr .rd_rs1  ,     'x              ,  5'h01                  }};
    T_CI   :  gpr16 = '{'{'1, '0, '1}, '{        op.ci .rd_rs1  ,     'x              ,         op.ci .rd_rs1   }};
    T_CI_J :  gpr16 = '{'{'1, '0, '0}, '{        op.cr .rd_rs1  ,     'x              ,     'x                  }};
    T_CI_S :  gpr16 = '{'{'1, '0, '1}, '{ 5'h02                 ,     'x              ,         op.ci .rd_rs1   }};
    T_CI_L :  gpr16 = '{'{'1, '0, '1}, '{ 5'h02                 ,     'x              ,         op.ci .rd_rs1   }};
    T_CSS  :  gpr16 = '{'{'1, '1, '0}, '{ 5'h02                 ,         op.css.rs2  ,     'x                  }};
    T_CIW  :  gpr16 = '{'{'0, '0, '1}, '{ 5'h02                 ,     'x              , {2'b01, op.ciw.rd_     }}};
    T_CL   :  gpr16 = '{'{'1, '0, '1}, '{{2'b01, op.cl .rs1_   },     'x              , {2'b01, op.cl .rd_     }}};
    T_CS   :  gpr16 = '{'{'1, '1, '0}, '{{2'b01, op.cs .rs1_   }, {2'b01, op.cs .rs2_},     'x                  }};
    T_CA   :  gpr16 = '{'{'1, '1, '1}, '{{2'b01, op.ca .rd_rs1_}, {2'b01, op.ca .rs2_}, {2'b01, op.ca .rd_rs1_ }}};
    T_CB   :  gpr16 = '{'{'1, '1, '0}, '{{2'b01, op.cb .rs1_   },  5'h00              ,     'x                  }};  // Branch
    T_CB_A :  gpr16 = '{'{'1, '0, '1}, '{{2'b01, op.cb .rs1_   },     'x              , {2'b01, op.cb .rs1_    }}};  // Branch/Arithmetic
    T_CJ   :  gpr16 = '{'{'0, '0, '1}, '{    'x                 ,     'x              ,  5'd00                  }};  // C.J   using x0, NOTE: writeback could be disabled
    T_CJ_L :  gpr16 = '{'{'0, '0, '1}, '{    'x                 ,     'x              ,  5'h01                  }};  // C.JAL using x1
    default:  gpr16 = '{'{'0, '0, '0}, '{    'x                 ,     'x              ,     'x                  }};
  endcase
endfunction: gpr16

///////////////////////////////////////////////////////////////////////////////
// I base (32E, 32I, 64I, 128I)
// data types
// 4-level type `logic` is used for signals
///////////////////////////////////////////////////////////////////////////////

// PC multiplexer
typedef enum logic [3-1:0] {
  PC_PCI = 3'b000,  // PC increnent address (PC + opsiz)
  PC_BRN = 3'b001,  // branch address (PC + immediate)
  PC_JMP = 3'b010,  // jump address
  PC_TRP = 3'b100,  // trap address
  PC_EPC = 3'b101   // EPC value from CSR
} pc_t;

// TODO: do this properly
localparam logic [3-1:0] PC_ILL = PC_PCI;

// branch type
typedef op32_b_func3_t br_t;

// branch immediate type {12-bit, 1'b0}
typedef logic signed [12+1-1:0] br_imm_t;

// ALU input operand multiplexer
// the encoding is not directly derived from opcode
typedef enum logic [2-1:0] {
  AI_R1_IM = 2'b00,  // GPR rs1 | immediate //   I-type {opcode[6], opcode[5]}
  AI_R1_R2 = 2'b01,  // GPR rs1 | GPR rs2   //   R-type {opcode[6], opcode[5]}
  AI_PC_IM = 2'b1?   // PC      | immediate // BUJ-type {opcode[6], ?}
} alu_in_t;

// ALU operation {func7[5], func3}
typedef struct packed {
  logic          f7_5;  // used for subtraction
  op32_r_func3_t f3;
} alu_op_t;

// ALU operation {func7[5], func3}
typedef enum logic [$bits(alu_op_t)-1:0] {
  AO_ADD  = {1'b0, ADD },  // addition
  AO_SUB  = {1'b1, ADD },  // subtraction
  AO_SLL  = {1'b?, SL  },  // shift left logical
  AO_SLT  = {1'b?, SLT },  // set less then   signed (not greater then or equal)
  AO_SLTU = {1'b?, SLTU},  // set less then unsigned (not greater then or equal)
  AO_XOR  = {1'b?, XOR },  // logic XOR
  AO_SRL  = {1'b0, SR  },  // shift right logical
  AO_SRA  = {1'b1, SR  },  // shift right arithmetic
  AO_OR   = {1'b?, OR  },  // logic OR
  AO_AND  = {1'b?, AND }   // logic AND
} ao_et;

// TODO: optimize enumeration against opcode
// result type
typedef enum logic [3-1:0] {
  R_X  = 3'b?00,  // XLEN
  R_SW = 3'b101,  //   signed word
  R_UW = 3'b001,  // unsigned word
  R_SD = 3'b110,  //   signed double
  R_UD = 3'b010,  // unsigned double
  R_SQ = 3'b111,  //   signed quad
  R_UQ = 3'b011   // unsigned quad
} result_t;

// ALU type
// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  alu_in_t ai;  // input operand multiplexer
  alu_op_t ao;  // operation
  result_t rt;  // result type
} alu_t;

// load/store func3 union
typedef union packed {
  op32_i_func3_load_t l;
  op32_s_func3_t      s;
} lsu_f3_t;

// load/store type
typedef struct packed {
  logic    en;  // transfer enable
  logic    we;  // write enable (opcode[5])
  lsu_f3_t f3;  // transfer sign/size
} lsu_t;

// load/store enumeration type
typedef enum logic [$bits(lsu_t)-1:0] {
  //        en,   we, f3
  L_BS = {1'b1, 1'b0, LB },  // load signed byte
  L_HS = {1'b1, 1'b0, LH },  // load signed half
  L_WS = {1'b1, 1'b0, LW },  // load signed word
  L_DS = {1'b1, 1'b0, LD },  // load signed double
//L_QS = {1'b1, 1'b0, LQ },  // load signed quad
  L_BU = {1'b1, 1'b0, LBU},  // load unsigned byte
  L_HU = {1'b1, 1'b0, LHU},  // load unsigned half
  L_WU = {1'b1, 1'b0, LWU},  // load unsigned word
  L_DU = {1'b1, 1'b0, LDU},  // load unsigned double
//L_QU = {1'b1, 1'b0, LQU},  // load unsigned quad
  S_B  = {1'b1, 1'b1, SB },  // store byte
  S_H  = {1'b1, 1'b1, SH },  // store half
  S_W  = {1'b1, 1'b1, SW },  // store word
  S_D  = {1'b1, 1'b1, SD },  // store double
  S_Q  = {1'b1, 1'b1, SQ },  // store quad
  LS_X = {1'b0, 1'b?, 3'b???}   // none
} lse_t;

// TODO: try to optimize against opcode
// write back multiplexer
typedef enum logic [3-1:0] {
  WB_ALU = 3'b000,  // RI-type OP, OP-IMM 5'b0?100  // arithmetic logic unit
  WB_MEM = 3'b001,  //  I-type LOAD       5'b00000  // memory
  WB_PCI = 3'b010,  //  J-type JAL        5'b11011 // program counter increment
  WB_IMM = 3'b011,  //   // immediate ()
  WB_CSR = 3'b100,  //   // CSR value
  WB_MUL = 3'b101   //   // MUL/DIV/REM
} wb_t;

// control structure
// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  pc_t   pc ;   // PC multiplexer
  br_t   br ;   // branch type
  alu_t  alu;   // ALU (multiplexer/operation/width)
  lsu_t  lsu;   // load/store (enable/wrte/sign/size)
  wb_t   wb ;   // write back multiplexer/enable
} ctl_i_t;

// NOTE: trap on illegal instruction
// illegal (idle) value          pc    , br, alu, ls   , wb
localparam ctl_i_t CTL_I_ILL = '{PC_TRP, 'x,  'x, LS_X , 'x};

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

// control structure
// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  muldiv_t      op;   // operation
  logic [2-1:0] s12;  // sign operand 1/2 (0 - unsigned, 1 - signed)
  result_t      rt;   // result type
  logic         en;   // enable
} ctl_m_t;

// illegal (idle) value
localparam ctl_m_t CTL_M_ILL = '{op: 'x, s12: 2'bxx, rt: 'x, en: '0};

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

// control structure
// TODO: change when Verilator supports unpacked structures
typedef struct packed {
  logic          ena;  // enable
  isa_priv_typ_t typ;  // type
} ctl_priv_t;

// illegal (idle) value
localparam ctl_priv_t CTL_PRIV_ILL = '{ena: 1'b0, typ: 'x};

///////////////////////////////////////////////////////////////////////////////
// Zicsr standard extension
///////////////////////////////////////////////////////////////////////////////

// CSR operation type
typedef enum logic [2-1:0] {
  CSR_RW  = 2'b01,  // read/write
  CSR_SET = 2'b10,  // set
  CSR_CLR = 2'b11   // clear
} csr_op_t;

// CSR mask source
typedef enum logic [1-1:0] {
  CSR_REG = 1'b0,  // register
  CSR_IMM = 1'b1   // immediate
} csr_msk_t;

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

// CSR immediate (zero extended from 5 to 32 bits
typedef logic [5-1:0] csr_imm_t;

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
localparam ctl_csr_t CTL_CSR_ILL = '{wen: 1'b0, ren: 1'b0, adr: 'x, imm: 'x, msk: 'x, op: 'x};

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
  gpr_t      gpr;     // GPR control signals
  imm_t      imm;     // immediate value
//  br_imm_t   br_imm;  // branch immediate
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
localparam ctl_t CTL_ILL = '{
  ill : ILL,
  gpr : GPR_ILL,
  imm : IMM_ILL,
  i   : CTL_I_ILL,
  m   : CTL_M_ILL,
  csr : CTL_CSR_ILL,
  priv: CTL_PRIV_ILL
};

///////////////////////////////////////////////////////////////////////////////
// 32-bit instruction decoder
///////////////////////////////////////////////////////////////////////////////

// instruction decoder
function ctl_t dec32 (isa_t isa, op32_t op);

// temporary variable used only to reduce line length
ctl_t      t;
op32_frm_t f;  // instruction format

// illegal (idle) default
t = CTL_ILL;

// RV32 I base extension
if (|(isa.spec.base & (RV_32I | RV_64I | RV_128I))) begin casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210            frm;         ill;       '{pc    , br  , '{ai      , ao     , rt  }, ls  , wb    };
  32'b????_????_????_????_????_????_?011_0111: begin f = T_U; t.ill = STD; t.i = '{PC_PCI, 'x  , '{'x      , 'x     , 'x  }, LS_X, WB_IMM}; end  // LUI
  32'b????_????_????_????_????_????_?001_0111: begin f = T_U; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_PC_IM, AO_ADD , R_X }, LS_X, WB_ALU}; end  // AUIPC
  32'b????_????_????_????_????_????_?110_1111: begin f = T_J; t.ill = STD; t.i = '{PC_JMP, 'x  , '{AI_PC_IM, AO_ADD , R_X }, LS_X, WB_PCI}; end  // JAL  TODO: Instruction-address-misaligned exception
  32'b????_????_????_????_?000_????_?110_0111: begin f = T_I; t.ill = STD; t.i = '{PC_JMP, 'x  , '{AI_R1_IM, AO_ADD , R_X }, LS_X, WB_PCI}; end  // JALR TODO: Instruction-address-misaligned exception
  32'b????_????_????_????_?000_????_?110_0011: begin f = T_B; t.ill = STD; t.i = '{PC_BRN, BEQ , '{AI_R1_R2, AO_SUB , R_X }, LS_X, 'x    }; end  // BEQ
  32'b????_????_????_????_?001_????_?110_0011: begin f = T_B; t.ill = STD; t.i = '{PC_BRN, BNE , '{AI_R1_R2, AO_SUB , R_X }, LS_X, 'x    }; end  // BNE
  32'b????_????_????_????_?100_????_?110_0011: begin f = T_B; t.ill = STD; t.i = '{PC_BRN, BLT , '{AI_R1_R2, AO_SLT , R_X }, LS_X, 'x    }; end  // BLT
  32'b????_????_????_????_?101_????_?110_0011: begin f = T_B; t.ill = STD; t.i = '{PC_BRN, BGE , '{AI_R1_R2, AO_SLT , R_X }, LS_X, 'x    }; end  // BGE
  32'b????_????_????_????_?110_????_?110_0011: begin f = T_B; t.ill = STD; t.i = '{PC_BRN, BLTU, '{AI_R1_R2, AO_SLTU, R_X }, LS_X, 'x    }; end  // BLTU
  32'b????_????_????_????_?111_????_?110_0011: begin f = T_B; t.ill = STD; t.i = '{PC_BRN, BGEU, '{AI_R1_R2, AO_SLTU, R_X }, LS_X, 'x    }; end  // BGEU
  32'b????_????_????_????_?000_????_?000_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_BS, WB_MEM}; end  // LB
  32'b????_????_????_????_?001_????_?000_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_HS, WB_MEM}; end  // LH
  32'b????_????_????_????_?010_????_?000_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_WS, WB_MEM}; end  // LW
  32'b????_????_????_????_?100_????_?000_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_BU, WB_MEM}; end  // LBU
  32'b????_????_????_????_?101_????_?000_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_HU, WB_MEM}; end  // LHU
  32'b????_????_????_????_?000_????_?010_0011: begin f = T_S; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, S_B , 'x    }; end  // SB
  32'b????_????_????_????_?001_????_?010_0011: begin f = T_S; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, S_H , 'x    }; end  // SH
  32'b????_????_????_????_?010_????_?010_0011: begin f = T_S; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, S_W , 'x    }; end  // SW
  32'b0000_0000_0000_0000_0000_0000_0001_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{'x      , 'x     , 'x  }, LS_X, 'x    }; end  // NOP (ADDI x0, x0, 0), 32'h000000013
  32'b????_????_????_????_?000_????_?001_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, LS_X, WB_ALU}; end  // ADDI
  32'b????_????_????_????_?010_????_?001_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLT , 'x  }, LS_X, WB_ALU}; end  // SLTI
  32'b????_????_????_????_?011_????_?001_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLTU, 'x  }, LS_X, WB_ALU}; end  // SLTIU
  32'b????_????_????_????_?100_????_?001_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_XOR , 'x  }, LS_X, WB_ALU}; end  // XORI
  32'b????_????_????_????_?110_????_?001_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_OR  , 'x  }, LS_X, WB_ALU}; end  // ORI
  32'b????_????_????_????_?111_????_?001_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_AND , 'x  }, LS_X, WB_ALU}; end  // ANDI
  32'b0000_000?_????_????_?001_????_?001_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLL , R_X }, LS_X, WB_ALU}; end  // SLLI
  32'b0000_000?_????_????_?101_????_?001_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRL , R_X }, LS_X, WB_ALU}; end  // SRLI
  32'b0100_000?_????_????_?101_????_?001_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRA , R_X }, LS_X, WB_ALU}; end  // SRAI
  32'b0000_000?_????_????_?000_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_ADD , R_X }, LS_X, WB_ALU}; end  // ADD
  32'b0100_000?_????_????_?000_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SUB , R_X }, LS_X, WB_ALU}; end  // SUB
  32'b0000_000?_????_????_?010_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SLT , 'x  }, LS_X, WB_ALU}; end  // SLT
  32'b0000_000?_????_????_?011_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SLTU, 'x  }, LS_X, WB_ALU}; end  // SLTU
  32'b0000_000?_????_????_?100_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_XOR , 'x  }, LS_X, WB_ALU}; end  // XOR
  32'b0000_000?_????_????_?001_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SLL , R_X }, LS_X, WB_ALU}; end  // SLL
  32'b0000_000?_????_????_?101_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SRL , R_X }, LS_X, WB_ALU}; end  // SRL
  32'b0100_000?_????_????_?101_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SRA , R_X }, LS_X, WB_ALU}; end  // SRA
  32'b0000_000?_????_????_?110_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_OR  , 'x  }, LS_X, WB_ALU}; end  // OR
  32'b0000_000?_????_????_?111_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_AND , 'x  }, LS_X, WB_ALU}; end  // AND
  32'b????_????_????_????_?000_????_?000_1111: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{'x      , 'x     , 'x  }, LS_X,     'x}; end  // FENCE
endcase end

// RV64 I base extension
if (|(isa.spec.base & (RV_64I | RV_128I))) begin casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210            frm;         ill;       '{pc    , br  , '{ai      , ao     , rt  }, ls  , wb    };
  32'b????_????_????_????_?011_????_?000_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_DS, WB_MEM}; end  // LD
  32'b????_????_????_????_?110_????_?000_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_WU, WB_MEM}; end  // LWU
  32'b????_????_????_????_?011_????_?010_0011: begin f = T_S; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, S_D , 'x    }; end  // SD
  32'b????_????_????_????_?000_????_?001_1011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_SW}, LS_X, WB_ALU}; end  // ADDIW
  32'b0000_00??_????_????_?001_????_?001_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLL , R_X }, LS_X, WB_ALU}; end  // SLLI
  32'b0000_00??_????_????_?101_????_?001_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRL , R_X }, LS_X, WB_ALU}; end  // SRLI
  32'b0100_00??_????_????_?101_????_?001_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRA , R_X }, LS_X, WB_ALU}; end  // SRAI
  32'b0000_000?_????_????_?001_????_?001_1011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLL , R_UW}, LS_X, WB_ALU}; end  // SLLIW
  32'b0000_000?_????_????_?101_????_?001_1011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRL , R_UW}, LS_X, WB_ALU}; end  // SRLIW
  32'b0100_000?_????_????_?101_????_?001_1011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRA , R_SW}, LS_X, WB_ALU}; end  // SRAIW
  32'b0000_000?_????_????_?000_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_ADD , R_SW}, LS_X, WB_ALU}; end  // ADDW
  32'b0100_000?_????_????_?000_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SUB , R_SW}, LS_X, WB_ALU}; end  // SUBW
  32'b0000_000?_????_????_?001_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SLL , R_SW}, LS_X, WB_ALU}; end  // SLLW
  32'b0000_000?_????_????_?101_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SRL , R_UW}, LS_X, WB_ALU}; end  // SRLW
  32'b0100_000?_????_????_?101_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SRA , R_SW}, LS_X, WB_ALU}; end  // SRAW
endcase end

// TODO: encoding is not finalized, the only reference I could find was:
// https://github.com/0xDeva/ida-cpu-RISC-V/blob/master/risc-v_opcode_map.txt
// RV128 I base extension
if (|(isa.spec.base & (RV_128I))) begin casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210            frm;         ill;       '{pc    , br  , '{ai      , ao     , rt  }, ls  , wb    };
//32'b????_????_????_????_?011_????_?000_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_QS, WB_MEM}; end  // LQ
  32'b????_????_????_????_?110_????_?000_0011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_DU, WB_MEM}; end  // LDU
//32'b????_????_????_????_?011_????_?010_0011: begin f = T_S; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, S_Q , 'x    }; end  // SQ
  32'b????_????_????_????_?000_????_?101_1011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_SW}, LS_X, WB_ALU}; end  // ADDID
  32'b0000_00??_????_????_?001_????_?101_1011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLL , R_UW}, LS_X, WB_ALU}; end  // SLLID
  32'b0000_00??_????_????_?101_????_?101_1011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRL , R_UW}, LS_X, WB_ALU}; end  // SRLID
  32'b0100_00??_????_????_?101_????_?101_1011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRA , R_SW}, LS_X, WB_ALU}; end  // SRAID
  32'b0000_000?_????_????_?000_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_ADD , R_SW}, LS_X, WB_ALU}; end  // ADDD
  32'b0100_000?_????_????_?000_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SUB , R_SW}, LS_X, WB_ALU}; end  // SUBD
  32'b0000_000?_????_????_?001_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SLL , R_UW}, LS_X, WB_ALU}; end  // SLLD
  32'b0000_000?_????_????_?101_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SRL , R_UW}, LS_X, WB_ALU}; end  // SRLD
  32'b0100_000?_????_????_?101_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SRA , R_SW}, LS_X, WB_ALU}; end  // SRAD
endcase end

// RV32 M standard extension
if (|(isa.spec.base & (RV_32I | RV_64I | RV_128I)) & isa.spec.ext.M) begin casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210            frm;         ill;       '{pc    , br,alu, lsu , wb    };       '{   op,   s12, rt  , en};
  32'b0000_001?_????_????_?000_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_MUL, 2'b11, R_X , '1}; end  // MUL
  32'b0000_001?_????_????_?001_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_MUH, 2'b11, R_X , '1}; end  // MULH
  32'b0000_001?_????_????_?010_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_MUH, 2'b10, R_X , '1}; end  // MULHSU
  32'b0000_001?_????_????_?011_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_MUH, 2'b00, R_X , '1}; end  // MULHU
  32'b0000_001?_????_????_?100_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_DIV, 2'b11, R_X , '1}; end  // DIV
  32'b0000_001?_????_????_?101_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_DIV, 2'b00, R_X , '1}; end  // DIVU
  32'b0000_001?_????_????_?110_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_REM, 2'b11, R_X , '1}; end  // REM
  32'b0000_001?_????_????_?111_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_REM, 2'b00, R_X , '1}; end  // REMU
endcase end

// RV64 M standard extension
if (|(isa.spec.base & (RV_64I | RV_128I)) & isa.spec.ext.M) begin casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210            frm;         ill;       '{pc    , br,alu, lsu , wb    };       '{   op,   s12, rt  , en};
  32'b0000_001?_????_????_?000_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_MUL, 2'b11, R_SW, '1}; end  // MULW
  32'b0000_001?_????_????_?100_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_DIV, 2'b11, R_SW, '1}; end  // DIVW
  32'b0000_001?_????_????_?101_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_DIV, 2'b10, R_UW, '1}; end  // DIVUW
  32'b0000_001?_????_????_?110_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_REM, 2'b11, R_SW, '1}; end  // REMW
  32'b0000_001?_????_????_?111_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_REM, 2'b10, R_UW, '1}; end  // REMUW
endcase end

// Zifencei standard extension
// TODO: this does nothing
if (isa.spec.ext.Zifencei) begin casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210                ill;     frm;       '{pc    , br,alu, lsu , wb    };
  32'b????_????_????_????_?001_????_?000_1111: begin t.ill = STD; f = T_I; t.i = '{PC_PCI, 'x, 'x, LS_X, 'x    }; end  // fence.i
endcase end

// Zicsr standard extension
if (isa.spec.ext.Zicsr) begin casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210            frm;         ill;       '{pc    , br,alu, lsu , wb    };         '{      wen,       ren,       adr,      imm,     msk,     op };
  32'b????_????_????_????_?001_????_?111_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_CSR}; t.csr = '{       '1, |op.r.rs1, op[31:20],       'x, CSR_REG, CSR_RW }; end  // CSRRW
  32'b????_????_????_????_?010_????_?111_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_CSR}; t.csr = '{|op.r.rs1,        '1, op[31:20],       'x, CSR_REG, CSR_SET}; end  // CSRRS
  32'b????_????_????_????_?011_????_?111_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_CSR}; t.csr = '{|op.r.rs1,        '1, op[31:20],       'x, CSR_REG, CSR_CLR}; end  // CSRRC
  32'b????_????_????_????_?101_????_?111_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_CSR}; t.csr = '{       '1, |op.r.rs1, op[31:20], op.r.rs1, CSR_IMM, CSR_RW }; end  // CSRRWI
  32'b????_????_????_????_?110_????_?111_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_CSR}; t.csr = '{|op.r.rs1,        '1, op[31:20], op.r.rs1, CSR_IMM, CSR_SET}; end  // CSRRSI
  32'b????_????_????_????_?111_????_?111_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x, 'x, LS_X, WB_CSR}; t.csr = '{|op.r.rs1,        '1, op[31:20], op.r.rs1, CSR_IMM, CSR_CLR}; end  // CSRRCI
endcase end

// privileged mode
if (isa.priv.M) begin casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210            frm;         ill;          '{ena , typ        };       '{pc    , br,alu, lsu , wb};
  32'b0000_0000_0000_0000_0000_0000_0111_0011: begin f = T_R; t.ill = STD; t.priv = '{1'b1, PRIV_ECALL }; t.i = '{PC_TRP, 'x, 'x, LS_X, 'x}; end  // ecall
  32'b0000_0000_0001_0000_0000_0000_0111_0011: begin f = T_R; t.ill = STD; t.priv = '{1'b1, PRIV_EBREAK}; t.i = '{PC_TRP, 'x, 'x, LS_X, 'x}; end  // ebreak
  32'b0001_0000_0010_0101_0000_0000_0111_0011: begin f = T_R; t.ill = STD; t.priv = '{1'b1, PRIV_WFI   }; t.i = '{PC_PCI, 'x, 'x, LS_X, 'x}; end  // wfi
endcase end

// Trap-Return Instructions
if (isa.priv.U) begin casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210            frm;         ill;          '{ena , typ        };       '{pc    , br,alu, lsu , wb};
  32'b0000_0000_0010_0000_0000_0000_0111_0011: begin f = T_I; t.ill = STD; t.priv = '{1'b1, PRIV_URET  }; t.i = '{PC_EPC, 'x, 'x, LS_X, 'x}; end  // uret
endcase end
if (isa.priv.S) begin casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210            frm;         ill;          '{ena , typ        };       '{pc    , br,alu, lsu , wb};
  32'b0001_0000_0010_0000_0000_0000_0111_0011: begin f = T_I; t.ill = STD; t.priv = '{1'b1, PRIV_SRET  }; t.i = '{PC_EPC, 'x, 'x, LS_X, 'x}; end  // sret
endcase end
if (isa.priv.M) begin casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210            frm;         ill;          '{ena , typ        };       '{pc    , br,alu, lsu , wb};
  32'b0011_0000_0010_0000_0000_0000_0111_0011: begin f = T_I; t.ill = STD; t.priv = '{1'b1, PRIV_MRET  }; t.i = '{PC_EPC, 'x, 'x, LS_X, 'x}; end  // mret
endcase end

//// RV32/RV64 Zba standard extension
//if (|(isa.spec.base & (RV_32I | RV_64I)) & isa.spec.ext.Zba) begin casez (op)
//  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210            frm;         ill;        {pc    , br  , '{bi      , bo          , br }, lsu , wb    }
//  32'b0010_000?_????_????_?010_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, BO_SH1ADD   , R_X}, LS_X, WB_BLU}; end  // SH1ADD
//  32'b0010_000?_????_????_?100_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, BO_SH2ADD   , R_X}, LS_X, WB_BLU}; end  // SH2ADD
//  32'b0010_000?_????_????_?110_????_?011_0011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, BO_SH3ADD   , R_X}, LS_X, WB_BLU}; end  // SH3ADD
//endcase end
//
//// RV32 Zba standard extension
//if (|(isa.spec.base & (RV_64I)) & isa.spec.ext.Zba) begin casez (op)
//  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210            frm;         ill;        {pc    , br  , '{bi      , bo          , br }, lsu , wb    }
//  32'b0000_100?_????_????_?010_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, BO_ADD.UW   , R_X}, LS_X, WB_BLU}; end  // ADD.SW
//  32'b0010_000?_????_????_?010_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, BO_SH1ADD.UW, R_X}, LS_X, WB_BLU}; end  // SH1ADD.UW
//  32'b0010_000?_????_????_?100_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, BO_SH2ADD.UW, R_X}, LS_X, WB_BLU}; end  // SH2ADD.UW
//  32'b0010_000?_????_????_?110_????_?011_1011: begin f = T_R; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, BO_SH3ADD.UW, R_X}, LS_X, WB_BLU}; end  // SH3ADD.UW
//  32'b0000_10??_????_????_?001_????_?001_1011: begin f = T_I; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLLI.UW  , R_X}, LS_X, WB_ALU}; end  // SLLI.UW
//endcase end

// GPR and immediate decoders are based on instruction formats
// TODO: also handle RES/NSE
if (t.ill != ILL) begin
  t.gpr = gpr32(op, f);
  t.imm = imm32(op, f);
end

// immediate values for each unit
//t.br_imm = 

// assign temporary variable to return value
dec32 = t;

endfunction: dec32

///////////////////////////////////////////////////////////////////////////////
// 16-bit instruction decoder
///////////////////////////////////////////////////////////////////////////////

// !!! NOTE !!!
// Define instructions in the next order:
// 1. reserved (usually        nzuimm==0)
// 2. HINT     (usually rd==0, nzuimm!=0)
// 3. normal   (usually rd!=0, nzuimm!=0)
// If the order is not correct, an illigal instruction might be executed as normal or hint.

// instruction decoder
/* verilator lint_off CASEOVERLAP */
/* verilator lint_off CASEINCOMPLETE */
function ctl_t dec16 (isa_t isa, op16_t op);

// temporary variable used only to reduce line length
ctl_t t;
// TODO: change when Verilator supports unpacked structures
struct packed {
  op16_frm_t f;  // instruction format
  op16_imm_t i;  // immediate qualifier
} fi;

// illegal (idle) default
t = CTL_ILL;

// RV32 I base extension
if (|(isa.spec.base & (RV_32I | RV_64I | RV_128I))) begin casez (op)
  //  fedc_ba98_7654_3210             '{  frm ,   wdh};         ill;       '{pc    , br  , '{ai      , ao     , rt  }, lsu , wb    };
  16'b0000_0000_0000_0000: begin fi = '{'x    , 'x   }; t.ill = ILL; t.i = '{PC_ILL, 'x  , '{'x      , 'x     , 'x  }, LS_X, 'x    }; end  // illegal instruction
  16'b0000_0000_000?_??00: begin fi = '{T_CIW , 'x   }; t.ill = RES; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, LS_X, WB_ALU}; end  // C.ADDI4SPN, nzuimm = 0
  16'b000?_????_????_??00: begin fi = '{T_CIW , 'x   }; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, LS_X, WB_ALU}; end  // C.ADDI4SPN
  16'b010?_????_????_??00: begin fi = '{T_CL  , T_C_W}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_WS, WB_MEM}; end  // C.LW
  16'b100?_????_????_??00: begin fi = '{'x    , 'x   }; t.ill = ILL; t.i = '{PC_ILL, 'x  , '{'x      , 'x     , 'x  }, LS_X, 'x    }; end  // Reserved
  16'b110?_????_????_??00: begin fi = '{T_CS  , T_C_W}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, S_W , 'x    }; end  // C.SW
  16'b0000_0000_0000_0001: begin fi = '{T_CI  , T_C_S}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, LS_X, WB_ALU}; end  // C.NOP
  16'b000?_0000_0???_??01: begin fi = '{T_CI  , T_C_S}; t.ill = HNT; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, LS_X, WB_ALU}; end  // C.NOP, nzimm != 0
  16'b0000_????_?000_0001: begin fi = '{T_CI  , T_C_S}; t.ill = HNT; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, LS_X, WB_ALU}; end  // C.ADDI, nzimm = 0 // TODO prevent WB
  16'b000?_????_????_??01: begin fi = '{T_CI  , T_C_S}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, LS_X, WB_ALU}; end  // C.ADDI
  16'b001?_????_????_??01: begin fi = '{T_CJ_L, 'x   }; t.ill = STD; t.i = '{PC_JMP, 'x  , '{AI_PC_IM, AO_ADD , R_X }, LS_X, WB_PCI}; end  // C.JAL, only RV32
  16'b010?_0000_0???_??01: begin fi = '{T_CI  , T_C_S}; t.ill = HNT; t.i = '{PC_PCI, 'x  , '{'x      , 'x     , 'x  }, LS_X, WB_IMM}; end  // C.LI, rd = 0
  16'b010?_????_????_??01: begin fi = '{T_CI  , T_C_S}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{'x      , 'x     , 'x  }, LS_X, WB_IMM}; end  // C.LI
  16'b0110_0001_0000_0001: begin fi = '{T_CI_S, T_C_F}; t.ill = RES; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, LS_X, WB_ALU}; end  // C.ADDI16SP, nzimm = 0
  16'b011?_0001_0???_??01: begin fi = '{T_CI_S, T_C_F}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, LS_X, WB_ALU}; end  // C.ADDI16SP
  16'b0110_????_?000_0001: begin fi = '{T_CI  , T_C_P}; t.ill = RES; t.i = '{PC_PCI, 'x  , '{'x      , 'x     , 'x  }, LS_X, WB_IMM}; end  // C.LUI, nzimm = 0
  16'b011?_0000_0???_??01: begin fi = '{T_CI  , T_C_P}; t.ill = HNT; t.i = '{PC_PCI, 'x  , '{'x      , 'x     , 'x  }, LS_X, WB_IMM}; end  // C.LUI, rd = 0
  16'b011?_????_????_??01: begin fi = '{T_CI  , T_C_P}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{'x      , 'x     , 'x  }, LS_X, WB_IMM}; end  // C.LUI
  16'b1001_00??_????_??01: begin fi = '{T_CB_A, T_C_W}; t.ill = NSE; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRL , R_X }, LS_X, WB_ALU}; end  // C.SRLI, only RV32,    nzuimm[5] = 1
  16'b1000_00??_?000_0001: begin fi = '{T_CB_A, T_C_W}; t.ill = HNT; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRL , R_X }, LS_X, WB_ALU}; end  // C.SRLI, only RV32/64, nzuimm    = 0
  16'b100?_00??_????_??01: begin fi = '{T_CB_A, T_C_W}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRL , R_X }, LS_X, WB_ALU}; end  // C.SRLI, only RV32/64
  16'b1001_01??_?000_0001: begin fi = '{T_CB_A, T_C_W}; t.ill = NSE; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRL , R_X }, LS_X, WB_ALU}; end  // C.SRAI, only RV32   , nzuimm[5] = 1
  16'b1000_01??_?000_0001: begin fi = '{T_CB_A, T_C_W}; t.ill = HNT; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRA , R_X }, LS_X, WB_ALU}; end  // C.SRAI, only RV32/64, nzuimm    = 0
  16'b100?_01??_????_??01: begin fi = '{T_CB_A, T_C_W}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRA , R_X }, LS_X, WB_ALU}; end  // C.SRAI, only RV32/64
  16'b100?_10??_????_??01: begin fi = '{T_CB_A, T_C_W}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_AND , R_X }, LS_X, WB_ALU}; end  // C.ANDI
  16'b1000_11??_?00?_??01: begin fi = '{T_CA  , 'x   }; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SUB , R_X }, LS_X, WB_ALU}; end  // C.SUB
  16'b1000_11??_?01?_??01: begin fi = '{T_CA  , 'x   }; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_XOR , R_X }, LS_X, WB_ALU}; end  // C.XOR
  16'b1000_11??_?10?_??01: begin fi = '{T_CA  , 'x   }; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_OR  , R_X }, LS_X, WB_ALU}; end  // C.OR
  16'b1000_11??_?11?_??01: begin fi = '{T_CA  , 'x   }; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_AND , R_X }, LS_X, WB_ALU}; end  // C.AND
  16'b1001_11??_?00?_??01: begin fi = '{'x    , 'x   }; t.ill = RES; t.i = '{'x    , 'x  , '{'x      , 'x     , 'x  }, LS_X, 'x    }; end  // RES (only RV64/128)
  16'b1001_11??_?01?_??01: begin fi = '{'x    , 'x   }; t.ill = RES; t.i = '{'x    , 'x  , '{'x      , 'x     , 'x  }, LS_X, 'x    }; end  // RES (only RV64/128)
  16'b1001_11??_?10?_??01: begin fi = '{'x    , 'x   }; t.ill = ILL; t.i = '{'x    , 'x  , '{'x      , 'x     , 'x  }, LS_X, 'x    }; end  // Reserved
  16'b1001_11??_?11?_??01: begin fi = '{'x    , 'x   }; t.ill = ILL; t.i = '{'x    , 'x  , '{'x      , 'x     , 'x  }, LS_X, 'x    }; end  // Reserved
  16'b101?_????_????_??01: begin fi = '{T_CJ  , 'x   }; t.ill = STD; t.i = '{PC_JMP, 'x  , '{AI_PC_IM, AO_ADD , R_X }, LS_X, WB_PCI}; end  // C.J
  16'b110?_????_????_??01: begin fi = '{T_CB  , 'x   }; t.ill = STD; t.i = '{PC_BRN, BEQ , '{AI_R1_R2, AO_SUB , R_X }, LS_X, 'x    }; end  // C.BEQZ
  16'b111?_????_????_??01: begin fi = '{T_CB  , 'x   }; t.ill = STD; t.i = '{PC_BRN, BNE , '{AI_R1_R2, AO_SUB , R_X }, LS_X, 'x    }; end  // C.BNEZ
  16'b0001_????_????_??10: begin fi = '{T_CI  , T_C_U}; t.ill = NSE; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLL , R_X }, LS_X, WB_ALU}; end  // C.SLLI, only RV32, nzuimm[5] = 1
  16'b0000_0000_0000_0010: begin fi = '{T_CI  , T_C_U}; t.ill = HNT; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLL , R_X }, LS_X, WB_ALU}; end  // C.SLLI, nzuimm = 0, rd = 0
  16'b0000_????_?000_0010: begin fi = '{T_CI  , T_C_U}; t.ill = HNT; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLL , R_X }, LS_X, WB_ALU}; end  // C.SLLI, nzuimm = 0
  16'b000?_0000_0???_??10: begin fi = '{T_CI  , T_C_U}; t.ill = HNT; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLL , R_X }, LS_X, WB_ALU}; end  // C.SLLI,             rd = 0
  16'b000?_????_????_??10: begin fi = '{T_CI  , T_C_U}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLL , R_X }, LS_X, WB_ALU}; end  // C.SLLI
  16'b010?_0000_0???_??10: begin fi = '{T_CI_L, T_C_W}; t.ill = RES; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_WS, WB_MEM}; end  // C.LWSP, rd = 0
  16'b010?_????_????_??10: begin fi = '{T_CI_L, T_C_W}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_WS, WB_MEM}; end  // C.LWSP
  16'b1000_0000_0000_0010: begin fi = '{T_CI_J, 'x   }; t.ill = RES; t.i = '{PC_JMP, 'x  , '{AI_R1_IM, AO_ADD , R_X }, LS_X, WB_PCI}; end  // C.JR, rs1 = 0
  16'b1000_????_?000_0010: begin fi = '{T_CI_J, 'x   }; t.ill = STD; t.i = '{PC_JMP, 'x  , '{AI_R1_IM, AO_ADD , R_X }, LS_X, WB_PCI}; end  // C.JR
  16'b1000_????_????_??10: begin fi = '{T_CR_0, 'x   }; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_ADD , R_X }, LS_X, WB_ALU}; end  // C.MV
  16'b1001_????_?000_0010: begin fi = '{T_CR_L, 'x   }; t.ill = STD; t.i = '{PC_JMP, 'x  , '{AI_R1_IM, AO_ADD , R_X }, LS_X, WB_PCI}; end  // C.JALR
  16'b1001_????_????_??10: begin fi = '{T_CR  , 'x   }; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_ADD , R_X }, LS_X, WB_ALU}; end  // C.ADD
  16'b110?_????_????_??10: begin fi = '{T_CSS , T_C_W}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, S_W , 'x    }; end  // C.SWSP
endcase end

// privileged mode
if (isa.priv.M) begin casez (op)
  //  fedc_ba98_7654_3210             '{  frm ,   wdh};         ill;            ena , typ                   pc    , br,alu, lsu , wb};
  16'b1001_0000_0000_0010: begin fi = '{T_CR  , 'x   }; t.ill = STD; t.priv = '{1'b1, PRIV_EBREAK}; t.i = '{PC_TRP, 'x, 'x, LS_X, 'x}; end  // C.EBREAK
endcase end

// TODO
// RV32 F standard extension
if (|(isa.spec.base & (RV_32I | RV_64I | RV_128I)) & isa.spec.ext.F) begin casez (op)
  16'b011?_????_????_??10: begin fi = '{T_CI, T_C_W}; t.ill = STD; end  // C.FLWSP
endcase end

// TODO
// RV32 F standard extension
if (|(isa.spec.base & (RV_64I | RV_128I)) & isa.spec.ext.F) begin casez (op)
  16'b001?_????_????_??00: begin fi = '{T_CL, T_C_D}; ; t.ill = STD; end  // C.FLD
  16'b011?_????_????_??00: begin fi = '{T_CL, T_C_W}; ; t.ill = STD; end  // C.FLW
  16'b101?_????_????_??00: begin fi = '{T_CS, T_C_D}; ; t.ill = STD; end  // C.FSD
  16'b111?_????_????_??00: begin fi = '{T_CS, T_C_W}; ; t.ill = STD; end  // C.FSW
  16'b001?_????_????_??10: begin fi = '{T_CI, T_C_W}; ; t.ill = STD; end  // C.FLDSP
  16'b101?_????_????_??10: begin fi = '{T_CI, T_C_W}; ; t.ill = STD; end  // C.FSDSP
  16'b111?_????_????_??10: begin fi = '{T_CI, T_C_W}; ; t.ill = STD; end  // C.FSWSP
endcase end

// TODO: all RESERVERD values should be repeated here, since they are overwritten by the RV64 decoder
// RV64 I base extension
if (|(isa.spec.base & (RV_64I | RV_128I))) begin casez (op)
  //  fedc_ba98_7654_3210             '{  frm ,   wdh};         ill;       '{pc    , br  , '{ai      , ao     , rt  }, lsu , wb    };
  16'b011?_????_????_??00: begin fi = '{T_CL  , T_C_D}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_DS, WB_MEM}; end  // C.LD
  16'b111?_????_????_??00: begin fi = '{T_CS  , T_C_D}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, S_D , 'x    }; end  // C.SD
  16'b100?_00??_????_??01: begin fi = '{T_CB_A, T_C_D}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRL , R_X }, LS_X, WB_ALU}; end  // C.SRLI, only RV32/64
  16'b100?_01??_????_??01: begin fi = '{T_CB_A, T_C_D}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRA , R_X }, LS_X, WB_ALU}; end  // C.SRAI, only RV32/64
  16'b1001_11??_?00?_??01: begin fi = '{T_CA  , 'x   }; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_SUB , R_SW}, LS_X, WB_ALU}; end  // C.SUBW
  16'b1001_11??_?01?_??01: begin fi = '{T_CA  , 'x   }; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_R2, AO_ADD , R_SW}, LS_X, WB_ALU}; end  // C.ADDW
  16'b001?_0000_0???_??01: begin fi = '{T_CI  , T_C_S}; t.ill = RES; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_SW}, LS_X, WB_ALU}; end  // C.ADDIW, rd = 0
  16'b001?_????_????_??01: begin fi = '{T_CI  , T_C_S}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_SW}, LS_X, WB_ALU}; end  // C.ADDIW
  16'b000?_????_????_??10: begin fi = '{T_CI  , T_C_U}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLL , R_X }, LS_X, WB_ALU}; end  // C.SLLI
  16'b011?_0000_0???_??10: begin fi = '{T_CI_L, T_C_D}; t.ill = RES; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_DS, WB_MEM}; end  // C.LDSP, rd = 0
  16'b011?_????_????_??10: begin fi = '{T_CI_L, T_C_D}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_DS, WB_MEM}; end  // C.LDSP
  16'b111?_????_????_??10: begin fi = '{T_CSS , T_C_D}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, S_D , 'x    }; end  // C.SDSP
endcase end

// RV128 I base extension
if (|(isa.spec.base & (RV_128I))) begin casez (op)
  //  fedc_ba98_7654_3210             '{  frm ,   wdh};         ill;       '{pc    , br  , '{ai      , ao     , rt  }, lsu , wb    };
//16'b001?_????_????_??00: begin fi = '{T_CL  , T_C_Q}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_QS, WB_MEM}; end  // C.LQ  // TODO: load quad encoding not supported yet
  16'b101?_????_????_??00: begin fi = '{T_CS  , T_C_Q}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, S_Q , 'x    }; end  // C.SQ
  16'b1000_00??_?000_0001: begin fi = '{T_CB_A, T_C_Q}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRL , R_X }, LS_X, WB_ALU}; end  // C.SRLI64  // TODO: decode immediate as signed
  16'b100?_00??_????_??01: begin fi = '{T_CB_A, T_C_Q}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRL , R_X }, LS_X, WB_ALU}; end  // C.SRLI
  16'b1000_01??_?000_0001: begin fi = '{T_CB_A, T_C_Q}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRA , R_X }, LS_X, WB_ALU}; end  // C.SRAI64  // TODO: decode immediate as signed
  16'b100?_01??_????_??01: begin fi = '{T_CB_A, T_C_Q}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SRA , R_X }, LS_X, WB_ALU}; end  // C.SRAI
  16'b0000_????_?000_0010: begin fi = '{T_CI  , T_C_Q}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLL , R_X }, LS_X, WB_ALU}; end  // C.SLLI64
  16'b000?_????_????_??10: begin fi = '{T_CI  , T_C_Q}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_SLL , R_X }, LS_X, WB_ALU}; end  // C.SLLI
//16'b001?_0000_0???_??10: begin fi = '{T_CI_L, T_C_Q}; t.ill = RES; t.i = '{PC_ILL, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_QS, WB_MEM}; end  // C.LQSP, rd = 0
//16'b001?_????_????_??10: begin fi = '{T_CI_L, T_C_Q}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, L_QS, WB_MEM}; end  // C.LQSP  // TODO: load quad encoding not supported yet
  16'b101?_????_????_??10: begin fi = '{T_CSS , T_C_Q}; t.ill = STD; t.i = '{PC_PCI, 'x  , '{AI_R1_IM, AO_ADD , R_X }, S_Q , 'x    }; end  // C.SQSP
endcase end

// GPR and immediate decoders are based on instruction formats
// TODO: also handle RES/NSE
if (t.ill != ILL) begin
  t.gpr = gpr16(op, fi.f);
  t.imm = imm16(op, fi.f, fi.i);
end

// assign temporary variable to return value
dec16 = t;

endfunction: dec16
/* verilator lint_on CASEOVERLAP */
/* verilator lint_on CASEINCOMPLETE */

///////////////////////////////////////////////////////////////////////////////
// instruction decoder
///////////////////////////////////////////////////////////////////////////////

// TODO: check for C extension
// instruction decoder
function ctl_t dec (isa_t isa, op32_t op);
  case (opsiz(op[16-1:0]))
    2      : dec = dec16(isa, op[16-1:0]);  // 16-bit C standard extension
    4      : dec = dec32(isa, op[32-1:0]);  // 32-bit
    default: dec = CTL_ILL;
  endcase
endfunction: dec

///////////////////////////////////////////////////////////////////////////////
// A extension
///////////////////////////////////////////////////////////////////////////////

//// RV.A32
////  fedc_ba98_7654_3210_fedc_ba98_7654_3210                 pc,     rs1,     rs2,   imm,     alu,     br,   st,ste,    ld,lde,     wb,wbe,   csr,ill
//32'b0001_0??0_0000_????_?010_????_?010_1111: dec = '{"lr.w              ", TYPE_32_R};
//32'b0001_1???_????_????_?010_????_?010_1111: dec = '{"sc.w              ", TYPE_32_R};
//32'b0000_0???_????_????_?010_????_?010_1111: dec = '{"amoadd.w          ", TYPE_32_R};
//32'b0010_0???_????_????_?010_????_?010_1111: dec = '{"amoxor.w          ", TYPE_32_R};
//32'b0100_0???_????_????_?010_????_?010_1111: dec = '{"amoor.w           ", TYPE_32_R};
//32'b0110_0???_????_????_?010_????_?010_1111: dec = '{"amoand.w          ", TYPE_32_R};
//32'b1000_0???_????_????_?010_????_?010_1111: dec = '{"amomin.w          ", TYPE_32_R};
//32'b1010_0???_????_????_?010_????_?010_1111: dec = '{"amomax.w          ", TYPE_32_R};
//32'b1100_0???_????_????_?010_????_?010_1111: dec = '{"amominu.w         ", TYPE_32_R};
//32'b1110_0???_????_????_?010_????_?010_1111: dec = '{"amomaxu.w         ", TYPE_32_R};
//32'b0000_1???_????_????_?010_????_?010_1111: dec = '{"amoswap.w         ", TYPE_32_R};
//
//// RV.A64
////  fedc_ba98_7654_3210_fedc_ba98_7654_3210                 pc,     rs1,     rs2,   imm,     alu,     br,   st,ste,    ld,lde,     wb,wbe,   csr,ill
//32'b0001_0??0_0000_????_?011_????_?010_1111: dec = '{"lr.d              ", TYPE_32_R};
//32'b0001_1???_????_????_?011_????_?010_1111: dec = '{"sc.d              ", TYPE_32_R};
//32'b0000_0???_????_????_?011_????_?010_1111: dec = '{"amoadd.d          ", TYPE_32_R};
//32'b0010_0???_????_????_?011_????_?010_1111: dec = '{"amoxor.d          ", TYPE_32_R};
//32'b0100_0???_????_????_?011_????_?010_1111: dec = '{"amoor.d           ", TYPE_32_R};
//32'b0110_0???_????_????_?011_????_?010_1111: dec = '{"amoand.d          ", TYPE_32_R};
//32'b1000_0???_????_????_?011_????_?010_1111: dec = '{"amomin.d          ", TYPE_32_R};
//32'b1010_0???_????_????_?011_????_?010_1111: dec = '{"amomax.d          ", TYPE_32_R};
//32'b1100_0???_????_????_?011_????_?010_1111: dec = '{"amominu.d         ", TYPE_32_R};
//32'b1110_0???_????_????_?011_????_?010_1111: dec = '{"amomaxu.d         ", TYPE_32_R};
//32'b0000_1???_????_????_?011_????_?010_1111: dec = '{"amoswap.d         ", TYPE_32_R};

/*
// RV.F32
//  fedc_ba98_7654_3210_fedc_ba98_7654_3210                 pc,     rs1,     rs2,   imm,     alu,     br,   st,ste,    ld,lde,     wb,wbe,   csr,ill
32'b????_????_????_????_?010_????_?000_0111: dec = '{"flw               ", TYPE_32_I};
32'b????_????_????_????_?010_????_?010_0111: dec = '{"fsw               ", TYPE_32_S};
32'b????_?00?_????_????_????_????_?100_0011: dec = '{"fmadd.s           ", TYPE_32_R4};
32'b????_?00?_????_????_????_????_?100_0111: dec = '{"fmsub.s           ", TYPE_32_R4};
32'b????_?00?_????_????_????_????_?100_1011: dec = '{"fnmsub.s          ", TYPE_32_R4};
32'b????_?00?_????_????_????_????_?100_1111: dec = '{"fnmadd.s          ", TYPE_32_R4};
32'b0000_000?_????_????_????_????_?101_0011: dec = '{"fadd.s            ", TYPE_32_R};
32'b0000_100?_????_????_????_????_?101_0011: dec = '{"fsub.s            ", TYPE_32_R};
32'b0001_000?_????_????_????_????_?101_0011: dec = '{"fmul.s            ", TYPE_32_R};
32'b0001_100?_????_????_????_????_?101_0011: dec = '{"fdiv.s            ", TYPE_32_R};
32'b0101_1000_0000_????_????_????_?101_0011: dec = '{"fsqrt.s           ", TYPE_32_R};
32'b0010_000?_????_????_?000_????_?101_0011: dec = '{"fsgnj.s           ", TYPE_32_R};
32'b0010_000?_????_????_?001_????_?101_0011: dec = '{"fsgnjn.s          ", TYPE_32_R};
32'b0010_000?_????_????_?010_????_?101_0011: dec = '{"fsgnjx.s          ", TYPE_32_R};
32'b0010_100?_????_????_?000_????_?101_0011: dec = '{"fmin.s            ", TYPE_32_R};
32'b0010_100?_????_????_?001_????_?101_0011: dec = '{"fmax.s            ", TYPE_32_R};
32'b1100_0000_0000_????_????_????_?101_0011: dec = '{"fcvt.w.s          ", TYPE_32_R};
32'b1100_0000_0001_????_????_????_?101_0011: dec = '{"fcvt.wu.s         ", TYPE_32_R};
32'b1110_0000_0000_????_????_????_?101_0011: dec = '{"fmv.x.w           ", TYPE_32_R};

32'b0001_0??0_0000_????_?011_????_?010_1111: dec = '{"lr.d              ", TYPE_32_R};
*/

endpackage: riscv_isa_pkg
