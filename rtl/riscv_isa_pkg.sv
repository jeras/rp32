///////////////////////////////////////////////////////////////////////////////
// RISC-V ISA package
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
typedef enum isa_base_t {
  //           EWDQ
  RV_32E  = 4'b1100,
  RV_32I  = 4'b0100,
  RV_64I  = 4'b0010,
  RV_128I = 4'b0001
} isa_base_et;

// standard extensions
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
typedef enum isa_ext_t {
  //                MAFD_ZZ_QLCBJTPVNHS_ZZ
  RV_M        = 19'b1000_00_00000000000_00,  // integer multiplication and division
  RV_A        = 19'b0100_00_00000000000_00,  // atomic instructions
  RV_F        = 19'b0010_00_00000000000_00,  // single-precision floating-point
  RV_D        = 19'b0001_00_00000000000_00,  // double-precision floating-point
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
  RV_G        = 19'b1111_11_00000000000_01,  // general-purpose standard extenssion combination (G = IMAFDZicsrZifencei)
  RV_NONE     = 19'b0000_00_00000000000_00   // no standard extensions
} isa_ext_et;

typedef struct packed {
  isa_base_t base;
  isa_ext_t  ext;
} isa_t;

// enumerations for common and individual configurations
typedef enum isa_t {
  RV32E   = {RV_32E , RV_NONE},
  RV32I   = {RV_32I , RV_NONE},
  RV64I   = {RV_64I , RV_NONE},
  RV128I  = {RV_128I, RV_NONE},
  RV32EC  = {RV_32E , RV_C},
  RV32IC  = {RV_32I , RV_C},
  RV64IC  = {RV_64I , RV_C},
  RV128IC = {RV_128I, RV_C},
  RV32EMC = {RV_32E , RV_M | RV_C},
  RV32IMC = {RV_32I , RV_M | RV_C},
  RV64IMC = {RV_64I , RV_M | RV_C},
  RV32G   = {RV_32I , RV_G},
  RV64G   = {RV_64I , RV_G},
  RV128G  = {RV_128I, RV_G},
  RV32GC  = {RV_32I , RV_G | RV_C},
  RV64GC  = {RV_64I , RV_G | RV_C},
  RV128GC = {RV_128I, RV_G | RV_C}
} isa_et;

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
// 32-bit instruction format
///////////////////////////////////////////////////////////////////////////////

typedef struct packed {logic [4:0] rs3; logic [1:0] func2;          logic [4:0] rs2; logic [4:0] rs1; logic [2:0] func3; logic [4:0] rd     ;                       logic [6:0] opcode;} op32_r4_t;  // Register 4
typedef struct packed {                 logic [6:0] func7;          logic [4:0] rs2; logic [4:0] rs1; logic [2:0] func3; logic [4:0] rd     ;                       logic [6:0] opcode;} op32_r_t ;  // Register
typedef struct packed {logic [11:00] imm_11_0;                                       logic [4:0] rs1; logic [2:0] func3; logic [4:0] rd     ;                       logic [6:0] opcode;} op32_i_t ;  // Immediate
typedef struct packed {logic [11:05] imm_11_5;                      logic [4:0] rs2; logic [4:0] rs1; logic [2:0] func3; logic [4:0] imm_4_0;                       logic [6:0] opcode;} op32_s_t ;  // Store
typedef struct packed {logic [12:12] imm_12; logic [10:5] imm_10_5; logic [4:0] rs2; logic [4:0] rs1; logic [2:0] func3; logic [4:1] imm_4_1; logic [11:11] imm_11; logic [6:0] opcode;} op32_b_t ;  // Branch
typedef struct packed {logic [31:12] imm_31_12;                                                                          logic [4:0] rd     ;                       logic [6:0] opcode;} op32_u_t ;  // Upper immediate
typedef struct packed {logic [20:20] imm_20; logic [10:1] imm_10_1; logic [11:11] imm_11; logic [19:12] imm_19_12;       logic [4:0] rd     ;                       logic [6:0] opcode;} op32_j_t ;  // Jump

// union of instruction formats
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
typedef enum logic [4-1:0] {
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

typedef logic signed [32-1:0] imm_t;

function imm_t imm32 (op32_t op, op32_frm_t frm);
  unique case (frm)
    T_R4   : imm32 = 'x;
    T_R    : imm32 = 'x;
    T_I    : imm32 = imm_t'($signed({op.i.imm_11_0}));                                                  // s11
    T_S    : imm32 = imm_t'($signed({op.s.imm_11_5, op.s.imm_4_0}));                                    // s11
    T_B    : imm32 = imm_t'($signed({op.b.imm_12, op.b.imm_11, op.b.imm_10_5, op.b.imm_4_1, 1'b0}));    // s12
    T_U    : imm32 = imm_t'($signed({op.u.imm_31_12, 12'h000}));                                        // s31
    T_J    : imm32 = imm_t'($signed({op.j.imm_20, op.j.imm_19_12, op.j.imm_11, op.j.imm_10_1, 1'b0}));  // s20
    default: imm32 = 'x;
  endcase
endfunction: imm32

///////////////////////////////////////////////////////////////////////////////
// 32-bit OP GPR decoder
///////////////////////////////////////////////////////////////////////////////

// GPR control signals
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

function gpr_t gpr32 (op32_t op, op32_frm_t frm);
  unique case (frm)  // rs1,rs2,rd            rs1,       rs2,       rd
    T_R4   : gpr32 = '{'{'0, '0, '0}, '{       'x,        'x,       'x}};
    T_R    : gpr32 = '{'{'1, '1, '1}, '{op.r .rs1, op.r .rs2, op.r .rd}};
    T_I    : gpr32 = '{'{'1, '0, '1}, '{op.i .rs1,        'x, op.i .rd}};
    T_S    : gpr32 = '{'{'1, '1, '0}, '{op.s .rs1, op.s .rs2,       'x}};
    T_B    : gpr32 = '{'{'1, '1, '0}, '{op.b .rs1, op.b .rs2,       'x}};
    T_U    : gpr32 = '{'{'0, '0, '1}, '{       'x,        'x, op.u .rd}};
    T_J    : gpr32 = '{'{'0, '0, '1}, '{       'x,        'x, op.j .rd}};
    default: gpr32 = '{'{'0, '0, '0}, '{       'x,        'x,       'x}};
  endcase
endfunction: gpr32

///////////////////////////////////////////////////////////////////////////////
// 16-bit compressed instruction format
///////////////////////////////////////////////////////////////////////////////

typedef struct packed {logic [ 3: 0] funct4;                          logic [ 4: 0] rd_rs1 ;                          logic [ 4: 0] rs2 ; logic [1:0] opcode;} op16_cr_t ;  // Register
typedef struct packed {logic [ 2: 0] funct3; logic [12:12] imm_12_12; logic [ 4: 0] rd_rs1 ; logic [ 6: 2] imm_06_02;                     logic [1:0] opcode;} op16_ci_t ;  // Immediate
typedef struct packed {logic [ 2: 0] funct3; logic [12: 7] imm_12_07;                                                 logic [ 4: 0] rs2 ; logic [1:0] opcode;} op16_css_t;  // Stack-relative Store
typedef struct packed {logic [ 2: 0] funct3; logic [12: 5] imm_12_05;                                                 logic [ 2: 0] rd_ ; logic [1:0] opcode;} op16_ciw_t;  // Wide Immediate
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] imm_12_10; logic [ 2: 0] rs1_   ; logic [ 6: 5] imm_06_05; logic [ 2: 0] rd_ ; logic [1:0] opcode;} op16_cl_t ;  // Load
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] imm_12_10; logic [ 2: 0] rs1_   ; logic [ 6: 5] imm_06_05; logic [ 2: 0] rs2_; logic [1:0] opcode;} op16_cs_t ;  // Store
typedef struct packed {logic [ 5: 0] funct6;                          logic [ 2: 0] rd_rs1_; logic [ 1: 0] func2;     logic [ 2: 0] rs2_; logic [1:0] opcode;} op16_ca_t ;  // Arithmetic
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] off_12_10; logic [ 2: 0] rs1_   ; logic [ 6: 2] off_06_02;                     logic [1:0] opcode;} op16_cb_t ;  // Branch
typedef struct packed {logic [ 2: 0] funct3; logic [12: 2] target;                                                                        logic [1:0] opcode;} op16_cj_t ;  // Jump

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

typedef enum logic [4-1:0] {
  T_CR ,  // Register
  T_CI ,  // Immediate
  T_CSS,  // Stack-relative Store
  T_CIW,  // Wide Immediate
  T_CL ,  // Load
  T_CS ,  // Store
  T_CA ,  // Arithmetic
  T_CB ,  // Branch
  T_CJ ,  // Jump
  T_CBS,  // shift operatios // TODO remove
  T_X
} op16_frm_t;

// register width
typedef enum logic [2-1:0] {
  T16_W,  // word
  T16_D,  // double
  T16_Q,  // quad
  T16_U   // upper immediate for C.LUI instruction
} op16_wdh_t;

///////////////////////////////////////////////////////////////////////////////
// 16-bit OP immediate decoder
///////////////////////////////////////////////////////////////////////////////

function imm_t imm16 (op16_t i, op16_frm_t sel, op16_wdh_t wdh);
  imm16 = '0;
  unique case (sel)
    T_CR:
      imm16 = 'x;
    T_CI:
      case (wdh)
        T16_W: {imm16[5], {imm16[4:2], imm16[7:6]}} = {i.ci.imm_12_12, i.ci.imm_06_02};
        T16_D: {imm16[5], {imm16[4:3], imm16[8:6]}} = {i.ci.imm_12_12, i.ci.imm_06_02};
        T16_Q: {imm16[5], {imm16[4:4], imm16[9:6]}} = {i.ci.imm_12_12, i.ci.imm_06_02};
        T16_U: {imm16[17], imm16[16:12]}            = {i.ci.imm_12_12, i.ci.imm_06_02};  // upper immediate for C.LUI instruction
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
    T_CA:
      imm16 = 'x;
    T_CB:
      {imm16[8], imm16[4:3], imm16[7:6], imm16[2:1], imm16[5]} = {i.cb.off_12_10, i.cb.off_06_02};
    T_CJ:
      {imm16[11], imm16[4], imm16[9:8], imm16[10], imm16[6], imm16[7], imm16[3:1], imm16[5]} = i.cj.target;
    default: imm16 = 'x;
  endcase
endfunction: imm16

function logic [4:0] reg_5 (logic [2:0] reg_3);
  reg_5 = {2'b01, reg_3};
endfunction: reg_5

///////////////////////////////////////////////////////////////////////////////
// 16-bit OP GPR decoder
///////////////////////////////////////////////////////////////////////////////

function gpr_t gpr16 (op16_t op, op16_frm_t frm);
  unique case (frm)   // rs1,rs2,rd                        rs1  ,                rs2  ,                rd
    T_CR   :  gpr16 = '{'{'1, '1, '1}, '{        op.cr .rd_rs1  ,         op.cr .rs2  ,         op.cr .rd_rs1   }};
    T_CI   :  gpr16 = '{'{'1, '0, '1}, '{        op.ci .rd_rs1  ,                  'x ,         op.ci .rd_rs1   }};
    T_CSS  :  gpr16 = '{'{'1, '1, '0}, '{5'h01                  ,         op.css.rs2  ,                      'x }};
    T_CIW  :  gpr16 = '{'{'0, '0, '1}, '{                   'x  ,                  'x , {2'b01, op.ciw.rd_     }}};
    T_CL   :  gpr16 = '{'{'1, '0, '1}, '{{2'b01, op.cl .rs1_   },                  'x , {2'b01, op.cl .rd_     }}};
    T_CS   :  gpr16 = '{'{'1, '1, '0}, '{{2'b01, op.cs .rs1_   }, {2'b01, op.cs .rs2_},                      'x }};
    T_CA   :  gpr16 = '{'{'1, '1, '1}, '{{2'b01, op.ca .rd_rs1_}, {2'b01, op.ca .rs2_}, {2'b01, op.ca .rd_rs1_ }}};
    T_CB   :  gpr16 = '{'{'1, '0, '0}, '{{2'b01, op.cb .rs1_   },                  'x ,                      'x }};
    T_CBS  :  gpr16 = '{'{'1, '0, '0}, '{{2'b01, op.cb .rs1_   },                  'x , {2'b01, op.cb .rs1_    }}};  // shift operations  // TODO: remove if possible
    T_CJ   :  gpr16 = '{'{'0, '0, '1}, '{                   'x  ,                  'x , {4'd0, ~op.cj.funct3[2]}}};  // C.JAL using x1, C.J using x0
    default:  gpr16 = '{'{'0, '0, '0}, '{                   'x  ,                  'x ,                      'x }};
  endcase
endfunction: gpr16

///////////////////////////////////////////////////////////////////////////////
// I base (32E, 32I, 64I, 128I)
// data types
// 4-level type `logic` is used for signals
///////////////////////////////////////////////////////////////////////////////

// PC multiplexer
typedef enum logic [2-1:0] {
  PC_PCI = 2'b00,  // PC increnent address (PC + opsiz)
  PC_BRN = 2'b01,  // branch address (PC + immediate)
  PC_JMP = 2'b11,  // jump address
  PC_EPC = 2'b10   // EPC value from CSR
} pc_t;

// TODO: do this properly
localparam logic [2-1:0] PC_ILL = PC_PCI;

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

// ALU argument 1 multiplexer (RS1,...)
typedef enum logic [1-1:0] {
  A1_RS1  = 1'b0,  // GPR register source 1
  A1_PC   = 1'b1   // zero extended program counter
} a1_t;

// ALU argument 2 multiplexer (RS2,...)
typedef enum logic [1-1:0] {
  A2_RS2 = 1'b0,  // GPR register source 1
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
  WB_ALU = 3'b000,  // arithmetic logic unit
  WB_MEM = 3'b001,  // memory
  WB_PCI = 3'b010,  // program counter increment
  WB_IMM = 3'b011,  // immediate ()
  WB_CSR = 3'b100,  // CSR value
  WB_MUL = 3'b101   // MUL/DIV/REM
} wb_t;

// control structure
typedef struct packed {
  pc_t   pc;   // PC multiplexer
  br_t   br;   // branch type
  a1_t   a1;   // ALU RS1 multiplexer
  a2_t   a2;   // ALU RS1 multiplexer
  ao_t   ao;   // ALU operation
  ar_t   ar;   // ALU result size
  ls_t   ls;   // load/store enable/wrte/sign/size
  wb_t   wb;   // write back multiplexer/enable
} ctl_i_t;

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
typedef struct packed {
  muldiv_t      op;   // operation
  logic [2-1:0] s12;  // sign operand 1/2 (0 - unsigned, 1 - signed)
  logic         xw;   // XWIDTH (0 - full width, 1 - word width (M64 additional opcodes))
  logic         en;   // enable
} ctl_m_t;

///////////////////////////////////////////////////////////////////////////////
// Zicsr standard extension
///////////////////////////////////////////////////////////////////////////////

// CSR operation type
typedef enum logic [2-1:0] {
  CSR_RW  = 2'b0?,  // read/write
  CSR_SET = 2'b10,  // set
  CSR_CLR = 2'b11   // clear
} csr_op_t;

// CSR mask source
typedef enum logic [1-1:0] {
  CSR_REG = 1'b0,  // register
  CSR_IMM = 1'b1   // immediate
} csr_msk_t;

// CSR address
typedef logic [12-1:0] csr_adr_t;

// CSR immediate (zero extended from 5 to 32 bits
typedef logic [5-1:0] csr_imm_t;

// control structure
typedef struct packed {
  logic     wen;  // write enable
  logic     ren;  // read enable
  csr_adr_t adr;  // address
  csr_imm_t imm;  // immediate
  csr_msk_t msk;  // mask
  csr_op_t  op;   // operation
} ctl_csr_t;

///////////////////////////////////////////////////////////////////////////////
// 32-bit instruction decoder
///////////////////////////////////////////////////////////////////////////////

// control structure
typedef struct packed {
  logic      ill;  // illegal
  op32_frm_t f32;  // 32-bit frame type
  gpr_t      gpr;  // GPR control signals
  imm_t      imm;  // immediate select
  ctl_i_t    i;    // integer
  ctl_m_t    m;    // integer multiplication and division
//ctl_a_t    a;    // atomic
//ctl_f_t    f;    // single-precision floating-point
//ctl_d_t    d;    // double-precision floating-point
//ctl_fnc_t  fnc;  // instruction fence
  ctl_csr_t  csr;  // CSR operation
//ctl_q_t    q;    // quad-precision floating-point
//ctl_l_t    l;    // decimal precision floating-point
//ctl_b_t    b;    // bit manipulation
//ctl_j_t    j;    // dynamically translated languages
//ctl_t_t    t;    // transactional memory
//ctl_p_t    p;    // packed-SIMD
//ctl_v_t    v;    // vector operations
//ctl_n_t    n;    // user-level interrupts
} ctl32_t;

// instruction decoder
function ctl32_t dec32 (isa_t isa, op32_t op);

// temporary variable used only to reduce line length
ctl32_t t;

// idle defaults
t.ill = '1;
//      pc    , br, a1, a2, alu, ar, ls   , wb
t.i = '{PC_PCI, 'x, 'x, 'x,  'x, 'x, LS_X , 'x};
//     {op,   s12, xw, en}
t.m = '{'x, 2'bxx, 'x, '0};

// RV32 I base extension
if (|(isa.base | (RV_32I | RV_64I | RV_128I))) begin priority casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210               ill;         frm;        {pc    , br    , a1    , a2    , alu   , ar  , ls   , wb    }
  32'b????_????_????_????_????_????_?011_0111: begin t.ill = '0; t.f32 = T_U; t.i = '{PC_PCI, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X , WB_IMM}; end  // LUI
  32'b????_????_????_????_????_????_?001_0111: begin t.ill = '0; t.f32 = T_U; t.i = '{PC_PCI, 'x    , A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , WB_ALU}; end  // AUIPC
  32'b????_????_????_????_????_????_?110_1111: begin t.ill = '0; t.f32 = T_J; t.i = '{PC_JMP, 'x    , A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , WB_PCI}; end  // JAL  TODO: Instruction-address-misaligned exception
  32'b????_????_????_????_?000_????_?110_0111: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_JMP, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_PCI}; end  // JALR TODO: Instruction-address-misaligned exception
  32'b????_????_????_????_?000_????_?110_0011: begin t.ill = '0; t.f32 = T_B; t.i = '{PC_BRN, BR_EQ , A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , 'x    }; end  // BEQ
  32'b????_????_????_????_?001_????_?110_0011: begin t.ill = '0; t.f32 = T_B; t.i = '{PC_BRN, BR_NE , A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , 'x    }; end  // BNE
  32'b????_????_????_????_?100_????_?110_0011: begin t.ill = '0; t.f32 = T_B; t.i = '{PC_BRN, BR_LTS, A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , 'x    }; end  // BLT
  32'b????_????_????_????_?101_????_?110_0011: begin t.ill = '0; t.f32 = T_B; t.i = '{PC_BRN, BR_GES, A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , 'x    }; end  // BGE
  32'b????_????_????_????_?110_????_?110_0011: begin t.ill = '0; t.f32 = T_B; t.i = '{PC_BRN, BR_LTU, A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , 'x    }; end  // BLTU
  32'b????_????_????_????_?111_????_?110_0011: begin t.ill = '0; t.f32 = T_B; t.i = '{PC_BRN, BR_GEU, A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , 'x    }; end  // BGEU
  32'b????_????_????_????_?000_????_?000_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_BS, WB_MEM}; end  // LB
  32'b????_????_????_????_?001_????_?000_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_HS, WB_MEM}; end  // LH
  32'b????_????_????_????_?010_????_?000_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_WS, WB_MEM}; end  // LW
  32'b????_????_????_????_?100_????_?000_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_BU, WB_MEM}; end  // LBU
  32'b????_????_????_????_?101_????_?000_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_HU, WB_MEM}; end  // LHU
  32'b????_????_????_????_?000_????_?010_0011: begin t.ill = '0; t.f32 = T_S; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, ST_B , 'x    }; end  // SB
  32'b????_????_????_????_?001_????_?010_0011: begin t.ill = '0; t.f32 = T_S; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, ST_H , 'x    }; end  // SH
  32'b????_????_????_????_?010_????_?010_0011: begin t.ill = '0; t.f32 = T_S; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, ST_W , 'x    }; end  // SW
  32'b0000_0000_0000_0000_0000_0000_0001_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X , 'x    }; end  // NOP (ADDI x0, x0, 0), 32'h000000013
  32'b????_????_????_????_?000_????_?001_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_ALU}; end  // ADDI
  32'b????_????_????_????_?010_????_?001_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_LTS, 'x  , LS_X , WB_ALU}; end  // SLTI
  32'b????_????_????_????_?011_????_?001_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_LTU, 'x  , LS_X , WB_ALU}; end  // SLTIU
  32'b????_????_????_????_?100_????_?001_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_XOR, 'x  , LS_X , WB_ALU}; end  // XORI
  32'b????_????_????_????_?110_????_?001_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_OR , 'x  , LS_X , WB_ALU}; end  // ORI
  32'b????_????_????_????_?111_????_?001_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_AND, 'x  , LS_X , WB_ALU}; end  // ANDI
  32'b0000_000?_????_????_?001_????_?001_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SLL, AR_X, LS_X , WB_ALU}; end  // SLLI TODO: illegal imm mask
  32'b0000_000?_????_????_?101_????_?001_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRL, AR_X, LS_X , WB_ALU}; end  // SRLI
  32'b0100_000?_????_????_?101_????_?001_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRA, AR_X, LS_X , WB_ALU}; end  // SRAI
  32'b0000_000?_????_????_?000_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_ADD, AR_X, LS_X , WB_ALU}; end  // ADD
  32'b0100_000?_????_????_?000_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_SUB, AR_X, LS_X , WB_ALU}; end  // SUB
  32'b0000_000?_????_????_?010_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_LTS, 'x  , LS_X , WB_ALU}; end  // SLT
  32'b0000_000?_????_????_?011_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_LTU, 'x  , LS_X , WB_ALU}; end  // SLTU
  32'b0000_000?_????_????_?100_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_XOR, 'x  , LS_X , WB_ALU}; end  // XOR
  32'b0000_000?_????_????_?001_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_SLL, AR_X, LS_X , WB_ALU}; end  // SLL
  32'b0000_000?_????_????_?101_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_SRL, AR_X, LS_X , WB_ALU}; end  // SRL
  32'b0100_000?_????_????_?101_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_SRA, AR_X, LS_X , WB_ALU}; end  // SRA
  32'b0000_000?_????_????_?110_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_OR , 'x  , LS_X , WB_ALU}; end  // OR
  32'b0000_000?_????_????_?111_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_AND, 'x  , LS_X , WB_ALU}; end  // AND
  32'b????_????_????_????_?000_????_?000_1111: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X ,     'x}; end  // FENCE
  default                                    : begin                                                                                                end
endcase end

// RV64 I base extension
if (|(isa.base | (RV_64I | RV_128I))) begin priority casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210               ill;         frm;        {pc    , br    , a1    , a2    , alu   , ar  , ls   , wb    }
  32'b????_????_????_????_?011_????_?000_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_DS, WB_MEM}; end  // LD
  32'b????_????_????_????_?110_????_?000_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_WU, WB_MEM}; end  // LWU
  32'b????_????_????_????_?011_????_?010_0011: begin t.ill = '0; t.f32 = T_S; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, ST_D , 'x    }; end  // SD
  32'b????_????_????_????_?000_????_?001_1011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_W, LS_X , WB_ALU}; end  // ADDIW
  32'b0000_000?_????_????_?001_????_?001_1011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SLL, AR_W, LS_X , WB_ALU}; end  // SLLIW
  32'b0000_000?_????_????_?101_????_?001_1011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRL, AR_W, LS_X , WB_ALU}; end  // SRLIW
  32'b0100_000?_????_????_?101_????_?001_1011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRA, AR_W, LS_X , WB_ALU}; end  // SRAIW
  32'b0000_000?_????_????_?000_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_ADD, AR_W, LS_X , WB_ALU}; end  // ADDW
  32'b0100_000?_????_????_?000_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_SUB, AR_W, LS_X , WB_ALU}; end  // SUBW
  32'b0000_000?_????_????_?001_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_SLL, AR_W, LS_X , WB_ALU}; end  // SLLW
  32'b0000_000?_????_????_?101_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_SRL, AR_W, LS_X , WB_ALU}; end  // SRLW
  32'b0100_000?_????_????_?101_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_SRA, AR_W, LS_X , WB_ALU}; end  // SRAW
  default                                    : begin                                                                                                end
endcase end

// TODO: encoding is not finalized, the only reference I could find was:
// https://github.com/0xDeva/ida-cpu-RISC-V/blob/master/risc-v_opcode_map.txt
// RV128 I base extension
if (|(isa.base | (RV_128I))) begin priority casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210               ill;         frm;        {pc    , br    , a1    , a2    , alu   , ar  , ls   , wb    }
  32'b????_????_????_????_?011_????_?000_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_DS, WB_MEM}; end  // LQ
  32'b????_????_????_????_?110_????_?000_0011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_WU, WB_MEM}; end  // LDU
  32'b????_????_????_????_?011_????_?010_0011: begin t.ill = '0; t.f32 = T_S; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, ST_D , 'x    }; end  // SQ
  32'b????_????_????_????_?000_????_?101_1011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_W, LS_X , WB_ALU}; end  // ADDID
  32'b0000_00??_????_????_?001_????_?101_1011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SLL, AR_W, LS_X , WB_ALU}; end  // SLLID
  32'b0000_00??_????_????_?101_????_?101_1011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRL, AR_W, LS_X , WB_ALU}; end  // SRLID
  32'b0100_00??_????_????_?101_????_?101_1011: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRA, AR_W, LS_X , WB_ALU}; end  // SRAID
  32'b0000_000?_????_????_?000_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_ADD, AR_W, LS_X , WB_ALU}; end  // ADDD
  32'b0100_000?_????_????_?000_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_SUB, AR_W, LS_X , WB_ALU}; end  // SUBD
  32'b0000_000?_????_????_?001_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_SLL, AR_W, LS_X , WB_ALU}; end  // SLLD
  32'b0000_000?_????_????_?101_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_SRL, AR_W, LS_X , WB_ALU}; end  // SRLD
  32'b0100_000?_????_????_?101_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_SRA, AR_W, LS_X , WB_ALU}; end  // SRAD
  default                                    : begin                                                                                                end
endcase end

// RV32 M standard extension
if (|(isa.base | (RV_32I | RV_64I | RV_128I)) & isa.ext.M) begin priority casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210               ill;         frm;        {pc    , br, a1, a2,alu, ar, ls  , wb    }           {   op,   s12, xw, en}
  32'b0000_001?_????_????_?000_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_MUL, 2'b11, '0, '1}; end  // MUL
  32'b0000_001?_????_????_?001_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_MUH, 2'b11, '0, '1}; end  // MULH
  32'b0000_001?_????_????_?010_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_MUH, 2'b10, '0, '1}; end  // MULHSU
  32'b0000_001?_????_????_?011_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_MUH, 2'b00, '0, '1}; end  // MULHU
  32'b0000_001?_????_????_?100_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_DIV, 2'b11, '0, '1}; end  // DIV
  32'b0000_001?_????_????_?101_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_DIV, 2'b00, '0, '1}; end  // DIVU
  32'b0000_001?_????_????_?110_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_REM, 2'b11, '0, '1}; end  // REM
  32'b0000_001?_????_????_?111_????_?011_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_REM, 2'b00, '0, '1}; end  // REMU
  default                                    : begin                                                                                                            end
endcase end

// RV64 M standard extension
if (|(isa.base | (RV_64I | RV_128I)) & isa.ext.M) begin priority casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210               ill;         frm;        {pc    , br, a1, a2,alu, ar, ls  , wb    }           {   op,   s12, xw, en}
  32'b0000_001?_????_????_?000_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_MUL, 2'b11, '1, '1}; end  // MULW
  32'b0000_001?_????_????_?100_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_DIV, 2'b11, '1, '1}; end  // DIVW
  32'b0000_001?_????_????_?101_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_DIV, 2'b10, '1, '1}; end  // DIVUW
  32'b0000_001?_????_????_?110_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_REM, 2'b11, '1, '1}; end  // REMW
  32'b0000_001?_????_????_?111_????_?011_1011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_MUL}; t.m = '{M_REM, 2'b10, '1, '1}; end  // REMUW
  default                                    : begin                                                                                                            end
endcase end

// Zifencei standard extension
if (isa.ext.Zifencei) begin priority casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210               ill;         frm;        {pc    , br    , a1    , a2    , alu   , ar  , ls   , wb    }
  32'b????_????_????_????_?001_????_?000_1111: begin t.ill = '0; t.f32 = T_I; t.i = '{PC_PCI, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X , 'x    }; end  // fence.i
  default                                    : begin                                                                                                end
endcase end

// Zicsr standard extension
if (isa.ext.Zicsr) begin priority casez (op)
  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210               ill;         frm;         pc    , br, a1, a2,alu, ar, ls  , wb                       ren,       wem,       adr,      imm,     msk,     op
  32'b????_????_????_????_?001_????_?111_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_CSR}; t.csr = '{|op.r.rs1,        '1, op[31:20],       'x, CSR_REG, CSR_RW }; end  // CSRRW
  32'b????_????_????_????_?010_????_?111_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_CSR}; t.csr = '{       '1, |op.r.rs1, op[31:20],       'x, CSR_REG, CSR_SET}; end  // CSRRS
  32'b????_????_????_????_?011_????_?111_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_CSR}; t.csr = '{       '1, |op.r.rs1, op[31:20],       'x, CSR_REG, CSR_CLR}; end  // CSRRC
  32'b????_????_????_????_?101_????_?111_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_CSR}; t.csr = '{|op.r.rs1,        '1, op[31:20], op.r.rs1, CSR_IMM, CSR_RW }; end  // CSRRWI
  32'b????_????_????_????_?110_????_?111_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_CSR}; t.csr = '{       '1, |op.r.rs1, op[31:20], op.r.rs1, CSR_IMM, CSR_SET}; end  // CSRRSI
  32'b????_????_????_????_?111_????_?111_0011: begin t.ill = '0; t.f32 = T_R; t.i = '{PC_PCI, 'x, 'x, 'x, 'x, 'x, LS_X, WB_CSR}; t.csr = '{       '1, |op.r.rs1, op[31:20], op.r.rs1, CSR_IMM, CSR_CLR}; end  // CSRRCI
  default                                    : begin                                                                                                                                                     end
endcase end

//// ??? standard extension
//if (???) begin casez (op)
//  //  fedc_ba98_7654_3210_fedc_ba98_7654_3210                frm,   pc    , br    , a1    , a2    , alu   , ar  , ls   , wb
//  32'b0000_0000_0000_0000_0000_0000_0111_0011: {frm, t.i} = {T_R, '{PC_PCI,     'x,     'x,     'x,     'x,   'x, LS_X ,     'x}};  // ecall
//  32'b0000_0000_0001_0000_0000_0000_0111_0011: {frm, t.i} = {T_R, '{PC_PCI,     'x,     'x,     'x,     'x,   'x, LS_X ,     'x}};  // ebreak
//  32'b0001_0000_0000_0000_0000_0000_0111_0011: {frm, t.i} = {T_R, '{PC_EPC,     'x,     'x,     'x,     'x,   'x, LS_X ,     'x}};  // eret
//  32'b0001_0000_0010_0000_0000_0000_0111_0011: {frm, t.i} = {T_R, '{PC_PCI,     'x,     'x,     'x,     'x,   'x, LS_X ,     'x}};  // wfi
// 32'b1000_0000_0000_0000_0000_0000_0111_0011: dec = '{"sret              ", TYPE_32_0};
//endcase end

// GPR and immediate decoders are based on instruction formats
if (~t.ill) begin
  t.gpr = gpr32(op, t.f32);
  t.imm = imm32(op, t.f32);
end

// assign temporary variable to return value
dec32 = t;

endfunction: dec32

///////////////////////////////////////////////////////////////////////////////
// 16-bit instruction decoder
///////////////////////////////////////////////////////////////////////////////

// !!! NOTE !!!
// Define instructions in the next order:
// 1. reserved, illegal instruction (usually nzuimm==0)
// 2. HINT (usually rd==0, nzuimm!=0)
// 3. normal (usually rd!=0, nzuimm!=0)
// If the order is not correct, an illigal instruction might be executed as normal or hint.

// LEGEND:
// RES - REServed for standard extensions
// NSE - reserved for Non Standard Extensions

// control structure
typedef struct packed {
  logic         ill;  // illegal
  op16_frm_t    f16;  // 32-bit frame type
  op16_wdh_t    wdh;  // data width
  logic [5-1:0] brg;  // base regiser
  gpr_t         gpr;  // GPR control signals
  imm_t         imm;  // immediate select
  ctl_i_t       i;    // integer
} ctl16_t;

// instruction decoder
function ctl16_t dec16 (isa_t isa, op16_t op);

// temporary variable used only to reduce line length
ctl16_t t;

// idle defaults
t.ill = '1;
t.f16 = 'x;
//      pc    , br, a1, a2, alu, ar, ls   , wb
t.i = '{PC_PCI, 'x, 'x, 'x,  'x, 'x, LS_X , 'x};

// RV32 I base extension
if (|(isa.base | (RV_32I | RV_64I | RV_128I))) begin priority casez (op)
  //  fedc_ba98_7654_3210               ill;           frm;         wdh  ;         reg           {pc    , br    , a1    , a2    , alu   , ar  , ls   , wb    }
  16'b0000_0000_0000_0000: begin t.ill = '1; t.f16 = T_CIW; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_ILL, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X , 'x    }; end  // illegal instruction
  16'b0000_0000_000?_??00: begin t.ill = '1; t.f16 = T_CIW; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_ALU}; end  // C.ADDI4SP, nzuimm=0, RES
  16'b000?_????_????_??00: begin t.ill = '0; t.f16 = T_CIW; t.wdh = 'x   ; t.brg = 5'h02; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_ALU}; end  // C.ADDI4SP
  16'b010?_????_????_??00: begin t.ill = '0; t.f16 = T_CL ; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_WS, WB_MEM}; end  // C.LW
  16'b100?_????_????_??00: begin t.ill = '1; t.f16 = 'x   ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_ILL, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X , 'x    }; end  // Reserved
  16'b110?_????_????_??00: begin t.ill = '0; t.f16 = T_CS ; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, ST_W , 'x    }; end  // C.SW
  16'b0000_0000_0000_0001: begin t.ill = '0; t.f16 = T_CI ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_ALU}; end  // C.NOP 
  16'b000?_0000_0???_??01: begin t.ill = '0; t.f16 = T_CI ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_ALU}; end  // C.NOP, nzimm!=0, HINT
  16'b0000_????_?000_0001: begin t.ill = '0; t.f16 = T_CI ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_ALU}; end  // C.ADDI, nzimm=0, HINT // TODO prevent WB
  16'b000?_????_????_??01: begin t.ill = '0; t.f16 = T_CI ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_ALU}; end  // C.ADDI
  16'b001?_????_????_??01: begin t.ill = '0; t.f16 = T_CJ ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_JMP, 'x    , A1_PC , A2_IMM, AO_ADD, AR_X, LS_X , WB_PCI}; end  // C.JAL, only RV32, NOTE: there are no restriction on immediate value
  16'b010?_0000_0???_?001: begin t.ill = '0; t.f16 = T_CI ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_PC , A2_IMM, 'x    , 'x  , LS_X , WB_IMM}; end  // C.LI, rd=0, HINT
  16'b010?_????_????_?001: begin t.ill = '0; t.f16 = T_CI ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_PC , A2_IMM, 'x    , 'x  , LS_X , WB_IMM}; end  // C.LI
  16'b0110_0001_0000_0001: begin t.ill = '1; t.f16 = T_CI ; t.wdh = 'x   ; t.brg = 5'h02; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_ALU}; end  // C.ADDI16SP, nzimm=0, RES
  16'b011?_0001_0???_??01: begin t.ill = '0; t.f16 = T_CI ; t.wdh = 'x   ; t.brg = 5'h02; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_ALU}; end  // C.ADDI16SP
  16'b0110_????_?000_0001: begin t.ill = '1; t.f16 = T_CI ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_PC , A2_IMM, 'x    , 'x  , LS_X , WB_IMM}; end  // C.LUI, nzimm=0, RES
  16'b011?_0000_0???_??01: begin t.ill = '0; t.f16 = T_CI ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_PC , A2_IMM, 'x    , 'x  , LS_X , WB_IMM}; end  // C.LUI, rd=0, HINT
  16'b011?_????_????_??01: begin t.ill = '0; t.f16 = T_CI ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_PC , A2_IMM, 'x    , 'x  , LS_X , WB_IMM}; end  // C.LUI
  16'b1001_00??_????_??01: begin t.ill = '1; t.f16 = T_CBS; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRL, AR_X, LS_X , WB_ALU}; end  // C.SRLI, only RV32, nzuimm[5]=1, NSE
  16'b1000_00??_?000_0001: begin t.ill = '0; t.f16 = T_CBS; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRL, AR_X, LS_X , WB_ALU}; end  // C.SRLI, only RV32/64, nzuimm=0, HINT
  16'b100?_00??_????_??01: begin t.ill = '0; t.f16 = T_CBS; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRL, AR_X, LS_X , WB_ALU}; end  // C.SRLI, only RV32/64
  16'b1001_01??_?000_0001: begin t.ill = '1; t.f16 = T_CBS; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRL, AR_X, LS_X , WB_ALU}; end  // C.SRLI, only RV32, nzuimm[5]=1, NSE
  16'b1000_01??_?000_0001: begin t.ill = '0; t.f16 = T_CBS; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRA, AR_X, LS_X , WB_ALU}; end  // C.SRAI, only RV32/64, nzuimm=0, HINT
  16'b100?_01??_????_??01: begin t.ill = '0; t.f16 = T_CBS; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRA, AR_X, LS_X , WB_ALU}; end  // C.SRAI, only RV32/64
  16'b100?_10??_????_??01: begin t.ill = '0; t.f16 = T_CBS; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_AND, 'x  , LS_X , WB_ALU}; end  // C.ANDI
  16'b1000_11??_?00?_??01: begin t.ill = '0; t.f16 = T_CA ; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_SUB, AR_X, LS_X , WB_ALU}; end  // C.SUB
  16'b1000_11??_?01?_??01: begin t.ill = '0; t.f16 = T_CA ; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_XOR, 'x  , LS_X , WB_ALU}; end  // C.XOR
  16'b1000_11??_?10?_??01: begin t.ill = '0; t.f16 = T_CA ; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_OR , 'x  , LS_X , WB_ALU}; end  // C.OR
  16'b1000_11??_?11?_??01: begin t.ill = '0; t.f16 = T_CA ; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_AND, 'x  , LS_X , WB_ALU}; end  // C.AND
  16'b1001_11??_?00?_??01: begin t.ill = '1; t.f16 = 'x   ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_ILL, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X , 'x    }; end  // RES
  16'b1001_11??_?01?_??01: begin t.ill = '1; t.f16 = 'x   ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_ILL, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X , 'x    }; end  // RES
  16'b1001_11??_?10?_??01: begin t.ill = '1; t.f16 = 'x   ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_ILL, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X , 'x    }; end  // Reserved
  16'b1001_11??_?11?_??01: begin t.ill = '1; t.f16 = 'x   ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_ILL, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X , 'x    }; end  // Reserved
  16'b0001_????_????_??10: begin t.ill = '1; t.f16 = 'x   ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_ILL, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X , 'x    }; end  // C.SLLI, only RV32, nzuimm[5]=1, NSE
  16'b0000_0000_0000_0010: begin t.ill = '0; t.f16 = T_CI ; t.wdh = T16_Q; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SLL, AR_X, LS_X , WB_ALU}; end  // C.SLLI, nzuimm=0, rd=0, HINT
  16'b0000_????_?000_0010: begin t.ill = '0; t.f16 = T_CI ; t.wdh = T16_Q; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SLL, AR_X, LS_X , WB_ALU}; end  // C.SLLI, nzuimm=0, HINT
  16'b000?_0000_0???_??10: begin t.ill = '0; t.f16 = T_CI ; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SLL, AR_X, LS_X , WB_ALU}; end  // C.SLLI, rd=0, HINT
  16'b000?_????_????_??10: begin t.ill = '0; t.f16 = T_CI ; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SLL, AR_X, LS_X , WB_ALU}; end  // C.SLLI
  16'b010?_0000_0???_??10: begin t.ill = '1; t.f16 = 'x   ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_ILL, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X , 'x    }; end  // C.LWSP, rd=0, RES
  16'b010?_????_????_??10: begin t.ill = '0; t.f16 = T_CI ; t.wdh = T16_W; t.brg = 5'h02; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_WS, WB_MEM}; end  // C.LWSP
  16'b1000_0000_0000_0010: begin t.ill = '1; t.f16 = 'x   ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_ILL, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X , 'x    }; end  // C.JR, rs1+0, RES
  16'b1000_????_?000_0010: begin t.ill = '0; t.f16 = T_CR ; t.wdh = T16_W; t.brg = 5'h00; t.i = '{PC_JMP, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_PCI}; end  // C.JR  // TODO
  16'b1000_????_????_??10: begin t.ill = '0; t.f16 = T_CR ; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_ADD, AR_X, LS_X , WB_ALU}; end  // C.MV
  16'b1001_0000_0000_0010: begin t.ill = '0; t.f16 = T_CR ; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_ADD, AR_X, LS_X , WB_ALU}; end  // C.EBREAK // TODO
  16'b1001_????_?000_0010: begin t.ill = '0; t.f16 = T_CR ; t.wdh = T16_W; t.brg = 5'h01; t.i = '{PC_JMP, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_PCI}; end  // C.JALR
  16'b1001_????_????_??10: begin t.ill = '0; t.f16 = T_CR ; t.wdh = T16_W; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_ADD, AR_X, LS_X , WB_ALU}; end  // C.ADD
  16'b110?_????_????_??10: begin t.ill = '0; t.f16 = T_CSS; t.wdh = T16_W; t.brg = 5'h02; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, ST_W , 'x    }; end  // C.SWSP
endcase end

// RV32 F standard extension
if (|(isa.base | (RV_32I | RV_64I | RV_128I)) & isa.ext.F) begin priority casez (op)
  16'b011?_????_????_??10: begin t.ill = '0; t.f16 = T_CI ; t.wdh = T16_W; end  // C.FLWSP
endcase end

// RV32 F standard extension
if (|(isa.base | (RV_64I | RV_128I)) & isa.ext.F) begin priority casez (op)
  16'b001?_????_????_??00: begin t.ill = '0; t.f16 = T_CL ; t.wdh = T16_D; end  // C.FLD
  16'b011?_????_????_??00: begin t.ill = '0; t.f16 = T_CL ; t.wdh = T16_W; end  // C.FLW
  16'b101?_????_????_??00: begin t.ill = '0; t.f16 = T_CS ; t.wdh = T16_D; end  // C.FSD
  16'b111?_????_????_??00: begin t.ill = '0; t.f16 = T_CS ; t.wdh = T16_W; end  // C.FSW
  16'b001?_????_????_??10: begin t.ill = '0; t.f16 = T_CI ; t.wdh = T16_W; end  // C.FLDSP
  16'b101?_????_????_??10: begin t.ill = '0; t.f16 = T_CI ; t.wdh = T16_W; end  // C.FSDSP
  16'b111?_????_????_??10: begin t.ill = '0; t.f16 = T_CI ; t.wdh = T16_W; end  // C.FSWSP
endcase end

// RV64 I base extension
if (|(isa.base | (RV_64I | RV_128I))) begin priority casez (op)
  //  fedc_ba98_7654_3210               ill;           frm;         wdh  ;         reg           {pc    , br    , a1    , a2    , alu   , ar  , ls   , wb    }
  16'b011?_????_????_??00: begin t.ill = '0; t.f16 = T_CL ; t.wdh = T16_D; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_DS, WB_MEM}; end  // C.LD
  16'b111?_????_????_??00: begin t.ill = '0; t.f16 = T_CS ; t.wdh = T16_D; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, ST_D , 'x    }; end  // C.SD
  16'b100?_00??_????_??01: begin t.ill = '0; t.f16 = T_CBS; t.wdh = T16_D; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRL, AR_X, LS_X , WB_ALU}; end  // C.SRLI, only RV32/64
  16'b100?_01??_????_??01: begin t.ill = '0; t.f16 = T_CBS; t.wdh = T16_D; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRA, AR_X, LS_X , WB_ALU}; end  // C.SRAI, only RV32/64
  16'b1001_11??_?00?_??01: begin t.ill = '1; t.f16 = T_CA ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_SUB, AR_X, LS_X , WB_ALU}; end  // C.SUBW
  16'b1001_11??_?01?_??01: begin t.ill = '1; t.f16 = T_CA ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_RS2, AO_ADD, AR_X, LS_X , WB_ALU}; end  // C.ADDW
  16'b001?_0000_0???_??01: begin t.ill = '0; t.f16 = T_CI ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_ALU}; end  // C.ADDIW, rd=0, RES
  16'b001?_????_????_??01: begin t.ill = '0; t.f16 = T_CI ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LS_X , WB_ALU}; end  // C.ADDIW
  16'b000?_????_????_??10: begin t.ill = '0; t.f16 = T_CI ; t.wdh = T16_D; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SLL, AR_X, LS_X , WB_ALU}; end  // C.SLLI
  16'b011?_0000_0???_??10: begin t.ill = '1; t.f16 = 'x   ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_ILL, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X , 'x    }; end  // C.LWSP, rd=0, RES
  16'b011?_????_????_??10: begin t.ill = '0; t.f16 = T_CI ; t.wdh = T16_D; t.brg = 5'h02; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_DS, WB_MEM}; end  // C.LWSP
  16'b111?_????_????_??10: begin t.ill = '0; t.f16 = T_CSS; t.wdh = T16_W; t.brg = 5'h02; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, ST_W , 'x    }; end  // C.SDSP
endcase end

// RV128 I base extension
if (|(isa.base | (RV_128I))) begin priority casez (op)
  //  fedc_ba98_7654_3210               ill;           frm;         wdh  ;         reg           {pc    , br    , a1    , a2    , alu   , ar  , ls   , wb    }
  16'b001?_????_????_??00: begin t.ill = '0; t.f16 = T_CL ; t.wdh = T16_Q; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_QS, WB_MEM}; end  // C.LQ
  16'b101?_????_????_??00: begin t.ill = '0; t.f16 = T_CS ; t.wdh = T16_Q; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, ST_Q , 'x    }; end  // C.SQ
  16'b1000_00??_?000_0001: begin t.ill = '0; t.f16 = T_CBS; t.wdh = T16_Q; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRL, AR_X, LS_X , WB_ALU}; end  // C.SRLI64  // TODO: decode immediate as signed
  16'b100?_00??_????_??01: begin t.ill = '0; t.f16 = T_CBS; t.wdh = T16_Q; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRL, AR_X, LS_X , WB_ALU}; end  // C.SRLI
  16'b1000_01??_?000_0001: begin t.ill = '0; t.f16 = T_CBS; t.wdh = T16_Q; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRA, AR_X, LS_X , WB_ALU}; end  // C.SRAI64  // TODO: decode immediate as signed
  16'b100?_01??_????_??01: begin t.ill = '0; t.f16 = T_CBS; t.wdh = T16_Q; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SRA, AR_X, LS_X , WB_ALU}; end  // C.SRAI
  16'b0000_????_?000_0010: begin t.ill = '0; t.f16 = T_CI ; t.wdh = T16_Q; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SLL, AR_X, LS_X , WB_ALU}; end  // C.SLLI64
  16'b000?_????_????_??10: begin t.ill = '0; t.f16 = T_CI ; t.wdh = T16_Q; t.brg = 'x   ; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_SLL, AR_X, LS_X , WB_ALU}; end  // C.SLLI
  16'b001?_0000_0???_??10: begin t.ill = '1; t.f16 = 'x   ; t.wdh = 'x   ; t.brg = 'x   ; t.i = '{PC_ILL, 'x    , 'x    , 'x    , 'x    , 'x  , LS_X , 'x    }; end  // C.LQSP, rd=0, RES
  16'b001?_????_????_??10: begin t.ill = '0; t.f16 = T_CI ; t.wdh = T16_Q; t.brg = 5'h02; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, LD_QS, WB_MEM}; end  // C.LQSP
  16'b101?_????_????_??10: begin t.ill = '0; t.f16 = T_CSS; t.wdh = T16_Q; t.brg = 5'h02; t.i = '{PC_PCI, 'x    , A1_RS1, A2_IMM, AO_ADD, AR_X, ST_Q , 'x    }; end  // C.SQSP
endcase end

// GPR and immediate decoders are based on instruction formats
if (~t.ill) begin
  t.gpr = gpr16(op, t.f16);
  t.imm = imm16(op, t.f16, t.wdh);
end

// assign temporary variable to return value
dec16 = t;

endfunction: dec16

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