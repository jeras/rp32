///////////////////////////////////////////////////////////////////////////////
// RISC-V ISA C extension package (based on ISA spec)
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

package riscv_isa_c_pkg;

import riscv_isa_pkg::*;
import riscv_isa_i_pkg::*;

///////////////////////////////////////////////////////////////////////////////
// 16-bit compressed instruction format
///////////////////////////////////////////////////////////////////////////////

// 16-bit instruction format structures
typedef struct packed {logic [ 3: 0] funct4;                          logic [ 4: 0] rd_rs1 ;                          logic [ 4: 0] rs2 ; logic [1:0] opcode;} op16_cr_t ;  // Register
typedef struct packed {logic [ 2: 0] funct3; logic [12:12] imm_12_12; logic [ 4: 0] rd_rs1 ; logic [ 6: 2] imm_06_02;                     logic [1:0] opcode;} op16_ci_t ;  // Immediate
typedef struct packed {logic [ 2: 0] funct3; logic [12: 7] imm_12_07;                                                 logic [ 4: 0] rs2 ; logic [1:0] opcode;} op16_css_t;  // Stack-relative Store
typedef struct packed {logic [ 2: 0] funct3; logic [12: 5] imm_12_05;                                                 logic [ 2: 0] rd_ ; logic [1:0] opcode;} op16_ciw_t;  // Wide Immediate
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] imm_12_10; logic [ 2: 0]    rs1_; logic [ 6: 5] imm_06_05; logic [ 2: 0] rd_ ; logic [1:0] opcode;} op16_cl_t ;  // Load
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] imm_12_10; logic [ 2: 0]    rs1_; logic [ 6: 5] imm_06_05; logic [ 2: 0] rs2_; logic [1:0] opcode;} op16_cs_t ;  // Store
typedef struct packed {logic [ 5: 0] funct6;                          logic [ 2: 0] rd_rs1_; logic [ 1: 0] funct2;    logic [ 2: 0] rs2_; logic [1:0] opcode;} op16_ca_t ;  // Arithmetic
typedef struct packed {logic [ 2: 0] funct3; logic [12:10] off_12_10; logic [ 2: 0] rd_rs1_; logic [ 6: 2] off_06_02;                     logic [1:0] opcode;} op16_cb_t ;  // Branch/Arithmetic
typedef struct packed {logic [ 2: 0] funct3; logic [12: 2] off_12_02;                                                                     logic [1:0] opcode;} op16_cj_t ;  // Jump

`ifndef LANGUAGE_UNSUPPORTED_UNION
// union of 16-bit instruction formats
typedef union packed {
  op16_cr_t  cr ;  // Register
  op16_ci_t  ci ;  // Immediate
  op16_css_t css;  // Stack-relative Store
  op16_ciw_t ciw;  // Wide Immediate
  op16_cl_t  cl ;  // Load
  op16_cs_t  cs ;  // Store
  op16_ca_t  ca ;  // Arithmetic
  op16_cb_t  cb ;  // Branch/Arithmetic
  op16_cj_t  cj ;  // Jump
} op16_t;
`endif

// immediate decoder qualifiers
typedef enum {
  T_C_W,  // word   sized load/store
  T_C_D,  // double sized load/store
  T_C_Q   // quad   sized load/store
} op16_qlf_t;

///////////////////////////////////////////////////////////////////////////////
// 16-bit OP immediate decoder
///////////////////////////////////////////////////////////////////////////////

// '{sign extended (signed), 6-bit} signed immediate (CI-type)
function automatic logic signed [6-1:0] imm_ci_f (op16_ci_t op);
  imm_ci_f = $signed({op.imm_12_12, op.imm_06_02});  // signed immediate
endfunction: imm_ci_f

// '{sign extended (signed), 6-bit, scaled by 16} stack pointer adjust immediate (CI-type)
function automatic logic signed [10-1:0] imm_cip_f (op16_ci_t op);
  logic signed [10-1:0] imm = '0;
  {imm[9], imm[4], imm[6], imm[8:7], imm[5]} = {op.imm_12_12, op.imm_06_02};  // C.ADDI16SP
  return imm;
endfunction: imm_cip_f

// '{zero extended (unsigned), 6-bit, scaled by 4/8/16} load immediate (CI_L-type)
function automatic logic unsigned [12-1:0] imm_cil_f (op16_ci_t op, op16_qlf_t qlf);
  logic unsigned [12-1:0] imm = '0;
  case (qlf)
    T_C_W: {imm[5], {imm[4:2], imm[7:6]}} = {op.imm_12_12, op.imm_06_02};  // C.LWSP, C.FLWSP
    T_C_D: {imm[5], {imm[4:3], imm[8:6]}} = {op.imm_12_12, op.imm_06_02};  // C.LDSP, C.FLDSP
    T_C_Q: {imm[5], {imm[4:4], imm[9:6]}} = {op.imm_12_12, op.imm_06_02};  // C.LQSP
    default: imm = 'x;
  endcase
  return imm;
endfunction: imm_cil_f

// '{zero extended (unsigned), 6-bit, scaled by 4/8/16} store immediate (CSS-type)
function automatic logic unsigned [12-1:0] imm_css_f (op16_css_t op, op16_qlf_t qlf);
  logic unsigned [12-1:0] imm = '0;
  case (qlf)
    T_C_W: {imm[5:2], imm[7:6]} = op.imm_12_07;  // C.SWSP, C.FSWSP
    T_C_D: {imm[5:3], imm[8:6]} = op.imm_12_07;  // C.SDSP, C.FSDSP
    T_C_Q: {imm[5:4], imm[9:6]} = op.imm_12_07;  // C.SQSP
    default: imm = 'x;
  endcase
  return imm;
endfunction: imm_css_f

// '{zero extended (unsigned), 6-bit, scaled by 4} load immediate (CIW-type)
function automatic logic unsigned [10-1:0] imm_ciw_f (op16_ciw_t op);
  logic unsigned [10-1:0] imm = '0;
  {imm[5:4], imm[9:6], imm[2], imm[3]} = op.imm_12_05;
  return imm;
endfunction: imm_ciw_f

// '{zero extended (unsigned), 5-bit, scaled by 4/8/16} store immediate (C[LS]-type)
function automatic logic unsigned [12-1:0] imm_cls_f (op16_cl_t op, op16_qlf_t qlf);
  logic unsigned [12-1:0] imm = '0;
  case (qlf)
    T_C_W: {imm[5:3], imm[2], imm[  6]} = {op.imm_12_10, op.imm_06_05};  // C.LW, C.SW, C.FLW, C.FSW
    T_C_D: {imm[5:3],         imm[7:6]} = {op.imm_12_10, op.imm_06_05};  // C.LD, C.SD, C.FLD, C.FSD
    T_C_Q: {imm[5:4], imm[8], imm[7:6]} = {op.imm_12_10, op.imm_06_05};  // C.LQ, C.SQ
    default: imm = 'x;
  endcase
  return imm;
endfunction: imm_cls_f

// branch immediate (CB-type)
function automatic logic signed [8:0] imm_cb_f (op16_cb_t op);
  logic signed [8:0] imm = '0;
  {imm[8], imm[4:3], imm[7:6], imm[2:1], imm[5]} = {op.off_12_10, op.off_06_02};
  return imm;
endfunction: imm_cb_f

// '{sign extended (signed), 11-bit, scaled by 2} jump immediate (CJ-type)
function automatic logic signed [12-1:0] imm_cj_f (op16_cj_t op);
  logic signed [12-1:0] imm;
  {imm[11], imm[4], imm[9:8], imm[10], imm[6], imm[7], imm[3:1], imm[5]} = op.off_12_02;
  imm[0] = 1'b0;
  return imm;
endfunction: imm_cj_f

// upper immediate (CI-type)
function automatic imm_u_t imm_ciu_f (op16_ci_t op);
  imm_ciu_f = 32'($signed({op.imm_12_12, op.imm_06_02, 12'h000}));  // upper immediate for C.LUI instruction
endfunction: imm_ciu_f

///////////////////////////////////////////////////////////////////////////////
// 16-bit instruction decoder
///////////////////////////////////////////////////////////////////////////////

// !!! NOTE !!!
// Define instructions in the next order:
// 1. reserved  OP (usually                imm=0)
// 3. different OP (usually rs2≠x0,             )
// 2. HINT      OP (usually         rd=x0, imm≠0)
// 3. normal    OP (usually rs2≠x0, rd≠x0, imm≠0)
// If the order is not correct, an illigal instruction might be executed as normal or hint.

// instruction decoder
// verilator lint_off CASEOVERLAP
// verilator lint_off CASEINCOMPLETE

`ifndef LANGUAGE_UNSUPPORTED_UNION
function automatic ctl_t dec16 (isa_t isa, op16_t op);
`else
function automatic ctl_t dec16 (isa_t isa, logic [16-1:0] op);
`endif

  // temporary variable used only to reduce line length
  ctl_t t = 'x;

  // GPR configurations
  // the name is constructed as {r (register), _/q (quarter), d (destination), s1/2 (source 1/2)}
  logic [5-1:0] r_d1;  //
  logic [5-1:0] r__2;  //
  logic [5-1:0] rqd_;  //
  logic [5-1:0] rq_1;  //
  logic [5-1:0] rq_2;  //
  logic [5-1:0] rqd1;  //
  
  `ifndef LANGUAGE_UNSUPPORTED_UNION
  // GPR configurations
  r_d1 =         op.cr .rd_rs1  ;  // |CR|CI|   |   |  |  |  |  | types
  r__2 =         op.cr .   rs2  ;  // |CR|  |CSS|   |  |  |  |  | types
  rqd_ = {2'b01, op.ciw.rd_    };  // |  |  |   |CIW|CL|  |  |  | types
  rq_1 = {2'b01, op.cl .   rs1_};  // |  |  |   |   |CL|CS|  |  | types
  rq_2 = {2'b01, op.cs .   rs2_};  // |  |  |   |   |  |CS|CA|  | types
  rqd1 = {2'b01, op.ca .rd_rs1_};  // |  |  |   |   |  |  |CA|CB| types
  `else
  r_d1 =         op[11: 7] ;  // |CR|CI|   |   |  |  |  |  | types
  r__2 =         op[ 6: 2] ;  // |CR|  |CSS|   |  |  |  |  | types
  rqd_ = {2'b01, op[ 4: 2]};  // |  |  |   |CIW|CL|  |  |  | types
  rq_1 = {2'b01, op[ 9: 7]};  // |  |  |   |   |CL|CS|  |  | types
  rq_2 = {2'b01, op[ 4: 2]};  // |  |  |   |   |  |CS|CA|  | types
  rqd1 = {2'b01, op[ 9: 7]};  // |  |  |   |   |  |  |CA|CB| types
  `endif

// RV32 I base extension
if (|(isa.spec.base & (RV_32I | RV_64I | RV_128I))) begin casez (op)
  //  fedc_ba98_7654_3210
//16'b0000_0000_0000_0000: t = '{ill: ILL,                                                                                                                            default: 'x};  // illegal instruction
//16'b0000_0000_000?_??00: t = '{ill: RES, opc: OP_IMM, gpr: '{3'b110, '{rqd_, 5'd2, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: ADD , imm: imm_i_t'(imm_ciw_f(op       ))}, default: 'x};  // C.ADDI4SPN | nzuimm=0
  16'b000?_????_????_??00: t = '{ill: STD, opc: OP_IMM, gpr: '{3'b110, '{rqd_, 5'd2, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: ADD , imm: imm_i_t'(imm_ciw_f(op       ))}, default: 'x};  // C.ADDI4SPN | addi rd', x2, nzuimm
  16'b010?_????_????_??00: t = '{ill: STD, opc: LOAD  , gpr: '{3'b110, '{rqd_, rq_1, 'x  }}, ldu: '{                 fn3: LW  , imm: imm_l_t'(imm_cls_f(op, T_C_W))}, default: 'x};  // C.LW       | lw rd', offset(rs1')
//16'b100?_????_????_??00: t = '{ill: RES,                                                                                                                            default: 'x};  // Reserved
  16'b110?_????_????_??00: t = '{ill: STD, opc: STORE , gpr: '{3'b011, '{'x  , rq_1, rq_2}}, stu: '{                 fn3: SW  , imm: imm_s_t'(imm_cls_f(op, T_C_W))}, default: 'x};  // C.SW       | sw rs2', offset(rs1')
//16'b0000_0000_0000_0001: t = '{ill: STD, opc: OP_IMM, gpr: '{3'b110, '{r_d1, r_d1, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: ADD , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.NOP      | rd=x0, nzimm=0
  16'b000?_0000_0???_??01: t = '{ill: HNT, opc: OP_IMM, gpr: '{3'b110, '{r_d1, r_d1, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: ADD , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.NOP      | rd=x0, nzimm≠0
//16'b0000_????_?000_0001: t = '{ill: HNT, opc: OP_IMM, gpr: '{3'b110, '{r_d1, r_d1, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: ADD , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.ADDI     | nzimm=0 // TODO prevent WB
  16'b000?_????_????_??01: t = '{ill: STD, opc: OP_IMM, gpr: '{3'b110, '{r_d1, r_d1, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: ADD , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.ADDI     | addi rd, rd, nzimm
  16'b001?_????_????_??01: t = '{ill: STD, opc: JAL   , gpr: '{3'b100, '{5'd1, 'x  , 'x  }}, jmp: '{default: 'x,                jmp: imm_j_t'(imm_cj_f (op       ))}, default: 'x};  // C.JAL      | jal x1, offset | only RV32
//16'b010?_0000_0???_??01: t = '{ill: HNT, opc: OP_IMM, gpr: '{3'b110, '{r_d1, 5'd0, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: ADD , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.LI       | rd=x0
  16'b010?_????_????_??01: t = '{ill: STD, opc: OP_IMM, gpr: '{3'b110, '{r_d1, 5'd0, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: ADD , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.LI       | addi rd, x0, imm
//16'b0110_0001_0000_0001: t = '{ill: RES, opc: OP_IMM, gpr: '{3'b110, '{r_d1, 5'd2, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: ADD , imm: imm_i_t'(imm_cip_f(op       ))}, default: 'x};  // C.ADDI16SP | nzimm=0
  16'b011?_0001_0???_??01: t = '{ill: STD, opc: OP_IMM, gpr: '{3'b110, '{r_d1, 5'd2, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: ADD , imm: imm_i_t'(imm_cip_f(op       ))}, default: 'x};  // C.ADDI16SP | addi x2, x2, nzimm
//16'b0110_????_?000_0001: t = '{ill: RES, opc: LUI   , gpr: '{3'b110, '{r_d1, 'x  , 'x  }}, uiu: '{                            imm:          imm_ciu_f(op       ) }, default: 'x};  // C.LUI      | nzimm=0
//16'b011?_0000_0???_??01: t = '{ill: HNT, opc: LUI   , gpr: '{3'b110, '{r_d1, 'x  , 'x  }}, uiu: '{                            imm:          imm_ciu_f(op       ) }, default: 'x};  // C.LUI      | rd=x0
  16'b011?_????_????_??01: t = '{ill: STD, opc: LUI   , gpr: '{3'b110, '{r_d1, 'x  , 'x  }}, uiu: '{                            imm:          imm_ciu_f(op       ) }, default: 'x};  // C.LUI      | lui rd, nzimm
//16'b1001_00??_????_??01: t = '{ill: NSE, opc: OP_IMM, gpr: '{3'b110, '{rqd1, rqd1, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: SR  , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.SRLI     | shamt[5]=1           | only RV32
//16'b1000_00??_?000_0001: t = '{ill: HNT, opc: OP_IMM, gpr: '{3'b110, '{rqd1, rqd1, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: SR  , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.SRLI     | shamt=0              | only RV32/64
  16'b100?_00??_????_??01: t = '{ill: STD, opc: OP_IMM, gpr: '{3'b110, '{rqd1, rqd1, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: SR  , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.SRLI     | srli rd', rd', shamt | only RV32/64
//16'b1001_01??_?000_0001: t = '{ill: NSE, opc: OP_IMM, gpr: '{3'b110, '{rqd1, rqd1, 'x  }}, alu: '{fn7: 7'bx1xxxxx, fn3: SR  , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.SRAI     | shamt[5]=1           | only RV32
//16'b1000_01??_?000_0001: t = '{ill: HNT, opc: OP_IMM, gpr: '{3'b110, '{rqd1, rqd1, 'x  }}, alu: '{fn7: 7'bx1xxxxx, fn3: SR  , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.SRAI     | shamt=0              | only RV32/64
  16'b100?_01??_????_??01: t = '{ill: STD, opc: OP_IMM, gpr: '{3'b110, '{rqd1, rqd1, 'x  }}, alu: '{fn7: 7'bx1xxxxx, fn3: SR  , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.SRAI     | srai rd', rd', shamt | only RV32/64
  16'b100?_10??_????_??01: t = '{ill: STD, opc: OP_IMM, gpr: '{3'b110, '{rqd1, rqd1, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: AND , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.ANDI     | andi rd', rd', imm
  16'b1000_11??_?00?_??01: t = '{ill: STD, opc: OP    , gpr: '{3'b111, '{rqd1, rqd1, rq_2}}, alu: '{fn7: 7'bx1xxxxx, fn3: ADD , imm: 'x                            }, default: 'x};  // C.SUB      | sub rd', rd', rs2'
  16'b1000_11??_?01?_??01: t = '{ill: STD, opc: OP    , gpr: '{3'b111, '{rqd1, rqd1, rq_2}}, alu: '{fn7: 7'bx0xxxxx, fn3: XOR , imm: 'x                            }, default: 'x};  // C.XOR      | xor rd', rd', rs2'
  16'b1000_11??_?10?_??01: t = '{ill: STD, opc: OP    , gpr: '{3'b111, '{rqd1, rqd1, rq_2}}, alu: '{fn7: 7'bx0xxxxx, fn3: OR  , imm: 'x                            }, default: 'x};  // C.OR       | or  rd', rd', rs2'
  16'b1000_11??_?11?_??01: t = '{ill: STD, opc: OP    , gpr: '{3'b111, '{rqd1, rqd1, rq_2}}, alu: '{fn7: 7'bx0xxxxx, fn3: AND , imm: 'x                            }, default: 'x};  // C.AND      | and rd', rd', rs2'
//16'b1001_11??_?00?_??01: t = '{ill: RES,                                                                                                                            default: 'x};  // RES (only RV64/128)
//16'b1001_11??_?01?_??01: t = '{ill: RES,                                                                                                                            default: 'x};  // RES (only RV64/128)
//16'b1001_11??_?10?_??01: t = '{ill: RES,                                                                                                                            default: 'x};  // Reserved
//16'b1001_11??_?11?_??01: t = '{ill: RES,                                                                                                                            default: 'x};  // Reserved
  16'b101?_????_????_??01: t = '{ill: STD, opc: JAL   , gpr: '{3'b100, '{5'd0, 'x  , 'x  }}, jmp: '{default: 'x,                jmp: imm_j_t'(imm_cj_f (op       ))}, default: 'x};  // C.J        | jal x0, offset
  16'b110?_????_????_??01: t = '{ill: STD, opc: BRANCH, gpr: '{3'b011, '{'x  , rqd1, 5'd0}}, bru: '{                 fn3: BEQ , imm: imm_b_t'(imm_cb_f (op       ))}, default: 'x};  // C.BEQZ     | beq rs1', x0, offset
  16'b111?_????_????_??01: t = '{ill: STD, opc: BRANCH, gpr: '{3'b011, '{'x  , rqd1, 5'd0}}, bru: '{                 fn3: BNE , imm: imm_b_t'(imm_cb_f (op       ))}, default: 'x};  // C.BNEZ     | bne rs1', x0, offset
//16'b0001_????_????_??10: t = '{ill: NSE, opc: OP_IMM, gpr: '{3'b110, '{r_d1, r_d1, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: SL  , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.SLLI     | shamt[5]=1     | only RV32
//16'b0000_0000_0000_0010: t = '{ill: HNT, opc: OP_IMM, gpr: '{3'b110, '{r_d1, r_d1, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: SL  , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.SLLI     | shamt=0, rd=x0
//16'b0000_????_?000_0010: t = '{ill: HNT, opc: OP_IMM, gpr: '{3'b110, '{r_d1, r_d1, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: SL  , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.SLLI     | shamt=0
//16'b000?_0000_0???_??10: t = '{ill: HNT, opc: OP_IMM, gpr: '{3'b110, '{r_d1, r_d1, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: SL  , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.SLLI     |          rd=x0
  16'b000?_????_????_??10: t = '{ill: STD, opc: OP_IMM, gpr: '{3'b110, '{r_d1, r_d1, 'x  }}, alu: '{fn7: 7'bx0xxxxx, fn3: SL  , imm: imm_i_t'(imm_ci_f (op       ))}, default: 'x};  // C.SLLI     | slli rd, rd, shamt
//16'b010?_0000_0???_??10: t = '{ill: RES, opc: LOAD  , gpr: '{3'b110, '{r_d1, 5'd2, 'x  }}, ldu: '{                 fn3: LW  , imm: imm_l_t'(imm_cil_f(op, T_C_W))}, default: 'x};  // C.LWSP     | rd=x0
  16'b010?_????_????_??10: t = '{ill: STD, opc: LOAD  , gpr: '{3'b110, '{r_d1, 5'd2, 'x  }}, ldu: '{                 fn3: LW  , imm: imm_l_t'(imm_cil_f(op, T_C_W))}, default: 'x};  // C.LWSP     | lw rd, offset(x2)
//16'b1000_0000_0000_0010: t = '{ill: RES, opc: JALR  , gpr: '{3'b110, '{5'd0, r_d1, 'x  }}, jmp: '{                            imm: '0, default: 'x               }, default: 'x};  // C.JR       | rs1=x0
  16'b1000_????_?000_0010: t = '{ill: STD, opc: JALR  , gpr: '{3'b110, '{5'd0, r_d1, 'x  }}, jmp: '{                            imm: '0, default: 'x               }, default: 'x};  // C.JR       | jalr x0, 0(rs1)
//16'b1000_0000_0???_??10: t = '{ill: HNT, opc: OP    , gpr: '{3'b101, '{r_d1, 5'd0, r__2}}, alu: '{fn7: 7'bx0xxxxx, fn3: ADD , imm: 'x                            }, default: 'x};  // C.MV       | rd=x0, rs2≠x0
  16'b1000_????_????_??10: t = '{ill: STD, opc: OP    , gpr: '{3'b101, '{r_d1, 5'd0, r__2}}, alu: '{fn7: 7'bx0xxxxx, fn3: ADD , imm: 'x                            }, default: 'x};  // C.MV       | add rd, x0, rs2
//16'b1001_0000_0000_0010: t = '{ill: STD, opc: OP    , gpr:                                 alu: '{                 fn3: 'x  , imm:   fi = '{T_CR  , T_X_X};  // C.EBREAK   | rs2=x0
  16'b1001_????_?000_0010: t = '{ill: STD, opc: JALR  , gpr: '{3'b110, '{5'd1, r_d1, 'x  }}, jmp: '{                            imm: '0, default: 'x               }, default: 'x};  // C.JALR     | jalr x1, 0(rs1)
//16'b1001_0000_0???_??10: t = '{ill: HNT, opc: OP    , gpr: '{3'b111, '{r_d1, r_d1, r__2}}, alu: '{fn7: 7'bx0xxxxx, fn3: ADD , imm: 'x                            }, default: 'x};  // C.ADD      | rs2≠x0, rd=x0
  16'b1001_????_????_??10: t = '{ill: STD, opc: OP    , gpr: '{3'b111, '{r_d1, r_d1, r__2}}, alu: '{fn7: 7'bx0xxxxx, fn3: ADD , imm: 'x                            }, default: 'x};  // C.ADD      | add rd, rd, rs2
  16'b110?_????_????_??10: t = '{ill: STD, opc: STORE , gpr: '{3'b011, '{'x  , 5'd2, r__2}}, stu: '{                 fn3: SW  , imm: imm_s_t'(imm_css_f(op, T_C_W))}, default: 'x};  // C.SWSP     | sw rs2, offset(x2)
  default                : t = '{ill: ILL,                                                                                                                            default: 'x};  // illegal instruction
endcase end

/*
// privileged mode
if (isa.priv.M) begin casez (op)
  //  fedc_ba98_7654_3210             '{  frm ,   qlf};         ill;            ena , typ                   pc    , br  , alu        , lsu , wb    };
  16'b1001_0000_0000_0010: begin fi = '{T_CR  , T_X_X}; t.ill = STD; t.priv = '{1'b1, PRIV_EBREAK}; t.i = '{PC_TRP, BXXX, CTL_ALU_ILL, LS_X, WB_XXX}; end  // C.EBREAK
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
  //  fedc_ba98_7654_3210             '{  frm ,   qlf};         ill;       '{opc   , br  , '{ao     , rt  }, lsu };
  16'b011?_????_????_??00: begin fi = '{T_CL  , T_C_D}; t.ill = STD; t.i = '{LOAD  , BXXX, '{AO_ADD , R_SX}, L_DS}; end  // C.LD    | ld rd', offset(rs1')
  16'b111?_????_????_??00: begin fi = '{T_CS  , T_C_D}; t.ill = STD; t.i = '{STORE , BXXX, '{AO_ADD , R_SX}, S_D }; end  // C.SD    | sd rs2', offset(rs1')
  16'b1000_00??_?000_0001: begin fi = '{T_CB_A, T_C_D}; t.ill = HNT; t.i = '{OP_IMM, BXXX, '{AO_SRL , R_UX}, LS_X}; end  // C.SRLI  | shamt=0
  16'b100?_00??_????_??01: begin fi = '{T_CB_A, T_C_D}; t.ill = STD; t.i = '{OP_IMM, BXXX, '{AO_SRL , R_UX}, LS_X}; end  // C.SRLI  | srli rd', rd', shamt | only RV32/64
  16'b1000_01??_?000_0001: begin fi = '{T_CB_A, T_C_D}; t.ill = HNT; t.i = '{OP_IMM, BXXX, '{AO_SRA , R_SX}, LS_X}; end  // C.SRAI  | shamt=0
  16'b100?_01??_????_??01: begin fi = '{T_CB_A, T_C_D}; t.ill = STD; t.i = '{OP_IMM, BXXX, '{AO_SRA , R_SX}, LS_X}; end  // C.SRAI  | srai rd', rd', shamt | only RV32/64
  16'b1001_11??_?00?_??01: begin fi = '{T_CA  , T_X_X}; t.ill = STD; t.i = '{OP    , BXXX, '{AO_SUB , R_SW}, LS_X}; end  // C.SUBW  | subw rd', rd', rs2'
  16'b1001_11??_?01?_??01: begin fi = '{T_CA  , T_X_X}; t.ill = STD; t.i = '{OP    , BXXX, '{AO_ADD , R_SW}, LS_X}; end  // C.ADDW  | addw rd', rd', rs2'
  16'b001?_0000_0???_??01: begin fi = '{T_CI  , T_C_S}; t.ill = RES; t.i = '{OP_IMM, BXXX, '{AO_ADD , R_SW}, LS_X}; end  // C.ADDIW | rd=x0
  16'b001?_????_????_??01: begin fi = '{T_CI  , T_C_S}; t.ill = STD; t.i = '{OP_IMM, BXXX, '{AO_ADD , R_SW}, LS_X}; end  // C.ADDIW | addiw rd, rd, imm
  16'b000?_????_????_??10: begin fi = '{T_CI  , T_C_U}; t.ill = STD; t.i = '{OP_IMM, BXXX, '{AO_SLL , R_XX}, LS_X}; end  // C.SLLI  | slli rd, rd, shamt
  16'b011?_0000_0???_??10: begin fi = '{T_CI_L, T_C_D}; t.ill = RES; t.i = '{LOAD  , BXXX, '{AO_ADD , R_SX}, L_DS}; end  // C.LDSP  | rd=x0
  16'b011?_????_????_??10: begin fi = '{T_CI_L, T_C_D}; t.ill = STD; t.i = '{LOAD  , BXXX, '{AO_ADD , R_SX}, L_DS}; end  // C.LDSP  | ld rd, offset(x2)
  16'b111?_????_????_??10: begin fi = '{T_CSS , T_C_D}; t.ill = STD; t.i = '{STORE , BXXX, '{AO_ADD , R_SX}, S_D }; end  // C.SDSP  | sd rs2, offset(x2)
endcase end

// RV128 I base extension
if (|(isa.spec.base & (RV_128I))) begin casez (op)
  //  fedc_ba98_7654_3210             '{  frm ,   qlf};         ill;       '{opc   , br  , '{ao     , rt  }, lsu };
//16'b001?_????_????_??00: begin fi = '{T_CL  , T_C_Q}; t.ill = STD; t.i = '{LOAD  , BXXX, '{AO_ADD , R_SX}, L_QS}; end  // C.LQ     | lq rd', offset(rs1') // TODO: load quad encoding not supported yet
  16'b101?_????_????_??00: begin fi = '{T_CS  , T_C_Q}; t.ill = STD; t.i = '{STORE , BXXX, '{AO_ADD , R_SX}, S_Q }; end  // C.SQ     | sq rs2', offset(rs1')
  16'b1000_00??_?000_0001: begin fi = '{T_CB_A, T_C_Q}; t.ill = STD; t.i = '{OP_IMM, BXXX, '{AO_SRL , R_UX}, LS_X}; end  // C.SRLI64 | srli rd', rd', 64 {shamt=0}
  16'b100?_00??_????_??01: begin fi = '{T_CB_A, T_C_Q}; t.ill = STD; t.i = '{OP_IMM, BXXX, '{AO_SRL , R_UX}, LS_X}; end  // C.SRLI   | srli rd', rd', shamt // TODO: decode immediate as signed
  16'b1000_01??_?000_0001: begin fi = '{T_CB_A, T_C_Q}; t.ill = STD; t.i = '{OP_IMM, BXXX, '{AO_SRA , R_SX}, LS_X}; end  // C.SRAI64 | srai rd', rd', 64 {shamt=0}
  16'b100?_01??_????_??01: begin fi = '{T_CB_A, T_C_Q}; t.ill = STD; t.i = '{OP_IMM, BXXX, '{AO_SRA , R_SX}, LS_X}; end  // C.SRAI   | srai rd', rd', shamt // TODO: decode immediate as signed
  16'b0000_????_?000_0010: begin fi = '{T_CI  , T_C_Q}; t.ill = STD; t.i = '{OP_IMM, BXXX, '{AO_SLL , R_XX}, LS_X}; end  // C.SLLI64 | slli rd, rd, 64 {shamt=0}
  16'b000?_????_????_??10: begin fi = '{T_CI  , T_C_Q}; t.ill = STD; t.i = '{OP_IMM, BXXX, '{AO_SLL , R_XX}, LS_X}; end  // C.SLLI   | slli rd, rd, shamt   // TODO: decode immediate as signed
//16'b001?_0000_0???_??10: begin fi = '{T_CI_L, T_C_Q}; t.ill = RES; t.i = '{LOAD  , BXXX, '{AO_ADD , R_SX}, L_QS}; end  // C.LQSP   | rd = 0
//16'b001?_????_????_??10: begin fi = '{T_CI_L, T_C_Q}; t.ill = STD; t.i = '{LOAD  , BXXX, '{AO_ADD , R_SX}, L_QS}; end  // C.LQSP   | lq rd, offset(x2)    // TODO: load quad encoding not supported yet
  16'b101?_????_????_??10: begin fi = '{T_CSS , T_C_Q}; t.ill = STD; t.i = '{STORE , BXXX, '{AO_ADD , R_SX}, S_Q }; end  // C.SQSP   | sq rs2, offset(x2)
endcase end
*/
// GPR and immediate decoders are based on instruction formats
// TODO: also handle RES/NSE
//if (t.ill != ILL) begin
//  t.imm = imm_c_f(op, fi.f, fi.q);
//  t.gpr = gpr_c_f(op, fi.f);
//end

// set instruction size
t.siz = 2;

// assign temporary variable to return value
dec16 = t;

endfunction: dec16
// verilator lint_on CASEOVERLAP
// verilator lint_on CASEINCOMPLETE

endpackage: riscv_isa_c_pkg