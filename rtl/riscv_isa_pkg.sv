package riscv_isa_pkg;

///////////////////////////////////////////////////////////////////////////////
// 32 bit instruction format
///////////////////////////////////////////////////////////////////////////////

typedef struct packed {logic [4:0] rs3; logic [1:0] func2;          logic [4:0] rs2; logic [4:0] rs1; logic [2:0] func3; logic [4:0] rd     ;                    logic [6:0] opcode;} t_format_r4;
typedef struct packed {                 logic [6:0] func7;          logic [4:0] rs2; logic [4:0] rs1; logic [2:0] func3; logic [4:0] rd     ;                    logic [6:0] opcode;} t_format_r;
typedef struct packed {logic [11:00] imm_11_0;                                       logic [4:0] rs1; logic [2:0] func3; logic [4:0] rd     ;                    logic [6:0] opcode;} t_format_i;
typedef struct packed {logic [11:05] imm_11_5;                      logic [4:0] rs2; logic [4:0] rs1; logic [2:0] func3; logic [4:0] imm_4_0;                    logic [6:0] opcode;} t_format_s;
typedef struct packed {logic [12:12] imm_12; logic [10:5] imm_10_5; logic [4:0] rs2; logic [4:0] rs1; logic [2:0] func3; logic [4:1] imm_4_1; logic [11] imm_11; logic [6:0] opcode;} t_format_b;
typedef struct packed {logic [31:12] imm_31_12;                                                                          logic [4:0] rd     ;                    logic [6:0] opcode;} t_format_u;
typedef struct packed {logic [20:20] imm_20; logic [10:1] imm_10_01; logic [11] imm_11; logic [19:12] imm_19_12;         logic [4:0] rd     ;                    logic [6:0] opcode;} t_format_j;

typedef union packed {
  t_format_r4 r4;
  t_format_r r;
  t_format_i i;
  t_format_s s;
  t_format_b b;
  t_format_u u;
  t_format_j j;
} t_format_32;

typedef enum logic [3:0] {
  TYPE_32_R4,
  TYPE_32_R,
  TYPE_32_I,
  TYPE_32_S,
  TYPE_32_B,
  TYPE_32_U,
  TYPE_32_J
} t_format_sel;

function logic signed [32-1:0] imm32 (t_format_32 i, t_format_sel sel);
  case (sel)
    TYPE_32_R4,
    TYPE_32_R: imm32 = 'x;
    TYPE_32_I: imm32 = {{20[i[31]}},        i[30:25], i[24:21], i[20]}; // s11
    TYPE_32_S: imm32 = {{20[i[31]}},        i[30:25], i[11:08], i[07]}; // s11
    TYPE_32_B: imm32 = {{19[i[31]}}, i[07], i[30:25], i[11:08], 1'b0 }; // s12
    TYPE_32_U: imm32 = {    i[31:12], 12'h000}; // s31
    TYPE_32_J: imm32 = {{12{i[31]}}, i[19:12], i[20], i[30:25], i[24:21], 1'b0}; // s20
    default:   imm32 = 'x;
  endcase
endfunction: imm32

///////////////////////////////////////////////////////////////////////////////
// 16 bit instruction format
///////////////////////////////////////////////////////////////////////////////

typedef struct packed {logic [ 3: 0] funct4;                          logic [ 4: 0] rd_rs1;                          logic [ 4: 0] rs2 ; logic [1:0] opcode;} t_format_cr;
typedef struct packed {logic [ 2: 0] funct3; logic [12:12] imm_12_12; logic [ 4: 0] rd_rs1; logic [ 6: 2] imm_06_02;                     logic [1:0] opcode;} t_format_ci;
typedef struct packed {logic [ 2: 0] funct3; logic [12: 7] imm_12_07; logic [ 4: 0] rd_rs1;                          logic [ 4: 0] rs2 ; logic [1:0] opcode;} t_format_css;
typedef struct packed {logic [ 2: 0] funct3; logic [12: 5] imm_12_05;                                                logic [ 2: 0] rd_ ; logic [1:0] opcode;} t_format_ciw;
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] imm_12_10; logic [ 2: 0] rs1_  ; logic [ 6: 5] imm_06_05; logic [ 2: 0] rd_ ; logic [1:0] opcode;} t_format_cl;
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] imm_12_10; logic [ 2: 0] rs1_  ; logic [ 6: 5] imm_06_05; logic [ 2: 0] rs2_; logic [1:0] opcode;} t_format_cs;
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] off_12_10; logic [ 2: 0] rs1_  ; logic [ 6: 2] off_06_02;                     logic [1:0] opcode;} t_format_cb;
typedef struct packed {logic [ 2: 0] funct3; logic [12: 2] target;                                                                       logic [1:0] opcode;} t_format_cj;

typedef union packed {
  t_format_cr  cr;
  t_format_ci  ci;
  t_format_css css;
  t_format_ciw ciw;
  t_format_cl  cl;
  t_format_cs  cs;
  t_format_cb  cb;
  t_format_cj  cj;
} t_format_16;

typedef enum logic [3:0] {
  TYPE_16_CR,
  TYPE_16_CI,
  TYPE_16_CSS,
  TYPE_16_CIW,
  TYPE_16_CL,
  TYPE_16_CS,
  TYPE_16_CB,
  TYPE_16_CJ
} t_format_16_sel;

// register width
typedef enum logic [3:0] {
  TYPE_16_W,
  TYPE_16_D,
  TYPE_16_Q
} t_format_16_wdh;

function logic signed [15:0] imm16 (t_format_16 i, t_format_16_sel sel, t_format_16_wdh wdh);
  logic [15:0] imm16 = '0;
  case (sel)
    TYPE_16_CR:
	imm16 = 'x;
    TYPE_16_CI:
      case (wdh)
        TYPE_16_W: {imm16[5], {imm16[4:2], imm16[7:6]}} = {i.ci.imm_12_12, i.ci.imm_06_02};
        TYPE_16_D: {imm16[5], {imm16[4:3], imm16[8:6]}} = {i.ci.imm_12_12, i.ci.imm_06_02};
        TYPE_16_Q: {imm16[5], {imm16[4:4], imm16[9:6]}} = {i.ci.imm_12_12, i.ci.imm_06_02};
	default: imm16 = 'x;
      endcase
    TYPE_16_CSS:
      case (wdh)
        TYPE_16_W: {imm16[5:2], imm16[7:6]} = i.css.imm_12_07;
        TYPE_16_D: {imm16[5:3], imm16[8:6]} = i.css.imm_12_07;
        TYPE_16_Q: {imm16[5:4], imm16[9:6]} = i.css.imm_12_07;
	default: imm16 = 'x;
      endcase
    TYPE_16_CL,
    TYPE_16_CS:
      case (wdh)
        TYPE_16_W: {imm16[5:3], imm16[2], imm16[  6]} = {i.cl.imm_12_10, i.cl.imm_06_05};
        TYPE_16_D: {imm16[5:3],           imm16[7:6]} = {i.cl.imm_12_10, i.cl.imm_06_05};
        TYPE_16_Q: {imm16[5:4], imm16[8], imm16[7:6]} = {i.cl.imm_12_10, i.cl.imm_06_05};
	default: imm16 = 'x;
      endcase
    TYPE_16_CJ:
      {imm16[11], imm16[4], imm16[9:8], imm16[10], imm16[6], imm16[7], imm16[3:1], imm16[5]} = i.cj.target;
    TYPE_16_CB:
      {imm16[8], imm16[4:3], imm16[7:6], imm16[2:1], imm16[5]} = {i.cb.off_12_10, i.cb.off_06_02};
    default: imm16 = 'x;
  endcase
endfunction: immediate_16

function logic [4:0] reg_5 (logic [2:0] reg_3);
  reg_5 = {1'b0, reg_3, 1'b0};
endfunction: reg_5

endpackage: riscv_isa_pkg
