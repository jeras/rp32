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
  // optimizations: timing versus area compromises
  bit          CFG_LSA = 1'b0,  // enable dedicated Load/Store Adder
  bit          CFG_LOM = 1'b0,  // enable dedicated Logical Operand Multiplexer
  bit          CFG_SOM = 1'b0,  // enable dedicated Shift   Operand Multiplexer
  bit          CFG_L4M = 1'b0   // enable dedicated 4 to 1 Logic    Multiplexer
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

// arithmetic operands multiplexer
logic [XLEN-1:0] mux_op1;  // arithmetic operand 1
logic [XLEN-1:0] mux_op2;  // arithmetic operand 2
// arithmetic operands (sign extended by 1 bit)
logic [XLEN-0:0] add_op1;  // arithmetic operand 1
logic [XLEN-0:0] add_op2;  // arithmetic operand 2
// arithmetic operation sign.signedness
logic            add_inv;
logic            add_sgn;

// logical operands
logic [XLEN-1:0] log_op1;  // logical operand 1
logic [XLEN-1:0] log_op2;  // logical operand 2
logic [XLEN-1:0] log_val;  // logical result

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

// signed/unsigned extension
function automatic logic [XLEN-0:0] extend (logic [XLEN-1:0] val, logic sgn);
  unique casez (sgn)
    1'b1   : extend = (XLEN+1)'(  signed'(val));  //   signed
    1'b0   : extend = (XLEN+1)'(unsigned'(val));  // unsigned
    default: extend = 'x;
  endcase
endfunction: extend

// ALU input multiplexer and signed/unsigned extension
always_comb
unique case (ctl.i.opc)
  OP     ,                                                         // R-type (arithmetic/logic)
  BRANCH : begin mux_op1 = rs1;  mux_op2 = rs2             ;  end  // B-type (branch)
  JALR   ,                                                         // I-type (jump)
  OP_IMM : begin mux_op1 = rs1;  mux_op2 = XLEN'(ctl.imm.i);  end  // I-type (arithmetic/logic)
  LOAD   : begin mux_op1 = rs1;  mux_op2 = XLEN'(ctl.imm.l);  end  // I-type (load)
  STORE  : begin mux_op1 = rs1;  mux_op2 = XLEN'(ctl.imm.s);  end  // S-type (store)
  AUIPC  : begin mux_op1 = pc ;  mux_op2 = XLEN'(ctl.imm.u);  end  // U-type
  JAL    : begin mux_op1 = pc ;  mux_op2 = XLEN'(ctl.imm.j);  end  // J-type (jump)
  default: begin mux_op1 = 'x ;  mux_op2 = 'x;                end
endcase

// TODO: check which keywords would best optimize this statement
// invert arithmetic operand 2 (bit 5 of f7 segment of operand)
always_comb
unique case (ctl.i.opc)
  OP     : unique case (ctl.i.alu.f3)
      ADD    : begin add_inv = ctl.i.alu.f7_5; add_sgn = 1'b1; end
      SLT    : begin add_inv = 1'b1; add_sgn = 1'b1; end
      SLTU   : begin add_inv = 1'b1; add_sgn = 1'b0; end
      default: begin add_inv = 1'bx; add_sgn = 1'bx; end
    endcase
  OP_IMM : unique case (ctl.i.alu.f3)
      ADD    : begin add_inv = 1'b0; add_sgn = 1'b1; end
      SLT    : begin add_inv = 1'b1; add_sgn = 1'b1; end
      SLTU   : begin add_inv = 1'b1; add_sgn = 1'b0; end
      default: begin add_inv = 1'bx; add_sgn = 1'bx; end
    endcase
  BRANCH : unique case (ctl.i.bru)
      BEQ    ,
      BNE    : begin add_inv = 1'b1; add_sgn = 1'bx; end
      BLT    ,
      BGE    : begin add_inv = 1'b1; add_sgn = 1'b1; end
      BLTU   ,
      BGEU   : begin add_inv = 1'b1; add_sgn = 1'b0; end
      default: begin add_inv = 1'bx; add_sgn = 1'bx; end
    endcase
  JALR   ,
  LOAD   ,
  STORE  ,
  AUIPC  ,
  JAL    : begin add_inv = 1'b0; add_sgn = 1'bx; end
  default: begin add_inv = 1'bx; add_sgn = 1'bx; end
endcase

always add_op1 = extend(mux_op1, add_sgn);
always add_op2 = extend(mux_op2, add_sgn);

// adder (summation, subtraction)
assign sum = $signed(add_op1) + $signed(add_inv ? ~add_op2 : add_op2) + $signed((XLEN+1)'(add_inv));

///////////////////////////////////////////////////////////////////////////////
// bitwise logical operations
///////////////////////////////////////////////////////////////////////////////

// logical operands
// NOTE: logical operations are not in the crytical path,
//       therefore a dedicated input multiplexer does not provide much improvement
// NOTE: enabled is favored on Altera Quartus - Cylone V,
//       disabled is favored on Xilinx Vivado - Artix.
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
  assign log_op1 = rs1;      // TODO: better on Altera Cyclone V
//assign log_op1 = mux_op1;  // TODO: better on Xilinx Artix
  assign log_op2 = mux_op2;

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

//// shift ammount length
assign shf_sam = shf_mux[XLOG-1:0] ;  // XLEN

// bit inversion
always_comb
unique casez (ctl.i.alu.f3)
  // barrel shifter
  SR     : shf_tmp =        rs1 ;
  SL     : shf_tmp = bitrev(rs1);
  default: shf_tmp = 'x;
endcase

// combined barrel shifter for left/right shifting
always_comb
unique casez (ctl.i.alu.f7_5)
  // barrel shifter
  1'b1   : shf_val =   $signed(shf_tmp) >>> shf_sam;
  1'b0   : shf_val = $unsigned(shf_tmp)  >> shf_sam;
  default: shf_val = 'x;
endcase

///////////////////////////////////////////////////////////////////////////////
// output multiplexer
///////////////////////////////////////////////////////////////////////////////

generate
if (CFG_L4M) begin: gen_l4m_ena

  // this can be implemented with a single LUT4
  always_comb
  unique case (ctl.i.alu.f3)
    // bitwise logical operations
    AND    : log_val = log_op1 & log_op2;
    OR     : log_val = log_op1 | log_op2;
    XOR    : log_val = log_op1 ^ log_op2;
    default: log_val = 'x;
  endcase

  // operations
  always_comb
  unique case (ctl.i.opc)
    OP     ,
    OP_IMM : unique case (ctl.i.alu.f3)
        // adder based instructions
        ADD : val = XLEN'(sum);
        SLT ,
        SLTU: val = XLEN'(sum[XLEN]);
        // bitwise logical operations
        AND ,
        OR  ,
        XOR : val = log_val;
        // barrel shifter
        SR  : val =        shf_val ;
        SL  : val = bitrev(shf_val);
      endcase
    AUIPC  : val = XLEN'(sum);
    default: val = 'x;
  endcase

end:gen_l4m_ena
else begin: gen_l4m_alu

  // operations
  always_comb
  unique case (ctl.i.opc)
    OP     ,
    OP_IMM : unique case (ctl.i.alu.f3)
        // adder based instructions
        ADD : val = XLEN'(sum);
        SLT ,
        SLTU: val = XLEN'(sum[XLEN]);
        // bitwise logical operations
        AND : val = log_op1 & log_op2;
        OR  : val = log_op1 | log_op2;
        XOR : val = log_op1 ^ log_op2;
        // barrel shifter
        SR  : val =        shf_val ;
        SL  : val = bitrev(shf_val);
      endcase
    AUIPC  : val = XLEN'(sum);
    default: val = 'x;
  endcase

end: gen_l4m_alu
endgenerate

assign rd = val;  // XLEN

endmodule: r5p_alu
