package riscv_asm;

///////////////////////////////////////////////////////////////////////////////
// 32 bit instruction format
///////////////////////////////////////////////////////////////////////////////

typedef struct packed {logic [ 6: 0] func7 ;                                                   logic [ 4: 0] rs2      ; logic [ 4: 0] rs1      ; logic [ 2: 0] func3    ; logic [ 4: 0] rd       ;                       logic [ 6: 0] opcode;} t_format_r;
typedef struct packed {logic [ 4: 0] rs3   ; logic [ 1: 0] func2    ;                          logic [ 4: 0] rs2      ; logic [ 4: 0] rs1      ; logic [ 2: 0] func3    ; logic [ 4: 0] rd       ;                       logic [ 6: 0] opcode;} t_format_r4;
typedef struct packed {logic [11:11] imm_11; logic [10: 5] imm_10_05; logic [ 4: 1] imm_04_01; logic [ 0: 0] imm_00   ; logic [ 4: 0] rs1      ; logic [ 2: 0] func3    ; logic [ 4: 0] rd       ;                       logic [ 6: 0] opcode;} t_format_i;
typedef struct packed {logic [11:11] imm_11; logic [10: 5] imm_10_05;                          logic [ 4: 0] rs2      ; logic [ 4: 0] rs1      ; logic [ 2: 0] func3    ; logic [ 4: 1] imm_04_01; logic [ 0: 0] imm_00; logic [ 6: 0] opcode;} t_format_s;
typedef struct packed {logic [12:12] imm_12; logic [10: 5] imm_10_05;                          logic [ 4: 0] rs2      ; logic [ 4: 0] rs1      ; logic [ 2: 0] func3    ; logic [ 4: 1] imm_04_01; logic [11:11] imm_11; logic [ 6: 0] opcode;} t_format_b;
typedef struct packed {logic [31:31] imm_31; logic [30:20] imm_30_20; logic [19:15] imm_19_15; logic [14:12] imm_14_12;                                                   logic [ 4: 0] rd       ;                       logic [ 6: 0] opcode;} t_format_u;
typedef struct packed {logic [20:20] imm_20; logic [10: 5] imm_10_05; logic [ 4: 1] imm_04_01; logic [11:11] imm_11   ; logic [19:15] imm_19_15; logic [14:12] imm_14_12; logic [ 4: 0] rd       ;                       logic [ 6: 0] opcode;} t_format_j;

typedef union packed {
  t_format_r r;
  t_format_r4 r4;
  t_format_i i;
  t_format_s s;
  t_format_b b;
  t_format_u u;
  t_format_j j;
} t_format_32;

typedef enum logic [3:0] {
  TYPE_32_R,
  TYPE_32_R4,
  TYPE_32_I,
  TYPE_32_L,
  TYPE_32_S,
  TYPE_32_B,
  TYPE_32_U,
  TYPE_32_J,
  TYPE_32_0,
  TYPE_32_X
} t_format_sel;

function logic signed [31:0] immediate_32 (t_format_32 i, t_format_sel sel);
  case (sel)
    TYPE_32_L,
    TYPE_32_I: immediate_32 = {{                                                            21{i.i.imm_11}}, i.i.imm_10_05, i.i.imm_04_01, i.i.imm_00}; // s11
    TYPE_32_S: immediate_32 = {                                                            {21{i.s.imm_11}}, i.s.imm_10_05, i.s.imm_04_01, i.s.imm_00}; // s11
    TYPE_32_B: immediate_32 = {                                             {20{i.b.imm_12}},  i.b.imm_11,   i.b.imm_10_05, i.b.imm_04_01, 1'b0      }; // s12
    TYPE_32_U: immediate_32 = {    i.u.imm_31  , i.u .imm_30_20, i.u.imm_19_15, i.u.imm_14_12, 12'h000                                               }; // s31
    TYPE_32_J: immediate_32 = {{12{i.j.imm_20}},                 i.j.imm_19_15, i.j.imm_14_12, i.j.imm_11,   i.j.imm_10_05, i.j.imm_04_01, 1'b0      }; // s20
    default: immediate_32 = 'x;
  endcase
endfunction: immediate_32

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

function logic signed [15:0] immediate_16 (t_format_16 i, t_format_16_sel sel, t_format_16_wdh wdh);
  logic [15:0] imm = '0;
  case (sel)
    TYPE_16_CI:
      case (wdh)
        TYPE_16_W: {imm[5], {imm[4:2], imm[7:6]}} = {i.ci.imm_12_12, i.ci.imm_06_02};
        TYPE_16_D: {imm[5], {imm[4:3], imm[8:6]}} = {i.ci.imm_12_12, i.ci.imm_06_02};
        TYPE_16_Q: {imm[5], {imm[4:4], imm[9:6]}} = {i.ci.imm_12_12, i.ci.imm_06_02};
	default: imm = 'x;
      endcase
    TYPE_16_CSS:
      case (wdh)
        TYPE_16_W: {imm[5:2], imm[7:6]} = i.css.imm_12_07;
        TYPE_16_D: {imm[5:3], imm[8:6]} = i.css.imm_12_07;
        TYPE_16_Q: {imm[5:4], imm[9:6]} = i.css.imm_12_07;
	default: imm = 'x;
      endcase
    TYPE_16_CL,
    TYPE_16_CS:
      case (wdh)
        TYPE_16_W: {imm[5:3], imm[2], imm[  6]} = {i.cl.imm_12_10, i.cl.imm_06_05};
        TYPE_16_D: {imm[5:3],         imm[7:6]} = {i.cl.imm_12_10, i.cl.imm_06_05};
        TYPE_16_Q: {imm[5:4], imm[8], imm[7:6]} = {i.cl.imm_12_10, i.cl.imm_06_05};
	default: imm = 'x;
      endcase
    TYPE_16_CJ:
      {imm[11], imm[4], imm[9:8], imm[10], imm[6], imm[7], imm[3:1], imm[5]} = i.cj.target;
    TYPE_16_CB:
      {imm[8], imm[4:3], imm[7:6], imm[2:1], imm[5]} = {i.cb.off_12_10, i.cb.off_06_02};
    default: imm = 'x;
  endcase
  immediate_16 = imm;
endfunction: immediate_16

function logic [4:0] reg_5 (logic [2:0] reg_3);
  reg_5 = {1'b0, reg_3, 1'b0};
endfunction: reg_5

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

typedef struct {
  string               nam;  // name
//  bit [18-1:0] [8-1:0] nam;  // name
  t_format_sel         typ;  // type
//integer              ext;  // extension
} t_asm;

function t_asm decode_32 (t_format_32 opcode);
  casez (opcode)
    //  fedc_ba98_7654_3210_fedc_ba98_7654_3210
    32'b0000_0000_0000_0000_0000_0000_0001_0011: decode_32 = '{"nop               ", TYPE_32_0};
    32'b0000_0000_0000_0000_0100_0000_0011_0011: decode_32 = '{"-                 ", TYPE_32_0}; // 32'h00004033 - machine generated bubble
    32'b????_????_????_????_?000_????_?110_0011: decode_32 = '{"beq               ", TYPE_32_B};
    32'b????_????_????_????_?001_????_?110_0011: decode_32 = '{"bne               ", TYPE_32_B};
    32'b????_????_????_????_?100_????_?110_0011: decode_32 = '{"blt               ", TYPE_32_B};
    32'b????_????_????_????_?101_????_?110_0011: decode_32 = '{"bge               ", TYPE_32_B};
    32'b????_????_????_????_?110_????_?110_0011: decode_32 = '{"bltu              ", TYPE_32_B};
    32'b????_????_????_????_?111_????_?110_0011: decode_32 = '{"bgeu              ", TYPE_32_B};
    32'b????_????_????_????_?000_????_?110_0111: decode_32 = '{"jalr              ", TYPE_32_L};
    32'b????_????_????_????_????_????_?110_1111: decode_32 = '{"jal               ", TYPE_32_J};
    32'b????_????_????_????_????_????_?011_0111: decode_32 = '{"lui               ", TYPE_32_U};
    32'b????_????_????_????_????_????_?001_0111: decode_32 = '{"auipc             ", TYPE_32_U};
    32'b????_????_????_????_?000_????_?001_0011: decode_32 = '{"addi              ", TYPE_32_I};
    32'b0000_00??_????_????_?001_????_?001_0011: decode_32 = '{"slli              ", TYPE_32_R};
    32'b????_????_????_????_?010_????_?001_0011: decode_32 = '{"slti              ", TYPE_32_I};
    32'b????_????_????_????_?011_????_?001_0011: decode_32 = '{"sltiu             ", TYPE_32_I};
    32'b????_????_????_????_?100_????_?001_0011: decode_32 = '{"xori              ", TYPE_32_I};
    32'b0000_00??_????_????_?101_????_?001_0011: decode_32 = '{"srli              ", TYPE_32_R};
    32'b0100_00??_????_????_?101_????_?001_0011: decode_32 = '{"srai              ", TYPE_32_R};
    32'b????_????_????_????_?110_????_?001_0011: decode_32 = '{"ori               ", TYPE_32_I};
    32'b????_????_????_????_?111_????_?001_0011: decode_32 = '{"andi              ", TYPE_32_I};
    32'b0000_000?_????_????_?000_????_?011_0011: decode_32 = '{"add               ", TYPE_32_R};
    32'b0100_000?_????_????_?000_????_?011_0011: decode_32 = '{"sub               ", TYPE_32_R};
    32'b0000_000?_????_????_?001_????_?011_0011: decode_32 = '{"sll               ", TYPE_32_R};
    32'b0000_000?_????_????_?010_????_?011_0011: decode_32 = '{"slt               ", TYPE_32_R};
    32'b0000_000?_????_????_?011_????_?011_0011: decode_32 = '{"sltu              ", TYPE_32_R};
    32'b0000_000?_????_????_?100_????_?011_0011: decode_32 = '{"xor               ", TYPE_32_R};
    32'b0000_000?_????_????_?101_????_?011_0011: decode_32 = '{"srl               ", TYPE_32_R};
    32'b0100_000?_????_????_?101_????_?011_0011: decode_32 = '{"sra               ", TYPE_32_R};
    32'b0000_000?_????_????_?110_????_?011_0011: decode_32 = '{"or                ", TYPE_32_R};
    32'b0000_000?_????_????_?111_????_?011_0011: decode_32 = '{"and               ", TYPE_32_R};
    32'b????_????_????_????_?000_????_?001_1011: decode_32 = '{"addiw             ", TYPE_32_I};
    32'b0000_000?_????_????_?001_????_?001_1011: decode_32 = '{"slliw             ", TYPE_32_R};
    32'b0000_000?_????_????_?101_????_?001_1011: decode_32 = '{"srliw             ", TYPE_32_R};
    32'b0100_000?_????_????_?101_????_?001_1011: decode_32 = '{"sraiw             ", TYPE_32_R};
    32'b0000_000?_????_????_?000_????_?011_1011: decode_32 = '{"addw              ", TYPE_32_R};
    32'b0100_000?_????_????_?000_????_?011_1011: decode_32 = '{"subw              ", TYPE_32_R};
    32'b0000_000?_????_????_?001_????_?011_1011: decode_32 = '{"sllw              ", TYPE_32_R};
    32'b0000_000?_????_????_?101_????_?011_1011: decode_32 = '{"srlw              ", TYPE_32_R};
    32'b0100_000?_????_????_?101_????_?011_1011: decode_32 = '{"sraw              ", TYPE_32_R};
    32'b????_????_????_????_?000_????_?000_0011: decode_32 = '{"lb                ", TYPE_32_L};
    32'b????_????_????_????_?001_????_?000_0011: decode_32 = '{"lh                ", TYPE_32_L};
    32'b????_????_????_????_?010_????_?000_0011: decode_32 = '{"lw                ", TYPE_32_L};
    32'b????_????_????_????_?011_????_?000_0011: decode_32 = '{"ld                ", TYPE_32_L};
    32'b????_????_????_????_?100_????_?000_0011: decode_32 = '{"lbu               ", TYPE_32_L};
    32'b????_????_????_????_?101_????_?000_0011: decode_32 = '{"lhu               ", TYPE_32_L};
    32'b????_????_????_????_?110_????_?000_0011: decode_32 = '{"lwu               ", TYPE_32_L};
    32'b????_????_????_????_?000_????_?010_0011: decode_32 = '{"sb                ", TYPE_32_S};
    32'b????_????_????_????_?001_????_?010_0011: decode_32 = '{"sh                ", TYPE_32_S};
    32'b????_????_????_????_?010_????_?010_0011: decode_32 = '{"sw                ", TYPE_32_S};
    32'b????_????_????_????_?011_????_?010_0011: decode_32 = '{"sd                ", TYPE_32_S};
    32'b????_????_????_????_?000_????_?000_1111: decode_32 = '{"fence             ", TYPE_32_0};
    32'b????_????_????_????_?001_????_?000_1111: decode_32 = '{"fence.i           ", TYPE_32_0};
    32'b0000_001?_????_????_?000_????_?011_0011: decode_32 = '{"mul               ", TYPE_32_R};
    32'b0000_001?_????_????_?001_????_?011_0011: decode_32 = '{"mulh              ", TYPE_32_R};
    32'b0000_001?_????_????_?010_????_?011_0011: decode_32 = '{"mulhsu            ", TYPE_32_R};
    32'b0000_001?_????_????_?011_????_?011_0011: decode_32 = '{"mulhu             ", TYPE_32_R};
    32'b0000_001?_????_????_?100_????_?011_0011: decode_32 = '{"div               ", TYPE_32_R};
    32'b0000_001?_????_????_?101_????_?011_0011: decode_32 = '{"divu              ", TYPE_32_R};
    32'b0000_001?_????_????_?110_????_?011_0011: decode_32 = '{"rem               ", TYPE_32_R};
    32'b0000_001?_????_????_?111_????_?011_0011: decode_32 = '{"remu              ", TYPE_32_R};
    32'b0000_001?_????_????_?000_????_?011_1011: decode_32 = '{"mulw              ", TYPE_32_R};
    32'b0000_001?_????_????_?100_????_?011_1011: decode_32 = '{"divw              ", TYPE_32_R};
    32'b0000_001?_????_????_?101_????_?011_1011: decode_32 = '{"divuw             ", TYPE_32_R};
    32'b0000_001?_????_????_?110_????_?011_1011: decode_32 = '{"remw              ", TYPE_32_R};
    32'b0000_001?_????_????_?111_????_?011_1011: decode_32 = '{"remuw             ", TYPE_32_R};
    32'b0000_0???_????_????_?010_????_?010_1111: decode_32 = '{"amoadd.w          ", TYPE_32_R};
    32'b0010_0???_????_????_?010_????_?010_1111: decode_32 = '{"amoxor.w          ", TYPE_32_R};
    32'b0100_0???_????_????_?010_????_?010_1111: decode_32 = '{"amoor.w           ", TYPE_32_R};
    32'b0110_0???_????_????_?010_????_?010_1111: decode_32 = '{"amoand.w          ", TYPE_32_R};
    32'b1000_0???_????_????_?010_????_?010_1111: decode_32 = '{"amomin.w          ", TYPE_32_R};
    32'b1010_0???_????_????_?010_????_?010_1111: decode_32 = '{"amomax.w          ", TYPE_32_R};
    32'b1100_0???_????_????_?010_????_?010_1111: decode_32 = '{"amominu.w         ", TYPE_32_R};
    32'b1110_0???_????_????_?010_????_?010_1111: decode_32 = '{"amomaxu.w         ", TYPE_32_R};
    32'b0000_1???_????_????_?010_????_?010_1111: decode_32 = '{"amoswap.w         ", TYPE_32_R};
    32'b0001_0??0_0000_????_?010_????_?010_1111: decode_32 = '{"lr.w              ", TYPE_32_R};
    32'b0001_1???_????_????_?010_????_?010_1111: decode_32 = '{"sc.w              ", TYPE_32_R};
    32'b0000_0???_????_????_?011_????_?010_1111: decode_32 = '{"amoadd.d          ", TYPE_32_R};
    32'b0010_0???_????_????_?011_????_?010_1111: decode_32 = '{"amoxor.d          ", TYPE_32_R};
    32'b0100_0???_????_????_?011_????_?010_1111: decode_32 = '{"amoor.d           ", TYPE_32_R};
    32'b0110_0???_????_????_?011_????_?010_1111: decode_32 = '{"amoand.d          ", TYPE_32_R};
    32'b1000_0???_????_????_?011_????_?010_1111: decode_32 = '{"amomin.d          ", TYPE_32_R};
    32'b1010_0???_????_????_?011_????_?010_1111: decode_32 = '{"amomax.d          ", TYPE_32_R};
    32'b1100_0???_????_????_?011_????_?010_1111: decode_32 = '{"amominu.d         ", TYPE_32_R};
    32'b1110_0???_????_????_?011_????_?010_1111: decode_32 = '{"amomaxu.d         ", TYPE_32_R};
    32'b0000_1???_????_????_?011_????_?010_1111: decode_32 = '{"amoswap.d         ", TYPE_32_R};
    32'b0001_0??0_0000_????_?011_????_?010_1111: decode_32 = '{"lr.d              ", TYPE_32_R};
    32'b0001_1???_????_????_?011_????_?010_1111: decode_32 = '{"sc.d              ", TYPE_32_R};
    32'b0000_0000_0000_0000_0000_0000_0111_0011: decode_32 = '{"scall             ", TYPE_32_0};
    32'b0000_0000_0001_0000_0000_0000_0111_0011: decode_32 = '{"sbreak            ", TYPE_32_0};
    32'b1000_0000_0000_0000_0000_0000_0111_0011: decode_32 = '{"sret              ", TYPE_32_0};
    32'b????_????_????_????_?001_????_?111_0011: decode_32 = '{"csrrw             ", TYPE_32_I};
    32'b????_????_????_????_?010_????_?111_0011: decode_32 = '{"csrrs             ", TYPE_32_I};
    32'b????_????_????_????_?011_????_?111_0011: decode_32 = '{"csrrc             ", TYPE_32_I};
    32'b????_????_????_????_?101_????_?111_0011: decode_32 = '{"csrrwi            ", TYPE_32_I};
    32'b????_????_????_????_?110_????_?111_0011: decode_32 = '{"csrrsi            ", TYPE_32_I};
    32'b????_????_????_????_?111_????_?111_0011: decode_32 = '{"csrrci            ", TYPE_32_I};
    default                                    : decode_32 = '{"csrrci            ", TYPE_32_X};
  endcase
endfunction: decode_32

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

parameter string REG_X [0:31] = '{"zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0/fp", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
                                  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"};
parameter string REG_F [0:31] = '{"ft0", "ft1", "ft2", "ft3", "ft4", "ft5", "ft6", "ft7", "fs0", "fs1", "fa0", "fa1", "fa2", "fa3", "fa4", "fa5",
                                  "fa6", "fa7", "fs2", "fs3", "fs4", "fs5", "fs6", "fs7", "fs8", "fs9", "fs10", "fs11", "ft8", "ft9", "ft10", "ft11"};
parameter string REG_P [0:31] = '{ "cr0", "cr1", "cr2", "cr3", "cr4", "cr5", "cr6", "cr7", "cr8", "cr9","cr10","cr11","cr12","cr13","cr14","cr15",
                                  "cr16","cr17","cr18","cr19","cr20","cr21","cr22","cr23","cr24","cr25","cr26","cr27","cr28","cr29","cr30","cr31"};

function string reg_x (logic [5-1:0] r, bit abi);
  reg_x = abi ? REG_X[r] : $sformatf("r%0d", r);
endfunction: reg_x

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

function string dis_32 (t_format_32 code, bit abi=1);  // enable "ABI" style register names
  logic [32-1:0] imm;
  t_asm op;

  op  = decode_32(code);
  imm = immediate_32(code, op.typ);
  case (op.typ)
    TYPE_32_R:  dis_32 = $sformatf("%s %s, %s, %s"        , op.nam, reg_x(code.r .rd , abi),      reg_x(code.r.rs1, abi), reg_x(code.r.rs2, abi)     );
    TYPE_32_0:  dis_32 = $sformatf("%s"                   , op.nam                                                                                   );
    TYPE_32_I:  dis_32 = $sformatf("%s %s, %s, 0x%03x"    , op.nam, reg_x(code.i .rd , abi),      reg_x(code.i.rs1, abi),                         imm);
    TYPE_32_B:  dis_32 = $sformatf("%s %s, %s, 0x%04x"    , op.nam,                               reg_x(code.b.rs1, abi), reg_x(code.b.rs2, abi), imm);
    TYPE_32_J:  dis_32 = $sformatf("%s 0x%06x"            , op.nam,                                                                               imm);
    TYPE_32_U:  dis_32 = $sformatf("%s %s, 0x%08x"        , op.nam, reg_x(code.u .rd , abi),                                                      imm);
    TYPE_32_L:  dis_32 = $sformatf("%s %s, 0x%03x (%s)"   , op.nam, reg_x(code.i .rd , abi), imm, reg_x(code.i.rs1, abi)                             );
    TYPE_32_S:  dis_32 = $sformatf("%s %s, 0x%03x (%s)"   , op.nam, reg_x(code.s .rs2, abi), imm, reg_x(code.s.rs1, abi)                             );
    default:  dis_32 =           "unknown";
  endcase
endfunction: dis_32

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

//function logic [32-1:0] asm (
//  input byte [128-1:0] str;
//);
//endfunction

endpackage: riscv_asm
