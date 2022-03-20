///////////////////////////////////////////////////////////////////////////////
// R5P: arithmetic/logic unit (ALU)
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

import riscv_isa_pkg::*;

module r5p_alu #(
  int unsigned XLEN = 32,
  // timing versus area compromises
  bit          CFG_LSA = 1'b0,  // enable dedicated Load/Store Adder
  bit          CFG_LOM = 1'b0,  // enable dedicated Logical Operand Multiplexer
  bit          CFG_SOM = 1'b1   // enable dedicated Shift   Operand Multiplexer
)(
  // system signals
  input  logic            clk,  // clock
  input  logic            rst,  // reset
  // control structure from instruction decode
  input  ctl_t            ctl,
  // data input/output
  input  logic [XLEN-1:0] pc ,  // PC
  input  logic [XLEN-1:0] rs1,  // source register 1
  input  logic [XLEN-1:0] rs2,  // source register 2
  output logic [XLEN-1:0] rd ,  // destination register
  // side ouputs
  output logic [XLEN-0:0] sum   // summation result including overflow bit
);

// logarithm of XLEN
localparam int unsigned XLOG = $clog2(XLEN);

// arithmetic operands (sign extended by 1 bit)
logic [XLEN-0:0] add_op1;  // arithmetic operand 1
logic [XLEN-0:0] add_op2;  // arithmetic operand 2
// invert operand 2
logic            add_inv;

// logical operands
logic [XLEN-1:0] log_op1;  // logical operand 1
logic [XLEN-1:0] log_op2;  // logical operand 2

// barrel shifter shift ammount
logic [XLOG-1:0] shf_mux;  // multiplexed
logic [XLOG-1:0] shf_sam;
// bit reversed operand/result
logic [XLEN-1:0] shf_tmp;  // operand
logic [XLEN-1:0] shf_val;  // result

// operation result
logic [XLEN-1:0] val;

///////////////////////////////////////////////////////////////////////////////
// arithmetic operations
///////////////////////////////////////////////////////////////////////////////

function automatic logic [XLEN-0:0] extend (logic [XLEN-1:0] val, result_sign_t sgn);
  unique casez (sgn)
    R_S    : extend = (XLEN+1)'(  signed'(val));  //   signed
    R_U    : extend = (XLEN+1)'(unsigned'(val));  // unsigned
    default: extend = 'x;
  endcase
endfunction: extend

result_sign_t sgn;
assign sgn = result_sign_t'(ctl.i.alu.rt[2]);

// ALU input multiplexer and signed/unsigned extension
generate
if (CFG_LSA) begin: gen_lsa_ena

  // verilator lint_off WIDTH
  // load/store address adders are implemented outside the ALU
  // TODO: it appears commenting out the AI_R1_IL line has negative timing/area efec with Xilinx Vivado 2021.2 on Arty
  // NOTE: for Arty enable the AI_R1_IL line
  always_comb
  unique casez (ctl.i.opc)
    OP     ,
    BRANCH : unique casez (ctl.i.alu.rt[1:0])                                                  // R-type
        R_X    :  begin add_op1 = extend(rs1        , sgn);  add_op2 = extend(rs2        , sgn);  end
        R_W    :  begin add_op1 = extend(rs1[32-1:0], sgn);  add_op2 = extend(rs2[32-1:0], sgn);  end
        default:  begin add_op1 = 'x;                        add_op2 = 'x;                        end
      endcase
    JALR   ,
    OP_IMM :      begin add_op1 = extend(rs1        , sgn);  add_op2 = extend(ctl.imm.i  , sgn);  end  // I-type (arithmetic/logic)
  //LOAD   :      begin add_op1 = extend(rs1        , R_S);  add_op2 = extend(ctl.imm.l  , R_S);  end  // I-type (load)
  //STORE  :      begin add_op1 = extend(rs1        , R_S);  add_op2 = extend(ctl.imm.s  , R_S);  end  // S-type (store)
    AUIPC  :      begin add_op1 = extend(pc         , R_S);  add_op2 = extend(ctl.imm.u  , R_S);  end  // U-type
    JAL    :      begin add_op1 = extend(pc         , R_S);  add_op2 = extend(ctl.imm.j  , R_S);  end  // J-type (jump)
    default:      begin add_op1 = 'x ;                       add_op2 = 'x;                        end
  endcase
  // verilator lint_on WIDTH

end:gen_lsa_ena
else begin: gen_lsa_alu

  // verilator lint_off WIDTH
  // ALU is used to calculate load/store address
  always_comb
  unique casez (ctl.i.opc)
    OP     ,
    BRANCH : unique casez (ctl.i.alu.rt[1:0])                                                  // R-type
        R_X    :  begin add_op1 = extend(rs1        , sgn);  add_op2 = extend(rs2        , sgn);  end
        R_W    :  begin add_op1 = extend(rs1[32-1:0], sgn);  add_op2 = extend(rs2[32-1:0], sgn);  end
        default:  begin add_op1 = 'x;                        add_op2 = 'x;                        end
      endcase
    JALR   ,
    OP_IMM :      begin add_op1 = extend(rs1        , sgn);  add_op2 = extend(ctl.imm.i  , sgn);  end  // I-type (arithmetic/logic)
    LOAD   :      begin add_op1 = extend(rs1        , R_S);  add_op2 = extend(ctl.imm.l  , R_S);  end  // I-type (load)
    STORE  :      begin add_op1 = extend(rs1        , R_S);  add_op2 = extend(ctl.imm.s  , R_S);  end  // S-type (store)
    AUIPC  :      begin add_op1 = extend(pc         , R_S);  add_op2 = extend(ctl.imm.u  , R_S);  end  // U-type
    JAL    :      begin add_op1 = extend(pc         , R_S);  add_op2 = extend(ctl.imm.j  , R_S);  end  // J-type (jump)
    default:      begin add_op1 = 'x ;                       add_op2 = 'x;                        end
  endcase
  // verilator lint_on WIDTH

end: gen_lsa_alu
endgenerate

// TODO: check which keywords would best optimize this statement
// invert arithmetic operand 2 (bit 5 of f7 segment of operand)
always_comb
unique casez (ctl.i.alu.ao)
  AO_ADD : add_inv = 1'b0;
  AO_SUB ,
  AO_SLT ,
  AO_SLTU: add_inv = 1'b1;
  default: add_inv = 1'bx;
endcase

// adder (summation, subtraction)
assign sum = $signed(add_op1) + $signed(add_inv ? ~add_op2 : add_op2) + $signed((XLEN+1)'(add_inv));
//assign sum = $signed(add_op1) + $signed(add_op2) + $signed((XLEN+1)'(add_inv));

///////////////////////////////////////////////////////////////////////////////
// bitwise logical operations
///////////////////////////////////////////////////////////////////////////////

// logical operands
// NOTE: logical operations are not in the crytical path,
//       therefore a dedicated input multiple does not provide much improvement
generate
if (CFG_LOM) begin: gen_lom_ena

  // dedicated logical operand multiplexer
  always_comb
  unique casez (ctl.i.opc)
    OP     : begin log_op1 = rs1; log_op2 = rs2;              end  // R-type
    OP_IMM : begin log_op1 = rs1; log_op2 = XLEN'(ctl.imm.i); end  // I-type (arithmetic/logic)
    default: begin log_op1 = 'x ; log_op2 = 'x;               end
  endcase

end:gen_lom_ena
else begin: gen_lom_alu

  // shared ALU common multiplexer
//assign log_op1 = rs1;
  assign log_op1 = add_op1[XLEN-1:0];
  assign log_op2 = add_op2[XLEN-1:0];

end: gen_lom_alu
endgenerate

///////////////////////////////////////////////////////////////////////////////
// barrel shifter
///////////////////////////////////////////////////////////////////////////////

// reverse bit order
function automatic logic [XLEN-1:0] bitrev (logic [XLEN-1:0] val);
`ifndef ALTERA_RESERVED_QIS
  bitrev = {<<{val}};
`else
  for (int unsigned i=0; i<XLEN; i++)  bitrev[i] = val[XLEN-1-i];
`endif
endfunction: bitrev

generate
if (CFG_SOM) begin: gen_som_ena

  // shift ammount multiplexer
  always_comb
  unique casez (ctl.i.opc)
    OP     : shf_mux = rs2      [XLOG-1:0];
    OP_IMM : shf_mux = ctl.imm.i[XLOG-1:0];
    default: shf_mux = 'x;
  endcase

end:gen_som_ena
else begin: gen_som_alu

  // shift ammount multiplexer shared with logic
  assign shf_mux = log_op2[XLOG-1:0];

end: gen_som_alu
endgenerate

// shift ammount length
always_comb
unique casez (ctl.i.alu.rt[1:0])
  R_X    : shf_sam =         shf_mux[XLOG-1:0] ;  // XLEN
  R_W    : shf_sam = (XLOG)'(shf_mux[   5-1:0]);  // word
  default: shf_sam = 'x;
endcase

// bit inversion
always_comb
unique casez (ctl.i.alu.ao)
  // barrel shifter
  AO_SRA, AO_SRL : shf_tmp =        rs1 ;
          AO_SLL : shf_tmp = bitrev(rs1);
  default        : shf_tmp = 'x;
endcase

// combined barrel shifter for left/right shifting
always_comb
unique casez (ctl.i.alu.ao)
  // barrel shifter
  AO_SRA         : shf_val =   $signed(shf_tmp) >>> shf_sam;
  AO_SRL, AO_SLL : shf_val = $unsigned(shf_tmp)  >> shf_sam;
  default        : shf_val = 'x;
endcase

///////////////////////////////////////////////////////////////////////////////
// output multiplexer
///////////////////////////////////////////////////////////////////////////////

// operations
always_comb
unique casez (ctl.i.alu.ao)
  // adder based instructions
  AO_ADD ,
  AO_SUB : val = XLEN'(sum);
  AO_SLT ,
  AO_SLTU: val = XLEN'(sum[XLEN]);
  // bitwise logical operations
  AO_AND : val = log_op1 & log_op2;
  AO_OR  : val = log_op1 | log_op2;
  AO_XOR : val = log_op1 ^ log_op2;
  // barrel shifter
  AO_SRA : val =        shf_val ;
  AO_SRL : val =        shf_val ;
  AO_SLL : val = bitrev(shf_val);
  default: val = 'x;
endcase

// handling operations narower than XLEN
// TODO: check if all or only adder based instructions have 32 versions
always_comb
unique casez (ctl.i.alu.rt[1:0])
  R_X    : rd =                 val          ;  // XLEN
  R_W    : rd = (XLEN)'($signed(val[32-1:0]));  // sign extended word
  default: rd = 'x;
endcase

endmodule: r5p_alu